import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
  String _sortBy = 'recent'; // recent, priority, status
  bool _showFilters = false;

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
      duration: const Duration(milliseconds: 800),
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

    return Scaffold(
      backgroundColor:
          isDesktop ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
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

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar com filtros e estatísticas
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            boxShadow: [
              BoxShadow(
                color: AppTheme.getTextColor(context).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDesktopSidebar(),
            ],
          ),
        ),
        // Conteúdo principal
        Expanded(
          child: Column(
            children: [
              _buildDesktopHeader(),
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

                          return _buildDesktopTicketsList(ticketStore.tickets);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _headerSlideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _headerSlideAnimation.value),
              child: _buildMobileHeader(),
            );
          },
        ),
        _buildMobileSearchBar(),
        _buildMobileStatsRow(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _showFilters ? null : 0,
          child: _showFilters ? _buildMobileFilters() : const SizedBox.shrink(),
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
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
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
                    color: AppTheme.getTextColor(context).withOpacity(0.6),
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
                      child: Icon(
                        PhosphorIcons.warning(),
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
                      icon: Icon(PhosphorIcons.arrowClockwise()),
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

  Widget _buildDesktopSidebar() {
    return Expanded(
      child: Column(
        children: [
          // Header do sidebar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.getBorderColor(context),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        PhosphorIcons.ticket(),
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tickets',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Consumer<TicketStore>(
                  builder: (context, ticketStore, child) {
                    return Text(
                      '${ticketStore.tickets.length} de ${ticketStore.allTickets.length} tickets',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getTextColor(context)
                            .withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Estatísticas
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estatísticas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDesktopStatsGrid(),
              ],
            ),
          ),
          // Filtros
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDesktopFilters(),
              ],
            ),
          ),
          // Botão de criar ticket
          Container(
            padding: const EdgeInsets.all(24),
            child: Consumer<AuthStore>(
              builder: (context, authStore, child) {
                if (authStore.appUser?.role == UserRole.customer ||
                    authStore.appUser?.role == UserRole.agent) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showCreateTicketDialog,
                      icon: Icon(PhosphorIcons.plus()),
                      label: const Text('Novo Ticket'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 73, 200, 50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
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
            child: _buildSearchBar(),
          ),
          const SizedBox(width: 16),
          Container(
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
                          PhosphorIcons.clock(),
                          size: 16,
                          color: AppTheme.getTextColor(context),
                        ),
                        const SizedBox(width: 6),
                        const Text('Mais recentes'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'priority',
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.flag(),
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
                          PhosphorIcons.circleHalf(),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Icon(
                      PhosphorIcons.sortAscending(),
                      color: AppTheme.getTextColor(context),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _searchFocusNode.hasFocus
              ? AppTheme.primaryColor
              : AppTheme.getBorderColor(context),
          width: _searchFocusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: _searchFocusNode.hasFocus
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Buscar tickets...',
          hintStyle: TextStyle(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              PhosphorIcons.magnifyingGlass(),
              color: _searchFocusNode.hasFocus
                  ? AppTheme.primaryColor
                  : AppTheme.getTextColor(context).withValues(alpha: 0.5),
              size: 20,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                      _applyFilters();
                    },
                    icon: Icon(
                      PhosphorIcons.x(),
                      color:
                          AppTheme.getTextColor(context).withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Consumer<TicketStore>(
      builder: (context, ticketStore, child) {
        final stats = ticketStore.ticketStats;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildStatCard(
                'Total',
                stats['total'] ?? 0,
                AppTheme.primaryColor,
              ),
              const SizedBox(width: AppTheme.spacing12),
              _buildStatCard(
                'Abertos',
                stats['open'] ?? 0,
                AppTheme.successColor,
              ),
              const SizedBox(width: AppTheme.spacing12),
              _buildStatCard(
                'Em Andamento',
                stats['in_progress'] ?? 0,
                AppTheme.warningColor,
              ),
              const SizedBox(width: AppTheme.spacing12),
              _buildStatCard(
                'Resolvidos',
                stats['resolved'] ?? 0,
                AppTheme.secondaryColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopStatsGrid() {
    return Consumer<TicketStore>(
      builder: (context, ticketStore, child) {
        final stats = ticketStore.ticketStats;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDesktopStatCard(
                    'Total',
                    stats['total'] ?? 0,
                    AppTheme.primaryColor,
                    PhosphorIcons.ticket(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDesktopStatCard(
                    'Abertos',
                    stats['open'] ?? 0,
                    AppTheme.successColor,
                    PhosphorIcons.circleNotch(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDesktopStatCard(
                    'Em Andamento',
                    stats['in_progress'] ?? 0,
                    AppTheme.warningColor,
                    PhosphorIcons.clock(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDesktopStatCard(
                    'Resolvidos',
                    stats['resolved'] ?? 0,
                    AppTheme.secondaryColor,
                    PhosphorIcons.checkCircle(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopStatCard(
      String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFilters() {
    return Column(
      children: [
        _buildDesktopFilterDropdown(
          'Status',
          _selectedStatus?.name ?? 'Todos',
          () => _showStatusFilter(),
        ),
        const SizedBox(height: 12),
        _buildDesktopFilterDropdown(
          'Prioridade',
          _selectedPriority?.name ?? 'Todas',
          () => _showPriorityFilter(),
        ),
        const SizedBox(height: 12),
        _buildDesktopFilterDropdown(
          'Categoria',
          _selectedCategory?.name ?? 'Todas',
          () => _showCategoryFilter(),
        ),
        if (_selectedStatus != null ||
            _selectedPriority != null ||
            _selectedCategory != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedStatus = null;
                  _selectedPriority = null;
                  _selectedCategory = null;
                });
                final ticketStore = context.read<TicketStore>();
                ticketStore.clearFilters();
              },
              icon: Icon(
                PhosphorIcons.x(),
                size: 16,
                color: AppTheme.errorColor,
              ),
              label: const Text(
                'Limpar filtros',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopFilterDropdown(
      String label, String value, VoidCallback onTap) {
    final bool isActive = (label == 'Status' && _selectedStatus != null) ||
        (label == 'Prioridade' && _selectedPriority != null) ||
        (label == 'Categoria' && _selectedCategory != null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : AppTheme.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? AppTheme.primaryColor.withValues(alpha: 0.3)
                  : AppTheme.getBorderColor(context),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          AppTheme.getTextColor(context).withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppTheme.primaryColor
                          : AppTheme.getTextColor(context),
                    ),
                  ),
                ],
              ),
              Icon(
                PhosphorIcons.caretDown(),
                size: 16,
                color: isActive
                    ? AppTheme.primaryColor
                    : AppTheme.getTextColor(context).withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTicketsList(List<Ticket> tickets) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
        ),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return TweenAnimationBuilder<double>(
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
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacing12,
          horizontal: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    final bool isActive = (label == 'Status' && _selectedStatus != null) ||
        (label == 'Prioridade' && _selectedPriority != null) ||
        (label == 'Categoria' && _selectedCategory != null);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing10,
              vertical: AppTheme.spacing6,
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
                Text(
                  '$label: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? AppTheme.primaryColor
                        : AppTheme.getTextColor(context).withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? AppTheme.primaryColor
                        : AppTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    PhosphorIcons.caretDown(),
                    size: 12,
                    color: isActive
                        ? AppTheme.primaryColor
                        : AppTheme.getTextColor(context).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.x(),
                      size: 12,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(width: 4),
                    const Text(
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
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return AnimatedContainer(
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
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
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
        return TweenAnimationBuilder<double>(
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
        );
      },
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                                  .withOpacity(0.7),
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
                _buildFilterButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar tickets...',
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.getTextColor(context).withOpacity(0.5),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppTheme.getTextColor(context).withOpacity(0.5),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {});
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildMobileStatsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
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
          const SizedBox(width: 12),
          Expanded(
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
          const SizedBox(width: 12),
          Expanded(
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
      ),
    );
  }

  Widget _buildMobileStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.getTextColor(context).withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'Status',
              _selectedStatus?.name ?? 'Todos',
              () => _showStatusFilter(),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Prioridade',
              _selectedPriority?.name ?? 'Todas',
              () => _showPriorityFilter(),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Categoria',
              _selectedCategory?.name ?? 'Todas',
              () => _showCategoryFilter(),
            ),
            if (_selectedStatus != null ||
                _selectedPriority != null ||
                _selectedCategory != null) ...[
              const SizedBox(width: 8),
              _buildClearFiltersChip(),
            ],
          ],
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
                    PhosphorIcons.clock(),
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
                    PhosphorIcons.flag(),
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
                    PhosphorIcons.circleHalf(),
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
                PhosphorIcons.sortAscending(),
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
                  color: AppTheme.primaryColor.withOpacity(0.3),
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
                PhosphorIcons.funnel(),
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
                      child: Icon(
                        PhosphorIcons.ticket(),
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
                      icon: Icon(PhosphorIcons.plus()),
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
              icon: Icon(
                PhosphorIcons.plus(),
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
        title: Row(
          children: [
            Icon(PhosphorIcons.plus(), color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Criar Novo Ticket'),
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
              icon: PhosphorIcons.ticket(),
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
              PhosphorIcons.arrowRight(),
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 600),
          child: TicketForm(
            onSubmit: (formData) async {
              try {
                final authStore = context.read<AuthStore>();
                final ticketStore = context.read<TicketStore>();

                if (authStore.appUser?.id == null) {
                  throw Exception('Usuário não autenticado');
                }

                // Criar o ticket usando o TicketStore
                final ticket = await ticketStore.createTicket(
                  title: formData.title,
                  description: formData.description,
                  customerId: authStore.appUser!.id,
                  priority: formData.priority,
                  category: formData.category,
                  assignedTo: formData.assignedAgent?.id,
                );

                if (ticket != null) {
                  Navigator.of(context).pop();
                  _loadTickets(); // Recarregar lista
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Ticket "${formData.title}" criado com sucesso!'),
                      backgroundColor: const Color(0xFF22C55E),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao criar ticket. Tente novamente.'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao criar ticket: $e'),
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _showStatusFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todos'),
              onTap: () {
                setState(() {
                  _selectedStatus = null;
                });
                _applyFilters();
                Navigator.of(context).pop();
              },
            ),
            ...TicketStatus.values.map((status) => ListTile(
                  title: Text(_getStatusName(status)),
                  onTap: () {
                    setState(() {
                      _selectedStatus = status;
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

  String _getStatusName(TicketStatus status) {
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
}
