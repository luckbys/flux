import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user.dart';
import '../../styles/app_theme.dart';
import '../../styles/app_constants.dart';
import '../../utils/color_extensions.dart';

class UserAvatar extends StatelessWidget {
  final User user;
  final double size;
  final bool showOnlineStatus;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const UserAvatar({
    super.key,
    required this.user,
    this.size = AppConstants.iconLarge,
    this.showOnlineStatus = true,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(size / 2),
                child: user.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: user.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => _buildInitials(),
                      )
                    : _buildInitials(),
              ),
            ),
            if (showOnlineStatus)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitials() {
    final initials = _getInitials(user.name);
    return Container(
      color: _getBackgroundColor(),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getBackgroundColor() {
    final hash = user.id.hashCode;
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    return colors[hash % colors.length];
  }

  Color _getStatusColor() {
    switch (user.status) {
      case UserStatus.online:
        return AppTheme.successColor;
      case UserStatus.away:
        return AppTheme.warningColor;
      case UserStatus.busy:
        return AppTheme.errorColor;
      case UserStatus.offline:
        return Colors.grey;
    }
  }
}

class UserAvatarGroup extends StatelessWidget {
  final List<User> users;
  final double size;
  final int maxVisible;
  final VoidCallback? onTap;

  const UserAvatarGroup({
    super.key,
    required this.users,
    this.size = AppConstants.iconLarge,
    this.maxVisible = 3,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleUsers = users.take(maxVisible).toList();
    final overflowCount = users.length - maxVisible;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...visibleUsers.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            return Container(
              margin: EdgeInsets.only(
                left: index > 0 ? -size * 0.3 : 0,
              ),
              child: UserAvatar(
                user: user,
                size: size,
                showOnlineStatus: false,
              ),
            );
          }),
          if (overflowCount > 0)
            Container(
              margin: EdgeInsets.only(left: -size * 0.3),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '+$overflowCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
