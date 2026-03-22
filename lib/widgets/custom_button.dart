import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        minimumSize: Size(double.infinity, 55),
      ),
      onPressed: onPressed,
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}
