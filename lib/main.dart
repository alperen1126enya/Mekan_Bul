import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/mekan_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/main_screen.dart';
import 'screens/mekan_list_screen.dart';
import 'screens/mekan_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/map_screen.dart';
import 'screens/notifications_screen.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MekanBulApp());
}

class MekanBulApp extends StatelessWidget {
  const MekanBulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MekanProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: AppConstants.splashRoute,
        routes: {
          AppConstants.splashRoute: (context) => const SplashScreen(),
          AppConstants.loginRoute: (context) => const LoginScreen(),
          AppConstants.registerRoute: (context) => const RegisterScreen(),
          AppConstants.preferencesRoute: (context) => const PreferencesScreen(),
          AppConstants.mainRoute: (context) => const MainScreen(),
          AppConstants.mekanListRoute: (context) => const MekanListScreen(),
          AppConstants.mekanDetailRoute: (context) => const MekanDetailScreen(),
          AppConstants.profileRoute: (context) => const ProfileScreen(),
          AppConstants.mapRoute: (context) => const MapScreen(),
          AppConstants.notificationsRoute: (context) => const NotificationsScreen(),
        },
      ),
    );
  }
}

