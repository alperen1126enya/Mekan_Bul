import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'mekanbul.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add latitude and longitude columns to mekanlar
      await db.execute('ALTER TABLE mekanlar ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE mekanlar ADD COLUMN longitude REAL');
      
      // Create mekan_photos table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS mekan_photos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mekan_id INTEGER NOT NULL,
          photo_url TEXT NOT NULL,
          uploaded_by INTEGER,
          created_at TEXT NOT NULL,
          FOREIGN KEY (mekan_id) REFERENCES mekanlar(id) ON DELETE CASCADE,
          FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL
        )
      ''');
      
      // Create notifications table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          type TEXT NOT NULL,
          reference_id INTEGER,
          is_read INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');
      
      // Update existing mekanlar with coordinates
      await _updateMekanlarWithCoordinates(db);
    }
    
    if (oldVersion < 3) {
      // Create menu_items table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS menu_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mekan_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          price REAL NOT NULL,
          category TEXT NOT NULL,
          image_url TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (mekan_id) REFERENCES mekanlar(id) ON DELETE CASCADE
        )
      ''');
      
      // Add sample menu items only if table is empty
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM menu_items');
      if ((count.first['count'] as int) == 0) {
        await _insertSampleMenuItems(db);
      }
    }
  }

  Future<void> _updateMekanlarWithCoordinates(Database db) async {
    final coordinates = {
      'Nusret Steakhouse': {'lat': 41.0823, 'lng': 29.0288},
      'Starbucks Bağdat Caddesi': {'lat': 40.9676, 'lng': 29.0570},
      'Burger King Taksim': {'lat': 41.0370, 'lng': 28.9850},
      'Club XL Istanbul': {'lat': 41.1128, 'lng': 29.0207},
      'Kahve Dünyası Levent': {'lat': 41.0794, 'lng': 29.0107},
      'The House Cafe Ortaköy': {'lat': 41.0477, 'lng': 29.0269},
      'Bebek Bar': {'lat': 41.0767, 'lng': 29.0433},
      'McDonalds Mecidiyeköy': {'lat': 41.0674, 'lng': 28.9963},
      'Reina Club': {'lat': 41.0477, 'lng': 29.0272},
      'Petra Rooftop': {'lat': 41.0220, 'lng': 28.9768},
      'Gloria Jeans Coffees': {'lat': 41.0612, 'lng': 28.9916},
      'Popeyes Ataşehir': {'lat': 40.9923, 'lng': 29.1099},
    };
    
    for (final entry in coordinates.entries) {
      await db.update(
        'mekanlar',
        {'latitude': entry.value['lat'], 'longitude': entry.value['lng']},
        where: 'name = ?',
        whereArgs: [entry.key],
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Mekanlar table with latitude and longitude
    await db.execute('''
      CREATE TABLE mekanlar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        age_min INTEGER NOT NULL,
        age_max INTEGER NOT NULL,
        rating REAL DEFAULT 0.0,
        address TEXT NOT NULL,
        maps_url TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        created_at TEXT NOT NULL
      )
    ''');

    // Yorumlar table
    await db.execute('''
      CREATE TABLE yorumlar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mekan_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        rating INTEGER NOT NULL CHECK(rating >= 1 AND rating <= 5),
        comment TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (mekan_id) REFERENCES mekanlar(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Favorites table
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        mekan_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (mekan_id) REFERENCES mekanlar(id) ON DELETE CASCADE,
        UNIQUE(user_id, mekan_id)
      )
    ''');

    // Recently viewed table
    await db.execute('''
      CREATE TABLE recently_viewed (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        mekan_id INTEGER NOT NULL,
        viewed_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (mekan_id) REFERENCES mekanlar(id) ON DELETE CASCADE
      )
    ''');

    // Mekan photos table
    await db.execute('''
      CREATE TABLE mekan_photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mekan_id INTEGER NOT NULL,
        photo_url TEXT NOT NULL,
        uploaded_by INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (mekan_id) REFERENCES mekanlar(id) ON DELETE CASCADE,
        FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT NOT NULL,
        reference_id INTEGER,
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Menu items table
    await db.execute('''
      CREATE TABLE menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mekan_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        category TEXT NOT NULL,
        image_url TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (mekan_id) REFERENCES mekanlar(id) ON DELETE CASCADE
      )
    ''');

    // Insert sample mekanlar
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    final sampleMekanlar = [
      {
        'name': 'Nusret Steakhouse',
        'category': 'restoran',
        'age_min': 18,
        'age_max': 65,
        'rating': 4.8,
        'address': 'Etiler, Nisbetiye Cad. No:87, Beşiktaş/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Nusret+Steakhouse+Istanbul',
        'latitude': 41.0823,
        'longitude': 29.0288,
        'created_at': now,
      },
      {
        'name': 'Starbucks Bağdat Caddesi',
        'category': 'cafe',
        'age_min': 12,
        'age_max': 65,
        'rating': 4.5,
        'address': 'Bağdat Cad. No:123, Kadıköy/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Starbucks+Bagdat+Caddesi',
        'latitude': 40.9676,
        'longitude': 29.0570,
        'created_at': now,
      },
      {
        'name': 'Burger King Taksim',
        'category': 'fast_food',
        'age_min': 8,
        'age_max': 65,
        'rating': 4.2,
        'address': 'İstiklal Cad. No:45, Beyoğlu/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Burger+King+Taksim',
        'latitude': 41.0370,
        'longitude': 28.9850,
        'created_at': now,
      },
      {
        'name': 'Club XL Istanbul',
        'category': 'eglence',
        'age_min': 21,
        'age_max': 45,
        'rating': 4.7,
        'address': 'Maslak, Büyükdere Cad. No:200, Sarıyer/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Club+XL+Istanbul',
        'latitude': 41.1128,
        'longitude': 29.0207,
        'created_at': now,
      },
      {
        'name': 'Kahve Dünyası Levent',
        'category': 'cafe',
        'age_min': 15,
        'age_max': 60,
        'rating': 4.4,
        'address': 'Levent, Kanyon AVM, Beşiktaş/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Kahve+Dunyasi+Levent',
        'latitude': 41.0794,
        'longitude': 29.0107,
        'created_at': now,
      },
      {
        'name': 'The House Cafe Ortaköy',
        'category': 'restoran',
        'age_min': 16,
        'age_max': 55,
        'rating': 4.6,
        'address': 'Ortaköy Sahili, Beşiktaş/İstanbul',
        'maps_url': 'https://maps.google.com/?q=House+Cafe+Ortakoy',
        'latitude': 41.0477,
        'longitude': 29.0269,
        'created_at': now,
      },
      {
        'name': 'Bebek Bar',
        'category': 'bar',
        'age_min': 21,
        'age_max': 50,
        'rating': 4.3,
        'address': 'Bebek Sahili, Beşiktaş/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Bebek+Bar+Istanbul',
        'latitude': 41.0767,
        'longitude': 29.0433,
        'created_at': now,
      },
      {
        'name': 'McDonalds Mecidiyeköy',
        'category': 'fast_food',
        'age_min': 5,
        'age_max': 70,
        'rating': 4.0,
        'address': 'Mecidiyeköy Meydan, Şişli/İstanbul',
        'maps_url': 'https://maps.google.com/?q=McDonalds+Mecidiyekoy',
        'latitude': 41.0674,
        'longitude': 28.9963,
        'created_at': now,
      },
      {
        'name': 'Reina Club',
        'category': 'eglence',
        'age_min': 21,
        'age_max': 40,
        'rating': 4.9,
        'address': 'Ortaköy, Muallım Naci Cad., Beşiktaş/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Reina+Istanbul',
        'latitude': 41.0477,
        'longitude': 29.0272,
        'created_at': now,
      },
      {
        'name': 'Petra Rooftop',
        'category': 'restoran',
        'age_min': 18,
        'age_max': 55,
        'rating': 4.5,
        'address': 'Karaköy, Kemeraltı Cad., Beyoğlu/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Petra+Rooftop+Istanbul',
        'latitude': 41.0220,
        'longitude': 28.9768,
        'created_at': now,
      },
      {
        'name': 'Gloria Jeans Coffees',
        'category': 'cafe',
        'age_min': 10,
        'age_max': 65,
        'rating': 4.1,
        'address': 'Cevahir AVM, Şişli/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Gloria+Jeans+Cevahir',
        'latitude': 41.0612,
        'longitude': 28.9916,
        'created_at': now,
      },
      {
        'name': 'Popeyes Ataşehir',
        'category': 'fast_food',
        'age_min': 8,
        'age_max': 60,
        'rating': 4.3,
        'address': 'Ataşehir Bulvarı, Ataşehir/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Popeyes+Atasehir',
        'latitude': 40.9923,
        'longitude': 29.1099,
        'created_at': now,
      },
      // New restaurants
      {
        'name': 'Midpoint Zorlu',
        'category': 'restoran',
        'age_min': 16,
        'age_max': 55,
        'rating': 4.6,
        'address': 'Zorlu Center, Beşiktaş/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Midpoint+Zorlu+Center',
        'latitude': 41.0665,
        'longitude': 29.0167,
        'created_at': now,
      },
      {
        'name': 'Caribou Coffee Kanyon',
        'category': 'cafe',
        'age_min': 12,
        'age_max': 65,
        'rating': 4.4,
        'address': 'Kanyon AVM, Levent/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Caribou+Coffee+Kanyon',
        'latitude': 41.0793,
        'longitude': 29.0113,
        'created_at': now,
      },
      {
        'name': 'Köfteci Yusuf',
        'category': 'restoran',
        'age_min': 8,
        'age_max': 70,
        'rating': 4.5,
        'address': 'Kadıköy Çarşı, Kadıköy/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Kofteci+Yusuf+Kadikoy',
        'latitude': 40.9903,
        'longitude': 29.0238,
        'created_at': now,
      },
      {
        'name': 'Klein Guduchi',
        'category': 'bar',
        'age_min': 21,
        'age_max': 45,
        'rating': 4.7,
        'address': 'Asmalımescit, Beyoğlu/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Klein+Guduchi+Istanbul',
        'latitude': 41.0298,
        'longitude': 28.9756,
        'created_at': now,
      },
      {
        'name': 'Dominos Pizza Beşiktaş',
        'category': 'fast_food',
        'age_min': 8,
        'age_max': 65,
        'rating': 4.1,
        'address': 'Sinanpaşa Mah., Beşiktaş/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Dominos+Pizza+Besiktas',
        'latitude': 41.0425,
        'longitude': 29.0024,
        'created_at': now,
      },
      {
        'name': 'Papa Johns Şişli',
        'category': 'fast_food',
        'age_min': 8,
        'age_max': 65,
        'rating': 4.2,
        'address': 'Halaskargazi Cad., Şişli/İstanbul',
        'maps_url': 'https://maps.google.com/?q=Papa+Johns+Sisli',
        'latitude': 41.0584,
        'longitude': 28.9873,
        'created_at': now,
      },
    ];

    for (final mekan in sampleMekanlar) {
      await db.insert('mekanlar', mekan);
    }

    // Insert sample photos for mekanlar
    final samplePhotos = [
      // Nusret (1)
      {'mekan_id': 1, 'photo_url': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800', 'created_at': now},
      {'mekan_id': 1, 'photo_url': 'https://images.unsplash.com/photo-1558030006-450675393462?w=800', 'created_at': now},
      {'mekan_id': 1, 'photo_url': 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=800', 'created_at': now},
      // Starbucks (2)
      {'mekan_id': 2, 'photo_url': 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800', 'created_at': now},
      {'mekan_id': 2, 'photo_url': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800', 'created_at': now},
      {'mekan_id': 2, 'photo_url': 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=800', 'created_at': now},
      // Burger King (3)
      {'mekan_id': 3, 'photo_url': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800', 'created_at': now},
      {'mekan_id': 3, 'photo_url': 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=800', 'created_at': now},
      // Club XL (4)
      {'mekan_id': 4, 'photo_url': 'https://images.unsplash.com/photo-1566737236500-c8ac43014a67?w=800', 'created_at': now},
      {'mekan_id': 4, 'photo_url': 'https://images.unsplash.com/photo-1571204829887-3b8d69e4094d?w=800', 'created_at': now},
      // Kahve Dünyası (5)
      {'mekan_id': 5, 'photo_url': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800', 'created_at': now},
      {'mekan_id': 5, 'photo_url': 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=800', 'created_at': now},
      // The House Cafe (6)
      {'mekan_id': 6, 'photo_url': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800', 'created_at': now},
      {'mekan_id': 6, 'photo_url': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800', 'created_at': now},
      // Bebek Bar (7)
      {'mekan_id': 7, 'photo_url': 'https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=800', 'created_at': now},
      {'mekan_id': 7, 'photo_url': 'https://images.unsplash.com/photo-1572116469696-31de0f17cc34?w=800', 'created_at': now},
      // McDonalds (8)
      {'mekan_id': 8, 'photo_url': 'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=800', 'created_at': now},
      {'mekan_id': 8, 'photo_url': 'https://images.unsplash.com/photo-1586816001966-79b736744398?w=800', 'created_at': now},
      // Reina (9)
      {'mekan_id': 9, 'photo_url': 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800', 'created_at': now},
      // Petra Rooftop (10)
      {'mekan_id': 10, 'photo_url': 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=800', 'created_at': now},
      {'mekan_id': 10, 'photo_url': 'https://images.unsplash.com/photo-1559329007-40df8a9345d8?w=800', 'created_at': now},
      // Gloria Jeans (11)
      {'mekan_id': 11, 'photo_url': 'https://images.unsplash.com/photo-1453614512568-c4024d13c247?w=800', 'created_at': now},
      // Popeyes (12)
      {'mekan_id': 12, 'photo_url': 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=800', 'created_at': now},
      // Midpoint (13)
      {'mekan_id': 13, 'photo_url': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800', 'created_at': now},
      {'mekan_id': 13, 'photo_url': 'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?w=800', 'created_at': now},
      // Caribou Coffee (14)
      {'mekan_id': 14, 'photo_url': 'https://images.unsplash.com/photo-1447933601403-0c6688de566e?w=800', 'created_at': now},
      // Köfteci Yusuf (15)
      {'mekan_id': 15, 'photo_url': 'https://images.unsplash.com/photo-1529042410759-ceddc12c4257?w=800', 'created_at': now},
      {'mekan_id': 15, 'photo_url': 'https://images.unsplash.com/photo-1603360946369-dc9bb6258143?w=800', 'created_at': now},
      // Klein Guduchi (16)
      {'mekan_id': 16, 'photo_url': 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800', 'created_at': now},
      // Dominos (17)
      {'mekan_id': 17, 'photo_url': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800', 'created_at': now},
      {'mekan_id': 17, 'photo_url': 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=800', 'created_at': now},
      // Papa Johns (18)
      {'mekan_id': 18, 'photo_url': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800', 'created_at': now},
    ];

    for (final photo in samplePhotos) {
      await db.insert('mekan_photos', photo);
    }

    // Insert sample menu items
    await _insertSampleMenuItems(db);
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> _insertSampleMenuItems(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    // Nusret Steakhouse Menu (mekan_id: 1)
    final nusretMenu = [
      {'name': 'Ottoman Steak', 'description': 'Dana antrikot, özel baharatlar', 'price': 1200.0, 'category': 'Ana Yemekler'},
      {'name': 'Nusret Burger', 'description': 'El yapımı köfte, özel sos', 'price': 450.0, 'category': 'Ana Yemekler'},
      {'name': 'Kaburga', 'description': 'Uzun pişirilmiş dana kaburga', 'price': 850.0, 'category': 'Ana Yemekler'},
      {'name': 'Lokum Et', 'description': 'Fileto minyondan özel kesim', 'price': 1500.0, 'category': 'Ana Yemekler'},
      {'name': 'Baklava', 'description': 'Antep fıstıklı', 'price': 180.0, 'category': 'Tatlılar'},
      {'name': 'Künefe', 'description': 'Geleneksel tarif', 'price': 150.0, 'category': 'Tatlılar'},
      {'name': 'Türk Kahvesi', 'description': 'Klasik', 'price': 60.0, 'category': 'İçecekler'},
      {'name': 'Ayran', 'description': 'Ev yapımı', 'price': 40.0, 'category': 'İçecekler'},
    ];

    for (final item in nusretMenu) {
      await db.insert('menu_items', {
        'mekan_id': 1,
        'name': item['name'],
        'description': item['description'],
        'price': item['price'],
        'category': item['category'],
        'created_at': now,
      });
    }

    // Starbucks Menu (mekan_id: 2)
    final starbucksMenu = [
      {'name': 'Caffe Latte', 'description': 'Espresso, süt', 'price': 85.0, 'category': 'Kahveler'},
      {'name': 'Cappuccino', 'description': 'Espresso, süt köpüğü', 'price': 80.0, 'category': 'Kahveler'},
      {'name': 'Americano', 'description': 'Espresso, sıcak su', 'price': 70.0, 'category': 'Kahveler'},
      {'name': 'Mocha', 'description': 'Espresso, çikolata, süt', 'price': 95.0, 'category': 'Kahveler'},
      {'name': 'Caramel Macchiato', 'description': 'Karamel, espresso, süt', 'price': 105.0, 'category': 'Kahveler'},
      {'name': 'Croissant', 'description': 'Tereyağlı', 'price': 65.0, 'category': 'Yiyecekler'},
      {'name': 'Cheesecake', 'description': 'New York usulü', 'price': 120.0, 'category': 'Tatlılar'},
      {'name': 'Brownie', 'description': 'Çikolatalı', 'price': 75.0, 'category': 'Tatlılar'},
    ];

    for (final item in starbucksMenu) {
      await db.insert('menu_items', {
        'mekan_id': 2,
        'name': item['name'],
        'description': item['description'],
        'price': item['price'],
        'category': item['category'],
        'created_at': now,
      });
    }

    // Burger King Menu (mekan_id: 3)
    final burgerKingMenu = [
      {'name': 'Whopper', 'description': 'Klasik dev hamburger', 'price': 145.0, 'category': 'Burgerler'},
      {'name': 'Whopper Menü', 'description': 'Whopper, patates, içecek', 'price': 195.0, 'category': 'Menüler'},
      {'name': 'King Chicken', 'description': 'Tavuk burger', 'price': 125.0, 'category': 'Burgerler'},
      {'name': 'Chicken Royale Menü', 'description': 'Chicken Royale, patates, içecek', 'price': 175.0, 'category': 'Menüler'},
      {'name': 'Patates Kızartması', 'description': 'Orta boy', 'price': 45.0, 'category': 'Yan Ürünler'},
      {'name': 'Soğan Halkası', 'description': '6 adet', 'price': 55.0, 'category': 'Yan Ürünler'},
      {'name': 'Coca Cola', 'description': 'Orta boy', 'price': 35.0, 'category': 'İçecekler'},
      {'name': 'Fanta', 'description': 'Orta boy', 'price': 35.0, 'category': 'İçecekler'},
    ];

    for (final item in burgerKingMenu) {
      await db.insert('menu_items', {
        'mekan_id': 3,
        'name': item['name'],
        'description': item['description'],
        'price': item['price'],
        'category': item['category'],
        'created_at': now,
      });
    }

    // Midpoint Menu (mekan_id: 13)
    final midpointMenu = [
      {'name': 'Izgara Somon', 'description': 'Taze sebzelerle', 'price': 320.0, 'category': 'Ana Yemekler'},
      {'name': 'Biftekli Makarna', 'description': 'Kremalı sos, mantar', 'price': 280.0, 'category': 'Ana Yemekler'},
      {'name': 'Tavuk Şiş', 'description': 'Marine edilmiş tavuk, pilav', 'price': 220.0, 'category': 'Ana Yemekler'},
      {'name': 'Caesar Salad', 'description': 'Tavuk, parmesan, kruton', 'price': 145.0, 'category': 'Salatalar'},
      {'name': 'Akdeniz Salata', 'description': 'Zeytinyağlı, peynirli', 'price': 120.0, 'category': 'Salatalar'},
      {'name': 'Tiramisu', 'description': 'İtalyan tatlısı', 'price': 95.0, 'category': 'Tatlılar'},
      {'name': 'Limonata', 'description': 'Taze sıkılmış', 'price': 55.0, 'category': 'İçecekler'},
    ];

    for (final item in midpointMenu) {
      await db.insert('menu_items', {
        'mekan_id': 13,
        'name': item['name'],
        'description': item['description'],
        'price': item['price'],
        'category': item['category'],
        'created_at': now,
      });
    }

    // Köfteci Yusuf Menu (mekan_id: 15)
    final kofteciMenu = [
      {'name': 'Kasap Köfte', 'description': 'Dana kıyma, özel baharat', 'price': 155.0, 'category': 'Köfteler'},
      {'name': 'İskender Köfte', 'description': 'Tereyağlı sos, ekmek', 'price': 185.0, 'category': 'Köfteler'},
      {'name': 'Pideli Köfte', 'description': 'Yoğurtlu, tereyağlı', 'price': 175.0, 'category': 'Köfteler'},
      {'name': 'Çorba', 'description': 'Günün çorbası', 'price': 45.0, 'category': 'Başlangıçlar'},
      {'name': 'Cacık', 'description': 'Ev yapımı', 'price': 35.0, 'category': 'Başlangıçlar'},
      {'name': 'Sütlaç', 'description': 'Fırın sütlaç', 'price': 55.0, 'category': 'Tatlılar'},
      {'name': 'Ayran', 'description': 'Özel ayran', 'price': 25.0, 'category': 'İçecekler'},
    ];

    for (final item in kofteciMenu) {
      await db.insert('menu_items', {
        'mekan_id': 15,
        'name': item['name'],
        'description': item['description'],
        'price': item['price'],
        'category': item['category'],
        'created_at': now,
      });
    }

    // Dominos Pizza Menu (mekan_id: 17)
    final dominosMenu = [
      {'name': 'Karışık Pizza (M)', 'description': 'Sucuk, sosis, mantar, biber', 'price': 185.0, 'category': 'Pizzalar'},
      {'name': 'Margarita (M)', 'description': 'Domates sos, mozzarella', 'price': 145.0, 'category': 'Pizzalar'},
      {'name': 'BBQ Chicken (M)', 'description': 'Tavuk, BBQ sos, mısır', 'price': 195.0, 'category': 'Pizzalar'},
      {'name': 'Pepperoni (L)', 'description': 'Bol pepperoni', 'price': 225.0, 'category': 'Pizzalar'},
      {'name': 'Cheesy Bread', 'description': 'Peynirli ekmek', 'price': 75.0, 'category': 'Yan Ürünler'},
      {'name': 'Tavuklu Wrap', 'description': 'Izgara tavuk, sebze', 'price': 95.0, 'category': 'Yan Ürünler'},
      {'name': 'Brownie', 'description': 'Çikolatalı', 'price': 65.0, 'category': 'Tatlılar'},
    ];

    for (final item in dominosMenu) {
      await db.insert('menu_items', {
        'mekan_id': 17,
        'name': item['name'],
        'description': item['description'],
        'price': item['price'],
        'category': item['category'],
        'created_at': now,
      });
    }

    // Papa Johns Menu (mekan_id: 18)
    final papaMenu = [
      {'name': 'Super Papa (M)', 'description': 'Sucuk, sosis, jambon, mantar', 'price': 195.0, 'category': 'Pizzalar'},
      {'name': 'Vejeteryan (M)', 'description': 'Sebzeli pizza', 'price': 165.0, 'category': 'Pizzalar'},
      {'name': 'Ton Balıklı (M)', 'description': 'Ton balığı, mısır, soğan', 'price': 185.0, 'category': 'Pizzalar'},
      {'name': 'Papa Sticks', 'description': 'Peynirli çubuklar', 'price': 85.0, 'category': 'Yan Ürünler'},
      {'name': 'Sarımsaklı Ekmek', 'description': 'Tereyağlı', 'price': 55.0, 'category': 'Yan Ürünler'},
      {'name': 'Cookie', 'description': 'Çikolatalı kurabiye', 'price': 45.0, 'category': 'Tatlılar'},
    ];

    for (final item in papaMenu) {
      await db.insert('menu_items', {
        'mekan_id': 18,
        'name': item['name'],
        'description': item['description'],
        'price': item['price'],
        'category': item['category'],
        'created_at': now,
      });
    }
  }
}

