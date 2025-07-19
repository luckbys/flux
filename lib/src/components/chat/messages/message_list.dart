import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../models/message.dart';
import '../../../models/user.dart';
import '../../../models/chat.dart';
import 'message_bubble.dart';
import '../inputs/chat_input.dart';
import '../../../styles/app_theme.dart';
import '../../../styles/app_constants.dart';
import '../../../utils/color_extensions.dart';

class MessageList extends StatefulWidget {
  final Chat chat;
  final User currentUser;
  final List<Message> messages;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final Function(Message)? onMessageReply;
  final Function(Message)? onMessageDelete;
  final Function(String)? onSendMessage;
  final List<String> typingUsers;
  final List<String> quickReplies;

  const MessageList({
    Key? key,
    required this.chat,
    required this.currentUser,
    required this.messages,
    this.isLoading = false,
    this.onLoadMore,
    this.onMessageReply,
    this.onMessageDelete,
    this.onSendMessage,
    this.typingUsers = const [],
    this.quickReplies = const [],
  }) : super(key: key);

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  Message? _replyingTo;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _onScroll() {
    final isAtBottom = _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 100;

    if (isAtBottom != !_showScrollToBottom) {
      setState(() {
        _showScrollToBottom = !isAtBottom;
      });
    }

    // Load more messages when reaching the top
    if (_scrollController.offset <= 100 && !widget.isLoading) {
      widget.onLoadMore?.call();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppConstants.normalAnimation,
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSendMessage() {
    final text = _inputController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage?.call(text);
      _inputController.clear();
      _replyingTo = null;
    }
  }

  void _handleReply(Message message) {
    setState(() {
      _replyingTo = message;
    });
    widget.onMessageReply?.call(message);
  }

  void _handleQuickReply(String reply) {
    _inputController.text = reply;
    _handleSendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            _buildChatHeader(),
            Expanded(
              child: Stack(
                children: [
                  _buildMessagesList(),
                  if (widget.isLoading) _buildLoadingIndicator(),
                  if (_showScrollToBottom) _buildScrollToBottomButton(),
                ],
              ),
            ),
            if (_replyingTo != null) _buildReplyPreview(),
            if (widget.quickReplies.isNotEmpty)
              QuickReplyChips(
                suggestions: widget.quickReplies,
                onReplySelected: _handleQuickReply,
              ),
            if (widget.typingUsers.isNotEmpty)
              TypingIndicator(typingUsers: widget.typingUsers),
            _buildChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:  0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              color: AppTheme.textColor,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.getDisplayTitle(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.chat.participants.isNotEmpty)
                    Text(
                      _getParticipantsStatus(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textColor.withValues(alpha:  0.7),
                          ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // TODO: Implementar opções do chat
              },
              icon: const Icon(Icons.more_vert),
              color: AppTheme.textColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (widget.messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];
        final showAvatar = _shouldShowAvatar(index);

        return FadeInUp(
          duration: AppConstants.quickAnimation,
          delay: Duration(milliseconds: index * 50),
          child: MessageBubble(
            message: message,
            currentUser: widget.currentUser,
            showAvatar: showAvatar,
            showTimestamp: true,
            onReply: () => _handleReply(message),
            onDelete: () => widget.onMessageDelete?.call(message),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.textColor.withValues(alpha:  0.3),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'Nenhuma mensagem ainda',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textColor.withValues(alpha:  0.7),
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Inicie a conversa enviando uma mensagem',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textColor.withValues(alpha:  0.5),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildScrollToBottomButton() {
    return Positioned(
      bottom: AppTheme.spacing16,
      right: AppTheme.spacing16,
      child: FloatingActionButton.small(
        onPressed: _scrollToBottom,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(
          Icons.keyboard_arrow_down,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (_replyingTo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppTheme.textColor.withValues(alpha:  0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Respondendo a ${_replyingTo!.sender.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing2),
                Text(
                  _replyingTo!.content,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _replyingTo = null;
              });
            },
            icon: const Icon(Icons.close),
            iconSize: AppConstants.iconSmall,
            color: AppTheme.textColor.withValues(alpha:  0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return ChatInput(
      controller: _inputController,
      onSend: _handleSendMessage,
      onAttachment: () {
        // TODO: Implementar anexos
      },
      onVoice: () {
        // TODO: Implementar gravação de voz
      },
    );
  }

  bool _shouldShowAvatar(int index) {
    if (index == 0) return true;

    final currentMessage = widget.messages[index];
    final previousMessage = widget.messages[index - 1];

    return currentMessage.sender.id != previousMessage.sender.id ||
        currentMessage.createdAt
                .difference(previousMessage.createdAt)
                .inMinutes >
            5;
  }

  String _getParticipantsStatus() {
    final onlineParticipants = widget.chat.participants
        .where((p) => p.status == UserStatus.online)
        .length;

    if (widget.chat.participants.length == 1) {
      final participant = widget.chat.participants.first;
      switch (participant.status) {
        case UserStatus.online:
          return 'Online';
        case UserStatus.away:
          return 'Ausente';
        case UserStatus.busy:
          return 'Ocupado';
        case UserStatus.offline:
          return 'Última vez: ${_formatLastSeen(participant.lastSeen)}';
      }
    }

    return '$onlineParticipants de ${widget.chat.participants.length} online';
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'há muito tempo';

    final difference = DateTime.now().difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'agora mesmo';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays}d atrás';
    }
  }
}
