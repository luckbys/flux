import 'package:flutter/material.dart';
import '../pages/main_layout.dart'; // Import NavItem from here
import 'dart:ui';

class IosDock extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  final Axis axis;

  const IosDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.axis = Axis.horizontal,
  });

  @override
  State<IosDock> createState() => _IosDockState();
}

class _IosDockState extends State<IosDock> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHorizontal = widget.axis == Axis.horizontal;
    return Padding(
      padding: isHorizontal
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: isHorizontal ? null : 60,
            height: isHorizontal ? 48 : null,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25), // Borda branca sutil
                width: 1.2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.30),
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Flex(
              direction: widget.axis,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = widget.currentIndex == item.index;
                return RepaintBoundary(
                  child: MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _hoveredIndex = index;
                      });
                      _hoverController.forward();
                    },
                    onExit: (_) {
                      setState(() {
                        _hoveredIndex = -1;
                      });
                      _hoverController.reverse();
                    },
                    child: GestureDetector(
                      onTap: () => widget.onTap(item.index),
                      child: Tooltip(
                        message: item.label,
                        child: Semantics(
                          label: item.label,
                          selected: isSelected,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.all(2),
                            transform: isSelected
                                ? (isHorizontal
                                    ? Matrix4.translationValues(0, -3, 0)
                                    : Matrix4.translationValues(-3, 0, 0))
                                : Matrix4.identity(),
                            child: AnimatedScale(
                              scale: _hoveredIndex == index ? 1.08 : 1.0,
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelected ? item.fillIcon : item.icon,
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[600],
                                    size: isSelected ? 22 : 18,
                                  ),
                                  if (isSelected)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1),
                                      child: SizedBox(
                                        width: isHorizontal ? 48 : 64,
                                        child: Text(
                                          item.label,
                                          style: TextStyle(
                                              fontSize: isHorizontal ? 8 : 9,
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
