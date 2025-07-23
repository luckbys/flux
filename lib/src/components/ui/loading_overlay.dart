import 'package:flutter/material.dart';
import '../../styles/app_theme.dart';
import 'glass_container.dart';

class LoadingOverlay extends StatelessWidget {
  final String message;
  final bool showBackground;

  const LoadingOverlay({
    super.key,
    this.message = 'Carregando...',
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color:
          showBackground ? Colors.black.withOpacity(0.5) : Colors.transparent,
      child: Center(
        child: GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
