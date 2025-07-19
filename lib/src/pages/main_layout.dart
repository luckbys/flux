import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'dashboard/dashboard_page.dart';
import 'tickets/tickets_page.dart';
import 'chat/chat_list_page.dart';
import 'profile/profile_page.dart';
import 'quotes_page.dart';
import '../stores/auth_store.dart';
import '../styles/app_theme.dart';
import '../styles/app_constants.dart';
import '../utils/color_extensions.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ChatListPage(),
    const TicketsPage(),
    const QuotesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_getPageTitle()),
      backgroundColor: AppTheme.getCardColor(context),
      elevation: 0,
      foregroundColor: AppTheme.getTextColor(context),
      actions: [
        Consumer<AuthStore>(
          builder: (context, authStore, child) {
            return PopupMenuButton<String>(
              icon: CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  authStore.appUser?.name.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onSelected: (value) {
                if (value == 'logout') {
                  _handleLogout();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.user()),
                      const SizedBox(width: 8),
                      const Text('Perfil'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.gear()),
                      const SizedBox(width: 8),
                      const Text('Configurações'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.signOut(), color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      const Text('Sair',
                          style: TextStyle(color: AppTheme.errorColor)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  String _getPageTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Conversas';
      case 2:
        return 'Tickets';
      case 3:
        return 'Orçamentos';
      case 4:
        return 'Perfil';
      default:
        return 'BKCRM';
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          Consumer<AuthStore>(
            builder: (context, authStore, child) {
              return ElevatedButton(
                onPressed: authStore.isLoading
                    ? null
                    : () async {
                        await authStore.signOut();
                        if (context.mounted) {
                          Navigator.pop(context); // Fechar dialog
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: authStore.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sair'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
            vertical: AppTheme.spacing8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: PhosphorIcons.house(),
                fillIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
                label: 'Dashboard',
                index: 0,
              ),
              _buildNavItem(
                icon: PhosphorIcons.chatCircle(),
                fillIcon: PhosphorIcons.chatCircle(PhosphorIconsStyle.fill),
                label: 'Chat',
                index: 1,
                badge: 3,
              ),
              _buildNavItem(
                icon: PhosphorIcons.ticket(),
                fillIcon: PhosphorIcons.ticket(PhosphorIconsStyle.fill),
                label: 'Tickets',
                index: 2,
                badge: 12,
              ),
              _buildNavItem(
                icon: PhosphorIcons.receiptX(),
                fillIcon: PhosphorIcons.receiptX(PhosphorIconsStyle.fill),
                label: 'Orçamentos',
                index: 3,
              ),
              _buildNavItem(
                icon: PhosphorIcons.user(),
                fillIcon: PhosphorIcons.user(PhosphorIconsStyle.fill),
                label: 'Perfil',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData fillIcon,
    required String label,
    required int index,
    int? badge,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha:  0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  isSelected ? fillIcon : icon,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.getTextColor(context).withValues(alpha:  0.6),
                  size: AppConstants.iconMedium,
                ),
                if (badge != null && badge > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppTheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge > 99 ? '99+' : badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.getTextColor(context).withValues(alpha:  0.6),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Páginas temporárias - serão substituídas por implementações completas
