import 'package:flutter/material.dart' hide Text;
import 'package:flutter/widgets.dart' show Text, TextStyle;
// Removido phosphor_flutter - usando Icons padrão do Flutter
import 'package:provider/provider.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../../components/tickets/ticket_card.dart';
import '../../components/tickets/ticket_form.dart';
import '../../stores/ticket_store.dart';
import '../../stores/auth_store.dart';
import '../../screens/new_ticket_form.dart';
import 'ticket_details_page.dart';
import '../../styles/app_theme.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});
  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage>
    with TickerProviderStateMixin {
  String _searchQuery = '';
  TicketStatus? _selectedStatus;
  TicketPriority? _selectedPriority;
  TicketCategory? _selectedCategory;
  String? _selectedAssignee;
  String _sortBy = 'recent'; // recent, priority, status
  bool _showFilters = false;
  bool _isListView = false;

  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late AnimationController _fabAnimationController;

  // Animations
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _listFadeAnimation;
  late Animation<double> _fabScaleAnimation;

  // Search focus
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Initialize animations
    _headerSlideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _listFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeInOut,
    ));

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTickets();
      _startAnimations();
    });
  }

  void _startAnimations() {
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _listAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    _fabAnimationController.dispose();

    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadTickets() {
    final ticketStore = context.read<TicketStore>();
    final authStore = context.read<AuthStore>();

    // Carregar tickets baseado no papel do usuário
    if (authStore.appUser?.role == UserRole.admin) {
      // Admin vê todos os tickets
      ticketStore.loadTickets(forceRefresh: true);
    } else if (authStore.appUser?.role == UserRole.agent) {
      // Agente vê tickets atribuídos a ele
      ticketStore.loadTickets(
        forceRefresh: true,
        assignedUserId: authStore.appUser?.id,
      );
    } else {
      // Cliente vê apenas seus tickets
      ticketStore.loadTickets(forceRefresh: true);
    }
  }

  bool get hasActiveFilters {
    return _selectedStatus != null ||
        _selectedPriority != null ||
        _selectedCategory != null ||
        _searchQuery.isNotEmpty ||
        _sortBy != 'recent';
  }

  void _applyFilters() {
    final ticketStore = context.read<TicketStore>();

    ticketStore.setFilters(
      status: _selectedStatus,
      priority: _selectedPriority,
      assignedUser: null, // Implementar se necessário
    );

    if (_searchQuery.isNotEmpty) {
      ticketStore.search(_searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;

    return Scaffold(
      backgroundColor:
          isDesktop ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: isDesktop
            ? _buildOptimizedDesktopLayout()
            : isTablet
                ? _buildTabletLayout()
                : _buildMobileLayout(),
      ),
      floatingActionButton: !isDesktop
          ? AnimatedBuilder(
              animation: _fabScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fabScaleAnimation.value,
                  child: _buildFloatingActionButton(),
                );
              },
            )
          : null,
    );
  }

  Widget _buildOptimizedDesktopLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Layout sem sidebar - conteúdo principal ocupa toda a largura
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFBFCFD), // Mais claro para Windows
            const Color(0xFFF8FAFC),
            const Color(0xFFF1F5F9),
            const Color(0xFFE2E8F0).withValues(alpha: 0.2),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFCFCFD), // Mais claro para Windows
          // Gradiente sutil para profundidade
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFCFCFD),
              Color(0xFFFAFBFC),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildModernHeaderContent(),
            _buildModernDesktopToolbar(),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(
                  screenWidth > 1920
                      ? 16
                      : // 4K/Large screens
                      screenWidth > 1600
                          ? 12
                          : // Full HD+
                          8, // Standard
                ),
                child: AnimatedBuilder(
                  animation: _listFadeAnimation,
                  builder: (context, child) {
                    return TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: _listFadeAnimation.value * value,
                            child: Consumer<TicketStore>(
                              builder: (context, ticketStore, child) {
                                if (ticketStore.isLoading) {
                                  return _buildModernLoadingState();
                                }

                                if (ticketStore.hasError) {
                                  return _buildModernErrorState(
                                      ticketStore.errorMessage ??
                                          'Erro desconhecido');
                                }

                                if (ticketStore.tickets.isEmpty) {
                                  return _buildModernEmptyState();
                                }

                                return _buildEnhancedDesktopTicketsList(
                                    ticketStore.tickets,
                                    screenWidth,
                                    screenHeight);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        _buildTabletHeader(),
        Expanded(
          child: AnimatedBuilder(
            animation: _listFadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _listFadeAnimation.value,
                child: Consumer<TicketStore>(
                  builder: (context, ticketStore, child) {
                    if (ticketStore.isLoading) {
                      return _buildLoadingState();
                    }

                    if (ticketStore.hasError) {
                      return _buildErrorState(ticketStore);
                    }

                    if (ticketStore.tickets.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildTabletTicketsList(ticketStore.tickets);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildMobileHeader(),
        _buildMobileSearchBar(),
        _buildMobileStatsRow(),
        if (_showFilters)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _buildMobileFilters(),
          ),
        Expanded(
          child: AnimatedBuilder(
            animation: _listFadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _listFadeAnimation.value,
                child: Consumer<TicketStore>(
                  builder: (context, ticketStore, child) {
                    if (ticketStore.isLoading) {
                      return _buildLoadingState();
                    }

                    if (ticketStore.hasError) {
                      return _buildErrorState(ticketStore);
                    }

                    if (ticketStore.tickets.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildTicketsList(ticketStore.tickets);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.getTextColor(context).withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Loading tickets...',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait a moment',
                  style: TextStyle(
                    color:
                        AppTheme.getTextColor(context).withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(TicketStore ticketStore) {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppTheme.getTextColor(context).withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.warning,
                        size: 48,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Erro ao carregar tickets',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.getTextColor(context),
                                fontWeight: FontWeight.w700,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ticketStore.errorMessage ?? 'Erro desconhecido',
                      style: TextStyle(
                        color: AppTheme.getTextColor(context)
                            .withValues(alpha: 0.7),
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _loadTickets,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar Novamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
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

  Widget _buildModernHeaderContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFFBFCFD),
            Color(0xFFF8FAFC),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.02),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Breadcrumbs modernos
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(
              children: [
                _buildBreadcrumb('Dashboard', false),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
                _buildBreadcrumb('Tickets', true),
                const Spacer(),
                // Indicador de notificações em tempo real
                Consumer<TicketStore>(
                  builder: (context, ticketStore, child) {
                    final urgentTickets = ticketStore.tickets
                        .where((t) =>
                            t.priority == TicketPriority.urgent &&
                            t.status != TicketStatus.resolved)
                        .length;

                    if (urgentTickets > 0) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFEF4444),
                              Color(0xFFDC2626),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$urgentTickets urgente${urgentTickets > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          // Header principal
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título com ícone moderno
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF3B82F6),
                                  Color(0xFF2563EB),
                                  Color(0xFF1D4ED8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: const Color(0xFF1D4ED8)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.support_agent_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gerenciamento de Tickets',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.8,
                                    height: 1.1,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Gerencie e acompanhe todos os tickets do sistema com eficiência',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Controles de visualização modernos
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildModernViewToggleButton(
                        icon: Icons.grid_view,
                        label: 'Grid',
                        isActive: !_isListView,
                        onTap: () => setState(() => _isListView = false),
                      ),
                      const SizedBox(width: 4),
                      _buildModernViewToggleButton(
                        icon: Icons.list,
                        label: 'Lista',
                        isActive: _isListView,
                        onTap: () => setState(() => _isListView = true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Cards de estatísticas compactos
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Consumer<TicketStore>(
              builder: (context, ticketStore, child) {
                final totalTickets = ticketStore.tickets.length;
                final openTickets = ticketStore.tickets
                    .where((t) => t.status == TicketStatus.open)
                    .length;
                final inProgressTickets = ticketStore.tickets
                    .where((t) => t.status == TicketStatus.inProgress)
                    .length;
                final resolvedTickets = ticketStore.tickets
                    .where((t) => t.status == TicketStatus.resolved)
                    .length;

                return Row(
                  children: [
                    Expanded(
                      child: _buildCompactStatCard(
                        title: 'Total',
                        value: totalTickets.toString(),
                        icon: Icons.confirmation_number,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactStatCard(
                        title: 'Abertos',
                        value: openTickets.toString(),
                        icon: Icons.circle,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactStatCard(
                        title: 'Em Progresso',
                        value: inProgressTickets.toString(),
                        icon: Icons.access_time,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactStatCard(
                        title: 'Resolvidos',
                        value: resolvedTickets.toString(),
                        icon: Icons.check_circle,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 12,
                      color: isPositive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPositive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                width: 1,
              )
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildCompactStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * animationValue),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFFBFCFD),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Ícone com progresso circular
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            value: animationValue,
                            strokeWidth: 3,
                            backgroundColor: color.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Animação de contagem
                    TweenAnimationBuilder<int>(
                      duration: const Duration(milliseconds: 1200),
                      tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedValue, child) {
                        return Text(
                          animatedValue.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    // Indicador de tendência
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            size: 12,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 2),
                          Text(
                            '+12%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Tooltip(
        message: 'Clique para ver detalhes de $title',
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFFBFCFD),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildModernViewToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedHeaderContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.02),
            Colors.transparent,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.getBorderColor(context),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título principal otimizado
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.confirmation_number,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Gerenciamento de Tickets',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.getTextColor(context),
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Consumer<TicketStore>(
                      builder: (context, ticketStore, child) {
                        final totalTickets = ticketStore.tickets.length;
                        final openTickets = ticketStore.tickets
                            .where((t) => t.status == TicketStatus.open)
                            .length;
                        final inProgressTickets = ticketStore.tickets
                            .where((t) => t.status == TicketStatus.inProgress)
                            .length;
                        return Row(
                          children: [
                            _buildHeaderStatChip(
                              'Total: $totalTickets',
                              AppTheme.primaryColor,
                              Icons.confirmation_number,
                            ),
                            const SizedBox(width: 12),
                            _buildHeaderStatChip(
                              'Abertos: $openTickets',
                              const Color(0xFF10B981),
                              Icons.circle,
                            ),
                            const SizedBox(width: 12),
                            _buildHeaderStatChip(
                              'Em Progresso: $inProgressTickets',
                              const Color(0xFF3B82F6),
                              Icons.access_time,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Controles de visualização otimizados
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.getBorderColor(context),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.getTextColor(context)
                          .withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildOptimizedViewToggleButton(
                      icon: Icons.grid_view,
                      label: 'Grid',
                      isActive: !_isListView,
                      onTap: () => setState(() => _isListView = false),
                    ),
                    const SizedBox(width: 4),
                    _buildOptimizedViewToggleButton(
                      icon: Icons.list,
                      label: 'Lista',
                      isActive: _isListView,
                      onTap: () => setState(() => _isListView = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Barra de pesquisa otimizada
          Container(
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.getBorderColor(context),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.getTextColor(context).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar tickets por título, descrição ou cliente...',
                hintStyle: TextStyle(
                  color: AppTheme.getTextColor(context).withValues(alpha: 0.5),
                  fontSize: 16,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search,
                    color:
                        AppTheme.getTextColor(context).withValues(alpha: 0.6),
                    size: 22,
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(
                          Icons.close,
                          size: 12,
                          color: AppTheme.errorColor,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedViewToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? Colors.white
                  : AppTheme.getTextColor(context).withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : AppTheme.getTextColor(context).withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.getBorderColor(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Filtros rápidos de status
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickStatusFilter(
                    'Todos',
                    null,
                    AppTheme.getTextColor(context).withValues(alpha: 0.7),
                    Icons.list,
                  ),
                  const SizedBox(width: 12),
                  _buildQuickStatusFilter(
                    'Abertos',
                    TicketStatus.open,
                    const Color(0xFF10B981),
                    Icons.circle,
                  ),
                  const SizedBox(width: 12),
                  _buildQuickStatusFilter(
                    'Em Progresso',
                    TicketStatus.inProgress,
                    const Color(0xFF3B82F6),
                    Icons.access_time,
                  ),
                  const SizedBox(width: 12),
                  _buildQuickStatusFilter(
                    'Resolvidos',
                    TicketStatus.resolved,
                    const Color(0xFF8B5CF6),
                    Icons.check_circle,
                  ),
                  const SizedBox(width: 12),
                  _buildQuickStatusFilter(
                    'Fechados',
                    TicketStatus.closed,
                    const Color(0xFF6B7280),
                    Icons.close,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Controles de ordenação
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.getBorderColor(context),
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                icon: Icon(
                  Icons.list,
                  size: 16,
                  color: AppTheme.getTextColor(context).withValues(alpha: 0.6),
                ),
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'recent',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.list,
                          size: 16,
                          color: AppTheme.getTextColor(context)
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        const Text('Mais Recentes'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'priority',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.list,
                          size: 16,
                          color: AppTheme.getTextColor(context)
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        const Text('Por Prioridade'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'status',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.list,
                          size: 16,
                          color: AppTheme.getTextColor(context)
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        const Text('Por Status'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortBy = value;
                    });
                    _applySorting();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Botão de atualizar
          Tooltip(
            message: 'Atualizar lista',
            child: IconButton(
              onPressed: () {
                _loadTickets();
                _listAnimationController.forward(from: 0);
              },
              icon: Icon(
                Icons.refresh,
                size: 20,
                color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.getCardColor(context),
                side: BorderSide(
                  color: AppTheme.getBorderColor(context),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDesktopToolbar() {
    final hasActiveFilters = _selectedStatus != null ||
        _selectedPriority != null ||
        _selectedCategory != null ||
        _sortBy != 'recent';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Barra de pesquisa aprimorada
          Expanded(
            flex: 3,
            child: Focus(
              onFocusChange: (hasFocus) {
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 48,
                decoration: BoxDecoration(
                  color: _searchFocusNode.hasFocus
                      ? const Color(0xFFFAFBFC)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _searchFocusNode.hasFocus
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFE2E8F0),
                    width: _searchFocusNode.hasFocus ? 2 : 1,
                  ),
                  boxShadow: _searchFocusNode.hasFocus
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar por título, descrição ou cliente...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.search_rounded,
                        color: _searchFocusNode.hasFocus
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? Tooltip(
                            message: 'Limpar pesquisa',
                            child: IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                _applyFilters();
                              },
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Filtros aprimorados
          _buildEnhancedFilterButton(
            icon: Icons.filter_list_rounded,
            label: _selectedStatus != null
                ? _getStatusText(_selectedStatus!)
                : 'Status',
            isActive: _selectedStatus != null,
            badgeCount: _selectedStatus != null ? 1 : 0,
            tooltip: 'Filtrar por status do ticket',
            onTap: () => _showStatusFilter(),
          ),
          const SizedBox(width: 12),
          _buildEnhancedFilterButton(
            icon: Icons.sort_rounded,
            label: _getSortLabel(_sortBy),
            isActive: _sortBy != 'recent',
            badgeCount: _sortBy != 'recent' ? 1 : 0,
            tooltip: 'Ordenar tickets',
            onTap: () => _showSortOptions(),
          ),
          const SizedBox(width: 12),
          _buildEnhancedFilterButton(
            icon: Icons.tune_rounded,
            label: 'Filtros',
            isActive: _selectedPriority != null || _selectedCategory != null,
            badgeCount: (_selectedPriority != null ? 1 : 0) +
                (_selectedCategory != null ? 1 : 0),
            tooltip: 'Filtros avançados',
            onTap: () => _showAdvancedFilters(),
          ),
          // Botão limpar filtros
          if (hasActiveFilters) ...[
            const SizedBox(width: 12),
            Tooltip(
              message: 'Limpar todos os filtros',
              child: InkWell(
                onTap: _clearAllFilters,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.clear_all_rounded,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 20),
          // Indicador de resultados
          Consumer<TicketStore>(
            builder: (context, ticketStore, child) {
              if (!ticketStore.isLoading && ticketStore.tickets.isNotEmpty) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '${ticketStore.tickets.length} ticket${ticketStore.tickets.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 16),
          // Botão de novo ticket aprimorado
          Tooltip(
            message: 'Criar novo ticket',
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3B82F6),
                    Color(0xFF1D4ED8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showCreateTicketDialog();
                },
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Novo Ticket',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFilterButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required int badgeCount,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
          highlightColor: const Color(0xFF3B82F6).withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF3B82F6),
                        Color(0xFF1D4ED8),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF8FAFC),
                        Color(0xFFF1F5F9),
                      ],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE2E8F0),
                width: isActive ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                      : const Color(0xFF1E293B).withValues(alpha: 0.08),
                  blurRadius: isActive ? 12 : 8,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                if (isActive)
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
              ],
            ),
            child: Stack(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone com animação
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFF64748B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color:
                            isActive ? Colors.white : const Color(0xFF64748B),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Label
                    Text(
                      label,
                      style: TextStyle(
                        color:
                            isActive ? Colors.white : const Color(0xFF374151),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Seta com animação
                    AnimatedRotation(
                      turns: isActive ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF64748B),
                        size: 18,
                      ),
                    ),
                  ],
                ),
                // Badge de contagem melhorado
                if (badgeCount > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'recent':
        return 'Recentes';
      case 'priority':
        return 'Prioridade';
      case 'status':
        return 'Status';
      default:
        return 'Ordenar';
    }
  }

  String _getPriorityText(TicketPriority priority) {
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

  String _getCategoryText(TicketCategory category) {
    switch (category) {
      case TicketCategory.general:
        return 'Geral';
      case TicketCategory.technical:
        return 'Técnico';
      case TicketCategory.billing:
        return 'Financeiro';
      case TicketCategory.complaint:
        return 'Reclamação';
      case TicketCategory.feature:
        return 'Funcionalidade';
    }
  }

  void _showStatusFilter() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFFAFBFC),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
                blurRadius: 40,
                offset: const Offset(0, 16),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.filter_list_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Filtrar por Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Opção "Todos"
                    _buildStatusOption(
                      status: null,
                      label: 'Todos os Status',
                      icon: Icons.all_inclusive_rounded,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(height: 8),
                    // Opções de status
                    ...TicketStatus.values.map((status) => Column(
                          children: [
                            _buildStatusOption(
                              status: status,
                              label: _getStatusText(status),
                              icon: _getStatusIcon(status),
                              color: _getStatusColor(status),
                            ),
                            const SizedBox(height: 8),
                          ],
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption({
    required TicketStatus? status,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedStatus == status;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStatus = status;
          });
          _applyFilters();
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF374151),
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedPriority = null;
      _selectedCategory = null;
      _sortBy = 'recent';
      _searchQuery = '';
      _searchController.clear();
    });
    _applyFilters();
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFFAFBFC),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.05),
                blurRadius: 40,
                offset: const Offset(0, 16),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sort_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Ordenar Tickets',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildSortOption(
                      value: 'recent',
                      label: 'Mais Recentes',
                      description: 'Ordenar por data de criação',
                      icon: Icons.access_time_rounded,
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 12),
                    _buildSortOption(
                      value: 'priority',
                      label: 'Por Prioridade',
                      description: 'Ordenar por nível de urgência',
                      icon: Icons.priority_high_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 12),
                    _buildSortOption(
                      value: 'status',
                      label: 'Por Status',
                      description: 'Agrupar por estado do ticket',
                      icon: Icons.info_outline_rounded,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required String value,
    required String label,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _sortBy == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _sortBy = value;
          });
          _applyFilters();
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF374151),
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF64748B)
                            : const Color(0xFF9CA3AF),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdvancedFilters() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFFAFBFC),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                blurRadius: 40,
                offset: const Offset(0, 16),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Filtros Avançados',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seção Prioridade
                    _buildFilterSection(
                      title: 'Prioridade',
                      icon: Icons.priority_high_rounded,
                      color: const Color(0xFFEF4444),
                      children: TicketPriority.values.map((priority) {
                        return _buildAdvancedFilterChip(
                          label: _getPriorityText(priority),
                          isSelected: _selectedPriority == priority,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPriority = selected ? priority : null;
                            });
                          },
                          color: _getPriorityColor(priority),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Seção Categoria
                    _buildFilterSection(
                      title: 'Categoria',
                      icon: Icons.category_rounded,
                      color: const Color(0xFF10B981),
                      children: TicketCategory.values.map((category) {
                        return _buildAdvancedFilterChip(
                          label: _getCategoryText(category),
                          isSelected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category : null;
                            });
                          },
                          color: const Color(0xFF10B981),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedPriority = null;
                          _selectedCategory = null;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Limpar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        _applyFilters();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor:
                            const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      ),
                      child: const Text(
                        'Aplicar Filtros',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children,
        ),
      ],
    );
  }

  Widget _buildAdvancedFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelected(!isSelected),
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.15),
                      color.withValues(alpha: 0.08),
                    ],
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernLoadingState() {
    return Column(
      children: [
        // Skeleton para header
        Container(
          margin: const EdgeInsets.all(16),
          child: _buildSkeletonHeader(),
        ),
        // Skeleton para estatísticas
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSkeletonStats(),
        ),
        const SizedBox(height: 16),
        // Skeleton para lista de tickets
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 6,
            itemBuilder: (context, index) => _buildSkeletonTicketCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonHeader() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.3, end: 1.0),
      curve: Curves.easeInOut,
      builder: (context, opacity, child) {
        return AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[200]!.withValues(alpha: opacity),
                  Colors.grey[100]!.withValues(alpha: opacity),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[300]!.withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300]!.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[300]!.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonStats() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.3, end: 1.0),
      curve: Curves.easeInOut,
      builder: (context, opacity, child) {
        return Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[200]!.withValues(alpha: opacity),
                      Colors.grey[100]!.withValues(alpha: opacity),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[300]!.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300]!.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300]!.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSkeletonTicketCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.3, end: 1.0),
      curve: Curves.easeInOut,
      builder: (context, opacity, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[200]!.withValues(alpha: opacity),
                Colors.grey[100]!.withValues(alpha: opacity),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Ícone skeleton
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300]!.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              // Conteúdo skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color:
                                  Colors.grey[300]!.withValues(alpha: opacity),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 60,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[300]!.withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300]!.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 200,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300]!.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[300]!.withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 60,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[300]!.withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.warning,
                color: Color(0xFFEF4444),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Erro ao carregar tickets',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _loadTickets();
              },
              icon: const Icon(
                Icons.refresh,
                size: 18,
              ),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF64748B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFF64748B),
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Nenhum ticket encontrado',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Não há tickets que correspondam aos filtros aplicados.\nTente ajustar os filtros ou criar um novo ticket.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _searchController.clear();
                    });
                    _applyFilters();
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                  ),
                  label: const Text('Limpar filtros'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(
                      color: Color(0xFFE2E8F0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _showCreateTicketDialog();
                  },
                  icon: const Icon(
                    Icons.confirmation_number,
                    size: 18,
                  ),
                  label: const Text('Criar ticket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatusFilter(
    String label,
    TicketStatus? status,
    Color color,
    IconData icon,
  ) {
    final isActive = _selectedStatus == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.4)
                : AppTheme.getBorderColor(context),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? color
                  : AppTheme.getTextColor(context).withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? color
                    : AppTheme.getTextColor(context).withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título e estatísticas
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tickets',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Consumer<TicketStore>(
                      builder: (context, ticketStore, child) {
                        final totalTickets = ticketStore.tickets.length;
                        final openTickets = ticketStore.tickets
                            .where((t) => t.status == TicketStatus.open)
                            .length;
                        return Text(
                          '$totalTickets tickets • $openTickets abertos',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Botões de visualização
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    _buildViewToggleButton(
                      icon: Icons.grid_view,
                      isActive: !_isListView,
                      onTap: () => setState(() => _isListView = false),
                      tooltip: 'Visualização em Grid',
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: const Color(0xFFE2E8F0),
                    ),
                    _buildViewToggleButton(
                      icon: Icons.list,
                      isActive: _isListView,
                      onTap: () => setState(() => _isListView = true),
                      tooltip: 'Visualização em Lista',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barra de pesquisa
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar tickets...',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(
                          Icons.close,
                          size: 12,
                          color: AppTheme.errorColor,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filtros rápidos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickFilterChip(
                  label: 'Todos',
                  isActive: _selectedStatus == null,
                  onTap: () => setState(() => _selectedStatus = null),
                ),
                const SizedBox(width: 8),
                _buildQuickFilterChip(
                  label: 'Abertos',
                  isActive: _selectedStatus == TicketStatus.open,
                  onTap: () =>
                      setState(() => _selectedStatus = TicketStatus.open),
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                _buildQuickFilterChip(
                  label: 'Em Progresso',
                  isActive: _selectedStatus == TicketStatus.inProgress,
                  onTap: () =>
                      setState(() => _selectedStatus = TicketStatus.inProgress),
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                _buildQuickFilterChip(
                  label: 'Resolvidos',
                  isActive: _selectedStatus == TicketStatus.resolved,
                  onTap: () =>
                      setState(() => _selectedStatus = TicketStatus.resolved),
                  color: const Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 8),
                _buildQuickFilterChip(
                  label: 'Fechados',
                  isActive: _selectedStatus == TicketStatus.closed,
                  onTap: () =>
                      setState(() => _selectedStatus = TicketStatus.closed),
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (color ?? const Color(0xFF3B82F6)).withValues(alpha: 0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? (color ?? const Color(0xFF3B82F6)).withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? (color ?? const Color(0xFF3B82F6))
                : const Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOptimizedDesktopStatsGrid() {
    return Consumer<TicketStore>(
      builder: (context, ticketStore, child) {
        final stats = ticketStore.ticketStats;
        final total = stats['total'] ?? 0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: crossAxisCount == 2 ? 2.8 : 3.5,
              children: [
                _buildOptimizedDesktopStatCard(
                  'Total de Tickets',
                  (stats['total'] ?? 0).toString(),
                  Icons.confirmation_number,
                  AppTheme.primaryColor,
                  '100%',
                ),
                _buildOptimizedDesktopStatCard(
                  'Tickets Abertos',
                  (stats['open'] ?? 0).toString(),
                  Icons.circle,
                  const Color(0xFFFF8C00),
                  total > 0
                      ? '${(((stats['open'] ?? 0) / total) * 100).toStringAsFixed(1)}%'
                      : '0.0%',
                ),
                _buildOptimizedDesktopStatCard(
                  'Em Andamento',
                  (stats['in_progress'] ?? 0).toString(),
                  Icons.access_time,
                  const Color(0xFF2196F3),
                  total > 0
                      ? '${(((stats['in_progress'] ?? 0) / total) * 100).toStringAsFixed(1)}%'
                      : '0.0%',
                ),
                _buildOptimizedDesktopStatCard(
                  'Resolvidos',
                  (stats['resolved'] ?? 0).toString(),
                  Icons.check_circle,
                  const Color(0xFF4CAF50),
                  total > 0
                      ? '${(((stats['resolved'] ?? 0) / total) * 100).toStringAsFixed(1)}%'
                      : '0.0%',
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOptimizedDesktopStatCard(String label, String count,
      IconData icon, Color color, String percentage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  percentage,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              count,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context).withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStatCard(
      String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        // Botão de criar ticket
        Consumer<AuthStore>(
          builder: (context, authStore, child) {
            if (authStore.appUser?.role == UserRole.customer ||
                authStore.appUser?.role == UserRole.agent) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showCreateTicketDialog,
                  icon: const Icon(Icons.confirmation_number),
                  label: const Text('Novo Ticket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        const SizedBox(height: 12),

        // Botões de ação rápida
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Implementar exportação
                },
                icon: const Icon(
                  Icons.list,
                  size: 16,
                ),
                label: const Text('Exportar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.getTextColor(context),
                  side: BorderSide(
                    color: AppTheme.getBorderColor(context),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Implementar atualização
                  final ticketStore = context.read<TicketStore>();
                  ticketStore.loadTickets();
                },
                icon: const Icon(
                  Icons.list,
                  size: 16,
                ),
                label: const Text('Atualizar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.getTextColor(context),
                  side: BorderSide(
                    color: AppTheme.getBorderColor(context),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopTicketsList(List<Ticket> tickets) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: EdgeInsets.all(
            constraints.maxWidth < 600 ? 12 : 24,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: _isListView
                ? _buildDesktopListView(tickets)
                : _buildDesktopGridView(tickets, constraints),
          ),
        );
      },
    );
  }

  Widget _buildDesktopGridView(
      List<Ticket> tickets, BoxConstraints constraints) {
    final crossAxisCount = constraints.maxWidth < 800 ? 1 : 2;
    final crossAxisSpacing = constraints.maxWidth < 600 ? 8 : 16;
    final mainAxisSpacing = constraints.maxWidth < 600 ? 8 : 16;
    final childAspectRatio = constraints.maxWidth < 600 ? 2.0 : 1.8;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing.toDouble(),
        mainAxisSpacing: mainAxisSpacing.toDouble(),
        childAspectRatio: childAspectRatio,
      ),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 50)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Hero(
                    tag: 'ticket_${ticket.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: TicketCard(
                        ticket: ticket,
                        onTap: () => _navigateToTicketDetails(ticket),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDesktopListView(List<Ticket> tickets) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 600 ? 8.0 : 16.0;

        return ListView.builder(
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return RepaintBoundary(
              child: TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 50)),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: padding),
                        child: Hero(
                          tag: 'ticket_${ticket.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: _buildTicketListItem(ticket, constraints),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOptimizedDesktopTicketsList(List<Ticket> tickets) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: _isListView
                ? _buildOptimizedDesktopListView(tickets)
                : _buildOptimizedDesktopGridView(tickets, constraints),
          ),
        );
      },
    );
  }

  Widget _buildOptimizedDesktopGridView(
      List<Ticket> tickets, BoxConstraints constraints) {
    final crossAxisCount = constraints.maxWidth > 1400 ? 3 : 2;
    const crossAxisSpacing = 24.0;
    const mainAxisSpacing = 24.0;
    final childAspectRatio = constraints.maxWidth > 1400 ? 1.6 : 1.8;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (index * 80)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: Hero(
                      tag: 'ticket_${ticket.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: _buildOptimizedTicketCard(ticket),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOptimizedDesktopListView(List<Ticket> tickets) {
    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (index * 60)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(-50 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Hero(
                      tag: 'ticket_${ticket.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: _buildOptimizedTicketListItem(ticket),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOptimizedTicketCard(Ticket ticket) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.getCardColor(context),
            AppTheme.getCardColor(context).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(ticket.status).withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(ticket.status).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToTicketDetails(ticket),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com status e prioridade
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(ticket.status)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(ticket.status)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(ticket.status),
                            size: 14,
                            color: _getStatusColor(ticket.status),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusText(ticket.status),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(ticket.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(ticket.priority)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPriorityIcon(ticket.priority),
                        size: 16,
                        color: _getPriorityColor(ticket.priority),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Título
                Text(
                  ticket.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getTextColor(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Descrição
                Text(
                  ticket.description,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        AppTheme.getTextColor(context).withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                // Footer com informações
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color:
                          AppTheme.getTextColor(context).withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ticket.customer.name ?? 'Cliente não informado',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getTextColor(context)
                              .withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatDate(ticket.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getTextColor(context)
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptimizedTicketListItem(Ticket ticket) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.getCardColor(context),
            AppTheme.getCardColor(context).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(ticket.status).withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(ticket.status).withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToTicketDetails(ticket),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Indicador de status
                Container(
                  width: 6,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getStatusColor(ticket.status),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 20),
                // Ícone de status
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(ticket.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _getStatusColor(ticket.status).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    _getStatusIcon(ticket.status),
                    color: _getStatusColor(ticket.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                // Conteúdo principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ticket.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.getTextColor(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(ticket.status)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusText(ticket.status),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(ticket.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getTextColor(context)
                              .withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: AppTheme.getTextColor(context)
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ticket.customer.name ?? 'Cliente não informado',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.getTextColor(context)
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(ticket.createdAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.getTextColor(context)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Prioridade
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(ticket.priority)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPriorityIcon(ticket.priority),
                    size: 20,
                    color: _getPriorityColor(ticket.priority),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketListItem(Ticket ticket, BoxConstraints constraints) {
    final isSmallScreen = constraints.maxWidth < 600;
    final padding = isSmallScreen ? 16.0 : 24.0;
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final titleSize = isSmallScreen ? 15.0 : 17.0;
    final descSize = isSmallScreen ? 13.0 : 14.0;
    final metaSize = isSmallScreen ? 11.0 : 12.0;

    return AnimatedBuilder(
      animation: _listFadeAnimation,
      builder: (context, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFFAFBFC),
                  const Color(0xFFF8FAFC),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: _getStatusColor(ticket.status).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _navigateToTicketDetails(ticket),
                splashColor:
                    _getStatusColor(ticket.status).withValues(alpha: 0.1),
                highlightColor:
                    _getStatusColor(ticket.status).withValues(alpha: 0.05),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Flex(
                    direction: isSmallScreen ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Indicator com animação melhorada
                      _buildAnimatedStatusIndicator(
                          ticket.status, isSmallScreen, iconSize),

                      SizedBox(
                        width: isSmallScreen ? 0 : 20,
                        height: isSmallScreen ? 16 : 0,
                      ),

                      // Conteúdo principal
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header com título e prioridade
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ticket.title,
                                    style: TextStyle(
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                      letterSpacing: -0.3,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 12 : 16),
                                _buildEnhancedPriorityChip(
                                    ticket.priority, isSmallScreen),
                              ],
                            ),

                            SizedBox(height: isSmallScreen ? 6 : 10),

                            // Descrição com melhor formatação
                            Text(
                              ticket.description,
                              style: TextStyle(
                                fontSize: descSize,
                                color: const Color(0xFF64748B),
                                height: 1.5,
                                letterSpacing: 0.2,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: isSmallScreen ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                            ),

                            SizedBox(height: isSmallScreen ? 12 : 16),

                            // Metadata melhorada
                            _buildEnhancedMetadata(
                                ticket, isSmallScreen, metaSize),
                          ],
                        ),
                      ),

                      // Indicador de ação
                      if (!isSmallScreen) _buildActionIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStatusIndicator(
      TicketStatus status, bool isSmallScreen, double iconSize) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
            width: isSmallScreen ? 48 : 56,
            height: isSmallScreen ? 48 : 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getStatusColor(status).withValues(alpha: 0.15),
                  _getStatusColor(status).withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getStatusColor(status).withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(status).withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring animado
                SizedBox(
                  width: isSmallScreen ? 48 : 56,
                  height: isSmallScreen ? 48 : 56,
                  child: CircularProgressIndicator(
                    value: _getStatusProgress(status),
                    strokeWidth: 3,
                    backgroundColor:
                        _getStatusColor(status).withValues(alpha: 0.1),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_getStatusColor(status)),
                  ),
                ),
                // Ícone central
                Container(
                  width: isSmallScreen ? 32 : 36,
                  height: isSmallScreen ? 32 : 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor(status).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: iconSize * 0.8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedMetadata(
      Ticket ticket, bool isSmallScreen, double metaSize) {
    return Row(
      children: [
        // Cliente com avatar
        Expanded(
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ticket.customer.name,
                  style: TextStyle(
                    fontSize: metaSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: isSmallScreen ? 16 : 24),

        // Data com ícone melhorado
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(ticket.createdAt),
              style: TextStyle(
                fontSize: metaSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),

        // ID do ticket
        if (!isSmallScreen) ...[
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Text(
              '#${ticket.id.substring(0, 8)}',
              style: TextStyle(
                fontSize: metaSize - 1,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionIndicator() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Color(0xFF64748B),
        size: 16,
      ),
    );
  }

  double _getStatusProgress(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 0.25;
      case TicketStatus.inProgress:
        return 0.5;
      case TicketStatus.waitingCustomer:
        return 0.75;
      case TicketStatus.resolved:
        return 1.0;
      case TicketStatus.closed:
        return 1.0;
    }
  }

  Widget _buildEnhancedPriorityChip(TicketPriority priority,
      [bool isSmall = false]) {
    Color color;
    String text;
    IconData icon;

    switch (priority) {
      case TicketPriority.low:
        color = const Color(0xFF10B981);
        text = 'Baixa';
        icon = Icons.keyboard_arrow_down_rounded;
        break;
      case TicketPriority.normal:
        color = const Color(0xFF3B82F6);
        text = 'Normal';
        icon = Icons.remove_rounded;
        break;
      case TicketPriority.high:
        color = const Color(0xFFF59E0B);
        text = 'Alta';
        icon = Icons.keyboard_arrow_up_rounded;
        break;
      case TicketPriority.urgent:
        color = const Color(0xFFEF4444);
        text = 'Urgente';
        icon = Icons.priority_high_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 3 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isSmall ? 10 : 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: isSmall ? 9 : 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return AppTheme.successColor;
      case TicketStatus.inProgress:
        return AppTheme.warningColor;
      case TicketStatus.waitingCustomer:
        return AppTheme.secondaryColor;
      case TicketStatus.resolved:
        return AppTheme.primaryColor;
      case TicketStatus.closed:
        return AppTheme.getTextColor(context).withValues(alpha: 0.5);
    }
  }

  IconData _getStatusIcon(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Icons.check_circle;
      case TicketStatus.inProgress:
        return Icons.access_time;
      case TicketStatus.waitingCustomer:
        return Icons.person;
      case TicketStatus.resolved:
        return Icons.check_circle;
      case TicketStatus.closed:
        return Icons.close;
    }
  }

  Widget _buildPriorityChip(TicketPriority priority, [bool isSmall = false]) {
    Color color;
    String text;

    switch (priority) {
      case TicketPriority.low:
        color = Colors.green;
        text = 'Baixa';
        break;
      case TicketPriority.normal:
        color = Colors.blue;
        text = 'Normal';
        break;
      case TicketPriority.high:
        color = Colors.orange;
        text = 'Alta';
        break;
      case TicketPriority.urgent:
        color = Colors.red;
        text = 'Urgente';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isSmall ? 9 : 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
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

  Widget _buildStatCard(String label, int count, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 150;
        final fontSize = isSmall ? 16 : 20;
        final labelSize = isSmall ? 10 : 12;
        final padding = isSmall ? 8.0 : 12.0;

        return Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: padding,
              horizontal: 4,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: fontSize.toDouble(),
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: labelSize.toDouble(),
                      fontWeight: FontWeight.w500,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    final bool isActive = (label == 'Status' && _selectedStatus != null) ||
        (label == 'Prioridade' && _selectedPriority != null) ||
        (label == 'Categoria' && _selectedCategory != null);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 120;
        final fontSize = isSmall ? 10.0 : 11.0;
        final padding = isSmall ? 6.0 : 8.0;
        final iconSize = isSmall ? 10.0 : 11.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: isSmall ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : AppTheme.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? AppTheme.primaryColor.withValues(alpha: 0.3)
                        : AppTheme.getBorderColor(context),
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '$label: ',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? AppTheme.primaryColor
                              : AppTheme.getTextColor(context)
                                  .withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? AppTheme.primaryColor
                              : AppTheme.getTextColor(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: isSmall ? 2 : 3),
                    Icon(
                      Icons.list,
                      size: iconSize,
                      color: isActive
                          ? AppTheme.primaryColor
                          : AppTheme.getTextColor(context)
                              .withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClearFiltersChip() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedStatus = null;
                  _selectedPriority = null;
                  _selectedCategory = null;
                });
                final ticketStore = context.read<TicketStore>();
                ticketStore.clearFilters();
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.close,
                      size: 12,
                      color: AppTheme.errorColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Limpar filtros',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTicketsList(List<Ticket> tickets) {
    final screenWidth = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      onRefresh: () async {
        _loadTickets();
      },
      color: AppTheme.primaryColor,
      backgroundColor: AppTheme.getCardColor(context),
      child: screenWidth > 768
          ? _buildTabletTicketsList(tickets)
          : _buildMobileTicketsList(tickets),
    );
  }

  Widget _buildMobileTicketsList(List<Ticket> tickets) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _isListView
          ? _buildMobileListView(tickets)
          : _buildMobileGridView(tickets),
    );
  }

  Widget _buildMobileGridView(List<Ticket> tickets) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return RepaintBoundary(
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutCubic,
            child: TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 400 + (index * 50)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppTheme.spacing12),
                      child: Hero(
                        tag: 'ticket_${ticket.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: TicketCard(
                            ticket: ticket,
                            onTap: () => _navigateToTicketDetails(ticket),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileListView(List<Ticket> tickets) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return RepaintBoundary(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutCubic,
                child: TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 50)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppTheme.spacing12),
                          child: Hero(
                            tag: 'ticket_${ticket.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: _buildTicketListItem(ticket, constraints),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabletTicketsList(List<Ticket> tickets) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 50)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Hero(
                    tag: 'ticket_${ticket.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: TicketCard(
                        ticket: ticket,
                        onTap: () => _navigateToTicketDetails(ticket),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTabletHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.getBorderColor(context),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gerenciamento de Tickets',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextColor(context),
                      ),
                ),
                const SizedBox(height: 4),
                Consumer<TicketStore>(
                  builder: (context, ticketStore, child) {
                    return Text(
                      '${ticketStore.tickets.length} tickets encontrados',
                      style: TextStyle(
                        color: AppTheme.getTextColor(context)
                            .withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          _buildViewToggleButton(
            icon: _isListView ? Icons.grid_view : Icons.list,
            isActive: true,
            onTap: () => setState(() => _isListView = !_isListView),
            tooltip:
                _isListView ? 'Visualização em Grid' : 'Visualização em Lista',
          ),
        ],
      ),
    );
  }

  void _applySorting() {
    // Implementação simplificada - apenas atualiza o estado
    setState(() {
      // O sorting será aplicado na UI através do _sortBy
    });
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tickets',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Consumer<TicketStore>(
                    builder: (context, ticketStore, child) {
                      return Text(
                        '${ticketStore.tickets.length} ${ticketStore.tickets.length == 1 ? 'ticket' : 'tickets'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.getTextColor(context)
                                  .withValues(alpha: 0.7),
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _buildSortButton(),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.getBorderColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Tooltip(
                      message: _isListView
                          ? 'Visualização em Cards'
                          : 'Visualização em Lista',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _isListView = !_isListView;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Icon(
                            _isListView ? Icons.grid_view : Icons.list,
                            color: AppTheme.getTextColor(context),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildFilterButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSearchBar() {
    return AnimatedBuilder(
      animation: _searchFocusNode,
      builder: (context, child) {
        final bool isFocused = _searchFocusNode.hasFocus;
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.0, end: isFocused ? 1.0 : 0.0),
          curve: Curves.easeOutCubic,
          builder: (context, focusValue, child) {
            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.getCardColor(context),
                    Color.lerp(AppTheme.getCardColor(context),
                        const Color(0xFFF8FAFC), focusValue)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color.lerp(
                    Colors.grey[200]!,
                    const Color(0xFF3B82F6),
                    focusValue,
                  )!,
                  width: 1 + focusValue,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.lerp(
                      Colors.black.withValues(alpha: 0.05),
                      const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      focusValue,
                    )!,
                    blurRadius: 8 + (focusValue * 8),
                    offset: Offset(0, 2 + (focusValue * 4)),
                    spreadRadius: focusValue * 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Buscar tickets...',
                      hintStyle: TextStyle(
                        color: AppTheme.getTextColor(context)
                            .withValues(alpha: 0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.search_rounded,
                          color: Color.lerp(
                            AppTheme.getTextColor(context)
                                .withValues(alpha: 0.5),
                            const Color(0xFF3B82F6),
                            focusValue,
                          ),
                          size: 22,
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? AnimatedScale(
                              scale: 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.grey[600],
                                    size: 16,
                                  ),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
                                },
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getTextColor(context),
                    ),
                    onChanged: (value) {
                      setState(() {});
                      _applyFilters();
                    },
                  ),
                  // Chips de filtros ativos para mobile
                  if (hasActiveFilters) _buildMobileActiveFiltersChips(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMobileActiveFiltersChips() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          if (_selectedStatus != null)
            _buildMobileFilterChip(
              'Status: ${_getStatusText(_selectedStatus!)}',
              () => setState(() => _selectedStatus = null),
              const Color(0xFF10B981),
            ),
          if (_selectedPriority != null)
            _buildMobileFilterChip(
              'Prioridade: ${_getPriorityText(_selectedPriority!)}',
              () => setState(() => _selectedPriority = null),
              const Color(0xFFF59E0B),
            ),
          if (_selectedCategory != null)
            _buildMobileFilterChip(
              'Categoria: ${_getCategoryText(_selectedCategory!)}',
              () => setState(() => _selectedCategory = null),
              const Color(0xFF8B5CF6),
            ),
          if (_selectedAssignee != null)
            _buildMobileFilterChip(
              'Responsável: $_selectedAssignee',
              () => setState(() => _selectedAssignee = null),
              const Color(0xFF06B6D4),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterChip(
      String label, VoidCallback onRemove, Color color) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    onRemove();
                    _applyFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 10,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileStatsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spacing = constraints.maxWidth > 400 ? 12.0 : 8.0;
          return Row(
            children: [
              Flexible(
                flex: 1,
                child: Consumer<TicketStore>(
                  builder: (context, ticketStore, child) {
                    return _buildMobileStatCard(
                      'Total',
                      ticketStore.tickets.length.toString(),
                      Icons.confirmation_number_outlined,
                      AppTheme.primaryColor,
                    );
                  },
                ),
              ),
              SizedBox(width: spacing),
              Flexible(
                flex: 1,
                child: Consumer<TicketStore>(
                  builder: (context, ticketStore, child) {
                    return _buildMobileStatCard(
                      'Abertos',
                      ticketStore.tickets
                          .where((t) => t.status == TicketStatus.open)
                          .length
                          .toString(),
                      Icons.schedule,
                      Colors.orange,
                    );
                  },
                ),
              ),
              SizedBox(width: spacing),
              Flexible(
                flex: 1,
                child: Consumer<TicketStore>(
                  builder: (context, ticketStore, child) {
                    return _buildMobileStatCard(
                      'Resolvidos',
                      ticketStore.tickets
                          .where((t) => t.status == TicketStatus.resolved)
                          .length
                          .toString(),
                      Icons.check_circle_outline,
                      Colors.green,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                    fontSize: 14,
                  ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        AppTheme.getTextColor(context).withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 24,
          ),
          child: Row(
            children: [
              _buildFilterChip(
                'Status',
                _selectedStatus != null
                    ? _getStatusText(_selectedStatus!)
                    : 'Todos',
                () => _showStatusFilter(),
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                'Prioridade',
                _selectedPriority != null
                    ? _getPriorityText(_selectedPriority!)
                    : 'Todas',
                () => _showAdvancedFilters(),
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                'Categoria',
                _selectedCategory != null
                    ? _getCategoryText(_selectedCategory!)
                    : 'Todas',
                () => _showAdvancedFilters(),
              ),
              if (_selectedStatus != null ||
                  _selectedPriority != null ||
                  _selectedCategory != null) ...[
                const SizedBox(width: 6),
                _buildClearFiltersChip(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getBorderColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: PopupMenuButton<String>(
          initialValue: _sortBy,
          onSelected: (value) {
            setState(() {
              _sortBy = value;
            });
            _applyFilters();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'recent',
              child: Row(
                children: [
                  Icon(
                    Icons.list,
                    size: 16,
                    color: AppTheme.getTextColor(context),
                  ),
                  const SizedBox(width: 8),
                  const Text('Mais recentes'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'priority',
              child: Row(
                children: [
                  Icon(
                    Icons.list,
                    size: 16,
                    color: AppTheme.getTextColor(context),
                  ),
                  const SizedBox(width: 8),
                  const Text('Por prioridade'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'status',
              child: Row(
                children: [
                  Icon(
                    Icons.list,
                    size: 16,
                    color: AppTheme.getTextColor(context),
                  ),
                  const SizedBox(width: 8),
                  const Text('Por status'),
                ],
              ),
            ),
          ],
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.list,
                color: AppTheme.getTextColor(context),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _showFilters
            ? AppTheme.primaryColor
            : AppTheme.getBorderColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _showFilters
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _showFilters = !_showFilters;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: AnimatedRotation(
              turns: _showFilters ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.list,
                color: _showFilters
                    ? Colors.white
                    : AppTheme.getTextColor(context),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToTicketDetails(Ticket ticket) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TicketDetailsPage(ticket: ticket),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppTheme.getTextColor(context).withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.confirmation_number,
                        size: 48,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nenhum ticket encontrado',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.getTextColor(context),
                                fontWeight: FontWeight.w700,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Crie um novo ticket ou ajuste os filtros para encontrar o que procura',
                      style: TextStyle(
                        color: AppTheme.getTextColor(context)
                            .withValues(alpha: 0.7),
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _showCreateTicketDialog,
                      icon: const Icon(Icons.confirmation_number),
                      label: const Text('Criar Novo Ticket'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
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

  Widget _buildFloatingActionButton() {
    return Consumer<AuthStore>(
      builder: (context, authStore, child) {
        // Apenas clientes e agentes podem criar tickets
        if (authStore.appUser?.role == UserRole.customer ||
            authStore.appUser?.role == UserRole.agent) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: _showCreateTicketDialog,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(
                Icons.confirmation_number,
                size: 20,
              ),
              label: const Text(
                'Novo Ticket',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showCreateTicketDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.confirmation_number, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Criar Novo Ticket'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha como deseja criar seu ticket:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              icon: Icons.confirmation_number,
              title: 'Formulário Completo',
              subtitle: 'Tela dedicada com todas as opções',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NewTicketForm(),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.list,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showPriorityFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por Prioridade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todas'),
              onTap: () {
                setState(() {
                  _selectedPriority = null;
                });
                _applyFilters();
                Navigator.of(context).pop();
              },
            ),
            ...TicketPriority.values.map((priority) => ListTile(
                  title: Text(_getPriorityName(priority)),
                  onTap: () {
                    setState(() {
                      _selectedPriority = priority;
                    });
                    _applyFilters();
                    Navigator.of(context).pop();
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por Categoria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todas'),
              onTap: () {
                setState(() {
                  _selectedCategory = null;
                });
                _applyFilters();
                Navigator.of(context).pop();
              },
            ),
            ...TicketCategory.values.map((category) => ListTile(
                  title: Text(_getCategoryName(category)),
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                    _applyFilters();
                    Navigator.of(context).pop();
                  },
                )),
          ],
        ),
      ),
    );
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

  String _getCategoryName(TicketCategory category) {
    switch (category) {
      case TicketCategory.technical:
        return 'Técnico';
      case TicketCategory.billing:
        return 'Cobrança';
      case TicketCategory.general:
        return 'Geral';
      case TicketCategory.complaint:
        return 'Reclamação';
      case TicketCategory.feature:
        return 'Funcionalidade';
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return const Color(0xFF10B981); // Green
      case TicketPriority.normal:
        return const Color(0xFF3B82F6); // Blue
      case TicketPriority.high:
        return const Color(0xFFF59E0B); // Orange
      case TicketPriority.urgent:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData _getPriorityIcon(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return Icons.keyboard_arrow_down;
      case TicketPriority.normal:
        return Icons.remove;
      case TicketPriority.high:
        return Icons.keyboard_arrow_up;
      case TicketPriority.urgent:
        return Icons.warning;
    }
  }

  String _getStatusText(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'Aberto';
      case TicketStatus.inProgress:
        return 'Em Andamento';
      case TicketStatus.resolved:
        return 'Resolvido';
      case TicketStatus.closed:
        return 'Fechado';
      case TicketStatus.waitingCustomer:
        return 'Aguardando Cliente';
    }
  }

  void _openTicketDetails(Ticket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailsPage(ticket: ticket),
      ),
    );
  }

  Widget _buildEnhancedDesktopTicketsList(
      List<Ticket> tickets, double screenWidth, double screenHeight) {
    if (_isListView) {
      // Visualização em lista
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _openTicketDetails(ticket),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  constraints: const BoxConstraints(minHeight: 120),
                  decoration: BoxDecoration(
                    color: AppTheme.getCardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.getTextColor(context)
                            .withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color:
                          AppTheme.getTextColor(context).withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Conteúdo principal
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ticket.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '#${ticket.id.substring(0, 8)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.getTextColor(context)
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ticket.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.getTextColor(context)
                                    .withValues(alpha: 0.7),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  _getPriorityIcon(ticket.priority),
                                  size: 16,
                                  color: _getPriorityColor(ticket.priority),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getPriorityName(ticket.priority),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _getPriorityColor(ticket.priority),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  _formatDate(ticket.createdAt),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.getTextColor(context)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(ticket.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(ticket.status),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(ticket.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      // Visualização em grid (código original)
      final crossAxisCount = screenWidth > 1920
          ? 3
          : screenWidth > 1400
              ? 2
              : 1;

      final itemHeight = screenHeight > 1080 ? 280 : 240;

      return GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: (screenWidth / crossAxisCount - 48) / itemHeight,
        ),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _openTicketDetails(ticket),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.getTextColor(context)
                          .withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color:
                        AppTheme.getTextColor(context).withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.getTextColor(context)
                                .withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '#${ticket.id.substring(0, 8)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.getTextColor(context)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(ticket.status)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(ticket.status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(ticket.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.getTextColor(context)
                                    .withValues(alpha: 0.7),
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(
                                  _getPriorityIcon(ticket.priority),
                                  size: 16,
                                  color: _getPriorityColor(ticket.priority),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getPriorityName(ticket.priority),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getPriorityColor(ticket.priority),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDate(ticket.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.getTextColor(context)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }
}
