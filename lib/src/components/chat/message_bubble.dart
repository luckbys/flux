import 'package:flutter/material.dart';
import '../../styles/app_theme.dart';
import '../../styles/app_constants.dart';
import '../../models/message.dart';
import '../ui/user_avatar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../utils/color_extensions.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: isMe ? AppTheme.spacing48 : AppTheme.spacing8,
        right: isMe ? AppTheme.spacing8 : AppTheme.spacing48,
        bottom: AppTheme.spacing8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            UserAvatar(
              user: message.sender,
              size: 32,
              showOnlineStatus: false,
            ),
            const SizedBox(width: AppTheme.spacing8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isMe 
                        ? [AppTheme.primaryColor, AppTheme.primaryColor.darken(10)]
                        : [Colors.white, Colors.grey[50]!],
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe) ...[
                        Text(
                          message.sender.name,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                      ],
                      _buildMessageContent(context),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textColor.withValues(alpha:  0.7),
                          ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: AppTheme.spacing4),
                      Icon(
                        message.status == MessageStatus.read
                            ? PhosphorIcons.checks()
                            : PhosphorIcons.check(),
                        size: 16,
                        color: message.status == MessageStatus.read
                            ? AppTheme.primaryColor
                            : AppTheme.textColor.withValues(alpha:  0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: AppTheme.spacing8),
            UserAvatar(
              user: message.sender,
              size: 32,
              showOnlineStatus: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isMe ? Colors.white : AppTheme.getTextColor(context),
              ),
        );
      case MessageType.system:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.info(),
              size: 16,
              color: AppTheme.warningColor,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.warningColor,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ],
        );
      case MessageType.aiSuggestion:
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha:  0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            border: Border.all(
              color: AppTheme.successColor.withValues(alpha:  0.3),
            ),
          ),
          padding: const EdgeInsets.all(AppTheme.spacing8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    PhosphorIcons.sparkle(),
                    size: 16,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                  Text(
                    'Sugestão da IA',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textColor,
                    ),
              ),
            ],
          ),
        );
      default:
        return Text(
          message.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isMe ? Colors.white : AppTheme.textColor,
              ),
        );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Agora';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}min';
    } else if (diff.inDays < 1) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
