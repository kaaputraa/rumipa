class AppValidators {
  // Validasi Email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  // Validasi Password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    // Tambahan: Cek angka jika ingin lebih kuat
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password harus mengandung setidaknya satu angka';
    }
    return null;
  }

  // Validasi NIM (Contoh: Harus angka dan panjang tertentu)
  static String? validateNIM(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIM tidak boleh kosong';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'NIM hanya boleh berisi angka';
    }
    return null;
  }

  // Validasi Nama
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'Nama terlalu pendek';
    }
    return null;
  }
}
