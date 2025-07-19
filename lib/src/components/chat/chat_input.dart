import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../styles/app_theme.dart';
import '../../styles/app_constants.dart';
import '../../models/message.dart';
import '../../utils/color_extensions.dart';

class ChatInput extends StatefulWidget {
  final Function(String, MessageType) onSendMessage;
  final Function(String)? onTyping;
  final Function()? onStopTyping;
  final Function()? onStartVoiceRecording;
  final Function()? onStopVoiceRecording;
  final Function()? onAttachmentTap;
  final bool isTyping;
  final bool isRecording;
  final bool enabled;
  final String? placeholder;
  final List<String> quickReplies;
  final List<String> aiSuggestions;
  final Function(String)? onUseSuggestion;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.onTyping,
    this.onStopTyping,
    this.onStartVoiceRecording,
    this.onStopVoiceRecording,
    this.onAttachmentTap,
    this.isTyping = false,
    this.isRecording = false,
    this.enabled = true,
    this.placeholder = 'Digite sua mensagem...',
    this.quickReplies = const [],
    this.aiSuggestions = const [],
    this.onUseSuggestion,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
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

    if (widget.onTyping != null) {
      widget.onTyping!(_controller.text);
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSendMessage(_controller.text.trim(), MessageType.text);
      _controller.clear();
      setState(() {
        _hasText = false;
      });
    }
  }

  void _sendQuickReply(String reply) {
    widget.onSendMessage(reply, MessageType.text);
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  void _onEmojiSelected(Emoji emoji) {
    final text = _controller.text;
    final selection = _controller.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji.emoji,
    );
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: selection.start + emoji.emoji.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isDesktop ? null : Border(
          top: BorderSide(
            color: AppTheme.textColor.withValues(alpha:  0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Quick replies
          if (widget.quickReplies.isNotEmpty) ...[
            _buildQuickReplies(),
            const SizedBox(height: AppTheme.spacing12),
          ],

          // Typing indicator
          if (widget.isTyping) ...[
            _buildTypingIndicator(),
            const SizedBox(height: AppTheme.spacing8),
          ],

          // Input row
          Row(
            children: [
              // Attachment button
              IconButton(
                onPressed: widget.enabled ? widget.onAttachmentTap : null,
                icon: Icon(
                  PhosphorIcons.paperclip(),
                  color: widget.enabled
                      ? AppTheme.primaryColor
                      : AppTheme.textColor.withValues(alpha:  0.5),
                  size: isDesktop ? 24 : 20,
                ),
                padding: EdgeInsets.all(isDesktop ? 12 : AppTheme.spacing8),
                constraints: BoxConstraints(
                  minWidth: isDesktop ? 48 : AppConstants.buttonHeight,
                  minHeight: isDesktop ? 48 : AppConstants.buttonHeight,
                ),
              ),

              // Emoji button
              IconButton(
                onPressed: widget.enabled ? _toggleEmojiPicker : null,
                icon: Icon(
                  _showEmojiPicker ? PhosphorIcons.keyboard() : PhosphorIcons.smiley(),
                  color: widget.enabled
                      ? (_showEmojiPicker ? AppTheme.primaryColor : AppTheme.textColor.withValues(alpha: 0.7))
                      : AppTheme.textColor.withValues(alpha: 0.5),
                  size: isDesktop ? 24 : 20,
                ),
                padding: EdgeInsets.all(isDesktop ? 12 : AppTheme.spacing8),
                constraints: BoxConstraints(
                  minWidth: isDesktop ? 48 : AppConstants.buttonHeight,
                  minHeight: isDesktop ? 48 : AppConstants.buttonHeight,
                ),
              ),

              // Text input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius:
                        BorderRadius.circular(isDesktop ? 12 : AppConstants.radiusLarge),
                    border: Border.all(
                      color: AppTheme.textColor.withValues(alpha:  0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    maxLines: isDesktop ? 4 : null,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : 14,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 20 : AppTheme.spacing16,
                        vertical: isDesktop ? 16 : AppTheme.spacing12,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: isDesktop ? 12 : AppTheme.spacing8),

              // Send/Voice button
              if (widget.isRecording)
                _buildRecordingButton()
              else if (_hasText)
                _buildSendButton()
              else
                _buildVoiceButton(),
            ],
          ),

          // Emoji picker
          if (_showEmojiPicker)
            Container(
              height: 250,
              child: EmojiPicker(
                 onEmojiSelected: (category, emoji) {
                   _onEmojiSelected(emoji);
                 },
                 config: Config(
                    height: 250,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      emojiSizeMax: isDesktop ? 32 : 28,
                      backgroundColor: AppTheme.backgroundColor,
                      recentsLimit: 28,
                    ),
                    skinToneConfig: const SkinToneConfig(),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: AppTheme.backgroundColor,
                      iconColorSelected: AppTheme.primaryColor,
                      categoryIcons: const CategoryIcons(),
                    ),
                    bottomActionBarConfig: BottomActionBarConfig(
                      backgroundColor: AppTheme.backgroundColor,
                    ),
                    searchViewConfig: SearchViewConfig(
                      backgroundColor: AppTheme.backgroundColor,
                    ),
                  ),
               ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.quickReplies.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppTheme.spacing8),
        itemBuilder: (context, index) {
          final reply = widget.quickReplies[index];
          return Material(
            color: AppTheme.primaryColor.withValues(alpha:  0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            child: InkWell(
              onTap: () => _sendQuickReply(reply),
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.lightning(),
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: AppTheme.spacing4),
                    Text(
                      reply,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha:  0.05),
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Text(
            'Digitando...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final buttonSize = isDesktop ? 48.0 : AppConstants.buttonHeight;
    final iconSize = isDesktop ? 24.0 : AppConstants.iconMedium;
    
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(isDesktop ? 12 : AppConstants.radiusLarge),
        boxShadow: isDesktop ? [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isDesktop ? 12 : AppConstants.radiusLarge),
        child: InkWell(
          onTap: _sendMessage,
          borderRadius: BorderRadius.circular(isDesktop ? 12 : AppConstants.radiusLarge),
          child: Icon(
            PhosphorIcons.paperPlaneTilt(),
            color: Colors.white,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceButton() {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final buttonSize = isDesktop ? 48.0 : AppConstants.buttonHeight;
    final iconSize = isDesktop ? 24.0 : AppConstants.iconMedium;
    
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha:  0.1),
        borderRadius: BorderRadius.circular(isDesktop ? 12 : AppConstants.radiusLarge),
        border: isDesktop ? Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isDesktop ? 12 : AppConstants.radiusLarge),
        child: InkWell(
          onTap: widget.onStartVoiceRecording,
          borderRadius: BorderRadius.circular(isDesktop ? 12 : AppConstants.radiusLarge),
          child: Icon(
            PhosphorIcons.microphone(),
            color: AppTheme.primaryColor,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingButton() {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final buttonSize = isDesktop ? 48.0 : AppConstants.buttonHeight;
    final iconSize = isDesktop ? 24.0 : AppConstants.iconMedium;
    
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: AppTheme.errorColor,
        borderRadius: BorderRadius.circular(isDesktop ? 12 : AppConstants.radiusLarge),
        boxShadow: isDesktop ? [
          BoxShadow(
            color: AppTheme.errorColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isDesktop ? 12 : AppConstants.radiusLarge),
        child: InkWell(
          onTap: widget.onStopVoiceRecording,
          borderRadius: BorderRadius.circular(isDesktop ? 12 : AppConstants.radiusLarge),
          child: Icon(
              PhosphorIcons.stop(),
              color: Colors.white,
              size: iconSize,
            ),
        ),
      ),
    );
  }
}
