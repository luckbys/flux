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
import '../styles/design_tokens.dart';
import '../components/auth/auth_wrapper.dart';

// Modelo para itens de navegação - otimização de performance
class NavItem {
  final IconData icon;
  final IconData fillIcon;
  final String label;
  final int index;
  final int? badge;

  const NavItem({
    required this.icon,
    required this.fillIcon,
    required this.label,
    required this.index,
    this.badge,
  });
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  bool _isCollapsed = false;

  // Cache das páginas para evitar reconstruções desnecessárias
  static const List<Widget> _pages = [
    DashboardPage(),
    ChatListPage(),
    TicketsPage(),
    QuotesPage(),
    ProfilePage(),
  ];

  // Lista de itens de navegação como constante para otimização
  static const List<NavItem> _navItems = [
    NavItem(
      icon: PhosphorIconsRegular.house,
      fillIcon: PhosphorIconsFill.house,
      label: 'Dashboard',
      index: 0,
    ),
    NavItem(
      icon: PhosphorIconsRegular.chatCircle,
      fillIcon: PhosphorIconsFill.chatCircle,
      label: 'Conversas',
      index: 1,
      badge: 3,
    ),
    NavItem(
      icon: PhosphorIconsRegular.ticket,
      fillIcon: PhosphorIconsFill.ticket,
      label: 'Tickets',
      index: 2,
      badge: 12,
    ),
    NavItem(
      icon: PhosphorIconsRegular.receiptX,
      fillIcon: PhosphorIconsFill.receiptX,
      label: 'Orçamentos',
      index: 3,
    ),
    NavItem(
      icon: PhosphorIconsRegular.user,
      fillIcon: PhosphorIconsFill.user,
      label: 'Perfil',
      index: 4,
    ),
  ];

  // Cache dos títulos das páginas
  static const Map<int, String> _pageTitles = {
    0: 'Dashboard',
    1: 'Conversas',
    2: 'Tickets',
    3: 'Orçamentos',
    4: 'Perfil',
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= DesignTokens.breakpointLg;

        if (isDesktop) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: _pages[_currentIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isCollapsed = false),
      onExit: (_) => setState(() => _isCollapsed = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        width: _isCollapsed ? 72.0 : 240.0,
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.getTextColor(context).withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSidebarHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildSidebarNavigation(),
            ),
            _buildSidebarFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: EdgeInsets.all(_isCollapsed ? 12 : 16),
      child: _isCollapsed
          ? Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.business_center,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 12),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isCollapsed = !_isCollapsed;
                    });
                  },
                  icon: AnimatedRotation(
                    turns: _isCollapsed ? 0.5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      PhosphorIcons.caretRight(),
                      color:
                          AppTheme.getTextColor(context).withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.business_center,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BKCRM',
                        style: TextStyle(
                          color: AppTheme.getTextColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        'Sistema de Gestão',
                        style: TextStyle(
                          color: AppTheme.getTextColor(context)
                              .withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isCollapsed = !_isCollapsed;
                    });
                  },
                  icon: AnimatedRotation(
                    turns: _isCollapsed ? 0.5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      PhosphorIcons.caretLeft(),
                      color:
                          AppTheme.getTextColor(context).withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSidebarNavigation() {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: _isCollapsed ? 8 : 12, vertical: 8),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _navItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final navItem = _navItems[index];
          return _OptimizedSidebarNavItem(
            navItem: navItem,
            isSelected: _currentIndex == navItem.index,
            isCollapsed: _isCollapsed,
            onTap: () {
              setState(() {
                _currentIndex = navItem.index;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: EdgeInsets.all(_isCollapsed ? 8 : 16),
      child: Consumer<AuthStore>(
        builder: (context, authStore, child) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleLogout,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _isCollapsed ? 8 : 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: _isCollapsed
                    ? Center(
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            authStore.appUser?.name
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              authStore.appUser?.name
                                      .substring(0, 1)
                                      .toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authStore.appUser?.name ?? 'Usuário',
                                  style: TextStyle(
                                    color: AppTheme.getTextColor(context),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Sair da conta',
                                  style: TextStyle(
                                    color: AppTheme.errorColor
                                        .withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            PhosphorIcons.signOut(),
                            color: AppTheme.errorColor.withValues(alpha: 0.7),
                            size: 18,
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

  Widget _buildDesktopHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _getPageTitle(),
            style: TextStyle(
              color: AppTheme.getTextColor(context),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIcons.bell(),
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Notificações',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return _pageTitles[_currentIndex] ?? 'BKCRM';
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
                          // Navegar para a tela de login removendo todas as rotas anteriores
                          Navigator.pushAndRemoveUntil(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const AuthWrapper(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                            ),
                            (route) => false,
                          );
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
            mainAxisSize: MainAxisSize.max,
            children: _navItems.map((navItem) {
              return Expanded(
                child: _OptimizedBottomNavItem(
                  navItem: navItem,
                  isSelected: _currentIndex == navItem.index,
                  onTap: () {
                    setState(() {
                      _currentIndex = navItem.index;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// Widget otimizado para itens de navegação do sidebar
class _OptimizedSidebarNavItem extends StatelessWidget {
  final NavItem navItem;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _OptimizedSidebarNavItem({
    required this.navItem,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 10 : 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.2)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: isCollapsed
                ? _buildCollapsedContent(context)
                : _buildExpandedContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isSelected ? navItem.fillIcon : navItem.icon,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.getTextColor(context).withValues(alpha: 0.7),
              size: 20,
            ),
          ),
          if (navItem.badge != null && navItem.badge! > 0)
            Positioned(
              right: -4,
              top: -4,
              child: _buildBadge(),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? navItem.fillIcon : navItem.icon,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.getTextColor(context).withValues(alpha: 0.7),
                size: 22,
              ),
            ),
            if (navItem.badge != null && navItem.badge! > 0)
              Positioned(
                right: -2,
                top: -2,
                child: _buildBadge(),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.getTextColor(context).withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: isSelected ? 0.2 : 0,
            ),
            child: Text(navItem.label),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge() {
    return Container(
      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        navItem.badge! > 99 ? '99+' : navItem.badge.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Widget otimizado para itens de navegação do bottom navigation
class _OptimizedBottomNavItem extends StatelessWidget {
  final NavItem navItem;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptimizedBottomNavItem({
    required this.navItem,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? navItem.fillIcon : navItem.icon,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.getTextColor(context).withValues(alpha: 0.7),
                    size: 20,
                  ),
                ),
                if (navItem.badge != null && navItem.badge! > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: _buildBadge(),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.getTextColor(context).withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(
                  navItem.label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        navItem.badge! > 99 ? '99+' : navItem.badge.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Páginas temporárias - serão substituídas por implementações completas
