import 'package:flutter/material.dart';

class EnhancedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Widget? loadingWidget;
  final Duration animationDuration;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const EnhancedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.padding,
    this.textStyle,
    this.loadingWidget,
    this.animationDuration = const Duration(milliseconds: 200),
    this.boxShadow,
    this.gradient,
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.isEnabled && !widget.isLoading) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  Color _getBackgroundColor() {
    if (!widget.isEnabled || widget.isLoading) {
      return (widget.backgroundColor ?? const Color(0xFF3B82F6))
          .withValues(alpha: 0.5);
    }
    if (_isHovered) {
      return (widget.backgroundColor ?? const Color(0xFF3B82F6))
          .withValues(alpha: 0.9);
    }
    return widget.backgroundColor ?? const Color(0xFF3B82F6);
  }

  List<BoxShadow> _getBoxShadow() {
    if (!widget.isEnabled || widget.isLoading) {
      return [];
    }

    if (widget.boxShadow != null) {
      return widget.boxShadow!;
    }

    final baseColor = widget.backgroundColor ?? const Color(0xFF3B82F6);

    if (_isHovered) {
      return [
        BoxShadow(
          color: baseColor.withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];
    }

    return [
      BoxShadow(
        color: baseColor.withValues(alpha: 0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return widget.loadingWidget ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.textColor ?? Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Carregando...',
                style: widget.textStyle ??
                    TextStyle(
                      color: widget.textColor ?? Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            color: widget.textColor ?? Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: widget.textStyle ??
                TextStyle(
                  color: widget.textColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: widget.textStyle ??
          TextStyle(
            color: widget.textColor ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _handleHover(true),
            onExit: (_) => _handleHover(false),
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              onTap: (widget.isEnabled && !widget.isLoading)
                  ? widget.onPressed
                  : null,
              child: AnimatedContainer(
                duration: widget.animationDuration,
                width: widget.width,
                height: widget.height ?? (isDesktop ? 56 : 52),
                padding: widget.padding ??
                    EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 20,
                      vertical: isDesktop ? 16 : 14,
                    ),
                decoration: BoxDecoration(
                  gradient: widget.gradient ??
                      LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getBackgroundColor(),
                          _getBackgroundColor().withValues(alpha: 0.8),
                        ],
                      ),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: _getBoxShadow(),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class EnhancedOutlinedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Widget? loadingWidget;
  final Duration animationDuration;

  const EnhancedOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.borderColor,
    this.textColor,
    this.backgroundColor,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.padding,
    this.textStyle,
    this.loadingWidget,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<EnhancedOutlinedButton> createState() => _EnhancedOutlinedButtonState();
}

class _EnhancedOutlinedButtonState extends State<EnhancedOutlinedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.isEnabled && !widget.isLoading) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  Color _getBorderColor() {
    if (!widget.isEnabled || widget.isLoading) {
      return (widget.borderColor ?? const Color(0xFF3B82F6))
          .withValues(alpha: 0.5);
    }
    return widget.borderColor ?? const Color(0xFF3B82F6);
  }

  Color _getBackgroundColor() {
    if (!widget.isEnabled || widget.isLoading) {
      return Colors.transparent;
    }
    if (_isHovered) {
      return (widget.borderColor ?? const Color(0xFF3B82F6))
          .withValues(alpha: 0.1);
    }
    return widget.backgroundColor ?? Colors.transparent;
  }

  Color _getTextColor() {
    if (!widget.isEnabled || widget.isLoading) {
      return (widget.textColor ?? const Color(0xFF3B82F6))
          .withValues(alpha: 0.5);
    }
    return widget.textColor ?? const Color(0xFF3B82F6);
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return widget.loadingWidget ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Carregando...',
                style: widget.textStyle ??
                    TextStyle(
                      color: _getTextColor(),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            color: _getTextColor(),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: widget.textStyle ??
                TextStyle(
                  color: _getTextColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: widget.textStyle ??
          TextStyle(
            color: _getTextColor(),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _handleHover(true),
            onExit: (_) => _handleHover(false),
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              onTap: (widget.isEnabled && !widget.isLoading)
                  ? widget.onPressed
                  : null,
              child: AnimatedContainer(
                duration: widget.animationDuration,
                width: widget.width,
                height: widget.height ?? (isDesktop ? 56 : 52),
                padding: widget.padding ??
                    EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 20,
                      vertical: isDesktop ? 16 : 14,
                    ),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: _getBorderColor(),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
