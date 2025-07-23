import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/message.dart';
import '../../../models/user.dart';
import '../../ui/user_avatar.dart';
import '../../ui/status_badge.dart';
import '../../../styles/app_theme.dart';
import '../../../styles/app_constants.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final User currentUser;
  final bool showAvatar;
  final bool showTimestamp;
  final VoidCallback? onTap;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUser,
    this.showAvatar = true,
    this.showTimestamp = true,
    this.onTap,
    this.onReply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isFromCurrentUser = message.sender.id == currentUser.id;
    final isSystemMessage = message.isSystemMessage;
    final isAiSuggestion = message.isAiSuggestion;

    if (isSystemMessage) {
      return _buildSystemMessage();
    }

    if (isAiSuggestion) {
      return _buildAiSuggestion();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromCurrentUser && showAvatar)
            UserAvatar(
              user: message.sender,
              size: AppConstants.iconLarge,
              margin: const EdgeInsets.only(right: AppTheme.spacing8),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: isFromCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isFromCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppTheme.spacing12,
                      bottom: AppTheme.spacing4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          message.sender.name,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color:
                                    AppTheme.textColor.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(width: AppTheme.spacing4),
                        UserStatusBadge(
                          status: message.sender.status,
                          showText: false,
                        ),
                      ],
                    ),
                  ),
                GestureDetector(
                  onTap: onTap,
                  onLongPress: () => _showMessageOptions(context),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing12,
                    ),
                    decoration: BoxDecoration(
                      color: isFromCurrentUser
                          ? AppTheme.primaryColor
                          : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft:
                            const Radius.circular(AppConstants.radiusLarge),
                        topRight:
                            const Radius.circular(AppConstants.radiusLarge),
                        bottomLeft: Radius.circular(
                          isFromCurrentUser
                              ? AppConstants.radiusLarge
                              : AppConstants.radiusSmall,
                        ),
                        bottomRight: Radius.circular(
                          isFromCurrentUser
                              ? AppConstants.radiusSmall
                              : AppConstants.radiusLarge,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.replyTo != null)
                          _buildReplyPreview(message.replyTo!),
                        _buildMessageContent(),
                        if (message.hasAttachments) _buildAttachments(),
                        if (showTimestamp)
                          _buildMessageFooter(isFromCurrentUser),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isFromCurrentUser && showAvatar)
            UserAvatar(
              user: message.sender,
              size: AppConstants.iconLarge,
              margin: const EdgeInsets.only(left: AppTheme.spacing8),
            ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
            vertical: AppTheme.spacing8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.textColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildAiSuggestion() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
            ],
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: AppConstants.iconSmall,
                ),
                SizedBox(width: AppTheme.spacing8),
                Text(
                  'Sugestão da IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              message.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    return Text(
      message.content,
      style: TextStyle(
        color: message.sender.id == currentUser.id
            ? Colors.white
            : AppTheme.textColor,
        fontSize: 14,
      ),
    );
  }

  Widget _buildReplyPreview(Message replyMessage) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.all(AppTheme.spacing8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: const Border(
          left: BorderSide(
            color: AppTheme.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyMessage.sender.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppTheme.spacing2),
          Text(
            replyMessage.content,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments() {
    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacing8),
      child: Wrap(
        spacing: AppTheme.spacing8,
        runSpacing: AppTheme.spacing8,
        children: message.attachments.map((attachment) {
          if (attachment.type.startsWith('image/')) {
            return _buildImageAttachment(attachment);
          }
          return _buildFileAttachment(attachment);
        }).toList(),
      ),
    );
  }

  Widget _buildImageAttachment(MessageAttachment attachment) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      child: CachedNetworkImage(
        imageUrl: attachment.url,
        width: 200,
        height: 150,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 200,
          height: 150,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 200,
          height: 150,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildFileAttachment(MessageAttachment attachment) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(attachment.type),
            size: AppConstants.iconMedium,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attachment.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              Text(
                _formatFileSize(attachment.size),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageFooter(bool isFromCurrentUser) {
    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacing4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('HH:mm').format(message.createdAt),
            style: TextStyle(
              color: isFromCurrentUser
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppTheme.textColor.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          if (isFromCurrentUser) ...[
            const SizedBox(width: AppTheme.spacing4),
            Icon(
              _getStatusIcon(),
              size: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ],
          if (message.isEdited) ...[
            const SizedBox(width: AppTheme.spacing4),
            Text(
              'editado',
              style: TextStyle(
                color: isFromCurrentUser
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textColor.withValues(alpha: 0.5),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
    }
  }

  IconData _getFileIcon(String type) {
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('word')) return Icons.description;
    if (type.contains('excel')) return Icons.table_chart;
    if (type.contains('audio')) return Icons.audiotrack;
    if (type.contains('video')) return Icons.videocam;
    return Icons.attach_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppConstants.radiusLarge),
            topRight: Radius.circular(AppConstants.radiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Responder'),
                onTap: () {
                  Navigator.pop(context);
                  onReply!();
                },
              ),
            if (message.sender.id == currentUser.id && onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                title: const Text('Excluir'),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }
}
