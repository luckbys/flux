import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../stores/quote_store.dart';
import '../models/quote.dart';
import '../styles/app_theme.dart';
import '../utils/color_extensions.dart';
import '../components/loading_indicator.dart';
import '../components/error_message.dart';
import '../components/empty_state.dart';
import 'quote_detail_page.dart';
import 'quote_form_page.dart';

class QuotesPage extends StatefulWidget {
  const QuotesPage({super.key});

  @override
  State<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = false;
  
  // Filtros avançados
  String? _selectedStatusFilter;
  DateTimeRange? _selectedDateRange;
  double? _minValue;
  double? _maxValue;
  
  // Ordenação
  String _sortBy = 'date'; // 'date', 'value', 'client', 'status'
  bool _sortAscending = false;
  
  // Busca avançada
  String _searchQuery = '';
  bool _isAdvancedSearch = false;
  final TextEditingController _clientSearchController = TextEditingController();
  final TextEditingController _minValueController = TextEditingController();
  final TextEditingController _maxValueController = TextEditingController();
  
  // Pull to refresh
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    
    // Carregar orçamentos ao inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuoteStore>().loadQuotes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _clientSearchController.dispose();
    _minValueController.dispose();
    _maxValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.darken(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToQuoteForm(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(
            Icons.add_circle,
            color: Colors.white,
            size: 24,
          ),
          label: const Text(
            'Novo Orçamento',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 280,
          height: double.infinity,
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
              _buildSidebarHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSidebarStats(),
                      _buildSidebarFilters(),
                    ],
                  ),
                ),
              ),
              _buildSidebarActions(),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: Column(
            children: [
              _buildDesktopHeader(),
              _buildDesktopToolbar(),
              Expanded(
                child: _buildTabBarView(),
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
        _buildCompactHeader(),
        _buildCompactSearchAndFilters(),
        _buildTabBar(),
        Expanded(
          child: _buildTabBarView(),
        ),
      ],
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.getBorderColor(context), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long,
                size: 24,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Orçamentos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.getTextColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Gerencie propostas',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarStats() {
    return Consumer<QuoteStore>(
      builder: (context, quoteStore, child) {
        final stats = quoteStore.quoteStats;
        
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estatísticas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildSidebarStatItem('Total', stats['total'].toString(), Icons.receipt_long, AppTheme.primaryColor),
              const SizedBox(height: 8),
              _buildSidebarStatItem('Pendentes', stats['pending'].toString(), Icons.pending, AppTheme.warningColor),
              const SizedBox(height: 8),
              _buildSidebarStatItem('Aprovados', stats['approved'].toString(), Icons.check_circle, AppTheme.successColor),
              const SizedBox(height: 8),
              _buildSidebarStatItem('Rejeitados', stats['rejected'].toString(), Icons.cancel, AppTheme.errorColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarStatItem(String label, String value, IconData icon, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textColor.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros Rápidos',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSidebarFilterItem('Todos', null, Icons.list),
          _buildSidebarFilterItem('Rascunhos', QuoteStatus.draft, Icons.edit),
          _buildSidebarFilterItem('Pendentes', QuoteStatus.pending, Icons.pending),
          _buildSidebarFilterItem('Aprovados', QuoteStatus.approved, Icons.check_circle),
          _buildSidebarFilterItem('Rejeitados', QuoteStatus.rejected, Icons.cancel),
          _buildSidebarFilterItem('Expirados', null, Icons.schedule, showExpired: true),
          _buildSidebarFilterItem('Convertidos', QuoteStatus.converted, Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildSidebarFilterItem(String label, QuoteStatus? status, IconData icon, {bool showExpired = false}) {
    final isSelected = _tabController.index == _getTabIndex(status, showExpired);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1.5) : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _tabController.animateTo(_getTabIndex(status, showExpired)),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primaryColor.withOpacity(0.2)
                          : AppTheme.textColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _getTabIndex(QuoteStatus? status, bool showExpired) {
    if (showExpired) return 5;
    if (status == null) return 0;
    switch (status) {
      case QuoteStatus.draft: return 1;
      case QuoteStatus.pending: return 2;
      case QuoteStatus.approved: return 3;
      case QuoteStatus.rejected: return 4;
      case QuoteStatus.converted: return 6;
      case QuoteStatus.expired: return 5;
    }
  }

  Widget _buildSidebarActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.darken(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToQuoteForm(),
                  icon: const Icon(Icons.add_circle, size: 20),
                  label: const Text(
                    'Novo Orçamento',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: OutlinedButton.icon(
                  onPressed: () => _showFilterDialog(),
                  icon: Icon(
                    Icons.tune,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  label: Text(
                    'Filtros Avançados',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.05),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _isAdvancedSearch 
                          ? 'Busca avançada ativa - use os filtros abaixo'
                          : '🔍 Buscar por cliente, descrição ou número do orçamento...',
                      hintStyle: TextStyle(
                        color: AppTheme.getTextColor(context).withOpacity(0.6),
                        fontSize: 14,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _isAdvancedSearch ? Icons.manage_search : Icons.search,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                _performAdvancedSearch();
                              },
                              icon: Icon(
                                Icons.clear,
                                color: AppTheme.getTextColor(context).withOpacity(0.6),
                                size: 20,
                              ),
                            ),
                          IconButton(
                            onPressed: _toggleAdvancedSearch,
                            icon: Icon(
                              _isAdvancedSearch ? Icons.search_off : Icons.tune,
                              color: _isAdvancedSearch ? AppTheme.primaryColor : AppTheme.getTextColor(context).withOpacity(0.6),
                              size: 20,
                            ),
                            tooltip: _isAdvancedSearch ? 'Busca simples' : 'Busca avançada',
                          ),
                        ],
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _isAdvancedSearch 
                              ? AppTheme.primaryColor.withOpacity(0.5)
                              : AppTheme.borderColor.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _isAdvancedSearch 
                              ? AppTheme.primaryColor.withOpacity(0.5)
                              : AppTheme.borderColor.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      if (_isAdvancedSearch) {
                        _performAdvancedSearch();
                      } else {
                        context.read<QuoteStore>().setSearchQuery(value);
                      }
                    },
                  ),
                  if (_isAdvancedSearch) ...[
                    const SizedBox(height: 12),
                    _buildAdvancedSearchFilters(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: IconButton(
              onPressed: () => context.read<QuoteStore>().loadQuotes(forceRefresh: true),
              icon: Icon(
                Icons.refresh,
                color: AppTheme.primaryColor,
              ),
              tooltip: 'Atualizar lista',
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Consumer<QuoteStore>(
            builder: (context, quoteStore, child) {
              final currentTab = _getCurrentTabLabel();
              return Text(
                currentTab,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          const SizedBox(width: 24),
          // Filtros ativos
          if (_hasActiveFilters()) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_alt,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Filtros Ativos',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _clearAllFilters,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
          const Spacer(),
          // Botões de ordenação
          _buildSortButton('Data', 'date'),
          const SizedBox(width: 8),
          _buildSortButton('Valor', 'value'),
          const SizedBox(width: 8),
          _buildSortButton('Cliente', 'client'),
          const SizedBox(width: 8),
          _buildSortButton('Status', 'status'),
          const SizedBox(width: 16),
          // Botões de ação
          _buildToolbarButton(
            icon: Icons.tune,
            label: 'Filtros',
            onPressed: _showAdvancedFiltersDialog,
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.file_download,
            label: 'Exportar',
            onPressed: _showExportDialog,
          ),
          const SizedBox(width: 16),
          ToggleButtons(
            isSelected: [!_isGridView, _isGridView],
            onPressed: (index) {
              setState(() {
                _isGridView = index == 1;
              });
            },
            borderRadius: BorderRadius.circular(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            children: const [
              Icon(Icons.view_list),
              Icon(Icons.grid_view),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedStatusFilter != null ||
           _selectedDateRange != null ||
           _minValue != null ||
           _maxValue != null ||
           _searchQuery.isNotEmpty;
  }

  Widget _buildSortButton(String label, String sortBy) {
    final isActive = _sortBy == sortBy;
    return GestureDetector(
      onTap: () => _sortQuotes(sortBy),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppTheme.primaryColor.withOpacity(0.3) : AppTheme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primaryColor : AppTheme.getTextColor(context),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            if (isActive)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: AppTheme.getTextColor(context).withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCurrentTabLabel() {
    switch (_tabController.index) {
      case 0: return 'Todos os Orçamentos';
      case 1: return 'Rascunhos';
      case 2: return 'Pendentes';
      case 3: return 'Aprovados';
      case 4: return 'Rejeitados';
      case 5: return 'Expirados';
      case 6: return 'Convertidos';
      default: return 'Orçamentos';
    }
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    
    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppTheme.primaryColor.withOpacity(0.02),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.15),
                  AppTheme.primaryColor.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.receipt_long,
              size: isDesktop ? 36 : 32,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orçamentos',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.getTextColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: isDesktop ? 28 : 24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gerencie seus orçamentos e propostas comerciais',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.getTextColor(context).withOpacity(0.7),
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: _buildStatsCards(),
            ),
          ],
        ],
      ),
    );
  }

  // Header compacto para mobile
  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.receipt_long,
              size: 20,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Orçamentos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          // Estatísticas compactas
          Consumer<QuoteStore>(
            builder: (context, quoteStore, child) {
              final stats = quoteStore.quoteStats;
              return Row(
                children: [
                  _buildCompactStat('Total', stats['total'].toString(), AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  _buildCompactStat('Pendentes', stats['pending'].toString(), AppTheme.warningColor),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Consumer<QuoteStore>(
      builder: (context, quoteStore, child) {
        final stats = quoteStore.quoteStats;
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                stats['total'].toString(),
                Icons.receipt_long,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Pendentes',
                stats['pending'].toString(),
                Icons.pending,
                AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Aprovados',
                stats['approved'].toString(),
                Icons.check_circle,
                AppTheme.successColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.getTextColor(context).withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768;
    
    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : 20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: isDesktop ? Row(
        children: [
          Expanded(
            child: _buildEnhancedSearchField(),
          ),
          const SizedBox(width: 20),
          _buildEnhancedFilterButton(),
          const SizedBox(width: 16),
          _buildEnhancedRefreshButton(),
        ],
      ) : Column(
        children: [
          _buildEnhancedSearchField(),
          const SizedBox(height: 16),
          if (isTablet)
            Row(
              children: [
                Expanded(child: _buildEnhancedFilterButton()),
                const SizedBox(width: 16),
                Expanded(child: _buildEnhancedRefreshButton()),
              ],
            )
          else
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _buildEnhancedFilterButton(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildEnhancedRefreshButton(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Versão compacta para mobile
  Widget _buildCompactSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactSearchField(),
          ),
          const SizedBox(width: 12),
          _buildCompactFilterButton(),
          const SizedBox(width: 8),
          _buildCompactRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildCompactSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar orçamentos...',
          hintStyle: TextStyle(
            color: AppTheme.getTextColor(context).withOpacity(0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.primaryColor.withOpacity(0.7),
            size: 20,
          ),
          filled: true,
          fillColor: AppTheme.getSurfaceColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        onChanged: (value) {
          context.read<QuoteStore>().setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildCompactFilterButton() {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: IconButton(
        onPressed: () => _showFilterDialog(),
        icon: Icon(
          Icons.tune,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildCompactRefreshButton() {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => context.read<QuoteStore>().loadQuotes(forceRefresh: true),
        icon: const Icon(
          Icons.refresh,
          color: Colors.white,
          size: 20,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildEnhancedSearchField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '🔍 Buscar por cliente, descrição, número ou valor...',
          hintStyle: TextStyle(
            color: AppTheme.textColor.withOpacity(0.6),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.15),
                  AppTheme.primaryColor.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.search_rounded,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
          filled: true,
          fillColor: AppTheme.getCardColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppTheme.borderColor.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppTheme.borderColor.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        ),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        onChanged: (value) {
          context.read<QuoteStore>().setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildEnhancedFilterButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: OutlinedButton.icon(
        onPressed: () => _showFilterDialog(),
        icon: Icon(
          Icons.tune_rounded,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        label: Text(
          'Filtros',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.06),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.darken(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => context.read<QuoteStore>().loadQuotes(forceRefresh: true),
        icon: const Icon(
          Icons.refresh_rounded,
          color: Colors.white,
          size: 20,
        ),
        label: const Text(
          'Atualizar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }



  Widget _buildTabBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    
    return Container(
      color: AppTheme.getCardColor(context),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.getTextColor(context).withOpacity(0.7),
        indicatorColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          fontSize: isDesktop ? 14 : 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: isDesktop ? 14 : 12,
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 8),
        indicatorPadding: EdgeInsets.symmetric(horizontal: isDesktop ? 8 : 4),
        tabs: const [
          Tab(text: 'Todos'),
          Tab(text: 'Rascunhos'),
          Tab(text: 'Pendentes'),
          Tab(text: 'Aprovados'),
          Tab(text: 'Rejeitados'),
          Tab(text: 'Expirados'),
          Tab(text: 'Convertidos'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildQuotesList(null),
        _buildQuotesList(QuoteStatus.draft),
        _buildQuotesList(QuoteStatus.pending),
        _buildQuotesList(QuoteStatus.approved),
        _buildQuotesList(QuoteStatus.rejected),
        _buildQuotesList(null, showExpired: true),
        _buildQuotesList(QuoteStatus.converted),
      ],
    );
  }

  Widget _buildQuotesList(QuoteStatus? status, {bool showExpired = false}) {
    return Consumer<QuoteStore>(
      builder: (context, quoteStore, child) {
        if (quoteStore.isLoading) {
          return const Center(child: LoadingIndicator());
        }

        if (quoteStore.hasError) {
          return Center(
            child: ErrorMessage(
              message: quoteStore.errorMessage ?? 'Erro desconhecido',
              onRetry: () => quoteStore.loadQuotes(forceRefresh: true),
            ),
          );
        }

        var quotes = quoteStore.quotes;
        
        // Aplicar filtros
        if (status != null) {
          quotes = quotes.where((q) => q.status == status).toList();
        }
        
        if (showExpired) {
          quotes = quotes.where((q) => q.isExpired).toList();
        }

        // Aplicar filtros avançados
        if (_selectedStatusFilter != null) {
          quotes = quotes.where((q) => q.status.name == _selectedStatusFilter).toList();
        }

        if (_selectedDateRange != null) {
          quotes = quotes.where((q) => 
            q.createdAt.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            q.createdAt.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)))
          ).toList();
        }

        if (_minValue != null) {
          quotes = quotes.where((q) => q.total >= _minValue!).toList();
        }

        if (_maxValue != null) {
          quotes = quotes.where((q) => q.total <= _maxValue!).toList();
        }

        if (_searchQuery.isNotEmpty) {
          quotes = quotes.where((q) => 
            q.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            q.customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (q.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
          ).toList();
        }

        // Aplicar ordenação
        quotes = _applySorting(quotes);

        if (quotes.isEmpty) {
          return RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: EmptyState(
                    icon: Icons.receipt_long,
                    title: 'Nenhum orçamento encontrado',
                    subtitle: status == null
                        ? 'Crie seu primeiro orçamento'
                        : 'Não há orçamentos com este status',
                    actionText: 'Criar Orçamento',
                    onAction: () => _navigateToQuoteForm(),
                  ),
                ),
              ),
            ),
          );
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth > 1200;
        
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _onRefresh,
          child: isDesktop && _isGridView
              ? _buildGridView(quotes)
              : _buildListView(quotes),
        );
      },
    );
  }

  Widget _buildListView(List<Quote> quotes) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    
    return ListView.builder(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final quote = quotes[index];
        return _buildSwipeableQuoteCard(quote);
      },
    );
  }

  Widget _buildSwipeableQuoteCard(Quote quote) {
    return Dismissible(
      key: Key('quote_${quote.id}'),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: [
            Icon(
              Icons.edit,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Editar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Excluir',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.delete,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Editar
          _navigateToQuoteForm(quote: quote);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // Confirmar exclusão
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirmar Exclusão'),
              content: Text(
                'Tem certeza que deseja excluir o orçamento #${quote.id}?\n\nEsta ação não pode ser desfeita.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                  ),
                  child: const Text('Excluir'),
                ),
              ],
            ),
          ) ?? false;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteQuote(quote);
        }
      },
      child: GestureDetector(
        onLongPress: () => _showQuoteActions(quote),
        child: _buildQuoteCard(quote),
      ),
    );
  }

  Widget _buildGridView(List<Quote> quotes) {
    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 1.1,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final quote = quotes[index];
        return _buildDesktopQuoteCard(quote);
      },
    );
  }

  Widget _buildDesktopQuoteCard(Quote quote) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToQuoteDetail(quote),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quote.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(quote.status),
                ],
              ),
              const SizedBox(height: 12),
              if (quote.description != null) ...[
                Text(
                  quote.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textColor.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: AppTheme.textColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      quote.customer.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildPriorityChip(quote.priority),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.textColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(quote.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'R\$ ${quote.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (quote.isExpired) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning,
                        size: 12,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Expirado',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.errorColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteCard(Quote quote) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToQuoteDetail(quote),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quote.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.getTextColor(context),
                  ),
                        ),
                        if (quote.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            quote.description!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.getTextColor(context).withOpacity(0.7),
                  ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _buildStatusChip(quote.status),
                  ),
                  const SizedBox(width: 4),
                  _buildPriorityChip(quote.priority),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: AppTheme.getTextColor(context).withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quote.customer.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.getTextColor(context),
                        ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.textColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(quote.createdAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.getTextColor(context).withOpacity(0.7),
                      ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'R\$ ${quote.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                         color: AppTheme.primaryColor,
                         fontWeight: FontWeight.bold,
                       ),
                  ),
                ],
              ),
              if (quote.isExpired) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning,
                        size: 16,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Expirado',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(QuoteStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case QuoteStatus.draft:
        color = AppTheme.getTextColor(context).withOpacity(0.7);
        label = 'Rascunho';
        break;
      case QuoteStatus.pending:
        color = AppTheme.warningColor;
        label = 'Pendente';
        break;
      case QuoteStatus.approved:
        color = AppTheme.successColor;
        label = 'Aprovado';
        break;
      case QuoteStatus.rejected:
        color = AppTheme.errorColor;
        label = 'Rejeitado';
        break;
      case QuoteStatus.converted:
        color = AppTheme.primaryColor;
        label = 'Convertido';
        break;
      case QuoteStatus.expired:
        color = AppTheme.errorColor;
        label = 'Expirado';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPriorityChip(QuotePriority priority) {
    Color color;
    IconData icon;
    
    switch (priority) {
      case QuotePriority.low:
        color = AppTheme.successColor;
        icon = Icons.keyboard_arrow_down;
        break;
      case QuotePriority.normal:
        color = AppTheme.getTextColor(context).withOpacity(0.7);
        icon = Icons.remove;
        break;
      case QuotePriority.high:
        color = AppTheme.warningColor;
        icon = Icons.keyboard_arrow_up;
        break;
      case QuotePriority.urgent:
        color = AppTheme.errorColor;
        icon = Icons.priority_high;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  // Pull to refresh
  Future<void> _onRefresh() async {
    await context.read<QuoteStore>().loadQuotes(forceRefresh: true);
  }

  // Filtros avançados
  void _applyAdvancedFilters() {
    final quoteStore = context.read<QuoteStore>();
    quoteStore.setAdvancedFilters(
      status: _selectedStatusFilter,
      dateRange: _selectedDateRange,
      minValue: _minValue,
      maxValue: _maxValue,
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatusFilter = null;
      _selectedDateRange = null;
      _minValue = null;
      _maxValue = null;
      _searchQuery = '';
      _searchController.clear();
      _clientSearchController.clear();
      _minValueController.clear();
      _maxValueController.clear();
    });
    context.read<QuoteStore>().clearFilters();
  }

  // Ordenação
  void _sortQuotes(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
    });
    context.read<QuoteStore>().sortQuotes(_sortBy, _sortAscending);
  }

  List<Quote> _applySorting(List<Quote> quotes) {
    final sortedQuotes = List<Quote>.from(quotes);
    
    switch (_sortBy) {
      case 'date':
        sortedQuotes.sort((a, b) => _sortAscending 
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt));
        break;
      case 'value':
        sortedQuotes.sort((a, b) => _sortAscending 
            ? a.total.compareTo(b.total)
            : b.total.compareTo(a.total));
        break;
      case 'client':
        sortedQuotes.sort((a, b) => _sortAscending 
            ? a.customer.name.compareTo(b.customer.name)
            : b.customer.name.compareTo(a.customer.name));
        break;
      case 'status':
        sortedQuotes.sort((a, b) => _sortAscending 
            ? a.status.index.compareTo(b.status.index)
            : b.status.index.compareTo(a.status.index));
        break;
    }
    
    return sortedQuotes;
  }

  // Busca avançada
  void _toggleAdvancedSearch() {
    setState(() {
      _isAdvancedSearch = !_isAdvancedSearch;
    });
  }

  void _performAdvancedSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      if (_minValueController.text.isNotEmpty) {
        _minValue = double.tryParse(_minValueController.text);
      }
      if (_maxValueController.text.isNotEmpty) {
        _maxValue = double.tryParse(_maxValueController.text);
      }
    });
    _applyAdvancedFilters();
  }

  // Seleção de data
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _applyAdvancedFilters();
    }
  }

  // Exportação
  Future<void> _exportToPDF() async {
    try {
      final quoteStore = context.read<QuoteStore>();
      await quoteStore.exportToPDF();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lista exportada para PDF com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final quoteStore = context.read<QuoteStore>();
      await quoteStore.exportToExcel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lista exportada para Excel com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Ações por item
  void _showQuoteActions(Quote quote) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ações para Orçamento #${quote.id}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildActionTile(
              icon: Icons.visibility,
              title: 'Visualizar',
              subtitle: 'Ver detalhes do orçamento',
              onTap: () {
                Navigator.pop(context);
                _navigateToQuoteDetail(quote);
              },
            ),
            _buildActionTile(
              icon: Icons.edit,
              title: 'Editar',
              subtitle: 'Modificar orçamento',
              onTap: () {
                Navigator.pop(context);
                _navigateToQuoteForm(quote: quote);
              },
            ),
            _buildActionTile(
              icon: Icons.copy,
              title: 'Duplicar',
              subtitle: 'Criar cópia do orçamento',
              onTap: () {
                Navigator.pop(context);
                _duplicateQuote(quote);
              },
            ),
            _buildActionTile(
              icon: Icons.email,
              title: 'Enviar por E-mail',
              subtitle: 'Enviar para o cliente',
              onTap: () {
                Navigator.pop(context);
                _sendQuoteByEmail(quote);
              },
            ),
            _buildActionTile(
              icon: Icons.share,
              title: 'Compartilhar',
              subtitle: 'Compartilhar orçamento',
              onTap: () {
                Navigator.pop(context);
                _shareQuote(quote);
              },
            ),
            _buildActionTile(
              icon: Icons.delete,
              title: 'Excluir',
              subtitle: 'Remover orçamento',
              color: AppTheme.errorColor,
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteQuote(quote);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tileColor = color ?? AppTheme.getTextColor(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tileColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: tileColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: tileColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: tileColor.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // Ações específicas
  void _duplicateQuote(Quote quote) async {
    try {
      await context.read<QuoteStore>().duplicateQuote(quote.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orçamento duplicado com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao duplicar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _sendQuoteByEmail(Quote quote) async {
    try {
      await context.read<QuoteStore>().sendQuoteByEmail(quote.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orçamento enviado por e-mail!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _shareQuote(Quote quote) async {
    try {
      await context.read<QuoteStore>().shareQuote(quote.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao compartilhar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _confirmDeleteQuote(Quote quote) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o orçamento #${quote.id}?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteQuote(quote);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _deleteQuote(Quote quote) async {
    try {
      await context.read<QuoteStore>().deleteQuote(quote.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orçamento excluído com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showAdvancedFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.tune, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Filtros Avançados'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Filter
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedStatusFilter,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Selecione um status',
                ),
                items: [
                  'draft',
                  'pending',
                  'approved',
                  'rejected',
                  'expired',
                  'converted'
                ].map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(_getStatusLabel(status)),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatusFilter = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Date Range
              const Text('Período:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _selectedDateRange != null
                            ? '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}'
                            : 'Selecionar período',
                      ),
                    ),
                  ),
                  if (_selectedDateRange != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              
              // Value Range
              const Text('Faixa de Valor:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minValueController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Valor mínimo',
                        prefixText: 'R\$ ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _minValue = double.tryParse(value.replaceAll(',', '.'));
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxValueController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Valor máximo',
                        prefixText: 'R\$ ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _maxValue = double.tryParse(value.replaceAll(',', '.'));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearAllFilters();
              Navigator.of(context).pop();
            },
            child: const Text('Limpar'),
          ),
          ElevatedButton(
            onPressed: () {
              _applyAdvancedFilters();
              Navigator.of(context).pop();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.file_download, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Exportar Orçamentos'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Exportar como PDF'),
              subtitle: const Text('Relatório detalhado em PDF'),
              onTap: () {
                Navigator.of(context).pop();
                _exportToPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Exportar como Excel'),
              subtitle: const Text('Planilha para análise de dados'),
              onTap: () {
                Navigator.of(context).pop();
                _exportToExcel();
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'draft': return 'Rascunho';
      case 'pending': return 'Pendente';
      case 'approved': return 'Aprovado';
      case 'rejected': return 'Rejeitado';
      case 'expired': return 'Expirado';
      case 'converted': return 'Convertido';
      default: return status;
    }
  }

  Widget _buildAdvancedSearchFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: AppTheme.primaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtros de Busca Avançada',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cliente:',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _clientSearchController,
                      decoration: InputDecoration(
                        hintText: 'Nome do cliente',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      onChanged: (value) => _performAdvancedSearch(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _selectedStatusFilter,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      hint: const Text('Todos'),
                      items: [
                        'draft',
                        'pending',
                        'approved',
                        'rejected',
                        'expired',
                        'converted'
                      ].map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(_getStatusLabel(status)),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatusFilter = value;
                        });
                        _performAdvancedSearch();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Valor mín:',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _minValueController,
                      decoration: InputDecoration(
                        hintText: 'R\$ 0,00',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _minValue = double.tryParse(value.replaceAll(',', '.'));
                        _performAdvancedSearch();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Valor máx:',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _maxValueController,
                      decoration: InputDecoration(
                        hintText: 'R\$ 999.999,99',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _maxValue = double.tryParse(value.replaceAll(',', '.'));
                        _performAdvancedSearch();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    _selectedDateRange != null
                        ? '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}'
                        : 'Período',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  _clearAllFilters();
                  _performAdvancedSearch();
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Limpar', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(),
    );
  }

  void _navigateToQuoteForm({Quote? quote}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuoteFormPage(quote: quote),
      ),
    );
  }

  void _navigateToQuoteDetail(Quote quote) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuoteDetailPage(quoteId: quote.id),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _FilterDialog extends StatefulWidget {
  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  String? _selectedStatus;
  QuotePriority? _selectedPriority;
  String? _selectedAssignedUser;

  @override
  void initState() {
    super.initState();
    final quoteStore = context.read<QuoteStore>();
    _selectedStatus = quoteStore.filterStatus?.name;
    _selectedPriority = quoteStore.filterPriority;
    _selectedAssignedUser = quoteStore.filterAssignedUser;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtros'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Selecione um status',
              ),
              items: [
                'draft',
                'pending',
                'approved',
                'rejected',
                'expired',
                'converted'
              ].map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getStatusLabel(status)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedStatus = value),
            ),
            const SizedBox(height: 16),
            const Text('Prioridade'),
            const SizedBox(height: 8),
            DropdownButtonFormField<QuotePriority>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Selecione uma prioridade',
              ),
              items: QuotePriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(_getPriorityLabel(priority)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedPriority = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.read<QuoteStore>().clearFilters();
            Navigator.of(context).pop();
          },
          child: const Text('Limpar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<QuoteStore>().setAdvancedFilters(
              status: _selectedStatus,
              minValue: null,
              maxValue: null,
              dateRange: null,
            );
            Navigator.of(context).pop();
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'draft': return 'Rascunho';
      case 'pending': return 'Pendente';
      case 'approved': return 'Aprovado';
      case 'rejected': return 'Rejeitado';
      case 'expired': return 'Expirado';
      case 'converted': return 'Convertido';
      default: return status;
    }
  }

  String _getPriorityLabel(QuotePriority priority) {
    switch (priority) {
      case QuotePriority.low:
        return 'Baixa';
      case QuotePriority.normal:
        return 'Normal';
      case QuotePriority.high:
        return 'Alta';
      case QuotePriority.urgent:
        return 'Urgente';
    }
  }
}