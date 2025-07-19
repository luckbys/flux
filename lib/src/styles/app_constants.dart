class AppConstants {
  // Raios de borda
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Elevações
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  static const double elevationXLarge = 16.0;

  // Tamanhos de ícones
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // Alturas de componentes
  static const double buttonHeight = 48.0;
  static const double inputHeight = 48.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 60.0;

  // Larguras máximas
  static const double maxContentWidth = 1200.0;
  static const double maxCardWidth = 400.0;
  static const double maxModalWidth = 600.0;

  // Breakpoints responsivos
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // Durações de animação específicas
  static const Duration quickAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Opacidades
  static const double opacityDisabled = 0.5;
  static const double opacitySecondary = 0.7;
  static const double opacityOverlay = 0.8;

  // Z-index (para sobreposições)
  static const int zIndexModal = 1000;
  static const int zIndexTooltip = 1100;
  static const int zIndexDropdown = 1200;
}
