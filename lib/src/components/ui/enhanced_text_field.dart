import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EnhancedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enableRealTimeValidation;
  final FocusNode? focusNode;
  final bool enabled;

  const EnhancedTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.enableRealTimeValidation = true,
    this.focusNode,
    this.enabled = true,
  });

  @override
  State<EnhancedTextField> createState() => _EnhancedTextFieldState();
}

class _EnhancedTextFieldState extends State<EnhancedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;
  late FocusNode _focusNode;
  
  bool _isFocused = false;
  bool _hasError = false;
  bool _isValid = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _setupAnimations();
    _setupListeners();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _borderColorAnimation = ColorTween(
      begin: const Color(0xFFE5E7EB),
      end: const Color(0xFF3B82F6),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupListeners() {
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      
      if (_isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });

    widget.controller.addListener(() {
      if (widget.enableRealTimeValidation && widget.validator != null) {
        _validateField();
      }
    });
  }

  void _validateField() {
    final error = widget.validator?.call(widget.controller.text);
    setState(() {
      _hasError = error != null;
      _isValid = error == null && widget.controller.text.isNotEmpty;
      _errorMessage = error;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  Color _getBorderColor() {
    if (_hasError) return const Color(0xFFEF4444);
    if (_isValid) return const Color(0xFF10B981);
    if (_isFocused) return const Color(0xFF3B82F6);
    return const Color(0xFFE5E7EB);
  }

  Color _getIconColor() {
    if (_hasError) return const Color(0xFFEF4444);
    if (_isValid) return const Color(0xFF10B981);
    if (_isFocused) return const Color(0xFF3B82F6);
    return const Color(0xFF9CA3AF);
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    if (widget.enableRealTimeValidation && widget.controller.text.isNotEmpty) {
      if (_hasError) {
        return Icon(
          PhosphorIcons.xCircle(),
          color: const Color(0xFFEF4444),
          size: 20,
        );
      } else if (_isValid) {
        return Icon(
          PhosphorIcons.checkCircle(),
          color: const Color(0xFF10B981),
          size: 20,
        );
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: _getBorderColor().withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  autofillHints: widget.autofillHints,
                  enabled: widget.enabled,
                  onChanged: widget.onChanged,
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.labelText,
                    hintText: widget.hintText,
                    labelStyle: TextStyle(
                      color: _isFocused ? _getBorderColor() : const Color(0xFF6B7280),
                      fontSize: isDesktop ? 15 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                    hintStyle: TextStyle(
                      color: const Color(0xFF9CA3AF),
                      fontSize: isDesktop ? 15 : 14,
                    ),
                    prefixIcon: widget.prefixIcon != null
                        ? AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              widget.prefixIcon,
                              color: _getIconColor(),
                              size: isDesktop ? 22 : 20,
                            ),
                          )
                        : null,
                    suffixIcon: _buildSuffixIcon(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: isDesktop ? 18 : 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _getBorderColor(),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _getBorderColor(),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _getBorderColor(),
                        width: 2.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF4444),
                        width: 2.5,
                      ),
                    ),
                    filled: true,
                    fillColor: _isFocused
                        ? Colors.white
                        : const Color(0xFFF9FAFB),
                    errorText: null, // Removemos o erro padrão para usar nosso próprio
                  ),
                  validator: widget.validator,
                ),
              ),
              if (_hasError && _errorMessage != null) ...[
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.warning(),
                        size: 14,
                        color: const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}