import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../styles/app_theme.dart';
import '../../../styles/app_constants.dart';
import '../../../utils/color_extensions.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final VoidCallback? onSend;
  final VoidCallback? onAttachment;
  final VoidCallback? onVoice;
  final Function(String)? onChanged;
  final Function(String)? onTyping;
  final bool isEnabled;
  final bool showAttachment;
  final bool showVoice;
  final int maxLines;

  const ChatInput({
    super.key,
    this.controller,
    this.placeholder = 'Digite sua mensagem...',
    this.onSend,
    this.onAttachment,
    this.onVoice,
    this.onChanged,
    this.onTyping,
    this.isEnabled = true,
    this.showAttachment = true,
    this.showVoice = true,
    this.maxLines = 5,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged?.call(_controller.text);
    widget.onTyping?.call(_controller.text);
  }

  void _handleSend() {
    if (_hasText && widget.isEnabled) {
      widget.onSend?.call();
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppTheme.textColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (widget.showAttachment)
              _buildActionButton(
                icon: PhosphorIcons.paperclip(),
                onTap: widget.onAttachment,
              ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: widget.maxLines * 24.0,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                  border: Border.all(
                    color: AppTheme.getBorderColor(context),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.isEnabled,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    hintStyle: TextStyle(
                      color: AppTheme.getTextColor(context).withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing12,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.getTextColor(context),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            if (_hasText)
              _buildSendButton()
            else if (widget.showVoice)
              _buildActionButton(
                icon: PhosphorIcons.microphone(),
                onTap: widget.onVoice,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppConstants.buttonHeight,
        height: AppConstants.buttonHeight,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: AppConstants.iconMedium,
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _handleSend,
      child: Container(
        width: AppConstants.buttonHeight,
        height: AppConstants.buttonHeight,
        decoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill),
          color: Colors.white,
          size: AppConstants.iconMedium,
        ),
      ),
    );
  }
}

class QuickReplyChips extends StatelessWidget {
  final List<String> suggestions;
  final Function(String)? onReplySelected;

  const QuickReplyChips({
    super.key,
    required this.suggestions,
    this.onReplySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      margin: const EdgeInsets.only(
        left: AppTheme.spacing16,
        right: AppTheme.spacing16,
        bottom: AppTheme.spacing8,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppTheme.spacing8),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return GestureDetector(
            onTap: () => onReplySelected?.call(suggestion),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing8,
              ),
              decoration: BoxDecoration(
                color: AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.getTextColor(context).withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                suggestion,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  final List<String> typingUsers;

  const TypingIndicator({
    super.key,
    required this.typingUsers,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Row(
                children: List.generate(3, (index) {
                  final delay = index * 0.3;
                  final opacity = ((_animation.value + delay) % 1.0);
                  return Container(
                    margin: const EdgeInsets.only(right: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          AppTheme.textColor.withValues(alpha: opacity * 0.7),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: AppTheme.spacing8),
          Text(
            _getTypingText(),
            style: TextStyle(
              color: AppTheme.textColor.withValues(alpha: 0.7),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypingText() {
    if (widget.typingUsers.length == 1) {
      return '${widget.typingUsers.first} está digitando...';
    } else if (widget.typingUsers.length == 2) {
      return '${widget.typingUsers.join(' e ')} estão digitando...';
    } else {
      return '${widget.typingUsers.length} pessoas estão digitando...';
    }
  }
}
