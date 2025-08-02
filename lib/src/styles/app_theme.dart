import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de cores e temas do BKCRM - DEPRECATED
/// Use EnhancedTheme e DesignTokens para novos desenvolvimentos
class AppTheme {
  // ==================== CORES - DEPRECATED ====================
  // Mantido para compatibilidade com código existente

  // Cores principais conforme BKCRM
  static const Color primaryColor = Color(0xFF3B82F6);
  static const Color secondaryColor = Color(0xFF6366F1);
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

  // Cores adicionais para melhor UX
  static const Color infoColor = Color(0xFF06B6D4);
  static const Color purpleColor = Color(0xFF8B5CF6);
  static const Color pinkColor = Color(0xFFEC4899);
  static const Color orangeColor = Color(0xFFF97316);
  static const Color tealColor = Color(0xFF14B8A6);

  // Cores Light Theme
  static const Color lightBackgroundColor = Color(0xFFF8FAFC);
  static const Color lightTextColor = Color(0xFF1E293B);
  static const Color lightBorderColor = Color(0xFFE2E8F0);
  static const Color lightCardColor = Colors.white;
  static const Color lightSurfaceColor = Color(0xFFF1F5F9);

  // Cores Dark Theme
  static const Color darkBackgroundColor = Color(0xFF0F172A);
  static const Color darkTextColor = Color(0xFFF1F5F9);
  static const Color darkBorderColor = Color(0xFF334155);
  static const Color darkCardColor = Color(0xFF1E293B);
  static const Color darkSurfaceColor = Color(0xFF334155);

  // Cores adicionais para Dark Theme
  static const Color darkSecondaryBackground = Color(0xFF1A2234);
  static const Color darkTertiaryBackground = Color(0xFF263045);
  static const Color darkElevatedCardColor = Color(0xFF2A3549);
  static const Color darkHighlightColor = Color(0xFF3B82F6);
  static const Color darkDividerColor = Color(0xFF475569);

  // Cores para glassmorphism
  static const Color lightGlassBackground = Color(0x1AFFFFFF);
  static const Color lightGlassBorder = Color(0x33FFFFFF);
  static const Color darkGlassBackground = Color(0x1A000000);
  static const Color darkGlassBorder = Color(0x33000000);

  // Cores compatíveis com ambos os temas
  static const Color backgroundColor =
      lightBackgroundColor; // Deprecated - use getBackgroundColor
  static const Color textColor =
      lightTextColor; // Deprecated - use getTextColor
  static const Color borderColor =
      lightBorderColor; // Deprecated - use getBorderColor
  static const Color glassBackground = lightGlassBackground; // Deprecated
  static const Color glassBorder = lightGlassBorder; // Deprecated

  // ==================== ESPAÇAMENTOS - DEPRECATED ====================
  // Use DesignTokens para novos desenvolvimentos

  // Espaçamentos base (4px)
  static const double spacing2 = 2;
  static const double spacing4 = 4;
  static const double spacing6 = 6;
  static const double spacing8 = 8;
  static const double spacing10 = 10;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing48 = 48;
  static const double spacing64 = 64;

  // ==================== ANIMAÇÕES - DEPRECATED ====================
  // Use DesignTokens para novos desenvolvimentos

  // Duração de animação
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeInOut;

  // Métodos auxiliares para obter cores baseadas no tema
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackgroundColor
        : lightBackgroundColor;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextColor
        : lightTextColor;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardColor
        : lightCardColor;
  }

  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorderColor
        : lightBorderColor;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurfaceColor
        : lightSurfaceColor;
  }

  static Color getSecondaryBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSecondaryBackground
        : lightBackgroundColor.withValues(alpha: 0.8);
  }

  static Color getTertiaryBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTertiaryBackground
        : lightBackgroundColor.withValues(alpha: 0.6);
  }

  static Color getElevatedCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkElevatedCardColor
        : Colors.white;
  }

  static Color getHighlightColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkHighlightColor
        : primaryColor;
  }

  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkDividerColor
        : lightBorderColor;
  }

  static BoxDecoration getGlassDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkGlassBackground : lightGlassBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? darkGlassBorder : lightGlassBorder,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Decoração de vidro premium para o tema escuro
  static BoxDecoration getDarkGlassDecoration() {
    return BoxDecoration(
      color: const Color(0x1A3B82F6), // Azul semi-transparente
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0x333B82F6), // Borda azul semi-transparente
        width: 1.5,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x403B82F6), // Sombra azul
          blurRadius: 20,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  // Decoração de vidro com efeito de brilho para o tema escuro
  static BoxDecoration getDarkGlowDecoration() {
    return BoxDecoration(
      color: darkCardColor.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x403B82F6), // Brilho azul
          blurRadius: 15,
          spreadRadius: 1,
        ),
      ],
    );
  }

  /// Tema claro principal - DEPRECATED
  /// Use EnhancedTheme.lightTheme para novos desenvolvimentos
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackgroundColor,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightBackgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextColor,
        onError: Colors.white,
        surfaceContainerHighest: lightSurfaceColor,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightTextColor,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: lightTextColor,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightTextColor,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextColor,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextColor,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: lightTextColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: lightTextColor,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: lightTextColor,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: lightTextColor.withValues(alpha: 0.7),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: lightTextColor,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: lightTextColor,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: lightTextColor.withValues(alpha: 0.7),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shadowColor: const Color(0x403B82F6), // Sombra azul sutil
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCardColor,
        labelStyle: GoogleFonts.inter(
          color: lightTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.inter(
          color: lightTextColor.withValues(alpha: 0.6),
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        helperStyle: GoogleFonts.inter(
          color: lightTextColor.withValues(alpha: 0.7),
          fontSize: 12,
        ),
        errorStyle: GoogleFonts.inter(
          color: errorColor,
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: lightBorderColor,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: lightBorderColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: errorColor,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing16,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: lightCardColor,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: lightTextColor,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextColor,
        ),
      ),
      // Configurações para diálogos no tema escuro
      dialogTheme: DialogTheme(
        backgroundColor: darkSurfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkTextColor,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextColor,
        ),
      ),
      // Configurações para chips no tema escuro
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceColor,
        disabledColor: darkSurfaceColor.withValues(alpha: 0.5),
        selectedColor: primaryColor,
        secondarySelectedColor: primaryColor,
        padding: const EdgeInsets.symmetric(
            horizontal: spacing8, vertical: spacing4),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkTextColor,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: darkBorderColor),
        ),
      ),
      // Configurações para switches no tema escuro
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return const Color(0xFF9E9E9E); // darkHintColor
          }
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return darkTextColor;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return const Color(0xFF9E9E9E).withValues(alpha: 0.3); // darkHintColor
          }
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.5);
          }
          return darkSurfaceColor;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.transparent;
          }
          return Colors.transparent;
        }),
      ),
    );
  }

  /// Tema escuro principal - DEPRECATED
  /// Use EnhancedTheme.darkTheme para novos desenvolvimentos
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkBackgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextColor,
        onError: Colors.white,
        surfaceContainerHighest: darkSurfaceColor,
        // Cores adicionais para melhorar o tema escuro
        surfaceContainer: darkCardColor,
        surfaceContainerLow: darkSecondaryBackground,
        surfaceContainerLowest: darkTertiaryBackground,
        surfaceContainerHigh: darkElevatedCardColor,
        outline: darkBorderColor,
        outlineVariant: darkDividerColor,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkTextColor,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkTextColor,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkTextColor,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextColor,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkTextColor,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkTextColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkTextColor,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: darkTextColor,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: darkTextColor.withValues(alpha: 0.7),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkTextColor,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkTextColor,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: darkTextColor.withValues(alpha: 0.7),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: errorColor,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: errorColor,
            width: 1.5,
          ),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextColor.withValues(alpha: 0.6),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextColor,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: errorColor,
        ),
        prefixIconColor: primaryColor,
        suffixIconColor: primaryColor,
        helperStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: darkTextColor.withValues(alpha: 0.7),
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primaryColor,
        ),
        isDense: false,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: darkCardColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x403B82F6), // Sombra azul sutil
        margin: const EdgeInsets.symmetric(
            vertical: spacing8, horizontal: spacing8),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: darkTextColor,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkTextColor,
        ),
        iconTheme: const IconThemeData(
          color: primaryColor,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: primaryColor,
          size: 24,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: darkBackgroundColor,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
    );
  }

  // Decoração para glassmorphism (deprecated - use getGlassDecoration)
  static BoxDecoration get glassDecoration {
    return BoxDecoration(
      color: lightGlassBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: lightGlassBorder,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Decoração para cards baseada no tema
  static BoxDecoration getCardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkCardColor : lightCardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? const Color(0x403B82F6)
                  .withValues(alpha: 0.1) // Sombra azul sutil para tema escuro
              : Colors.black.withValues(alpha: 0.05),
          blurRadius: isDark ? 10 : 8,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Decoração para cards elevados com efeito mais pronunciado
  static BoxDecoration getElevatedCardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkElevatedCardColor : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? const Color(0x403B82F6)
                  .withValues(alpha: 0.2) // Sombra azul para tema escuro
              : Colors.black.withValues(alpha: 0.1),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // Decoração para cards com borda destacada
  static BoxDecoration getOutlinedCardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkCardColor : lightCardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark
            ? darkHighlightColor.withValues(alpha: 0.5)
            : primaryColor.withValues(alpha: 0.3),
        width: 2,
      ),
    );
  }

  // Decoração para cards (deprecated - use getCardDecoration)
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: lightCardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Gradiente de fundo baseado no tema
  static LinearGradient getBackgroundGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1A1A2E),
          Color(0xFF16213E),
        ],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF5F7FA),
          Color(0xFFE4E7EB),
        ],
      );
    }
  }

  // Gradiente de destaque para o tema escuro
  static LinearGradient getDarkAccentGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF3B82F6), // Azul primário
        Color(0xFF2563EB), // Azul mais escuro
      ],
    );
  }

  // Gradiente para cards no tema escuro
  static LinearGradient getDarkCardGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1E293B), // Azul escuro
        Color(0xFF0F172A), // Azul mais escuro
      ],
    );
  }

  // Gradiente para seções de destaque no tema escuro
  static LinearGradient getDarkHighlightGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1E293B), // Azul escuro
        Color(0xFF1A1A2E), // Azul-roxo escuro
      ],
    );
  }

  // Gradiente de fundo (deprecated - use getBackgroundGradient)
  static LinearGradient get backgroundGradient {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        lightBackgroundColor,
        lightSurfaceColor,
      ],
    );
  }
}
