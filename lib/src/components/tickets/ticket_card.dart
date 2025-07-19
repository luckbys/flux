import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/ticket.dart';
import '../../styles/app_theme.dart';
import '../../styles/app_constants.dart';
import '../../utils/color_extensions.dart';
import '../ui/user_avatar.dart';
import '../ui/status_badge.dart';
import '../ui/glass_container.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onAssign;
  final VoidCallback? onChat;
  final bool isCompact;

  const TicketCard({
    super.key,
    required this.ticket,
    this.onTap,
    this.onEdit,
    this.onAssign,
    this.onChat,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing8,
        ),
        decoration: AppTheme.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppTheme.spacing12),
              _buildTitle(context),
              if (!isCompact) ...[
                const SizedBox(height: AppTheme.spacing8),
                _buildDescription(context),
              ],
              const SizedBox(height: AppTheme.spacing12),
              _buildMetadata(context),
              if (!isCompact) ...[
                const SizedBox(height: AppTheme.spacing16),
                _buildActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing8,
            vertical: AppTheme.spacing4,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          ),
          child: Text(
            '#${ticket.id.substring(0, 8)}',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacing8),
        TicketStatusBadge(status: ticket.status),
        const SizedBox(width: AppTheme.spacing8),
        TicketPriorityBadge(priority: ticket.priority),
        const Spacer(),
        Text(
          _formatDate(ticket.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      ticket.title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
      maxLines: isCompact ? 1 : 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      ticket.description,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textColor.withValues(alpha: 0.8),
          ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              PhosphorIcons.user(),
              size: AppConstants.iconSmall,
              color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
            ),
            const SizedBox(width: AppTheme.spacing4),
            Text(
              'Cliente: ${ticket.customer.name}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        AppTheme.getTextColor(context).withValues(alpha: 0.7),
                  ),
            ),
            const Spacer(),
            if (ticket.assignedAgent != null) ...[
              Icon(
                PhosphorIcons.userGear(),
                size: AppConstants.iconSmall,
                color: AppTheme.textColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: AppTheme.spacing4),
              Text(
                ticket.assignedAgent!.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textColor.withValues(alpha: 0.7),
                    ),
              ),
            ] else ...[
              StatusBadge(
                text: 'Não Atribuído',
                color: Colors.orange,
                isOutlined: true,
              ),
            ],
          ],
        ),
        if (!isCompact) ...[
          const SizedBox(height: AppTheme.spacing8),
          Row(
            children: [
              Icon(
                PhosphorIcons.tag(),
                size: AppConstants.iconSmall,
                color: AppTheme.textColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: AppTheme.spacing4),
              Text(
                _getCategoryText(ticket.category),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textColor.withValues(alpha: 0.7),
                    ),
              ),
              const Spacer(),
              if (ticket.hasChat)
                Icon(
                  PhosphorIcons.chatCircle(),
                  size: AppConstants.iconSmall,
                  color: AppTheme.primaryColor,
                ),
              if (ticket.messages.isNotEmpty) ...[
                const SizedBox(width: AppTheme.spacing4),
                Text(
                  '${ticket.messages.length} mensagens',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextColor(context)
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ],
          ),
        ],
        if (ticket.tags.isNotEmpty && !isCompact) ...[
          const SizedBox(height: AppTheme.spacing8),
          Wrap(
            spacing: AppTheme.spacing4,
            children: ticket.tags.take(3).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing2,
                ),
                decoration: BoxDecoration(
                  color: Color(int.parse(tag.color, radix: 16) | 0xFF000000)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  border: Border.all(
                    color: Color(int.parse(tag.color, radix: 16) | 0xFF000000),
                    width: 1,
                  ),
                ),
                child: Text(
                  tag.name,
                  style: TextStyle(
                    color: Color(int.parse(tag.color, radix: 16) | 0xFF000000),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        if (ticket.hasChat)
          _buildActionButton(
            icon: PhosphorIcons.chatCircle(),
            label: 'Chat',
            onTap: onChat,
            color: AppTheme.primaryColor,
          ),
        const SizedBox(width: AppTheme.spacing8),
        _buildActionButton(
          icon: PhosphorIcons.userPlus(),
          label: 'Atribuir',
          onTap: onAssign,
          color: AppTheme.secondaryColor,
        ),
        const Spacer(),
        _buildActionButton(
          icon: PhosphorIcons.pencilSimple(),
          label: 'Editar',
          onTap: onEdit,
          color: AppTheme.textColor.withValues(alpha: 0.7),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppConstants.iconSmall,
              color: color,
            ),
            const SizedBox(width: AppTheme.spacing4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes}m atrás';
      }
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  String _getCategoryText(TicketCategory category) {
    switch (category) {
      case TicketCategory.technical:
        return 'Técnico';
      case TicketCategory.billing:
        return 'Financeiro';
      case TicketCategory.general:
        return 'Geral';
      case TicketCategory.complaint:
        return 'Reclamação';
      case TicketCategory.feature:
        return 'Feature';
    }
  }
}

class TicketCompactCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;

  const TicketCompactCard({
    Key? key,
    required this.ticket,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing4,
      ),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _getPriorityColor(ticket.priority),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${ticket.id.substring(0, 8)}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    TicketStatusBadge(
                      status: ticket.status,
                      isOutlined: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  ticket.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacing2),
                Text(
                  ticket.customer.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextColor(context)
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          if (ticket.assignedAgent != null)
            UserAvatar(
              user: ticket.assignedAgent!,
              size: AppConstants.iconLarge,
              showOnlineStatus: false,
            )
          else
            Container(
              width: AppConstants.iconLarge,
              height: AppConstants.iconLarge,
              decoration: BoxDecoration(
                color: AppTheme.getTextColor(context).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.userPlus(),
                size: AppConstants.iconSmall,
                color: AppTheme.getTextColor(context).withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return AppTheme.successColor;
      case TicketPriority.normal:
        return const Color(0xFF6B7280);
      case TicketPriority.high:
        return AppTheme.warningColor;
      case TicketPriority.urgent:
        return AppTheme.errorColor;
    }
  }
}
