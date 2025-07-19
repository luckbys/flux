import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_tokens.dart';
import 'micro_animations.dart';

/// Componentes acessíveis que seguem as diretrizes WCAG 2.1 AA
/// Inclui suporte para leitores de tela, navegação por teclado e alto contraste
class AccessibleComponents {
  // ==================== BOTÕES ACESSÍVEIS ====================
  
  /// Botão primário com acessibilidade completa
  static Widget primaryButton({
    required String text,
    required VoidCallback? onPressed,
    String? semanticLabel,
    String? tooltip,
    IconData? icon,
    bool isLoading = false,
    bool autofocus = false,
    FocusNode? focusNode,
  }) {
    return _AccessibleButton(
      text: text,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      icon: icon,
      isLoading: isLoading,
      autofocus: autofocus,
      focusNode: focusNode,
      buttonType: _ButtonType.primary,
    );
  }
  
  /// Botão secundário com acessibilidade completa
  static Widget secondaryButton({
    required String text,
    required VoidCallback? onPressed,
    String? semanticLabel,
    String? tooltip,
    IconData? icon,
    bool isLoading = false,
    bool autofocus = false,
    FocusNode? focusNode,
  }) {
    return _AccessibleButton(
      text: text,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      icon: icon,
      isLoading: isLoading,
      autofocus: autofocus,
      focusNode: focusNode,
      buttonType: _ButtonType.secondary,
    );
  }
  
  /// Botão de texto com acessibilidade completa
  static Widget textButton({
    required String text,
    required VoidCallback? onPressed,
    String? semanticLabel,
    String? tooltip,
    IconData? icon,
    bool isLoading = false,
    bool autofocus = false,
    FocusNode? focusNode,
  }) {
    return _AccessibleButton(
      text: text,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      icon: icon,
      isLoading: isLoading,
      autofocus: autofocus,
      focusNode: focusNode,
      buttonType: _ButtonType.text,
    );
  }
  
  // ==================== CAMPOS DE INPUT ACESSÍVEIS ====================
  
  /// Campo de texto com acessibilidade completa
  static Widget textField({
    required String label,
    String? hint,
    String? helperText,
    String? errorText,
    TextEditingController? controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool required = false,
    int? maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
    bool autofocus = false,
    FocusNode? focusNode,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return _AccessibleTextField(
      label: label,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      required: required,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onTap: onTap,
      autofocus: autofocus,
      focusNode: focusNode,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }
  
  // ==================== COMPONENTES DE SELEÇÃO ACESSÍVEIS ====================
  
  /// Checkbox com acessibilidade completa
  static Widget checkbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    String? semanticLabel,
    bool autofocus = false,
    FocusNode? focusNode,
  }) {
    return _AccessibleCheckbox(
      label: label,
      value: value,
      onChanged: onChanged,
      semanticLabel: semanticLabel,
      autofocus: autofocus,
      focusNode: focusNode,
    );
  }
  
  /// Radio button com acessibilidade completa
  static Widget radio<T>({
    required String label,
    required T value,
    required T? groupValue,
    required ValueChanged<T?> onChanged,
    String? semanticLabel,
    bool autofocus = false,
    FocusNode? focusNode,
  }) {
    return _AccessibleRadio<T>(
      label: label,
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      semanticLabel: semanticLabel,
      autofocus: autofocus,
      focusNode: focusNode,
    );
  }
  
  /// Switch com acessibilidade completa
  static Widget switch_({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? semanticLabel,
    bool autofocus = false,
    FocusNode? focusNode,
  }) {
    return _AccessibleSwitch(
      label: label,
      value: value,
      onChanged: onChanged,
      semanticLabel: semanticLabel,
      autofocus: autofocus,
      focusNode: focusNode,
    );
  }
  
  // ==================== COMPONENTES DE NAVEGAÇÃO ACESSÍVEIS ====================
  
  /// Card clicável com acessibilidade completa
  static Widget card({
    required Widget child,
    VoidCallback? onTap,
    String? semanticLabel,
    String? tooltip,
    bool autofocus = false,
    FocusNode? focusNode,
  }) {
    return _AccessibleCard(
      onTap: onTap,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      autofocus: autofocus,
      focusNode: focusNode,
      child: child,
    );
  }
  
  /// Lista com acessibilidade completa
  static Widget listTile({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    String? semanticLabel,
    bool autofocus = false,
    FocusNode? focusNode,
  }) {
    return _AccessibleListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      semanticLabel: semanticLabel,
      autofocus: autofocus,
      focusNode: focusNode,
    );
  }
  
  // ==================== COMPONENTES DE FEEDBACK ACESSÍVEIS ====================
  
  /// Snackbar com acessibilidade completa
  static SnackBar snackBar({
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    return SnackBar(
      content: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: const TextStyle(
            fontSize: DesignTokens.fontSize14,
            fontWeight: DesignTokens.fontWeightRegular,
          ),
        ),
      ),
      duration: duration,
      action: action ?? (actionLabel != null && onActionPressed != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onActionPressed,
            )
          : null),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(DesignTokens.space16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
    );
  }
  
  /// Dialog com acessibilidade completa
  static Widget dialog({
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return _AccessibleDialog(
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      barrierDismissible: barrierDismissible,
    );
  }
  
  // ==================== UTILITÁRIOS DE ACESSIBILIDADE ====================
  
  /// Wrapper para anunciar mudanças para leitores de tela
  static Widget liveRegion({
    required Widget child,
    bool assertive = false,
  }) {
    return Semantics(
      liveRegion: true,
      child: child,
    );
  }
  
  /// Wrapper para excluir do leitor de tela
  static Widget excludeSemantics({
    required Widget child,
  }) {
    return ExcludeSemantics(
      child: child,
    );
  }
  
  /// Wrapper para adicionar semântica customizada
  static Widget customSemantics({
    required Widget child,
    String? label,
    String? hint,
    String? value,
    bool? button,
    bool? header,
    bool? textField,
    bool? readOnly,
    bool? focusable,
    bool? focused,
    bool? selected,
    bool? checked,
    bool? expanded,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onScrollLeft,
    VoidCallback? onScrollRight,
    VoidCallback? onScrollUp,
    VoidCallback? onScrollDown,
    VoidCallback? onIncrease,
    VoidCallback? onDecrease,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: button,
      header: header,
      textField: textField,
      readOnly: readOnly,
      focusable: focusable,
      focused: focused,
      selected: selected,
      checked: checked,
      expanded: expanded,
      onTap: onTap,
      onLongPress: onLongPress,
      onScrollLeft: onScrollLeft,
      onScrollRight: onScrollRight,
      onScrollUp: onScrollUp,
      onScrollDown: onScrollDown,
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      child: child,
    );
  }
}

// ==================== ENUMS ====================

enum _ButtonType { primary, secondary, text }

// ==================== WIDGETS INTERNOS ====================

class _AccessibleButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? tooltip;
  final IconData? icon;
  final bool isLoading;
  final bool autofocus;
  final FocusNode? focusNode;
  final _ButtonType buttonType;
  
  const _AccessibleButton({
    required this.text,
    required this.onPressed,
    this.semanticLabel,
    this.tooltip,
    this.icon,
    required this.isLoading,
    required this.autofocus,
    this.focusNode,
    required this.buttonType,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget button;
    
    final buttonChild = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: DesignTokens.space8),
              ],
              Text(text),
            ],
          );
    
    switch (buttonType) {
      case _ButtonType.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          autofocus: autofocus,
          focusNode: focusNode,
          child: buttonChild,
        );
        break;
      case _ButtonType.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          autofocus: autofocus,
          focusNode: focusNode,
          child: buttonChild,
        );
        break;
      case _ButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          autofocus: autofocus,
          focusNode: focusNode,
          child: buttonChild,
        );
        break;
    }
    
    // Wrapper com semântica e tooltip
    Widget wrappedButton = Semantics(
      label: semanticLabel ?? text,
      hint: isLoading ? 'Carregando' : null,
      button: true,
      enabled: onPressed != null && !isLoading,
      child: button,
    );
    
    if (tooltip != null) {
      wrappedButton = Tooltip(
        message: tooltip!,
        child: wrappedButton,
      );
    }
    
    return MicroAnimations.animatedButton(
      onPressed: isLoading ? null : onPressed,
      child: wrappedButton,
    );
  }
}

class _AccessibleTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool required;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool autofocus;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  
  const _AccessibleTextField({
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType,
    required this.obscureText,
    required this.required,
    this.maxLines,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    required this.autofocus,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
  });
  
  @override
  Widget build(BuildContext context) {
    final effectiveLabel = required ? '$label *' : label;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label com indicação de obrigatório
        Semantics(
          label: effectiveLabel,
          child: Text(
            effectiveLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.space8),
        
        // Campo de texto
        Semantics(
          textField: true,
          label: effectiveLabel,
          hint: hint,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            onTap: onTap,
            autofocus: autofocus,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: hint,
              helperText: helperText,
              errorText: errorText,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              // Remove o label do decoration pois já temos acima
              labelText: null,
            ),
            validator: required
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Este campo é obrigatório';
                    }
                    return null;
                  }
                : null,
          ),
        ),
        
        // Texto de ajuda ou erro
        if (helperText != null || errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.space4),
            child: Semantics(
              liveRegion: errorText != null,
              child: Text(
                errorText ?? helperText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: errorText != null
                      ? DesignTokens.error500
                      : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AccessibleCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? semanticLabel;
  final bool autofocus;
  final FocusNode? focusNode;
  
  const _AccessibleCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    required this.autofocus,
    this.focusNode,
  });
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      checked: value,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(
                autofocus: autofocus,
                focusNode: focusNode,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessibleRadio<T> extends StatelessWidget {
  final String label;
  final T value;
  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final String? semanticLabel;
  final bool autofocus;
  final FocusNode? focusNode;
  
  const _AccessibleRadio({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.semanticLabel,
    required this.autofocus,
    this.focusNode,
  });
  
  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    
    return Semantics(
      label: semanticLabel ?? label,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(
                autofocus: autofocus,
                focusNode: focusNode,
                child: Radio<T>(
                  value: value,
                  groupValue: groupValue,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: DesignTokens.space8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessibleSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;
  final bool autofocus;
  final FocusNode? focusNode;
  
  const _AccessibleSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    required this.autofocus,
    this.focusNode,
  });
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      toggled: value,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Focus(
                autofocus: autofocus,
                focusNode: focusNode,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? tooltip;
  final bool autofocus;
  final FocusNode? focusNode;
  
  const _AccessibleCard({
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.tooltip,
    required this.autofocus,
    this.focusNode,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
        child: Focus(
          autofocus: autofocus,
          focusNode: focusNode,
          child: child,
        ),
      ),
    );
    
    if (onTap != null) {
      card = Semantics(
        label: semanticLabel,
        button: true,
        child: card,
      );
    }
    
    if (tooltip != null) {
      card = Tooltip(
        message: tooltip!,
        child: card,
      );
    }
    
    return MicroAnimations.animatedCard(
      onTap: onTap,
      child: card,
    );
  }
}

class _AccessibleListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool autofocus;
  final FocusNode? focusNode;
  
  const _AccessibleListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    required this.autofocus,
    this.focusNode,
  });
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? title,
      hint: subtitle,
      button: onTap != null,
      child: Focus(
        autofocus: autofocus,
        focusNode: focusNode,
        child: ListTile(
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          leading: leading,
          trailing: trailing,
          onTap: onTap,
          minVerticalPadding: DesignTokens.space12,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space8,
          ),
        ),
      ),
    );
  }
}

class _AccessibleDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool barrierDismissible;
  
  const _AccessibleDialog({
    required this.title,
    required this.content,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    required this.barrierDismissible,
  });
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: AlertDialog(
        title: Semantics(
          header: true,
          child: Text(title),
        ),
        content: Semantics(
          readOnly: true,
          child: Text(content),
        ),
        actions: [
          if (cancelText != null)
            AccessibleComponents.textButton(
              text: cancelText!,
              onPressed: onCancel ?? () => Navigator.of(context).pop(false),
            ),
          if (confirmText != null)
            AccessibleComponents.primaryButton(
              text: confirmText!,
              onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
              autofocus: true,
            ),
        ],
      ),
    );
  }
}