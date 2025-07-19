import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../../components/tickets/ticket_card.dart';
import '../../components/tickets/ticket_form.dart';
import '../../components/ui/status_badge.dart';
import '../../stores/ticket_store.dart';
import '../../stores/auth_store.dart';
import '../../utils/color_extensions.dart';
import 'ticket_details_page.dart';
import '../../styles/app_theme.dart';
import '../../styles/app_constants.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  String _searchQuery = '';
  TicketStatus? _selectedStatus;
  TicketPriority? _selectedPriority;
  TicketCategory? _selectedCategory;
  String _sortBy = 'recent'; // recent, priority, status
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTickets();
    });
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

  int _getPriorityWeight(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.urgent:
        return 4;
      case TicketPriority.high:
        return 3;
      case TicketPriority.normal:
        return 2;
      case TicketPriority.low:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_showFilters) _buildFilters(),
            Expanded(
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
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Carregando tickets...',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(TicketStore ticketStore) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.warning(),
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar tickets',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            ticketStore.errorMessage ?? 'Erro desconhecido',
            style: TextStyle(
              color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadTickets,
            icon: Icon(PhosphorIcons.arrowClockwise()),
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing24),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tickets',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextColor(context),
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Consumer<TicketStore>(
                    builder: (context, ticketStore, child) {
                      return Text(
                        '${ticketStore.tickets.length} de ${ticketStore.allTickets.length} tickets',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                      );
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _showFilters
                          ? AppTheme.primaryColor
                          : AppTheme.getBorderColor(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                      icon: Icon(
                        PhosphorIcons.funnel(),
                        color: _showFilters
                            ? Colors.white
                            : AppTheme.getTextColor(context),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.getBorderColor(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PopupMenuButton<String>(
                      initialValue: _sortBy,
                      onSelected: (value) {
                        setState(() {
                          _sortBy = value;
                        });
                        _applyFilters();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'recent',
                          child: Text('Mais recentes'),
                        ),
                        const PopupMenuItem(
                          value: 'priority',
                          child: Text('Por prioridade'),
                        ),
                        const PopupMenuItem(
                          value: 'status',
                          child: Text('Por status'),
                        ),
                      ],
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
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildSearchBar(),
          const SizedBox(height: AppTheme.spacing16),
          _buildStatsRow(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getBorderColor(context),
        ),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Buscar por título, cliente ou ID...',
          hintStyle: TextStyle(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            PhosphorIcons.magnifyingGlass(),
            color: AppTheme.getTextColor(context).withValues(alpha: 0.5),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Consumer<TicketStore>(
      builder: (context, ticketStore, child) {
        final stats = ticketStore.ticketStats;

        return Row(
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
        );
      },
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
          color: color.withValues(alpha:  0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha:  0.2),
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
                color: color.withValues(alpha:  0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.getBorderColor(context),
            width: 1,
          ),
        ),
      ),
      child: Wrap(
        spacing: AppTheme.spacing12,
        runSpacing: AppTheme.spacing8,
        children: [
          _buildFilterChip(
            'Status',
            _selectedStatus?.name ?? 'Todos',
            () => _showStatusFilter(),
          ),
          _buildFilterChip(
            'Prioridade',
            _selectedPriority?.name ?? 'Todas',
            () => _showPriorityFilter(),
          ),
          _buildFilterChip(
            'Categoria',
            _selectedCategory?.name ?? 'Todas',
            () => _showCategoryFilter(),
          ),
          if (_selectedStatus != null ||
              _selectedPriority != null ||
              _selectedCategory != null)
            _buildClearFiltersChip(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.getBorderColor(context),
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
                color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              PhosphorIcons.caretDown(),
              size: 12,
              color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearFiltersChip() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = null;
          _selectedPriority = null;
          _selectedCategory = null;
        });
        final ticketStore = context.read<TicketStore>();
        ticketStore.clearFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha:  0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha:  0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.x(),
              size: 12,
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(width: 4),
            const Text(
              'Limpar filtros',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList(List<Ticket> tickets) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadTickets();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
            child: TicketCard(
              ticket: ticket,
              onTap: () => _navigateToTicketDetails(ticket),
            ),
          );
        },
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.ticket(),
            size: 64,
            color: const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum ticket encontrado',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crie um novo ticket ou ajuste os filtros',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateTicketDialog,
            icon: Icon(PhosphorIcons.plus()),
            label: const Text('Criar Ticket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<AuthStore>(
      builder: (context, authStore, child) {
        // Apenas clientes e agentes podem criar tickets
        if (authStore.appUser?.role == UserRole.customer ||
            authStore.appUser?.role == UserRole.agent) {
          return FloatingActionButton.extended(
            onPressed: _showCreateTicketDialog,
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: Icon(PhosphorIcons.plus()),
            label: const Text(
              'Novo Ticket',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          );
        }
        return Container();
      },
    );
  }

  void _showCreateTicketDialog() {
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
                      content: Text('Ticket "${formData.title}" criado com sucesso!'),
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
