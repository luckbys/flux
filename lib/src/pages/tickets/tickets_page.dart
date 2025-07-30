import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/ticket.dart';
import '../../components/tickets/ticket_card.dart';
import '../../stores/ticket_store.dart';
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
  String _sortBy = 'recent'; // recent, priority, status
  bool _showFilters = false;
  bool _isGridView = false; // Toggle entre lista e grid

  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _sidebarAnimationController;

  // Animations
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _sidebarAnimation;

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

    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize animations
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _sidebarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOut,
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
    _sidebarAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    _fabAnimationController.dispose();
    _sidebarAnimationController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    final ticketStore = context.read<TicketStore>();
    await ticketStore.loadTickets();
  }

  void _showCreateTicketDialog() {
    showDialog(
      context: context,
      builder: (context) => const NewTicketForm(),
    );
  }

  void _applyFilters() {
    final ticketStore = context.read<TicketStore>();
    ticketStore.setFilters(
      status: _selectedStatus,
      priority: _selectedPriority,
    );
    if (_searchQuery.isNotEmpty) {
      ticketStore.search(_searchQuery);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedStatus = null;
      _selectedPriority = null;
      _sortBy = 'recent';
    });
    final ticketStore = context.read<TicketStore>();
    ticketStore.clearFilters();
  }

  bool get _isDesktop => MediaQuery.of(context).size.width > 768;

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) {
      return _buildDesktopLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: Consumer<TicketStore>(
        builder: (context, ticketStore, child) {
          if (ticketStore.isLoading) {
            return _buildLoadingState();
          }

          if (ticketStore.hasError) {
            return _buildErrorState(ticketStore);
          }

          return Row(
            children: [
              // Sidebar
              AnimatedBuilder(
                animation: _sidebarAnimation,
                builder: (context, child) {
                  return SizeTransition(
                    sizeFactor: _sidebarAnimation,
                    child: _buildSidebar(ticketStore),
                  );
                },
              ),
              // Main content
              Expanded(
                child: _buildMainContent(ticketStore),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showCreateTicketDialog,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          icon: Icon(PhosphorIcons.plus()),
          label: const Text('Novo Ticket'),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: Consumer<TicketStore>(
        builder: (context, ticketStore, child) {
          if (ticketStore.isLoading) {
            return _buildLoadingState();
          }

          if (ticketStore.hasError) {
            return _buildErrorState(ticketStore);
          }

          return _buildMainContent(ticketStore);
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showCreateTicketDialog,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          icon: Icon(PhosphorIcons.plus()),
          label: const Text('Novo Ticket'),
        ),
      ),
    );
  }

  Widget _buildSidebar(TicketStore ticketStore) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        border: Border(
          right: BorderSide(
            color: AppTheme.getBorderColor(context),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Sidebar header
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
                    Icon(
                      PhosphorIcons.ticket(),
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tickets',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.getTextColor(context),
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${ticketStore.tickets.length} tickets',
                  style: TextStyle(
                    color:
                        AppTheme.getTextColor(context).withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Filters section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search
                  _buildSidebarSearch(),
                  const SizedBox(height: 24),

                  // Status filter
                  _buildSidebarSection(
                    title: 'Status',
                    icon: PhosphorIcons.circle(),
                    children: _buildStatusOptions(),
                  ),
                  const SizedBox(height: 24),

                  // Priority filter
                  _buildSidebarSection(
                    title: 'Prioridade',
                    icon: PhosphorIcons.warning(),
                    children: _buildPriorityOptions(),
                  ),
                  const SizedBox(height: 24),

                  // Sort options
                  _buildSidebarSection(
                    title: 'Ordenar por',
                    icon: PhosphorIcons.sortAscending(),
                    children: _buildSortOptions(),
                  ),
                  const SizedBox(height: 24),

                  // Clear filters
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _clearFilters,
                      icon: Icon(PhosphorIcons.x()),
                      label: const Text('Limpar Filtros'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(color: AppTheme.errorColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSearch() {
    return TextField(
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
        ),
        prefixIcon: Icon(
          PhosphorIcons.magnifyingGlass(),
          color: AppTheme.getTextColor(context).withOpacity(0.5),
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                  _applyFilters();
                },
                icon: Icon(
                  PhosphorIcons.x(),
                  color: AppTheme.getTextColor(context).withOpacity(0.5),
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildSidebarSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppTheme.getTextColor(context).withOpacity(0.7),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  List<Widget> _buildStatusOptions() {
    return TicketStatus.values.map((status) {
      final isSelected = _selectedStatus == status;
      return InkWell(
        onTap: () {
          setState(() {
            _selectedStatus = isSelected ? null : status;
          });
          _applyFilters();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  status.name,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  PhosphorIcons.check(),
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPriorityOptions() {
    return TicketPriority.values.map((priority) {
      final isSelected = _selectedPriority == priority;
      return InkWell(
        onTap: () {
          setState(() {
            _selectedPriority = isSelected ? null : priority;
          });
          _applyFilters();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _getPriorityIcon(priority),
                color: _getPriorityColor(priority),
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  priority.name,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  PhosphorIcons.check(),
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildSortOptions() {
    final options = [
      {
        'value': 'recent',
        'label': 'Mais Recentes',
        'icon': PhosphorIcons.clock()
      },
      {
        'value': 'priority',
        'label': 'Prioridade',
        'icon': PhosphorIcons.warning()
      },
      {'value': 'status', 'label': 'Status', 'icon': PhosphorIcons.circle()},
    ];

    return options.map((option) {
      final isSelected = _sortBy == option['value'];
      return InkWell(
        onTap: () {
          setState(() {
            _sortBy = option['value'] as String;
          });
          _applyFilters();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                option['icon'] as IconData,
                color: AppTheme.getTextColor(context).withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option['label'] as String,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  PhosphorIcons.check(),
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Carregando tickets...',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aguarde um momento',
              style: TextStyle(
                color: AppTheme.getTextColor(context).withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(TicketStore ticketStore) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.getTextColor(context).withOpacity(0.1),
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
                  color: AppTheme.errorColor.withOpacity(0.1),
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.getTextColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                ticketStore.errorMessage ?? 'Erro desconhecido',
                style: TextStyle(
                  color: AppTheme.getTextColor(context).withOpacity(0.7),
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
      ),
    );
  }

  Widget _buildMainContent(TicketStore ticketStore) {
    final tickets = ticketStore.tickets;
    final isEmpty = tickets.isEmpty;

    return Column(
      children: [
        if (!_isDesktop) _buildHeader(),
        if (!_isDesktop && _showFilters) _buildFilters(),
        Expanded(
          child: isEmpty ? _buildEmptyState() : _buildTicketsContent(tickets),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tickets',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.getTextColor(context),
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Consumer<TicketStore>(
                      builder: (context, ticketStore, child) {
                        return Text(
                          '${ticketStore.tickets.length} tickets encontrados',
                          style: TextStyle(
                            color:
                                AppTheme.getTextColor(context).withOpacity(0.7),
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                icon: Icon(
                  _showFilters
                      ? PhosphorIcons.funnel()
                      : PhosphorIcons.funnelSimple(),
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getBorderColor(context),
        ),
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
            color: AppTheme.getTextColor(context).withOpacity(0.5),
          ),
          prefixIcon: Icon(
            PhosphorIcons.magnifyingGlass(),
            color: AppTheme.getTextColor(context).withOpacity(0.5),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _applyFilters();
                  },
                  icon: Icon(
                    PhosphorIcons.x(),
                    color: AppTheme.getTextColor(context).withOpacity(0.5),
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
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getBorderColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.funnel(),
                color: AppTheme.getTextColor(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtros',
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Limpar',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatusFilter(),
        _buildPriorityFilter(),
        _buildSortFilter(),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return FilterChip(
      label: Text(_selectedStatus?.name ?? 'Status'),
      selected: _selectedStatus != null,
      onSelected: (selected) {
        if (selected) {
          _showStatusFilter();
        } else {
          setState(() {
            _selectedStatus = null;
          });
          _applyFilters();
        }
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildPriorityFilter() {
    return FilterChip(
      label: Text(_selectedPriority?.name ?? 'Prioridade'),
      selected: _selectedPriority != null,
      onSelected: (selected) {
        if (selected) {
          _showPriorityFilter();
        } else {
          setState(() {
            _selectedPriority = null;
          });
          _applyFilters();
        }
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildSortFilter() {
    return FilterChip(
      label: Text(_getSortLabel()),
      selected: true,
      onSelected: (selected) {
        _showSortFilter();
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'recent':
        return 'Mais Recentes';
      case 'priority':
        return 'Prioridade';
      case 'status':
        return 'Status';
      default:
        return 'Ordenar';
    }
  }

  void _showStatusFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TicketStatus.values.map((status) {
            return ListTile(
              title: Text(status.name),
              onTap: () {
                setState(() {
                  _selectedStatus = status;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            );
          }).toList(),
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
          children: TicketPriority.values.map((priority) {
            return ListTile(
              title: Text(priority.name),
              onTap: () {
                setState(() {
                  _selectedPriority = priority;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSortFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ordenar por'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Mais Recentes'),
              leading: Icon(PhosphorIcons.clock()),
              onTap: () {
                setState(() {
                  _sortBy = 'recent';
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Prioridade'),
              leading: Icon(PhosphorIcons.warning()),
              onTap: () {
                setState(() {
                  _sortBy = 'priority';
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Status'),
              leading: Icon(PhosphorIcons.circle()),
              onTap: () {
                setState(() {
                  _sortBy = 'status';
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.ticket(),
              size: 64,
              color: AppTheme.getTextColor(context).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum ticket encontrado',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie seu primeiro ticket para começar',
              style: TextStyle(
                color: AppTheme.getTextColor(context).withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showCreateTicketDialog,
              icon: Icon(PhosphorIcons.plus()),
              label: const Text('Criar Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
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

  Widget _buildTicketsContent(List<Ticket> tickets) {
    return Column(
      children: [
        // Toolbar para desktop
        if (_isDesktop) _buildDesktopToolbar(tickets),
        // Content
        Flexible(
          child: _isGridView
              ? _buildTicketsGrid(tickets)
              : _buildTicketsList(tickets),
        ),
      ],
    );
  }

  Widget _buildDesktopToolbar(List<Ticket> tickets) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Expanded(
            child: Text(
              '${tickets.length} tickets encontrados',
              style: TextStyle(
                color: AppTheme.getTextColor(context).withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          // View toggle
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isGridView = false;
                  });
                },
                icon: Icon(
                  PhosphorIcons.list(),
                  color: !_isGridView
                      ? AppTheme.primaryColor
                      : AppTheme.getTextColor(context).withOpacity(0.5),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isGridView = true;
                  });
                },
                icon: Icon(
                  PhosphorIcons.gridFour(),
                  color: _isGridView
                      ? AppTheme.primaryColor
                      : AppTheme.getTextColor(context).withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsList(List<Ticket> tickets) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TicketCard(
            ticket: ticket,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TicketDetailsPage(ticket: ticket),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTicketsGrid(List<Ticket> tickets) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _isDesktop ? 3 : 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _buildGridTicketCard(ticket);
      },
    );
  }

  Widget _buildGridTicketCard(Ticket ticket) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailsPage(ticket: ticket),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ticket.status.name,
                      style: TextStyle(
                        color: _getStatusColor(ticket.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _getPriorityIcon(ticket.priority),
                    color: _getPriorityColor(ticket.priority),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.title,
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                ticket.description,
                style: TextStyle(
                  color: AppTheme.getTextColor(context).withOpacity(0.7),
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    PhosphorIcons.clock(),
                    size: 14,
                    color: AppTheme.getTextColor(context).withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: TextStyle(
                      color: AppTheme.getTextColor(context).withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }
}
