import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Import for Timer
import 'dashboard/dashboard_page.dart';
import 'tickets/tickets_page.dart';
import 'profile/profile_page.dart';
import 'quotes_page.dart';
import '../stores/auth_store.dart';
import '../stores/notification_store.dart';
import '../styles/app_theme.dart';
import '../styles/design_tokens.dart';
import '../components/auth/auth_wrapper.dart';
import '../widgets/ios_dock.dart';

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

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isCollapsed = false;
  bool _isAutoCollapseEnabled = true;
  final bool _isHovering = false;
  bool _isManuallyToggling = false; // Flag para controlar ações manuais
  Timer? _autoCollapseTimer;
  Timer? _inactivityTimer;

  // Controladores de animação otimizados
  late AnimationController _collapseAnimationController;
  late AnimationController _hoverAnimationController;
  late AnimationController _bounceAnimationController;
  late Animation<double> _collapseAnimation;
  late Animation<double> _hoverAnimation;
  late Animation<double> _bounceAnimation;

  // Cache das páginas para evitar reconstruções desnecessárias
  static const List<Widget> _pages = [
    DashboardPage(),
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
      icon: PhosphorIconsRegular.ticket,
      fillIcon: PhosphorIconsFill.ticket,
      label: 'Tickets',
      index: 1,
    ),
    NavItem(
      icon: PhosphorIconsRegular.receiptX,
      fillIcon: PhosphorIconsFill.receiptX,
      label: 'Orçamentos',
      index: 2,
    ),
    NavItem(
      icon: PhosphorIconsRegular.user,
      fillIcon: PhosphorIconsFill.user,
      label: 'Perfil',
      index: 3,
    ),
  ];

  // Cache dos títulos das páginas
  static const Map<int, String> _pageTitles = {
    0: 'Dashboard',
    1: 'Tickets',
    2: 'Orçamentos',
    3: 'Perfil',
  };

  // Cache de widgets para otimização
  final Map<int, Widget> _cachedNavItems = {};
  final Map<int, Widget> _cachedPages = {};

  @override
  void initState() {
    super.initState();

    // Inicializar controladores de animação
    _collapseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _hoverAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bounceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _collapseAnimation = CurvedAnimation(
      parent: _collapseAnimationController,
      curve: Curves.easeInOutCubic,
    );

    _hoverAnimation = CurvedAnimation(
      parent: _hoverAnimationController,
      curve: Curves.easeOut,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceAnimationController,
      curve: Curves.elasticOut,
    ));

    // Carregar estado salvo
    _loadSidebarState();

    // Inicializar cache
    _initializeCache();

    // Carregar notificações
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationStore =
          Provider.of<NotificationStore>(context, listen: false);
      notificationStore.loadNotifications();
    });
  }

  Future<void> _loadSidebarState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCollapsed = prefs.getBool('sidebar_collapsed') ?? false;
      final savedAutoCollapse = prefs.getBool('sidebar_auto_collapse') ?? true;

      setState(() {
        _isCollapsed = savedCollapsed;
        _isAutoCollapseEnabled = savedAutoCollapse;
      });

      // Aplicar animação inicial
      if (_isCollapsed) {
        _collapseAnimationController.value = 0.0;
      } else {
        _collapseAnimationController.value = 1.0;
      }
    } catch (e) {
      // Fallback para estado padrão
      setState(() {
        _isCollapsed = false;
        _isAutoCollapseEnabled = true;
      });
      _collapseAnimationController.value = 1.0;
    }
  }

  Future<void> _saveSidebarState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sidebar_collapsed', _isCollapsed);
      await prefs.setBool('sidebar_auto_collapse', _isAutoCollapseEnabled);
    } catch (e) {
      // Ignorar erros de persistência
    }
  }

  void _initializeCache() {
    // Cache das páginas
    for (int i = 0; i < _pages.length; i++) {
      _cachedPages[i] = RepaintBoundary(child: _pages[i]);
    }
  }

  Widget _buildCachedNavItem(int index) {
    return RepaintBoundary(
      child: _OptimizedSidebarNavItem(
        navItem: _navItems[index],
        isSelected: _currentIndex == index,
        isCollapsed: _isCollapsed,
        onTap: () => _onNavItemTap(index),
      ),
    );
  }

  void _onNavItemTap(int index) {
    _updateActivity();

    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });

      // Auto-colapsar em telas menores após navegação
      if (_isAutoCollapseEnabled && _isCollapsed == false) {
        _scheduleAutoCollapse();
      }
    }
  }

  void _updateActivity() {
    _inactivityTimer?.cancel();

    if (_isAutoCollapseEnabled && !_isCollapsed) {
      _inactivityTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && !_isHovering && _isAutoCollapseEnabled) {
          _toggleCollapse(true);
        }
      });
    }
  }

  void _scheduleAutoCollapse() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = Timer(const Duration(seconds: 3), () {
      if (!_isHovering && mounted) {
        _toggleCollapse(true);
      }
    });
  }

  void _toggleCollapse(bool collapsed) {
    setState(() {
      _isCollapsed = collapsed;
    });

    if (collapsed) {
      _collapseAnimationController.reverse();
    } else {
      _collapseAnimationController.forward();
    }

    // Salvar estado
    _saveSidebarState();

    // Feedback visual
    _bounceAnimationController.forward().then((_) {
      _bounceAnimationController.reverse();
    });
  }

  void _toggleCollapseManual(bool collapsed) {
    // Marcar como ação manual
    _isManuallyToggling = true;

    // Cancelar timers automáticos
    _autoCollapseTimer?.cancel();
    _inactivityTimer?.cancel();

    _toggleCollapse(collapsed);

    // Resetar flag após um delay para permitir que a animação termine
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isManuallyToggling = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    _inactivityTimer?.cancel();
    _collapseAnimationController.dispose();
    _hoverAnimationController.dispose();
    _bounceAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= DesignTokens.breakpointLg;
        final isTablet = constraints.maxWidth >= DesignTokens.breakpointMd &&
            constraints.maxWidth < DesignTokens.breakpointLg;

        // Ajustar comportamento baseado no tamanho da tela
        if (isTablet && !_isCollapsed && _isAutoCollapseEnabled) {
          // Auto-colapsar em tablets para economizar espaço
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isHovering) {
              _scheduleAutoCollapse();
            }
          });
        }

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
      body: SafeArea(
        child: RepaintBoundary(
          child: IndexedStack(
            index: _currentIndex,
            children: _pages.asMap().entries.map((entry) {
              final index = entry.key;
              final page = entry.value;

              // Cache apenas a página atual e adjacentes para economizar memória
              if ((_currentIndex - index).abs() <= 1) {
                return RepaintBoundary(
                  key: ValueKey('page_$index'),
                  child: page,
                );
              } else {
                return const SizedBox.shrink();
              }
            }).toList(),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      appBar: _buildDesktopHeader(context),
      body: Row(
        children: [
          Consumer<NotificationStore>(
            builder: (context, notificationStore, child) {
              return IosDock(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                items: _navItems,
                axis: Axis.vertical,
              );
            },
          ),
          Expanded(
            child: RepaintBoundary(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
                child: _cachedPages[_currentIndex] ?? _pages[_currentIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildDesktopHeader(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
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
            Consumer<NotificationStore>(
              builder: (context, notificationStore, child) {
                return PopupMenuButton<String>(
                  offset: const Offset(0, 50),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Icon(
                          PhosphorIcons.bell(),
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        if (notificationStore.unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                notificationStore.unreadCount.toString(),
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
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Container(
                        width: 350,
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(PhosphorIcons.bell(),
                                    color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                const Text(
                                  'Notificações',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (notificationStore.unreadCount > 0)
                                  TextButton(
                                    onPressed: () {
                                      notificationStore.markAllAsRead();
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'Marcar todas como lidas',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(),
                            SizedBox(
                              height: 300,
                              child: notificationStore.isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : notificationStore.notifications.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                PhosphorIcons.bellSlash(),
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Nenhuma notificação',
                                                style: TextStyle(
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: notificationStore
                                              .notifications.length,
                                          itemBuilder: (context, index) {
                                            final notification =
                                                notificationStore
                                                    .notifications[index];
                                            return Card(
                                              margin: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: ListTile(
                                                leading: Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: notification.isRead
                                                        ? Colors.grey
                                                            .withValues(
                                                                alpha: 0.2)
                                                        : AppTheme.primaryColor
                                                            .withValues(
                                                                alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    notification.type ==
                                                            'ticket'
                                                        ? PhosphorIcons.ticket()
                                                        : PhosphorIcons.info(),
                                                    color: notification.isRead
                                                        ? Colors.grey
                                                        : AppTheme.primaryColor,
                                                    size: 20,
                                                  ),
                                                ),
                                                title: Text(
                                                  notification.title,
                                                  style: TextStyle(
                                                    fontWeight:
                                                        notification.isRead
                                                            ? FontWeight.normal
                                                            : FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      notification.message,
                                                      style: const TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _formatNotificationTime(
                                                          notification
                                                              .createdAt),
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                onTap: () {
                                                  if (!notification.isRead) {
                                                    notificationStore
                                                        .markAsRead(
                                                            notification.id);
                                                  }
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            );
                                          },
                                        ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 16),
            Consumer<AuthStore>(
              builder: (context, authStore, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _handleLogout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.signOut(),
                              color: AppTheme.errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Sair',
                              style: TextStyle(
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
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
        // Botão de logout visível
        Consumer<AuthStore>(
          builder: (context, authStore, child) {
            return IconButton(
              onPressed: _handleLogout,
              icon: Icon(
                PhosphorIcons.signOut(),
                color: AppTheme.errorColor,
              ),
              tooltip: 'Sair',
            );
          },
        ),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.user()),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text('Perfil'),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.gear()),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text('Configurações'),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.signOut(), color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text('Sair',
                            style: TextStyle(color: AppTheme.errorColor)),
                      ),
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

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays}d atrás';
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
    return Consumer<NotificationStore>(
      builder: (context, notificationStore, child) {
        return SafeArea(
          child: IosDock(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: _navItems,
          ),
        );
      },
    );
  }
}

// Widget otimizado para itens de navegação do sidebar
class _OptimizedSidebarNavItem extends StatefulWidget {
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
  State<_OptimizedSidebarNavItem> createState() =>
      _OptimizedSidebarNavItemState();
}

class _OptimizedSidebarNavItemState extends State<_OptimizedSidebarNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_OptimizedSidebarNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animar apenas quando necessário
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            constraints: BoxConstraints(
              minHeight: 48,
              maxWidth: widget.isCollapsed ? 70 : double.infinity,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 8 : 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : _isHovered
                      ? AppTheme.primaryColor.withValues(alpha: 0.05)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.2)
                    : _isHovered
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: widget.isCollapsed
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
            scale: widget.isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              widget.isSelected ? widget.navItem.fillIcon : widget.navItem.icon,
              color: widget.isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.getTextColor(context).withValues(alpha: 0.7),
              size: 20,
            ),
          ),
          // Badge removido - notificações agora são centralizadas
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Se o espaço for muito pequeno, usar layout compacto
        if (constraints.maxWidth < 140) {
          return _buildCompactContent(context);
        }

        return Row(
          children: [
            Stack(
              children: [
                AnimatedScale(
                  scale: widget.isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.isSelected
                        ? widget.navItem.fillIcon
                        : widget.navItem.icon,
                    color: widget.isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.getTextColor(context).withValues(alpha: 0.7),
                    size: 22,
                  ),
                ),
                // Badge removido - notificações agora são centralizadas
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: widget.isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.getTextColor(context).withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: widget.isSelected ? 0.2 : 0,
                ),
                child: Text(
                  widget.navItem.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactContent(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            AnimatedScale(
              scale: widget.isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.isSelected
                    ? widget.navItem.fillIcon
                    : widget.navItem.icon,
                color: widget.isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.getTextColor(context).withValues(alpha: 0.7),
                size: 20,
              ),
            ),
            // Badge removido - notificações agora são centralizadas
          ],
        ),
        const SizedBox(width: 6),
        Flexible(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: widget.isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.getTextColor(context).withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: widget.isSelected ? 0.2 : 0,
            ),
            child: Text(
              widget.navItem.label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
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
        widget.navItem.badge! > 99 ? '99+' : widget.navItem.badge.toString(),
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
                // Badge removido - notificações agora são centralizadas
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
