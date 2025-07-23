import 'package:flutter/material.dart';

/// Design Tokens para o BKCRM
/// Implementa um sistema de design consistente com suporte completo
/// a modo escuro, acessibilidade WCAG 2.1 AA e animações micro-interativas
class DesignTokens {
  // ==================== CORES SEMÂNTICAS ====================

  /// Cores primárias do sistema
  static const Color primary50 = Color(0xFFEFF6FF);
  static const Color primary100 = Color(0xFFDBEAFE);
  static const Color primary200 = Color(0xFFBFDBFE);
  static const Color primary300 = Color(0xFF93C5FD);
  static const Color primary400 = Color(0xFF60A5FA);
  static const Color primary500 = Color(0xFF3B82F6); // Cor principal
  static const Color primary600 = Color(0xFF2563EB);
  static const Color primary700 = Color(0xFF1D4ED8);
  static const Color primary800 = Color(0xFF1E40AF);
  static const Color primary900 = Color(0xFF1E3A8A);
  static const Color primary950 = Color(0xFF172554);

  /// Cores secundárias
  static const Color secondary50 = Color(0xFFEEF2FF);
  static const Color secondary100 = Color(0xFFE0E7FF);
  static const Color secondary200 = Color(0xFFC7D2FE);
  static const Color secondary300 = Color(0xFFA5B4FC);
  static const Color secondary400 = Color(0xFF818CF8);
  static const Color secondary500 = Color(0xFF6366F1);
  static const Color secondary600 = Color(0xFF4F46E5);
  static const Color secondary700 = Color(0xFF4338CA);
  static const Color secondary800 = Color(0xFF3730A3);
  static const Color secondary900 = Color(0xFF312E81);
  static const Color secondary950 = Color(0xFF1E1B4B);

  /// Cores de estado
  static const Color success50 = Color(0xFFF0FDF4);
  static const Color success500 = Color(0xFF22C55E);
  static const Color success700 = Color(0xFF15803D);

  static const Color warning50 = Color(0xFFFFFBEB);
  static const Color warning500 = Color(0xFFF59E0B);
  static const Color warning700 = Color(0xFFA16207);

  static const Color error50 = Color(0xFFFEF2F2);
  static const Color error100 = Color(0xFFFEF2F2);
  static const Color error200 = Color(0xFFFECACA);
  static const Color error300 = Color(0xFFFCA5A5);
  static const Color error400 = Color(0xFFF87171);
  static const Color error500 = Color(0xFFEF4444);
  static const Color error700 = Color(0xFFC53030);
  static const Color error800 = Color(0xFF991B1B);
  static const Color error950 = Color(0xFF450A0A);

  static const Color info50 = Color(0xFFEFF6FF);
  static const Color info100 = Color(0xFFDBEAFE);
  static const Color info400 = Color(0xFF60A5FA);
  static const Color info500 = Color(0xFF3B82F6);
  static const Color info700 = Color(0xFF1D4ED8);
  static const Color info800 = Color(0xFF1E40AF);
  static const Color info900 = Color(0xFF1E3A8A);
  static const Color info950 = Color(0xFF172554);

  /// Cores neutras (Light Theme)
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);
  static const Color neutral950 = Color(0xFF0A0A0A);

  /// Cores neutras escuras (Dark Theme)
  static const Color darkNeutral50 = Color(0xFF18181B);
  static const Color darkNeutral100 = Color(0xFF27272A);
  static const Color darkNeutral200 = Color(0xFF3F3F46);
  static const Color darkNeutral300 = Color(0xFF52525B);
  static const Color darkNeutral400 = Color(0xFF71717A);
  static const Color darkNeutral500 = Color(0xFFA1A1AA);
  static const Color darkNeutral600 = Color(0xFFD4D4D8);
  static const Color darkNeutral700 = Color(0xFFE4E4E7);
  static const Color darkNeutral800 = Color(0xFFF4F4F5);
  static const Color darkNeutral900 = Color(0xFFFAFAFA);

  // ==================== TIPOGRAFIA ====================

  /// Escala tipográfica baseada em proporção áurea
  static const double fontSize10 = 10.0;
  static const double fontSize12 = 12.0;
  static const double fontSize14 = 14.0;
  static const double fontSize16 = 16.0; // Base
  static const double fontSize18 = 18.0;
  static const double fontSize20 = 20.0;
  static const double fontSize24 = 24.0;
  static const double fontSize28 = 28.0;
  static const double fontSize32 = 32.0;
  static const double fontSize36 = 36.0;
  static const double fontSize48 = 48.0;
  static const double fontSize64 = 64.0;

  /// Pesos de fonte
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;

  /// Altura de linha para melhor legibilidade (WCAG 2.1 AA)
  static const double lineHeightTight = 1.25;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // ==================== ESPAÇAMENTOS ====================

  /// Sistema de espaçamento baseado em múltiplos de 4px
  static const double space0 = 0.0;
  static const double space1 = 1.0;
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space56 = 56.0;
  static const double space64 = 64.0;
  static const double space80 = 80.0;
  static const double space96 = 96.0;
  static const double space128 = 128.0;

  // ==================== BORDAS E RAIOS ====================

  /// Raios de borda consistentes
  static const double radiusNone = 0.0;
  static const double radiusXs = 2.0;
  static const double radiusSm = 4.0;
  static const double radiusMd = 6.0;
  static const double radiusLg = 8.0;
  static const double radiusXl = 12.0;
  static const double radius2xl = 16.0;
  static const double radius3xl = 24.0;
  static const double radiusFull = 9999.0;

  /// Larguras de borda
  static const double borderWidthThin = 0.5;
  static const double borderWidthDefault = 1.0;
  static const double borderWidth1 = 1.0;
  static const double borderWidth2 = 2.0;
  static const double borderWidthThick = 2.0;
  static const double borderWidthExtra = 4.0;

  // ==================== SOMBRAS ====================

  /// Sombras para elevação (Material Design 3)
  static const List<BoxShadow> shadowNone = [];

  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 2,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 15,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x19000000),
      blurRadius: 25,
      offset: Offset(0, 20),
    ),
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 10,
      offset: Offset(0, 8),
    ),
  ];

  // Sombras individuais para compatibilidade
  static const BoxShadow shadowSmSingle = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow shadowMdSingle = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow shadowLgSingle = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow shadowXlSingle = BoxShadow(
    color: Color(0x25000000),
    blurRadius: 12,
    offset: Offset(0, 6),
  );

  // ==================== ANIMAÇÕES ====================

  /// Durações de animação baseadas em Material Design
  static const Duration durationInstant = Duration(milliseconds: 0);
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationSlower = Duration(milliseconds: 750);
  static const Duration durationSlowest = Duration(milliseconds: 1000);

  /// Curvas de animação para micro-interações
  static const Curve curveLinear = Curves.linear;
  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveEaseIn = Curves.easeIn;
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveEaseInBack = Curves.easeInBack;
  static const Curve curveEaseOutBack = Curves.easeOutBack;
  static const Curve curveEaseInOutBack = Curves.easeInOutBack;
  static const Curve curveBounce = Curves.bounceOut;
  static const Curve curveElastic = Curves.elasticOut;

  // ==================== BREAKPOINTS RESPONSIVOS ====================

  /// Breakpoints para design responsivo
  static const double breakpointXs = 480.0;
  static const double breakpointSm = 640.0;
  static const double breakpointMd = 768.0;
  static const double breakpointLg = 1024.0;
  static const double breakpointXl = 1280.0;
  static const double breakpoint2xl = 1536.0;

  // ==================== ACESSIBILIDADE ====================

  /// Tamanhos mínimos para toque (WCAG 2.1 AA)
  static const double minTouchTarget = 44.0;
  static const double recommendedTouchTarget = 48.0;

  /// Contrastes mínimos para acessibilidade
  static const double contrastRatioAA = 4.5;
  static const double contrastRatioAAA = 7.0;

  /// Cores com contraste adequado para texto
  static Color getAccessibleTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? neutral900 : neutral50;
  }

  /// Verifica se uma cor tem contraste suficiente
  static bool hasAccessibleContrast(Color foreground, Color background) {
    final ratio = _calculateContrastRatio(foreground, background);
    return ratio >= contrastRatioAA;
  }

  static double _calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = color1.computeLuminance();
    final luminance2 = color2.computeLuminance();
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  // ==================== GLASSMORPHISM ====================

  /// Efeitos de vidro para o design system
  static BoxDecoration getGlassDecoration({
    bool isDark = false,
    double opacity = 0.1,
    double borderOpacity = 0.2,
    double radius = 16.0,
    List<BoxShadow>? customShadows,
  }) {
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: opacity)
          : Colors.black.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: borderOpacity)
            : Colors.black.withValues(alpha: borderOpacity),
        width: borderWidthThin,
      ),
      boxShadow: customShadows ?? shadowMd,
    );
  }

  // ==================== UTILITÁRIOS DE TEMA ====================

  /// Obtém a cor baseada no tema atual
  static Color getColorByTheme({
    required BuildContext context,
    required Color lightColor,
    required Color darkColor,
  }) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkColor
        : lightColor;
  }

  /// Obtém a cor de texto com contraste adequado
  static Color getContrastingTextColor(
      BuildContext context, Color backgroundColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final luminance = backgroundColor.computeLuminance();

    if (isDark) {
      return luminance > 0.5 ? darkNeutral50 : darkNeutral900;
    } else {
      return luminance > 0.5 ? neutral900 : neutral50;
    }
  }
}

/// Extensão para facilitar o uso dos tokens
extension DesignTokensExtension on BuildContext {
  /// Verifica se está no modo escuro
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Obtém cor baseada no tema
  Color colorByTheme({required Color light, required Color dark}) {
    return DesignTokens.getColorByTheme(
      context: this,
      lightColor: light,
      darkColor: dark,
    );
  }

  /// Obtém cor de texto com contraste adequado
  Color contrastingTextColor(Color backgroundColor) {
    return DesignTokens.getContrastingTextColor(this, backgroundColor);
  }
}
