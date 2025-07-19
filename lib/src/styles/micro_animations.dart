import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Componentes de animações micro-interativas para melhorar a experiência do usuário
/// Seguindo princípios de design de movimento e acessibilidade
class MicroAnimations {
  // ==================== ANIMAÇÕES DE ENTRADA ====================
  
  /// Animação de fade in suave
  static Widget fadeIn({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveDefault,
    double begin = 0.0,
    double end = 1.0,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween(begin: begin, end: end),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// Animação de slide in com direção customizável
  static Widget slideIn({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveDefault,
    Offset begin = const Offset(0, 0.3),
    Offset end = Offset.zero,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      duration: duration,
      curve: curve,
      tween: Tween(begin: begin, end: end),
      builder: (context, value, child) {
        return Transform.translate(
          offset: value * 50, // Multiplicador para controlar a distância
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// Animação de scale in suave
  static Widget scaleIn({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveDefault,
    double begin = 0.8,
    double end = 1.0,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween(begin: begin, end: end),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// Animação combinada de fade + slide + scale
  static Widget enterAnimation({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveDefault,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, progress, child) {
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 20),
            child: Transform.scale(
              scale: 0.95 + (progress * 0.05),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
  
  // ==================== ANIMAÇÕES DE INTERAÇÃO ====================
  
  /// Botão com animação de press e hover
  static Widget animatedButton({
    required Widget child,
    required VoidCallback? onPressed,
    Duration duration = DesignTokens.durationFast,
    Curve curve = DesignTokens.curveDefault,
    double scaleOnPress = 0.95,
    double scaleOnHover = 1.02,
  }) {
    return _AnimatedButton(
      onPressed: onPressed,
      duration: duration,
      curve: curve,
      scaleOnPress: scaleOnPress,
      scaleOnHover: scaleOnHover,
      child: child,
    );
  }
  
  /// Card com animação de hover e tap
  static Widget animatedCard({
    required Widget child,
    VoidCallback? onTap,
    Duration duration = DesignTokens.durationFast,
    Curve curve = DesignTokens.curveDefault,
    double elevation = 2.0,
    double hoverElevation = 8.0,
    double scaleOnHover = 1.02,
  }) {
    return _AnimatedCard(
      onTap: onTap,
      duration: duration,
      curve: curve,
      elevation: elevation,
      hoverElevation: hoverElevation,
      scaleOnHover: scaleOnHover,
      child: child,
    );
  }
  
  /// Container com animação de shimmer para loading
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    Color? baseColor,
    Color? highlightColor,
  }) {
    return _ShimmerWidget(
      duration: duration,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
  
  /// Animação de pulse para chamar atenção
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.95,
    double maxScale = 1.05,
    bool repeat = true,
  }) {
    return _PulseWidget(
      duration: duration,
      minScale: minScale,
      maxScale: maxScale,
      repeat: repeat,
      child: child,
    );
  }
  
  /// Animação de bounce para feedback de sucesso
  static Widget bounce({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    double scale = 1.2,
  }) {
    return _BounceWidget(
      duration: duration,
      scale: scale,
      child: child,
    );
  }
  
  /// Animação de shake para feedback de erro
  static Widget shake({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    double offset = 10.0,
  }) {
    return _ShakeWidget(
      duration: duration,
      offset: offset,
      child: child,
    );
  }
  
  // ==================== ANIMAÇÕES DE TRANSIÇÃO ====================
  
  /// Transição de página com slide
  static PageRouteBuilder slidePageRoute({
    required Widget page,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveDefault,
    SlideDirection direction = SlideDirection.right,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case SlideDirection.up:
            begin = const Offset(0.0, 1.0);
            break;
          case SlideDirection.down:
            begin = const Offset(0.0, -1.0);
            break;
          case SlideDirection.left:
            begin = const Offset(-1.0, 0.0);
            break;
          case SlideDirection.right:
            begin = const Offset(1.0, 0.0);
            break;
        }
        
        final offsetAnimation = Tween(
          begin: begin,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));
        
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
  
  /// Transição de página com fade
  static PageRouteBuilder fadePageRoute({
    required Widget page,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveDefault,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: curve,
          ),
          child: child,
        );
      },
    );
  }
  
  /// Transição de página com scale
  static PageRouteBuilder scalePageRoute({
    required Widget page,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveDefault,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: curve,
          ),
          child: child,
        );
      },
    );
  }
}

// ==================== ENUMS ====================

enum SlideDirection { up, down, left, right }

// ==================== WIDGETS INTERNOS ====================

class _AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final Curve curve;
  final double scaleOnPress;
  final double scaleOnHover;
  
  const _AnimatedButton({
    required this.child,
    required this.onPressed,
    required this.duration,
    required this.curve,
    required this.scaleOnPress,
    required this.scaleOnHover,
  });
  
  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  bool _isPressed = false;
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _updateScale() {
    double targetScale = 1.0;
    if (_isPressed) {
      targetScale = widget.scaleOnPress;
    } else if (_isHovered) {
      targetScale = widget.scaleOnHover;
    }
    
    _scaleAnimation = Tween<double>(
      begin: _scaleAnimation.value,
      end: targetScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    _controller.reset();
    _controller.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
        _updateScale();
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
        _updateScale();
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _isPressed = true;
          });
          _updateScale();
        },
        onTapUp: (_) {
          setState(() {
            _isPressed = false;
          });
          _updateScale();
          widget.onPressed?.call();
        },
        onTapCancel: () {
          setState(() {
            _isPressed = false;
          });
          _updateScale();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final Curve curve;
  final double elevation;
  final double hoverElevation;
  final double scaleOnHover;
  
  const _AnimatedCard({
    required this.child,
    this.onTap,
    required this.duration,
    required this.curve,
    required this.elevation,
    required this.hoverElevation,
    required this.scaleOnHover,
  });
  
  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _updateAnimations() {
    final targetElevation = _isHovered ? widget.hoverElevation : widget.elevation;
    final targetScale = _isHovered ? widget.scaleOnHover : 1.0;
    
    _elevationAnimation = Tween<double>(
      begin: _elevationAnimation.value,
      end: targetElevation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: _scaleAnimation.value,
      end: targetScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    _controller.reset();
    _controller.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
        _updateAnimations();
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
        _updateAnimations();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Material(
                elevation: _elevationAnimation.value,
                borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;
  
  const _ShimmerWidget({
    required this.child,
    required this.duration,
    this.baseColor,
    this.highlightColor,
  });
  
  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final baseColor = widget.baseColor ?? 
        (isDark ? DesignTokens.darkNeutral200 : DesignTokens.neutral200);
    final highlightColor = widget.highlightColor ?? 
        (isDark ? DesignTokens.darkNeutral300 : DesignTokens.neutral300);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _PulseWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool repeat;
  
  const _PulseWidget({
    required this.child,
    required this.duration,
    required this.minScale,
    required this.maxScale,
    required this.repeat,
  });
  
  @override
  State<_PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<_PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

class _BounceWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scale;
  
  const _BounceWidget({
    required this.child,
    required this.duration,
    required this.scale,
  });
  
  @override
  State<_BounceWidget> createState() => _BounceWidgetState();
}

class _BounceWidgetState extends State<_BounceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _controller.forward().then((_) {
      _controller.reverse();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

class _ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;
  
  const _ShakeWidget({
    required this.child,
    required this.duration,
    required this.offset,
  });
  
  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticIn,
    ));
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final offset = widget.offset * _animation.value * 
            (1 - _animation.value) * 4; // Efeito de shake
        return Transform.translate(
          offset: Offset(offset, 0),
          child: widget.child,
        );
      },
    );
  }
}