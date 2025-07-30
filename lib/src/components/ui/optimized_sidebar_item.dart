import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../styles/app_theme.dart';

/// Item otimizado para o menu lateral com alta performance e micro-interações
class OptimizedSidebarItem extends StatefulWidget {
  final IconData icon;
  final IconData fillIcon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final int? badge;
  final VoidCallback onTap;
  final Color? customColor;

  const OptimizedSidebarItem({
    super.key,
    required this.icon,
    required this.fillIcon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
    this.badge,
    this.customColor,
  });

  @override
  State<OptimizedSidebarItem> createState() => _OptimizedSidebarItemState();
}

class _OptimizedSidebarItemState extends State<OptimizedSidebarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: widget.customColor ?? AppTheme.primaryColor,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Iniciar animação se já estiver selecionado
    if (widget.isSelected) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OptimizedSidebarItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animar apenas quando necessário
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _handleTap() {
    // Feedback tátil
    HapticFeedback.lightImpact();

    // Animar pressionamento
    setState(() => _isPressed = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isPressed = false);
      }
    });

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _handleTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            constraints: BoxConstraints(
              minHeight: 48,
              maxWidth: widget.isCollapsed ? 70 : double.infinity,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 8 : 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getBorderColor(),
                width: 1.5,
              ),
              boxShadow: _getBoxShadow(),
            ),
            child: widget.isCollapsed
                ? _buildCollapsedContent()
                : _buildExpandedContent(),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.isSelected) {
      return (widget.customColor ?? AppTheme.primaryColor)
          .withValues(alpha: 0.1);
    }
    if (_isHovered) {
      return (widget.customColor ?? AppTheme.primaryColor)
          .withValues(alpha: 0.05);
    }
    if (_isPressed) {
      return (widget.customColor ?? AppTheme.primaryColor)
          .withValues(alpha: 0.15);
    }
    return Colors.transparent;
  }

  Color _getBorderColor() {
    if (widget.isSelected) {
      return (widget.customColor ?? AppTheme.primaryColor)
          .withValues(alpha: 0.3);
    }
    if (_isHovered) {
      return (widget.customColor ?? AppTheme.primaryColor)
          .withValues(alpha: 0.2);
    }
    return Colors.transparent;
  }

  List<BoxShadow>? _getBoxShadow() {
    if (widget.isSelected || _isHovered) {
      return [
        BoxShadow(
          color: (widget.customColor ?? AppTheme.primaryColor)
              .withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return null;
  }

  Widget _buildCollapsedContent() {
    return Center(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              children: [
                Icon(
                  widget.isSelected ? widget.fillIcon : widget.icon,
                  color: _getIconColor(),
                  size: 20,
                ),
                if (widget.badge != null && widget.badge! > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: _buildBadge(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandedContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 140) {
          return _buildCompactContent();
        }

        return Row(
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Stack(
                    children: [
                      Icon(
                        widget.isSelected ? widget.fillIcon : widget.icon,
                        color: _getIconColor(),
                        size: 22,
                      ),
                      if (widget.badge != null && widget.badge! > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: _buildBadge(),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: _getTextColor(),
                  fontSize: 13,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: widget.isSelected ? 0.2 : 0,
                ),
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactContent() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                children: [
                  Icon(
                    widget.isSelected ? widget.fillIcon : widget.icon,
                    color: _getIconColor(),
                    size: 20,
                  ),
                  if (widget.badge != null && widget.badge! > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: _buildBadge(),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 6),
        Flexible(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: _getTextColor(),
              fontSize: 11,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: widget.isSelected ? 0.2 : 0,
            ),
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }

  Color _getIconColor() {
    if (widget.isSelected) {
      return widget.customColor ?? AppTheme.primaryColor;
    }
    if (_isHovered) {
      return (widget.customColor ?? AppTheme.primaryColor)
          .withValues(alpha: 0.8);
    }
    return AppTheme.getTextColor(context).withValues(alpha: 0.7);
  }

  Color _getTextColor() {
    if (widget.isSelected) {
      return widget.customColor ?? AppTheme.primaryColor;
    }
    if (_isHovered) {
      return (widget.customColor ?? AppTheme.primaryColor)
          .withValues(alpha: 0.8);
    }
    return AppTheme.getTextColor(context).withValues(alpha: 0.8);
  }

  Widget _buildBadge() {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: widget.customColor ?? AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: (widget.customColor ?? AppTheme.primaryColor)
                      .withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              widget.badge! > 99 ? '99+' : widget.badge.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
