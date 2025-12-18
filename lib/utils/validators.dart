class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email adresi gerekli';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir email adresi girin';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }

    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kullanıcı adı gerekli';
    }

    if (value.length < 3) {
      return 'Kullanıcı adı en az 3 karakter olmalı';
    }

    if (value.length > 20) {
      return 'Kullanıcı adı en fazla 20 karakter olabilir';
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Sadece harf, rakam ve alt çizgi kullanılabilir';
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı gerekli';
    }

    if (value != password) {
      return 'Şifreler eşleşmiyor';
    }

    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Yaş gerekli';
    }

    final age = int.tryParse(value);
    if (age == null) {
      return 'Geçerli bir yaş girin';
    }

    if (age < 5 || age > 100) {
      return 'Yaş 5-100 arasında olmalı';
    }

    return null;
  }

  static String? validateComment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Yorum boş olamaz';
    }

    if (value.trim().length < 10) {
      return 'Yorum en az 10 karakter olmalı';
    }

    if (value.length > 500) {
      return 'Yorum en fazla 500 karakter olabilir';
    }

    return null;
  }
}
