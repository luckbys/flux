import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

/// Tema aprimorado do BKCRM com suporte completo a modo escuro,
/// acessibilidade WCAG 2.1 AA e animações micro-interativas
class EnhancedTheme {
  // ==================== TEMAS PRINCIPAIS ====================

  /// Tema claro aprimorado
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      brightness: Brightness.light,

      // Color Scheme baseado nos tokens
      colorScheme: const ColorScheme.light(
        primary: DesignTokens.primary500,
        onPrimary: Colors.white,
        primaryContainer: DesignTokens.primary100,
        onPrimaryContainer: DesignTokens.primary900,
        secondary: DesignTokens.secondary500,
        onSecondary: Colors.white,
        secondaryContainer: DesignTokens.secondary100,
        onSecondaryContainer: DesignTokens.secondary900,
        tertiary: DesignTokens.info500,
        onTertiary: Colors.white,
        tertiaryContainer: DesignTokens.info100,
        onTertiaryContainer: DesignTokens.info900,
        error: DesignTokens.error500,
        onError: Colors.white,
        errorContainer: DesignTokens.error50,
        onErrorContainer: DesignTokens.error700,
        surface: DesignTokens.neutral50,
        onSurface: DesignTokens.neutral900,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: DesignTokens.neutral100,
        surfaceContainer: DesignTokens.neutral200,
        surfaceContainerHigh: DesignTokens.neutral300,
        surfaceContainerHighest: DesignTokens.neutral400,
        outline: DesignTokens.neutral300,
        outlineVariant: DesignTokens.neutral200,
        shadow: DesignTokens.neutral900,
        scrim: Colors.black54,
        inverseSurface: DesignTokens.neutral900,
        onInverseSurface: DesignTokens.neutral100,
        inversePrimary: DesignTokens.primary200,
      ),

      // Configurações de scaffold
      scaffoldBackgroundColor: DesignTokens.neutral50,

      // Configurações de app bar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: DesignTokens.neutral900,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: DesignTokens.neutral200,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: DesignTokens.fontSize18,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.neutral900,
          height: DesignTokens.lineHeightNormal,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),

      // Tipografia aprimorada
      textTheme: _buildTextTheme(false),

      // Componentes de botão
      elevatedButtonTheme: _buildElevatedButtonTheme(false),
      filledButtonTheme: _buildFilledButtonTheme(false),
      outlinedButtonTheme: _buildOutlinedButtonTheme(false),
      textButtonTheme: _buildTextButtonTheme(false),

      // Componentes de input
      inputDecorationTheme: _buildInputDecorationTheme(false),

      // Componentes de card
      cardTheme: _buildCardTheme(false),

      // Componentes de chip
      chipTheme: _buildChipTheme(false),

      // Componentes de switch
      switchTheme: _buildSwitchTheme(false),

      // Componentes de checkbox
      checkboxTheme: _buildCheckboxTheme(false),

      // Componentes de radio
      radioTheme: _buildRadioTheme(false),

      // Componentes de slider
      sliderTheme: _buildSliderTheme(false),

      // Componentes de progress indicator
      progressIndicatorTheme: _buildProgressIndicatorTheme(false),

      // Componentes de snackbar
      snackBarTheme: _buildSnackBarTheme(false),

      // Componentes de dialog
      dialogTheme: _buildDialogTheme(false),

      // Componentes de bottom sheet
      bottomSheetTheme: _buildBottomSheetTheme(false),

      // Componentes de navigation
      navigationBarTheme: _buildNavigationBarTheme(false),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(false),

      // Componentes de tab
      tabBarTheme: _buildTabBarTheme(false),

      // Divisores
      dividerTheme: const DividerThemeData(
        color: DesignTokens.neutral200,
        thickness: DesignTokens.borderWidthThin,
        space: DesignTokens.space16,
      ),

      // Configurações de foco para acessibilidade
      focusColor: DesignTokens.primary500.withValues(alpha: 0.12),
      hoverColor: DesignTokens.primary500.withValues(alpha: 0.04),
      highlightColor: DesignTokens.primary500.withValues(alpha: 0.12),
      splashColor: DesignTokens.primary500.withValues(alpha: 0.12),

      // Configurações visuais
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  /// Tema escuro aprimorado
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      brightness: Brightness.dark,

      // Color Scheme baseado nos tokens
      colorScheme: const ColorScheme.dark(
        primary: DesignTokens.primary400,
        onPrimary: DesignTokens.primary950,
        primaryContainer: DesignTokens.primary800,
        onPrimaryContainer: DesignTokens.primary100,
        secondary: DesignTokens.secondary400,
        onSecondary: DesignTokens.secondary950,
        secondaryContainer: DesignTokens.secondary800,
        onSecondaryContainer: DesignTokens.secondary100,
        tertiary: DesignTokens.info400,
        onTertiary: DesignTokens.info950,
        tertiaryContainer: DesignTokens.info800,
        onTertiaryContainer: DesignTokens.info100,
        error: DesignTokens.error400,
        onError: DesignTokens.error950,
        errorContainer: DesignTokens.error800,
        onErrorContainer: DesignTokens.error100,
        surface: DesignTokens.darkNeutral50,
        onSurface: DesignTokens.darkNeutral900,
        surfaceContainerLowest: DesignTokens.darkNeutral50,
        surfaceContainerLow: DesignTokens.darkNeutral100,
        surfaceContainer: DesignTokens.darkNeutral200,
        surfaceContainerHigh: DesignTokens.darkNeutral300,
        surfaceContainerHighest: DesignTokens.darkNeutral400,
        outline: DesignTokens.darkNeutral300,
        outlineVariant: DesignTokens.darkNeutral200,
        shadow: Colors.black,
        scrim: Colors.black87,
        inverseSurface: DesignTokens.darkNeutral900,
        onInverseSurface: DesignTokens.darkNeutral100,
        inversePrimary: DesignTokens.primary600,
      ),

      // Configurações de scaffold
      scaffoldBackgroundColor: DesignTokens.darkNeutral50,

      // Configurações de app bar
      appBarTheme: AppBarTheme(
        backgroundColor: DesignTokens.darkNeutral100,
        foregroundColor: DesignTokens.darkNeutral900,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: DesignTokens.fontSize18,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.darkNeutral900,
          height: DesignTokens.lineHeightNormal,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: DesignTokens.darkNeutral50,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // Tipografia aprimorada
      textTheme: _buildTextTheme(true),

      // Componentes de botão
      elevatedButtonTheme: _buildElevatedButtonTheme(true),
      filledButtonTheme: _buildFilledButtonTheme(true),
      outlinedButtonTheme: _buildOutlinedButtonTheme(true),
      textButtonTheme: _buildTextButtonTheme(true),

      // Componentes de input
      inputDecorationTheme: _buildInputDecorationTheme(true),

      // Componentes de card
      cardTheme: _buildCardTheme(true),

      // Componentes de chip
      chipTheme: _buildChipTheme(true),

      // Componentes de switch
      switchTheme: _buildSwitchTheme(true),

      // Componentes de checkbox
      checkboxTheme: _buildCheckboxTheme(true),

      // Componentes de radio
      radioTheme: _buildRadioTheme(true),

      // Componentes de slider
      sliderTheme: _buildSliderTheme(true),

      // Componentes de progress indicator
      progressIndicatorTheme: _buildProgressIndicatorTheme(true),

      // Componentes de snackbar
      snackBarTheme: _buildSnackBarTheme(true),

      // Componentes de dialog
      dialogTheme: _buildDialogTheme(true),

      // Componentes de bottom sheet
      bottomSheetTheme: _buildBottomSheetTheme(true),

      // Componentes de navigation
      navigationBarTheme: _buildNavigationBarTheme(true),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(true),

      // Componentes de tab
      tabBarTheme: _buildTabBarTheme(true),

      // Divisores
      dividerTheme: const DividerThemeData(
        color: DesignTokens.darkNeutral200,
        thickness: DesignTokens.borderWidthThin,
        space: DesignTokens.space16,
      ),

      // Configurações de foco para acessibilidade
      focusColor: DesignTokens.primary400.withValues(alpha: 0.12),
      hoverColor: DesignTokens.primary400.withValues(alpha: 0.04),
      highlightColor: DesignTokens.primary400.withValues(alpha: 0.12),
      splashColor: DesignTokens.primary400.withValues(alpha: 0.12),

      // Configurações visuais
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  // ==================== BUILDERS DE COMPONENTES ====================

  /// Constrói o tema de tipografia
  static TextTheme _buildTextTheme(bool isDark) {
    final baseColor =
        isDark ? DesignTokens.darkNeutral900 : DesignTokens.neutral900;
    final mutedColor =
        isDark ? DesignTokens.darkNeutral600 : DesignTokens.neutral600;

    return TextTheme(
      // Display styles
      displayLarge: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize64,
        fontWeight: DesignTokens.fontWeightBold,
        color: baseColor,
        height: DesignTokens.lineHeightTight,
        letterSpacing: -0.02,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize48,
        fontWeight: DesignTokens.fontWeightBold,
        color: baseColor,
        height: DesignTokens.lineHeightTight,
        letterSpacing: -0.02,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize36,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: baseColor,
        height: DesignTokens.lineHeightTight,
        letterSpacing: -0.01,
      ),

      // Headline styles
      headlineLarge: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize32,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: baseColor,
        height: DesignTokens.lineHeightTight,
        letterSpacing: -0.01,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize28,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: baseColor,
        height: DesignTokens.lineHeightNormal,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize24,
        fontWeight: DesignTokens.fontWeightMedium,
        color: baseColor,
        height: DesignTokens.lineHeightNormal,
      ),

      // Title styles
      titleLarge: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize20,
        fontWeight: DesignTokens.fontWeightMedium,
        color: baseColor,
        height: DesignTokens.lineHeightNormal,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize18,
        fontWeight: DesignTokens.fontWeightMedium,
        color: baseColor,
        height: DesignTokens.lineHeightNormal,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize16,
        fontWeight: DesignTokens.fontWeightMedium,
        color: baseColor,
        height: DesignTokens.lineHeightNormal,
      ),

      // Body styles
      bodyLarge: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize16,
        fontWeight: DesignTokens.fontWeightRegular,
        color: baseColor,
        height: DesignTokens.lineHeightNormal,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize14,
        fontWeight: DesignTokens.fontWeightRegular,
        color: baseColor,
        height: DesignTokens.lineHeightNormal,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize12,
        fontWeight: DesignTokens.fontWeightRegular,
        color: mutedColor,
        height: DesignTokens.lineHeightNormal,
      ),

      // Label styles
      labelLarge: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize14,
        fontWeight: DesignTokens.fontWeightMedium,
        color: baseColor,
        height: DesignTokens.lineHeightNormal,
        letterSpacing: 0.01,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize12,
        fontWeight: DesignTokens.fontWeightMedium,
        color: baseColor,
        height: DesignTokens.lineHeightNormal,
        letterSpacing: 0.01,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize10,
        fontWeight: DesignTokens.fontWeightMedium,
        color: mutedColor,
        height: DesignTokens.lineHeightNormal,
        letterSpacing: 0.02,
      ),
    );
  }

  /// Constrói o tema de botões elevados
  static ElevatedButtonThemeData _buildElevatedButtonTheme(bool isDark) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isDark ? DesignTokens.primary400 : DesignTokens.primary500,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            isDark ? DesignTokens.darkNeutral300 : DesignTokens.neutral300,
        disabledForegroundColor:
            isDark ? DesignTokens.darkNeutral500 : DesignTokens.neutral500,
        elevation: 2,
        shadowColor: isDark ? Colors.black54 : DesignTokens.neutral400,
        surfaceTintColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space24,
          vertical: DesignTokens.space16,
        ),
        minimumSize: const Size(
            DesignTokens.minTouchTarget, DesignTokens.minTouchTarget),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: DesignTokens.fontSize14,
          fontWeight: DesignTokens.fontWeightMedium,
          height: DesignTokens.lineHeightNormal,
        ),
        animationDuration: DesignTokens.durationFast,
      ),
    );
  }

  /// Constrói o tema de botões preenchidos
  static FilledButtonThemeData _buildFilledButtonTheme(bool isDark) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor:
            isDark ? DesignTokens.primary400 : DesignTokens.primary500,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            isDark ? DesignTokens.darkNeutral300 : DesignTokens.neutral300,
        disabledForegroundColor:
            isDark ? DesignTokens.darkNeutral500 : DesignTokens.neutral500,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space24,
          vertical: DesignTokens.space16,
        ),
        minimumSize: const Size(
            DesignTokens.minTouchTarget, DesignTokens.minTouchTarget),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: DesignTokens.fontSize14,
          fontWeight: DesignTokens.fontWeightMedium,
          height: DesignTokens.lineHeightNormal,
        ),
        animationDuration: DesignTokens.durationFast,
      ),
    );
  }

  /// Constrói o tema de botões com contorno
  static OutlinedButtonThemeData _buildOutlinedButtonTheme(bool isDark) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor:
            isDark ? DesignTokens.primary400 : DesignTokens.primary500,
        disabledForegroundColor:
            isDark ? DesignTokens.darkNeutral500 : DesignTokens.neutral500,
        side: BorderSide(
          color: isDark ? DesignTokens.primary400 : DesignTokens.primary500,
          width: DesignTokens.borderWidthDefault,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space24,
          vertical: DesignTokens.space16,
        ),
        minimumSize: const Size(
            DesignTokens.minTouchTarget, DesignTokens.minTouchTarget),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: DesignTokens.fontSize14,
          fontWeight: DesignTokens.fontWeightMedium,
          height: DesignTokens.lineHeightNormal,
        ),
        animationDuration: DesignTokens.durationFast,
      ),
    );
  }

  /// Constrói o tema de botões de texto
  static TextButtonThemeData _buildTextButtonTheme(bool isDark) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor:
            isDark ? DesignTokens.primary400 : DesignTokens.primary500,
        disabledForegroundColor:
            isDark ? DesignTokens.darkNeutral500 : DesignTokens.neutral500,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space12,
        ),
        minimumSize: const Size(
            DesignTokens.minTouchTarget, DesignTokens.minTouchTarget),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: DesignTokens.fontSize14,
          fontWeight: DesignTokens.fontWeightMedium,
          height: DesignTokens.lineHeightNormal,
        ),
        animationDuration: DesignTokens.durationFast,
      ),
    );
  }

  /// Constrói o tema de campos de input
  static InputDecorationTheme _buildInputDecorationTheme(bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? DesignTokens.darkNeutral100 : DesignTokens.neutral100,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space16,
        vertical: DesignTokens.space16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        borderSide: BorderSide(
          color: isDark ? DesignTokens.darkNeutral300 : DesignTokens.neutral300,
          width: DesignTokens.borderWidthDefault,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        borderSide: BorderSide(
          color: isDark ? DesignTokens.darkNeutral300 : DesignTokens.neutral300,
          width: DesignTokens.borderWidthDefault,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        borderSide: BorderSide(
          color: isDark ? DesignTokens.primary400 : DesignTokens.primary500,
          width: DesignTokens.borderWidthThick,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        borderSide: const BorderSide(
          color: DesignTokens.error500,
          width: DesignTokens.borderWidthDefault,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        borderSide: const BorderSide(
          color: DesignTokens.error500,
          width: DesignTokens.borderWidthThick,
        ),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize14,
        fontWeight: DesignTokens.fontWeightRegular,
        color: isDark ? DesignTokens.darkNeutral600 : DesignTokens.neutral600,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize14,
        fontWeight: DesignTokens.fontWeightRegular,
        color: isDark ? DesignTokens.darkNeutral500 : DesignTokens.neutral500,
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize12,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.error500,
      ),
    );
  }

  /// Constrói o tema de cards
  static CardTheme _buildCardTheme(bool isDark) {
    return CardTheme(
      color: isDark ? DesignTokens.darkNeutral100 : Colors.white,
      shadowColor: isDark ? Colors.black54 : DesignTokens.neutral400,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
        side: BorderSide(
          color: isDark ? DesignTokens.darkNeutral200 : DesignTokens.neutral200,
          width: DesignTokens.borderWidthThin,
        ),
      ),
      margin: const EdgeInsets.all(DesignTokens.space8),
    );
  }

  /// Constrói o tema de chips
  static ChipThemeData _buildChipTheme(bool isDark) {
    return ChipThemeData(
      backgroundColor:
          isDark ? DesignTokens.darkNeutral200 : DesignTokens.neutral200,
      deleteIconColor:
          isDark ? DesignTokens.darkNeutral600 : DesignTokens.neutral600,
      disabledColor:
          isDark ? DesignTokens.darkNeutral300 : DesignTokens.neutral300,
      selectedColor: isDark ? DesignTokens.primary800 : DesignTokens.primary100,
      secondarySelectedColor:
          isDark ? DesignTokens.secondary800 : DesignTokens.secondary100,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space12,
        vertical: DesignTokens.space8,
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
      labelStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize12,
        fontWeight: DesignTokens.fontWeightMedium,
        color: isDark ? DesignTokens.darkNeutral800 : DesignTokens.neutral800,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize12,
        fontWeight: DesignTokens.fontWeightMedium,
        color: isDark ? DesignTokens.primary200 : DesignTokens.primary700,
      ),
      brightness: isDark ? Brightness.dark : Brightness.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
    );
  }

  // Métodos auxiliares para outros componentes (switch, checkbox, etc.)
  // Implementação similar seguindo os mesmos padrões...

  static SwitchThemeData _buildSwitchTheme(bool isDark) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark ? DesignTokens.darkNeutral400 : DesignTokens.neutral400;
        }
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return isDark ? DesignTokens.darkNeutral600 : DesignTokens.neutral600;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark ? DesignTokens.darkNeutral300 : DesignTokens.neutral300;
        }
        if (states.contains(WidgetState.selected)) {
          return isDark ? DesignTokens.primary400 : DesignTokens.primary500;
        }
        return isDark ? DesignTokens.darkNeutral400 : DesignTokens.neutral400;
      }),
    );
  }

  static CheckboxThemeData _buildCheckboxTheme(bool isDark) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark ? DesignTokens.darkNeutral300 : DesignTokens.neutral300;
        }
        if (states.contains(WidgetState.selected)) {
          return isDark ? DesignTokens.primary400 : DesignTokens.primary500;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: BorderSide(
        color: isDark ? DesignTokens.darkNeutral400 : DesignTokens.neutral400,
        width: DesignTokens.borderWidthDefault,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
    );
  }

  static RadioThemeData _buildRadioTheme(bool isDark) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark ? DesignTokens.darkNeutral300 : DesignTokens.neutral300;
        }
        if (states.contains(WidgetState.selected)) {
          return isDark ? DesignTokens.primary400 : DesignTokens.primary500;
        }
        return isDark ? DesignTokens.darkNeutral400 : DesignTokens.neutral400;
      }),
    );
  }

  static SliderThemeData _buildSliderTheme(bool isDark) {
    return SliderThemeData(
      activeTrackColor:
          isDark ? DesignTokens.primary400 : DesignTokens.primary500,
      inactiveTrackColor:
          isDark ? DesignTokens.darkNeutral300 : DesignTokens.neutral300,
      thumbColor: isDark ? DesignTokens.primary400 : DesignTokens.primary500,
      overlayColor: (isDark ? DesignTokens.primary400 : DesignTokens.primary500)
          .withValues(alpha: 0.12),
      valueIndicatorColor:
          isDark ? DesignTokens.darkNeutral800 : DesignTokens.neutral800,
      valueIndicatorTextStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize12,
        fontWeight: DesignTokens.fontWeightMedium,
        color: isDark ? DesignTokens.darkNeutral100 : DesignTokens.neutral100,
      ),
    );
  }

  static ProgressIndicatorThemeData _buildProgressIndicatorTheme(bool isDark) {
    return ProgressIndicatorThemeData(
      color: isDark ? DesignTokens.primary400 : DesignTokens.primary500,
      linearTrackColor:
          isDark ? DesignTokens.darkNeutral300 : DesignTokens.neutral300,
      circularTrackColor:
          isDark ? DesignTokens.darkNeutral300 : DesignTokens.neutral300,
    );
  }

  static SnackBarThemeData _buildSnackBarTheme(bool isDark) {
    return SnackBarThemeData(
      backgroundColor:
          isDark ? DesignTokens.darkNeutral800 : DesignTokens.neutral800,
      contentTextStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize14,
        fontWeight: DesignTokens.fontWeightRegular,
        color: isDark ? DesignTokens.darkNeutral100 : DesignTokens.neutral100,
      ),
      actionTextColor:
          isDark ? DesignTokens.primary300 : DesignTokens.primary200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      behavior: SnackBarBehavior.floating,
    );
  }

  static DialogTheme _buildDialogTheme(bool isDark) {
    return DialogTheme(
      backgroundColor: isDark ? DesignTokens.darkNeutral100 : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: isDark ? Colors.black54 : DesignTokens.neutral400,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radius3xl),
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize20,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: isDark ? DesignTokens.darkNeutral900 : DesignTokens.neutral900,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize14,
        fontWeight: DesignTokens.fontWeightRegular,
        color: isDark ? DesignTokens.darkNeutral700 : DesignTokens.neutral700,
        height: DesignTokens.lineHeightNormal,
      ),
    );
  }

  static BottomSheetThemeData _buildBottomSheetTheme(bool isDark) {
    return BottomSheetThemeData(
      backgroundColor: isDark ? DesignTokens.darkNeutral100 : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: isDark ? Colors.black54 : DesignTokens.neutral400,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radius3xl),
        ),
      ),
      modalElevation: 16,
      modalBackgroundColor: isDark ? DesignTokens.darkNeutral100 : Colors.white,
    );
  }

  static NavigationBarThemeData _buildNavigationBarTheme(bool isDark) {
    return NavigationBarThemeData(
      backgroundColor: isDark ? DesignTokens.darkNeutral100 : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shadowColor: isDark ? Colors.black26 : DesignTokens.neutral300,
      indicatorColor:
          isDark ? DesignTokens.primary800 : DesignTokens.primary100,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
        final color = states.contains(WidgetState.selected)
            ? (isDark ? DesignTokens.primary300 : DesignTokens.primary700)
            : (isDark ? DesignTokens.darkNeutral600 : DesignTokens.neutral600);
        return GoogleFonts.inter(
          fontSize: DesignTokens.fontSize12,
          fontWeight: DesignTokens.fontWeightMedium,
          color: color,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
        final color = states.contains(WidgetState.selected)
            ? (isDark ? DesignTokens.primary300 : DesignTokens.primary700)
            : (isDark ? DesignTokens.darkNeutral600 : DesignTokens.neutral600);
        return IconThemeData(color: color, size: 24);
      }),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme(
      bool isDark) {
    return BottomNavigationBarThemeData(
      backgroundColor: isDark ? DesignTokens.darkNeutral100 : Colors.white,
      elevation: 8,
      selectedItemColor:
          isDark ? DesignTokens.primary300 : DesignTokens.primary700,
      unselectedItemColor:
          isDark ? DesignTokens.darkNeutral600 : DesignTokens.neutral600,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize12,
        fontWeight: DesignTokens.fontWeightMedium,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize12,
        fontWeight: DesignTokens.fontWeightRegular,
      ),
      type: BottomNavigationBarType.fixed,
    );
  }

  static TabBarTheme _buildTabBarTheme(bool isDark) {
    return TabBarTheme(
      labelColor: isDark ? DesignTokens.primary300 : DesignTokens.primary700,
      unselectedLabelColor:
          isDark ? DesignTokens.darkNeutral600 : DesignTokens.neutral600,
      labelStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize14,
        fontWeight: DesignTokens.fontWeightMedium,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: DesignTokens.fontSize14,
        fontWeight: DesignTokens.fontWeightRegular,
      ),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: isDark ? DesignTokens.primary300 : DesignTokens.primary700,
          width: DesignTokens.borderWidthThick,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor:
          isDark ? DesignTokens.darkNeutral200 : DesignTokens.neutral200,
    );
  }
}
