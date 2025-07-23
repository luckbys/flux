import 'package:flutter/material.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../../styles/app_theme.dart';
import '../../styles/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color? textColor;
  final bool isOutlined;
  final double? width;
  final double? height;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.textColor,
    this.isOutlined = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isOutlined ? color.withValues(alpha: 0.1) : color;
    final fgColor = textColor ?? (isOutlined ? color : Colors.white);

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: isOutlined ? Border.all(color: color, width: 1) : null,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w500,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class TicketStatusBadge extends StatelessWidget {
  final TicketStatus status;
  final bool isOutlined;

  const TicketStatusBadge({
    super.key,
    required this.status,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      text: _getStatusText(),
      color: _getStatusColor(),
      isOutlined: isOutlined,
    );
  }

  String _getStatusText() {
    switch (status) {
      case TicketStatus.open:
        return 'Aberto';
      case TicketStatus.inProgress:
        return 'Em Andamento';
      case TicketStatus.waitingCustomer:
        return 'Aguardando Cliente';
      case TicketStatus.resolved:
        return 'Resolvido';
      case TicketStatus.closed:
        return 'Fechado';
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case TicketStatus.open:
        return const Color(0xFF3B82F6); // Blue
      case TicketStatus.inProgress:
        return const Color(0xFFF59E0B); // Amber
      case TicketStatus.waitingCustomer:
        return const Color(0xFF8B5CF6); // Purple
      case TicketStatus.resolved:
        return AppTheme.successColor;
      case TicketStatus.closed:
        return const Color(0xFF6B7280); // Gray
    }
  }
}

class TicketPriorityBadge extends StatelessWidget {
  final TicketPriority priority;
  final bool isOutlined;

  const TicketPriorityBadge({
    super.key,
    required this.priority,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      text: _getPriorityText(),
      color: _getPriorityColor(),
      isOutlined: isOutlined,
    );
  }

  String _getPriorityText() {
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

  Color _getPriorityColor() {
    switch (priority) {
      case TicketPriority.low:
        return const Color(0xFF10B981); // Green
      case TicketPriority.normal:
        return const Color(0xFF6B7280); // Gray
      case TicketPriority.high:
        return AppTheme.warningColor;
      case TicketPriority.urgent:
        return AppTheme.errorColor;
    }
  }
}

class UserStatusBadge extends StatelessWidget {
  final UserStatus status;
  final bool showText;
  final bool isOutlined;

  const UserStatusBadge({
    super.key,
    required this.status,
    this.showText = true,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showText) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _getStatusColor(),
          shape: BoxShape.circle,
        ),
      );
    }

    return StatusBadge(
      text: _getStatusText(),
      color: _getStatusColor(),
      isOutlined: isOutlined,
    );
  }

  String _getStatusText() {
    switch (status) {
      case UserStatus.online:
        return 'Online';
      case UserStatus.offline:
        return 'Offline';
      case UserStatus.away:
        return 'Ausente';
      case UserStatus.busy:
        return 'Ocupado';
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case UserStatus.online:
        return AppTheme.successColor;
      case UserStatus.away:
        return AppTheme.warningColor;
      case UserStatus.busy:
        return AppTheme.errorColor;
      case UserStatus.offline:
        return const Color(0xFF6B7280);
    }
  }
}

class CountBadge extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;
  final double size;

  const CountBadge({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      constraints: BoxConstraints(minWidth: size),
      height: size,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.errorColor,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
