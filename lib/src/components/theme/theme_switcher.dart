import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/theme_store.dart';
import '../../styles/app_theme.dart';

class ThemeSwitcher extends StatelessWidget {
  final bool showLabel;
  final bool isCompact;
  final VoidCallback? onThemeChanged;

  const ThemeSwitcher({
    super.key,
    this.showLabel = true,
    this.isCompact = false,
    this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeStore>(
      builder: (context, themeStore, child) {
        if (themeStore.isLoading) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (isCompact) {
          return _buildCompactSwitcher(context, themeStore);
        }

        return _buildFullSwitcher(context, themeStore);
      },
    );
  }

  Widget _buildCompactSwitcher(BuildContext context, ThemeStore themeStore) {
    return IconButton(
      onPressed: () async {
        await themeStore.toggleLightDark();
        onThemeChanged?.call();
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          themeStore.currentThemeIcon,
          key: ValueKey(themeStore.themeMode),
          color: AppTheme.getTextColor(context),
        ),
      ),
      tooltip: 'Alternar tema (${themeStore.currentThemeName})',
    );
  }

  Widget _buildFullSwitcher(BuildContext context, ThemeStore themeStore) {
    return Container(
      decoration: AppTheme.getCardDecoration(context),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel) ...[
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 20,
                  color: AppTheme.getTextColor(context),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Text(
                  'Tema do Aplicativo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
          ],
          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  context,
                  themeStore,
                  ThemeMode.light,
                  'Claro',
                  Icons.light_mode,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: _buildThemeOption(
                  context,
                  themeStore,
                  ThemeMode.dark,
                  'Escuro',
                  Icons.dark_mode,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: _buildThemeOption(
                  context,
                  themeStore,
                  ThemeMode.system,
                  'Sistema',
                  Icons.brightness_auto,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeStore themeStore,
    ThemeMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = themeStore.themeMode == mode;
    final textColor = AppTheme.getTextColor(context);
    
    return GestureDetector(
      onTap: () async {
        switch (mode) {
          case ThemeMode.light:
            await themeStore.setLightMode();
            break;
          case ThemeMode.dark:
            await themeStore.setDarkMode();
            break;
          case ThemeMode.system:
            await themeStore.setSystemMode();
            break;
        }
        onThemeChanged?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacing12,
          horizontal: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryColor
                : AppTheme.getBorderColor(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 24,
                color: isSelected 
                    ? AppTheme.primaryColor
                    : textColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                    ? AppTheme.primaryColor
                    : textColor.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget simples para alternar apenas entre claro e escuro
class SimpleThemeToggle extends StatelessWidget {
  final double? size;
  final Color? activeColor;
  final Color? inactiveColor;
  final VoidCallback? onChanged;

  const SimpleThemeToggle({
    super.key,
    this.size,
    this.activeColor,
    this.inactiveColor,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeStore>(
      builder: (context, themeStore, child) {
        final isDark = themeStore.isDarkModeActive(context);
        
        return GestureDetector(
          onTap: () async {
            await themeStore.toggleLightDark();
            onChanged?.call();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: size ?? 50,
            height: (size ?? 50) * 0.6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular((size ?? 50) * 0.3),
              color: isDark 
                  ? (activeColor ?? AppTheme.primaryColor)
                  : (inactiveColor ?? AppTheme.getBorderColor(context)),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: (size ?? 50) * 0.4,
                height: (size ?? 50) * 0.4,
                margin: EdgeInsets.all((size ?? 50) * 0.05),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  size: (size ?? 50) * 0.2,
                  color: isDark 
                      ? AppTheme.primaryColor
                      : Colors.orange,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}