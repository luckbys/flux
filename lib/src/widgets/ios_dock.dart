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

class _IosDockState extends State<IosDock> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
        widget.items.length,
        (_) => AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 200),
            ));
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
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
                return MouseRegion(
                  onEnter: (_) => _controllers[index].forward(),
                  onExit: (_) => _controllers[index].reverse(),
                  child: GestureDetector(
                    onTap: () => widget.onTap(item.index),
                    child: Tooltip(
                      message: item.label,
                      child: Semantics(
                        label: item.label,
                        selected: isSelected,
                        child: AnimatedBuilder(
                          animation: _controllers[index],
                          builder: (context, child) {
                            final scale = 1 + _controllers[index].value * 0.10;
                            return Transform.scale(
                              scale: scale,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.all(2),
                                transform: isSelected
                                    ? (isHorizontal
                                        ? Matrix4.translationValues(0, -4, 0)
                                        : Matrix4.translationValues(-4, 0, 0))
                                    : Matrix4.identity(),
                                child: Flex(
                                  direction: isHorizontal
                                      ? Axis.vertical
                                      : Axis.vertical,
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isSelected ? item.fillIcon : item.icon,
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[600],
                                      size: isSelected ? 22 : 18,
                                    ),
                                    if (isSelected || !isHorizontal)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 1),
                                        child: SizedBox(
                                          width: isHorizontal ? 48 : 64,
                                          child: Text(
                                            item.label,
                                            style: TextStyle(
                                                fontSize: isHorizontal ? 8 : 9,
                                                color: isSelected
                                                    ? Theme.of(context)
                                                        .primaryColor
                                                    : Colors.grey[700]),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
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
