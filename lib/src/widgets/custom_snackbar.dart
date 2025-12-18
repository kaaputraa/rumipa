// rumipa3/lib/src/widgets/custom_snackbar.dart

import 'package:flutter/material.dart';

void showCustomSnackBar(
  BuildContext context, {
  required String message,
  required bool isSuccess,
  SnackBarAction? action, // Tambahkan opsional action
}) {
  final theme = Theme.of(context);

  // Menentukan warna dasar berdasarkan status
  final Color baseColor = isSuccess
      ? theme.colorScheme.primary
      : Colors.red.shade700;
  final Color highlightColor = isSuccess
      ? Colors.lightBlue.shade300
      : Colors.red.shade400;
  final IconData icon = isSuccess
      ? Icons.check_circle_outline
      : Icons.error_outline;

  final gradient = LinearGradient(
    colors: [baseColor, highlightColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final contentWidget = Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: baseColor.withOpacity(0.3),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  // Untuk menggunakan Container kustom di SnackBar, kita perlu mengatur background SnackBar
  // menjadi transparan, dan menggunakan Padding 0, dan Elevation 0.

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      // [PERHATIAN KRITIS] Gunakan warna transparan untuk SnackBar
      // agar Container yang bergradasi terlihat
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      content: contentWidget,
      margin: const EdgeInsets.all(16),
      padding:
          EdgeInsets.zero, // Padding 0 agar container kustom mengambil alih
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),

      // Jika ada action (misal di User Dashboard), kita harus menampilkannya
      action: action != null
          ? SnackBarAction(
              label: action.label,
              onPressed: action.onPressed,
              textColor: Colors.white,
            )
          : null,
    ),
  );
}
