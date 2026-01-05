class AppValidators {
  // Validasi Email: Wajib format x@y.z
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    // Regex standar industri yang cukup kuat
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Format email tidak valid (contoh: user@domain.com)';
    }
    return null;
  }

  // Validasi Password: Huruf Besar + Angka + Simbol
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }

    // List untuk menampung pesan error
    List<String> errors = [];

    // Cek setiap syarat satu per satu
    if (value.length < 6) {
      errors.add('• Minimal 6 karakter');
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      errors.add('• Minimal 1 Huruf Besar (A-Z)');
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      errors.add('• Minimal 1 Angka (0-9)');
    }
    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      errors.add('• Minimal 1 Simbol (!@#...)');
    }

    // Jika list error tidak kosong, gabungkan jadi satu string
    if (errors.isNotEmpty) {
      return 'Password kurang kuat:\n${errors.join('\n')}';
    }

    return null; // Lolos validasi
  }

  // Validasi NIM: Hanya Angka
  static String? validateNIM(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIM tidak boleh kosong';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'NIM hanya boleh berisi angka';
    }
    return null;
  }

  // Validasi Nama: Hanya Huruf, Spasi, tanda petik ('), dan strip (-)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'Nama terlalu pendek';
    }
    // Mengizinkan nama seperti "O'Neil" atau "Anne-Marie" tapi menolak angka/simbol aneh
    final nameExp = RegExp(r"^[a-zA-Z\s\-\']+$");
    if (!nameExp.hasMatch(value)) {
      return 'Nama tidak boleh mengandung angka atau simbol';
    }
    return null;
  }
}
