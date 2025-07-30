import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/ticket.dart';
import '../../styles/app_theme.dart';
import '../ui/status_badge.dart';

// Componente para o Header do Card
class TicketCardHeader extends StatelessWidget {
  final Ticket ticket;
  final bool isMobile;

  const TicketCardHeader({
    super.key,
    required this.ticket,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatusIndicator(),
            SizedBox(width: isMobile ? 16 : 20),
            _buildTicketId(),
            const Spacer(),
            _buildPriorityBadge(),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 16),
        _buildAdditionalInfo(context),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 6,
      height: isMobile ? 48 : 56,
      decoration: BoxDecoration(
        color: _getStatusColor(ticket.status),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(ticket.status).withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketId() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 14,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.15),
            AppTheme.primaryColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.ticket(),
            size: isMobile ? 14 : 16,
            color: AppTheme.primaryColor,
          ),
          SizedBox(width: isMobile ? 6 : 8),
          Text(
            '#${ticket.id.substring(0, 8)}',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: isMobile ? 12 : 14,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 14,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: _getPriorityColor(ticket.priority).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
        border: Border.all(
          color: _getPriorityColor(ticket.priority).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getPriorityColor(ticket.priority).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPriorityIcon(ticket.priority),
            size: isMobile ? 12 : 14,
            color: _getPriorityColor(ticket.priority),
          ),
          SizedBox(width: isMobile ? 6 : 8),
          Text(
            _getPriorityName(ticket.priority),
            style: TextStyle(
              color: _getPriorityColor(ticket.priority),
              fontSize: isMobile ? 11 : 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(BuildContext context) {
    return Row(
      children: [
        _buildInfoChip(
          context: context,
          icon: PhosphorIcons.hash(),
          label: 'ID: ${ticket.id.substring(0, 8)}',
        ),
        SizedBox(width: isMobile ? 12 : 16),
        _buildInfoChip(
          context: context,
          icon: PhosphorIcons.calendar(),
          label: _formatDate(ticket.createdAt),
        ),
        const Spacer(),
        TicketStatusBadge(
          status: ticket.status,
          isOutlined: false,
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required BuildContext context,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
        border: Border.all(
          color: AppTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isMobile ? 12 : 14,
            color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
          ),
          SizedBox(width: isMobile ? 4 : 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return const Color(0xFF10B981);
      case TicketStatus.inProgress:
        return const Color(0xFF3B82F6);
      case TicketStatus.resolved:
        return const Color(0xFF8B5CF6);
      case TicketStatus.closed:
        return const Color(0xFF6B7280);
      case TicketStatus.waitingCustomer:
        return const Color(0xFFF59E0B);
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return const Color(0xFF10B981);
      case TicketPriority.normal:
        return const Color(0xFF3B82F6);
      case TicketPriority.high:
        return const Color(0xFFF59E0B);
      case TicketPriority.urgent:
        return const Color(0xFFEF4444);
    }
  }

  String _getPriorityName(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return 'Baixa';
      case TicketPriority.normal:
        return 'Normal';
      case TicketPriority.high:
        return 'Alta';
      case TicketPriority.urgent:
        return 'Urgente';
    }
  }

  IconData _getPriorityIcon(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return PhosphorIcons.handshake();
      case TicketPriority.normal:
        return PhosphorIcons.handshake();
      case TicketPriority.high:
        return PhosphorIcons.handshake();
      case TicketPriority.urgent:
        return PhosphorIcons.handshake();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m atrás';
      }
      return '${difference.inHours}h atrás';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Componente para o Título do Card
class TicketCardTitle extends StatelessWidget {
  final Ticket ticket;
  final bool isMobile;

  const TicketCardTitle({
    super.key,
    required this.ticket,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ticket.title,
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.getTextColor(context),
            height: 1.3,
          ),
          maxLines: isMobile ? 2 : 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (ticket.category != TicketCategory.general) ...[
          SizedBox(height: isMobile ? 6 : 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 6 : 8,
              vertical: isMobile ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: _getCategoryColor(ticket.category).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
            ),
            child: Text(
              _getCategoryName(ticket.category),
              style: TextStyle(
                fontSize: isMobile ? 10 : 11,
                color: _getCategoryColor(ticket.category),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getCategoryColor(TicketCategory category) {
    switch (category) {
      case TicketCategory.general:
        return AppTheme.primaryColor;
      case TicketCategory.billing:
        return const Color(0xFFF59E0B);
      case TicketCategory.technical:
        return const Color(0xFF3B82F6);
      case TicketCategory.complaint:
        return const Color(0xFFEF4444);
      case TicketCategory.feature:
        return const Color(0xFF10B981);
    }
  }

  String _getCategoryName(TicketCategory category) {
    switch (category) {
      case TicketCategory.general:
        return 'Geral';
      case TicketCategory.billing:
        return 'Faturamento';
      case TicketCategory.technical:
        return 'Técnico';
      case TicketCategory.complaint:
        return 'Reclamação';
      case TicketCategory.feature:
        return 'Funcionalidade';
    }
  }
}

// Componente para a Descrição do Card
class TicketCardDescription extends StatelessWidget {
  final String description;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final bool isMobile;

  const TicketCardDescription({
    super.key,
    required this.description,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final maxLines = isMobile ? 4 : 6;
    final isLongDescription = description.length > (isMobile ? 120 : 200);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(
          color: AppTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: AppTheme.getTextColor(context).withValues(alpha: 0.8),
              height: 1.5,
            ),
            maxLines: isExpanded ? null : maxLines,
            overflow: isExpanded ? null : TextOverflow.ellipsis,
          ),
          if (isLongDescription) ...[
            SizedBox(height: isMobile ? 8 : 12),
            GestureDetector(
              onTap: onToggleExpanded,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isExpanded
                        ? PhosphorIcons.caretUp()
                        : PhosphorIcons.caretDown(),
                    size: isMobile ? 14 : 16,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: isMobile ? 4 : 6),
                  Text(
                    isExpanded ? 'Ver menos' : 'Ver mais',
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
