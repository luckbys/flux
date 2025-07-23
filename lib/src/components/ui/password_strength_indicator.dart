import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showDetails;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final strength = _calculatePasswordStrength(password);
    final strengthData = _getStrengthData(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra de força
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          child: Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 3 ? 2 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: index < strength
                        ? strengthData['color']
                        : Colors.transparent,
                  ),
                ),
              );
            }),
          ),
        ),
        if (showDetails && password.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                strengthData['icon'],
                size: 14,
                color: strengthData['color'],
              ),
              const SizedBox(width: 4),
              Text(
                strengthData['text'],
                style: TextStyle(
                  fontSize: 12,
                  color: strengthData['color'],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildRequirements(),
        ],
      ],
    );
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int score = 0;
    
    // Comprimento
    if (password.length >= 8) score++;
    
    // Letras minúsculas
    if (password.contains(RegExp(r'[a-z]'))) score++;
    
    // Letras maiúsculas
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    
    // Números ou símbolos
    if (password.contains(RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]'))) score++;

    return score;
  }

  Map<String, dynamic> _getStrengthData(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return {
          'text': 'Muito fraca',
          'color': Colors.red,
          'icon': PhosphorIcons.x(),
        };
      case 2:
        return {
          'text': 'Fraca',
          'color': Colors.orange,
          'icon': PhosphorIcons.warning(),
        };
      case 3:
        return {
          'text': 'Boa',
          'color': Colors.yellow.shade700,
          'icon': PhosphorIcons.check(),
        };
      case 4:
        return {
          'text': 'Forte',
          'color': Colors.green,
          'icon': PhosphorIcons.checkCircle(),
        };
      default:
        return {
          'text': '',
          'color': Colors.grey,
          'icon': PhosphorIcons.circle(),
        };
    }
  }

  List<Widget> _buildRequirements() {
    final requirements = [
      {
        'text': 'Pelo menos 8 caracteres',
        'met': password.length >= 8,
      },
      {
        'text': 'Letras minúsculas',
        'met': password.contains(RegExp(r'[a-z]')),
      },
      {
        'text': 'Letras maiúsculas',
        'met': password.contains(RegExp(r'[A-Z]')),
      },
      {
        'text': 'Números ou símbolos',
        'met': password.contains(RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]')),
      },
    ];

    return requirements.map((req) {
      final met = req['met'] as bool;
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              met ? PhosphorIcons.check() : PhosphorIcons.circle(),
              size: 12,
              color: met ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              req['text'] as String,
              style: TextStyle(
                fontSize: 11,
                color: met ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class RealTimeValidationField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<String>? autofillHints;
  final String? Function(String?)? validator;
  final VoidCallback? onToggleObscure;
  final bool showPasswordStrength;
  final Function(String)? onChanged;

  const RealTimeValidationField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.autofillHints,
    this.validator,
    this.onToggleObscure,
    this.showPasswordStrength = false,
    this.onChanged,
  });

  @override
  State<RealTimeValidationField> createState() => _RealTimeValidationFieldState();
}

class _RealTimeValidationFieldState extends State<RealTimeValidationField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _hasError = false;
  bool _isValid = false;
  String _currentValue = '';

  @override
  void initState() {
    super.initState();
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

    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final value = widget.controller.text;
    setState(() {
      _currentValue = value;
      if (widget.validator != null) {
        final error = widget.validator!(value);
        _hasError = error != null;
        _isValid = error == null && value.isNotEmpty;
      }
    });

    if (widget.onChanged != null) {
      widget.onChanged!(value);
    }

    // Animação de feedback
    if (_isValid) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: TextFormField(
                controller: widget.controller,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                autofillHints: widget.autofillHints,
                validator: widget.validator,
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText,
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(widget.prefixIcon)
                      : null,
                  suffixIcon: _buildSuffixIcon(),
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
                      color: _getFocusedBorderColor(),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.showPasswordStrength && _currentValue.isNotEmpty) ...[
          const SizedBox(height: 8),
          PasswordStrengthIndicator(
            password: _currentValue,
            showDetails: true,
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText && widget.onToggleObscure != null) {
      return IconButton(
        icon: Icon(
          widget.obscureText
              ? PhosphorIcons.eyeSlash()
              : PhosphorIcons.eye(),
        ),
        onPressed: widget.onToggleObscure,
      );
    }

    if (_currentValue.isNotEmpty) {
      if (_isValid) {
        return Icon(
          PhosphorIcons.checkCircle(),
          color: Colors.green,
        );
      } else if (_hasError) {
        return Icon(
          PhosphorIcons.xCircle(),
          color: Colors.red,
        );
      }
    }

    return null;
  }

  Color _getBorderColor() {
    if (_currentValue.isEmpty) {
      return Colors.grey.withValues(alpha: 0.3);
    }
    if (_isValid) {
      return Colors.green.withValues(alpha: 0.5);
    }
    if (_hasError) {
      return Colors.red.withValues(alpha: 0.5);
    }
    return Colors.grey.withValues(alpha: 0.3);
  }

  Color _getFocusedBorderColor() {
    if (_isValid) {
      return Colors.green;
    }
    if (_hasError) {
      return Colors.red;
    }
    return Theme.of(context).primaryColor;
  }
}