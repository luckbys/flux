import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/ticket.dart';
import '../../styles/app_theme.dart';
import '../ui/user_avatar.dart';
import '../ui/status_badge.dart';

class TicketCard extends StatefulWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onAssign;
  final VoidCallback? onChat;
  final bool isCompact;
  final bool showActions;

  const TicketCard({
    super.key,
    required this.ticket,
    this.onTap,
    this.onEdit,
    this.onAssign,
    this.onChat,
    this.isCompact = false,
    this.showActions = true,
  });

  @override
  State<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<TicketCard> with TickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _hoverAnimationController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _hoverAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverAnimationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _hoverAnimationController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _hoverAnimationController.forward();
    } else {
      _hoverAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onEnter: (_) => _handleHover(true),
          onExit: (_) => _handleHover(false),
          child: AnimatedBuilder(
            animation: _hoverAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_hoverAnimation.value * 0.02),
                child: _buildCardContainer(isMobile, isTablet, isDesktop),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCardContainer(bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 4 : 8,
        vertical: isMobile ? 4 : 6,
      ),
      constraints: BoxConstraints(
        minHeight: isMobile ? 120 : 140, // Reduzido significativamente
        maxWidth: isDesktop ? 600 : double.infinity,
      ),
      decoration: _buildCardDecoration(isMobile),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          onTap: widget.onTap,
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16), // Reduzido
            child: _buildCardContent(isMobile, isTablet, isDesktop),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration(bool isMobile) {
    return BoxDecoration(
      color: AppTheme.getCardColor(context),
      borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
      border: Border.all(
        color: _isHovered
            ? AppTheme.primaryColor.withOpacity(0.4)
            : AppTheme.getBorderColor(context),
        width: _isHovered ? 2.0 : 1.0, // Reduzido
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.08),
          blurRadius: _isHovered ? 16 : 12,
          offset: Offset(0, _isHovered ? 6 : 4),
          spreadRadius: _isHovered ? 2 : 0,
        ),
      ],
    );
  }

  Widget _buildCardContent(bool isMobile, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(isMobile),
        SizedBox(height: isMobile ? 8 : 12), // Reduzido
        _buildTitle(isMobile),
        if (!widget.isCompact) ...[
          SizedBox(height: isMobile ? 6 : 8), // Reduzido
          _buildDescription(isMobile),
        ],
        SizedBox(height: isMobile ? 8 : 12), // Reduzido
        _buildCompactMetadata(isMobile), // Novo método mais compacto
        if (widget.ticket.tags.isNotEmpty && !widget.isCompact) ...[
          SizedBox(height: isMobile ? 8 : 10), // Reduzido
          _buildTags(isMobile),
        ],
        if (!widget.isCompact && widget.showActions) ...[
          SizedBox(height: isMobile ? 8 : 12), // Reduzido
          _buildActions(isMobile),
        ],
      ],
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        // Status indicator - mais compacto
        Container(
          width: 3, // Reduzido
          height: isMobile ? 32 : 36, // Reduzido
          decoration: BoxDecoration(
            color: _getStatusColor(widget.ticket.status),
            borderRadius: BorderRadius.circular(1.5),
            boxShadow: [
              BoxShadow(
                color: _getStatusColor(widget.ticket.status).withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12), // Reduzido

        // Ticket ID - mais compacto
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 6 : 8,
            vertical: isMobile ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.ticket(),
                size: isMobile ? 10 : 12, // Reduzido
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: isMobile ? 3 : 4), // Reduzido
              Text(
                '#${widget.ticket.id.substring(0, 8)}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 9 : 11, // Reduzido
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Priority badge - mais compacto
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 6 : 8,
            vertical: isMobile ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: _getPriorityColor(widget.ticket.priority).withOpacity(0.1),
            borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
            border: Border.all(
              color: _getPriorityColor(widget.ticket.priority).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getPriorityIcon(widget.ticket.priority),
                size: isMobile ? 10 : 12, // Reduzido
                color: _getPriorityColor(widget.ticket.priority),
              ),
              SizedBox(width: isMobile ? 3 : 4), // Reduzido
              Text(
                widget.ticket.priority.name,
                style: TextStyle(
                  color: _getPriorityColor(widget.ticket.priority),
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 8 : 10, // Reduzido
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(bool isMobile) {
    return Text(
      widget.ticket.title,
      style: TextStyle(
        fontSize: isMobile ? 14 : 16, // Reduzido
        fontWeight: FontWeight.w700,
        color: AppTheme.getTextColor(context),
        height: 1.2, // Reduzido
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription(bool isMobile) {
    return Text(
      widget.ticket.description,
      style: TextStyle(
        fontSize: isMobile ? 12 : 13, // Reduzido
        color: AppTheme.getTextColor(context).withOpacity(0.7),
        height: 1.3, // Reduzido
      ),
      maxLines: 2, // Reduzido de 3 para 2
      overflow: TextOverflow.ellipsis,
    );
  }

  // Novo método mais compacto para metadata
  Widget _buildCompactMetadata(bool isMobile) {
    return Row(
      children: [
        // Customer info - mais compacto
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 12 : 14, // Reduzido
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  widget.ticket.customer.name.isNotEmpty
                      ? widget.ticket.customer.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 10 : 12, // Reduzido
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 6 : 8), // Reduzido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.ticket.customer.name,
                      style: TextStyle(
                        color: AppTheme.getTextColor(context),
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 11 : 12, // Reduzido
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.ticket.customer.email,
                      style: TextStyle(
                        color: AppTheme.getTextColor(context).withOpacity(0.6),
                        fontSize: isMobile ? 9 : 10, // Reduzido
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Status badge - mais compacto
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 6 : 8,
            vertical: isMobile ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: _getStatusColor(widget.ticket.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
            border: Border.all(
              color: _getStatusColor(widget.ticket.status).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, // Reduzido
                height: 6, // Reduzido
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.ticket.status),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: isMobile ? 3 : 4), // Reduzido
              Text(
                widget.ticket.status.name,
                style: TextStyle(
                  color: _getStatusColor(widget.ticket.status),
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 8 : 10, // Reduzido
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: isMobile ? 8 : 12), // Reduzido

        // Date - mais compacto
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.clock(),
              size: isMobile ? 10 : 12, // Reduzido
              color: AppTheme.getTextColor(context).withOpacity(0.5),
            ),
            SizedBox(width: isMobile ? 3 : 4), // Reduzido
            Text(
              _formatDate(widget.ticket.createdAt),
              style: TextStyle(
                color: AppTheme.getTextColor(context).withOpacity(0.5),
                fontSize: isMobile ? 9 : 10, // Reduzido
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetadata(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12), // Reduzido
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12), // Reduzido
        border: Border.all(
          color: AppTheme.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Customer info
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 16 : 18, // Reduzido
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    widget.ticket.customer.name.isNotEmpty
                        ? widget.ticket.customer.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 12 : 14, // Reduzido
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12), // Reduzido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.ticket.customer.name,
                        style: TextStyle(
                          color: AppTheme.getTextColor(context),
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 12 : 14, // Reduzido
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.ticket.customer.email,
                        style: TextStyle(
                          color:
                              AppTheme.getTextColor(context).withOpacity(0.6),
                          fontSize: isMobile ? 10 : 12, // Reduzido
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 10,
              vertical: isMobile ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.ticket.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
              border: Border.all(
                color: _getStatusColor(widget.ticket.status).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.ticket.status),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: isMobile ? 4 : 6),
                Text(
                  widget.ticket.status.name,
                  style: TextStyle(
                    color: _getStatusColor(widget.ticket.status),
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 10 : 12,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: isMobile ? 8 : 12),

          // Date
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.clock(),
                size: isMobile ? 12 : 14,
                color: AppTheme.getTextColor(context).withOpacity(0.5),
              ),
              SizedBox(width: isMobile ? 4 : 6),
              Text(
                _formatDate(widget.ticket.createdAt),
                style: TextStyle(
                  color: AppTheme.getTextColor(context).withOpacity(0.5),
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTags(bool isMobile) {
    return Wrap(
      spacing: isMobile ? 4 : 6,
      runSpacing: isMobile ? 4 : 6,
      children: widget.ticket.tags.take(3).map((tag) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 6 : 8,
            vertical: isMobile ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            tag.name,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: isMobile ? 9 : 10, // Reduzido
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions(bool isMobile) {
    return Row(
      children: [
        // Edit button
        Expanded(
          child: _buildActionButton(
            icon: PhosphorIcons.pencilSimple(),
            label: 'Editar',
            onTap: widget.onEdit,
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 6 : 8), // Reduzido

        // Assign button
        Expanded(
          child: _buildActionButton(
            icon: widget.ticket.assignedAgent != null
                ? PhosphorIcons.userCheck()
                : PhosphorIcons.userPlus(),
            label:
                widget.ticket.assignedAgent != null ? 'Atribuído' : 'Atribuir',
            subtitle: widget.ticket.assignedAgent?.name ?? 'Ninguém',
            onTap: widget.onAssign,
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 6 : 8), // Reduzido

        // Chat button
        Expanded(
          child: _buildActionButton(
            icon: PhosphorIcons.chatCircle(),
            label: 'Chat',
            onTap: widget.onChat,
            isMobile: isMobile,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback? onTap,
    required bool isMobile,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 8 : 10), // Reduzido
        decoration: BoxDecoration(
          color: AppTheme.getBackgroundColor(context),
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          border: Border.all(
            color: AppTheme.getBorderColor(context),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isMobile ? 14 : 16, // Reduzido
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: isMobile ? 3 : 4), // Reduzido
            Text(
              label,
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 9 : 10, // Reduzido
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: isMobile ? 1 : 2), // Reduzido
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.getTextColor(context).withOpacity(0.6),
                  fontSize: isMobile ? 7 : 8, // Reduzido
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Colors.green;
      case TicketStatus.inProgress:
        return Colors.orange;
      case TicketStatus.waitingCustomer:
        return Colors.yellow;
      case TicketStatus.resolved:
        return Colors.blue;
      case TicketStatus.closed:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return Colors.green;
      case TicketPriority.normal:
        return Colors.orange;
      case TicketPriority.high:
        return Colors.red;
      case TicketPriority.urgent:
        return Colors.purple;
    }
  }

  IconData _getPriorityIcon(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return PhosphorIcons.arrowDown();
      case TicketPriority.normal:
        return PhosphorIcons.minus();
      case TicketPriority.high:
        return PhosphorIcons.arrowUp();
      case TicketPriority.urgent:
        return PhosphorIcons.warning();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Agora';
    }
  }
}

class TicketCompactCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;

  const TicketCompactCard({
    super.key,
    required this.ticket,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 12),
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
                        const SizedBox(width: 8),
                        TicketStatusBadge(
                          status: ticket.status,
                          isOutlined: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ticket.customer.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                AppTheme.getTextColor(context).withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (ticket.assignedAgent != null)
                UserAvatar(
                  user: ticket.assignedAgent!,
                  size: 32,
                  showOnlineStatus: false,
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.getTextColor(context).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.userPlus(),
                    size: 16,
                    color: AppTheme.getTextColor(context).withOpacity(0.5),
                  ),
                ),
            ],
          ),
        ),
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
