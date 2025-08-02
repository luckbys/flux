import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import '../services/pdf_service.dart';
import '../services/supabase/quote_service.dart';

enum QuoteLoadingState {
  idle,
  loading,
  success,
  error,
}

class QuoteStore extends ChangeNotifier {
  final QuoteService _quoteService = QuoteService();

  // Estados
  QuoteLoadingState _loadingState = QuoteLoadingState.idle;
  String? _errorMessage;

  // Dados
  List<Quote> _quotes = [];
  Map<String, int> _quoteStats = {
    'total': 0,
    'draft': 0,
    'pending': 0,
    'approved': 0,
    'rejected': 0,
    'expired': 0,
    'converted': 0,
  };

  // Filtros
  QuoteStatus? _filterStatus;
  QuotePriority? _filterPriority;
  String? _filterAssignedUser;
  String _searchQuery = '';

  // Filtros avançados
  DateTimeRange? _filterDateRange;
  double? _filterMinValue;
  double? _filterMaxValue;

  // Getters
  QuoteLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == QuoteLoadingState.loading;
  bool get hasError => _loadingState == QuoteLoadingState.error;

  List<Quote> get quotes => _applyFilters(_quotes);
  List<Quote> get allQuotes => _quotes;
  Map<String, int> get quoteStats => _quoteStats;

  // Filtros
  QuoteStatus? get filterStatus => _filterStatus;
  QuotePriority? get filterPriority => _filterPriority;
  String? get filterAssignedUser => _filterAssignedUser;
  String get searchQuery => _searchQuery;
  DateTimeRange? get filterDateRange => _filterDateRange;
  double? get filterMinValue => _filterMinValue;
  double? get filterMaxValue => _filterMaxValue;

  // Métodos públicos

  /// Carregar todos os orçamentos
  Future<void> loadQuotes({bool forceRefresh = false}) async {
    if (_loadingState == QuoteLoadingState.loading && !forceRefresh) return;

    try {
      _setLoadingState(QuoteLoadingState.loading);
      _clearError();

      AppConfig.log('Carregando orçamentos...', tag: 'QuoteStore');

      _quotes = await _quoteService.getQuotes(
        status: _filterStatus,
        priority: _filterPriority,
      );
      _setLoadingState(QuoteLoadingState.success);

      AppConfig.log('${_quotes.length} orçamentos carregados',
          tag: 'QuoteStore');

      // Carregar estatísticas
      await _loadQuoteStats();
    } catch (e) {
      AppConfig.log('Erro ao carregar orçamentos: $e', tag: 'QuoteStore');
      _setError('Erro ao carregar orçamentos: $e');

      // Fallback para dados mock em caso de erro
      _quotes = _generateMockQuotes();
      _setLoadingState(QuoteLoadingState.success);
    }
  }

  /// Buscar orçamento por ID
  Quote? getQuoteById(String quoteId) {
    try {
      return _quotes.firstWhere((q) => q.id == quoteId);
    } catch (e) {
      return null;
    }
  }

  /// Criar novo orçamento
  Future<Quote?> createQuote({
    required String title,
    String? description,
    required User customer,
    User? assignedAgent,
    QuotePriority priority = QuotePriority.normal,
    List<QuoteItem> items = const [],
    double taxRate = 0.0,
    double additionalDiscount = 0.0,
    String? notes,
    String? terms,
    DateTime? validUntil,
  }) async {
    try {
      _setLoadingState(QuoteLoadingState.loading);
      _clearError();

      AppConfig.log('Criando orçamento: $title', tag: 'QuoteStore');

      final quote = await _quoteService.createQuote(
        title: title,
        description: description,
        customerId: customer.id,
        assignedAgentId: assignedAgent?.id,
        priority: priority,
        items: items,
        taxRate: taxRate,
        additionalDiscount: additionalDiscount,
        notes: notes,
        terms: terms,
        validUntil: validUntil,
      );

      _quotes.insert(0, quote);
      _setLoadingState(QuoteLoadingState.success);

      AppConfig.log('Orçamento criado: ${quote.id}', tag: 'QuoteStore');
      await _loadQuoteStats();

      return quote;
    } catch (e) {
      AppConfig.log('Erro ao criar orçamento: $e', tag: 'QuoteStore');
      _setError('Erro ao criar orçamento: $e');
      return null;
    }
  }

  /// Atualizar orçamento
  Future<bool> updateQuote({
    required String quoteId,
    String? title,
    String? description,
    QuoteStatus? status,
    QuotePriority? priority,
    List<QuoteItem>? items,
    double? taxRate,
    double? additionalDiscount,
    String? notes,
    String? terms,
    DateTime? validUntil,
    String? rejectionReason,
  }) async {
    try {
      _setLoadingState(QuoteLoadingState.loading);
      _clearError();

      AppConfig.log('Atualizando orçamento: $quoteId', tag: 'QuoteStore');

      final updatedQuote = await _quoteService.updateQuote(
        quoteId: quoteId,
        title: title,
        description: description,
        status: status,
        priority: priority,
        items: items,
        taxRate: taxRate,
        additionalDiscount: additionalDiscount,
        notes: notes,
        terms: terms,
        validUntil: validUntil,
        rejectionReason: rejectionReason,
      );

      final index = _quotes.indexWhere((q) => q.id == quoteId);
      if (index != -1) {
        _quotes[index] = updatedQuote;
      }

      _setLoadingState(QuoteLoadingState.success);

      AppConfig.log('Orçamento atualizado: $quoteId', tag: 'QuoteStore');
      await _loadQuoteStats();

      return true;
    } catch (e) {
      AppConfig.log('Erro ao atualizar orçamento: $e', tag: 'QuoteStore');
      _setError('Erro ao atualizar orçamento: $e');
      return false;
    }
  }

  /// Aprovar orçamento
  Future<bool> approveQuote(String quoteId) async {
    return updateQuote(
      quoteId: quoteId,
      status: QuoteStatus.approved,
    );
  }

  /// Rejeitar orçamento
  Future<bool> rejectQuote(String quoteId, String reason) async {
    return updateQuote(
      quoteId: quoteId,
      status: QuoteStatus.rejected,
      rejectionReason: reason,
    );
  }

  /// Converter orçamento em pedido
  Future<bool> convertQuote(String quoteId) async {
    return updateQuote(
      quoteId: quoteId,
      status: QuoteStatus.converted,
    );
  }

  /// Duplicar orçamento
  Future<Quote?> duplicateQuote(String quoteId) async {
    final originalQuote = getQuoteById(quoteId);
    if (originalQuote == null) return null;

    return createQuote(
      title: '${originalQuote.title} (Cópia)',
      description: originalQuote.description,
      customer: originalQuote.customer,
      assignedAgent: originalQuote.assignedAgent,
      priority: originalQuote.priority,
      items: originalQuote.items,
      taxRate: originalQuote.taxRate,
      notes: originalQuote.notes,
      terms: originalQuote.terms,
      validUntil: originalQuote.validUntil,
    );
  }

  /// Enviar orçamento por email
  Future<bool> sendQuoteByEmail(String quoteId) async {
    try {
      AppConfig.log('Enviando orçamento por email: $quoteId',
          tag: 'QuoteStore');
      // Simulação de envio de email
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      AppConfig.log('Erro ao enviar orçamento por email: $e',
          tag: 'QuoteStore');
      return false;
    }
  }

  /// Compartilhar orçamento
  Future<bool> shareQuote(String quoteId) async {
    try {
      AppConfig.log('Compartilhando orçamento: $quoteId', tag: 'QuoteStore');
      // Simulação de compartilhamento
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      AppConfig.log('Erro ao compartilhar orçamento: $e', tag: 'QuoteStore');
      return false;
    }
  }

  /// Excluir orçamento
  Future<bool> deleteQuote(String quoteId) async {
    try {
      _setLoadingState(QuoteLoadingState.loading);
      _clearError();

      AppConfig.log('Excluindo orçamento: $quoteId', tag: 'QuoteStore');

      // Simulação de exclusão
      await Future.delayed(const Duration(milliseconds: 500));

      _quotes.removeWhere((q) => q.id == quoteId);
      _setLoadingState(QuoteLoadingState.success);

      AppConfig.log('Orçamento excluído: $quoteId', tag: 'QuoteStore');
      _loadQuoteStats();

      return true;
    } catch (e) {
      AppConfig.log('Erro ao excluir orçamento: $e', tag: 'QuoteStore');
      _setError('Erro ao excluir orçamento: $e');
      return false;
    }
  }

  /// Exportar para PDF (orçamento específico)
  Future<void> exportToPDF([Quote? quote]) async {
    try {
      if (quote != null) {
        await PdfService.printQuote(quote);
      } else {
        // Exportar lista completa (implementação futura)
        debugPrint('Exportação de lista completa não implementada ainda');
      }
    } catch (e) {
      debugPrint('Erro ao exportar PDF: $e');
    }
  }

  /// Imprimir orçamento
  Future<void> printQuote(Quote quote) async {
    try {
      await PdfService.printQuote(quote);
    } catch (e) {
      debugPrint('Erro ao imprimir orçamento: $e');
    }
  }

  /// Salvar PDF do orçamento
  Future<String?> saveQuotePdf(Quote quote) async {
    try {
      return await PdfService.saveQuotePdf(quote);
    } catch (e) {
      debugPrint('Erro ao salvar PDF: $e');
      return null;
    }
  }

  /// Compartilhar PDF do orçamento
  Future<void> shareQuotePdf(Quote quote) async {
    try {
      await PdfService.shareQuotePdf(quote);
    } catch (e) {
      debugPrint('Erro ao compartilhar PDF: $e');
    }
  }

  /// Exportar para Excel
  Future<bool> exportToExcel() async {
    try {
      AppConfig.log('Exportando orçamentos para Excel', tag: 'QuoteStore');
      // Simulação de exportação
      await Future.delayed(const Duration(milliseconds: 1000));
      return true;
    } catch (e) {
      AppConfig.log('Erro ao exportar para Excel: $e', tag: 'QuoteStore');
      return false;
    }
  }

  /// Aplicar filtros
  void setFilters({
    QuoteStatus? status,
    QuotePriority? priority,
    String? assignedUser,
  }) {
    _filterStatus = status;
    _filterPriority = priority;
    _filterAssignedUser = assignedUser;
    notifyListeners();
  }

  /// Aplicar filtros avançados
  void setAdvancedFilters({
    String? status,
    DateTimeRange? dateRange,
    double? minValue,
    double? maxValue,
  }) {
    // Converter string para QuoteStatus se necessário
    if (status != null && status.isNotEmpty) {
      _filterStatus = QuoteStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => QuoteStatus.draft,
      );
    } else {
      _filterStatus = null;
    }

    _filterDateRange = dateRange;
    _filterMinValue = minValue;
    _filterMaxValue = maxValue;
    notifyListeners();
  }

  /// Definir busca
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Ordenar orçamentos
  void sortQuotes(String sortBy, bool ascending) {
    // A ordenação é aplicada na UI através do método _applySorting
    // Este método apenas notifica os listeners para atualizar a UI
    notifyListeners();
  }

  /// Limpar filtros
  void clearFilters() {
    _filterStatus = null;
    _filterPriority = null;
    _filterAssignedUser = null;
    _searchQuery = '';
    _filterDateRange = null;
    _filterMinValue = null;
    _filterMaxValue = null;
    notifyListeners();
  }

  // Métodos privados

  void _setLoadingState(QuoteLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _loadingState = QuoteLoadingState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  List<Quote> _applyFilters(List<Quote> quotes) {
    var filtered = quotes;

    // Filtro por status
    if (_filterStatus != null) {
      filtered = filtered.where((q) => q.status == _filterStatus).toList();
    }

    // Filtro por prioridade
    if (_filterPriority != null) {
      filtered = filtered.where((q) => q.priority == _filterPriority).toList();
    }

    // Filtro por usuário atribuído
    if (_filterAssignedUser != null) {
      filtered = filtered
          .where((q) => q.assignedAgent?.id == _filterAssignedUser)
          .toList();
    }

    // Filtro por período de data
    if (_filterDateRange != null) {
      filtered = filtered.where((q) {
        final quoteDate = q.createdAt;
        return quoteDate.isAfter(
                _filterDateRange!.start.subtract(const Duration(days: 1))) &&
            quoteDate
                .isBefore(_filterDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Filtro por valor mínimo
    if (_filterMinValue != null) {
      filtered = filtered.where((q) => q.total >= _filterMinValue!).toList();
    }

    // Filtro por valor máximo
    if (_filterMaxValue != null) {
      filtered = filtered.where((q) => q.total <= _filterMaxValue!).toList();
    }

    // Busca por texto
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((q) {
        return q.title.toLowerCase().contains(query) ||
            q.customer.name.toLowerCase().contains(query) ||
            (q.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  Future<void> _loadQuoteStats() async {
    try {
      _quoteStats = await _quoteService.getQuoteStats();
      notifyListeners();
    } catch (e) {
      // Fallback para estatísticas locais
      _quoteStats = {
        'total': _quotes.length,
        'draft': _quotes.where((q) => q.status == QuoteStatus.draft).length,
        'pending': _quotes.where((q) => q.status == QuoteStatus.pending).length,
        'approved':
            _quotes.where((q) => q.status == QuoteStatus.approved).length,
        'rejected':
            _quotes.where((q) => q.status == QuoteStatus.rejected).length,
        'expired': _quotes.where((q) => q.isExpired).length,
        'converted':
            _quotes.where((q) => q.status == QuoteStatus.converted).length,
      };
      notifyListeners();
    }
  }

  List<Quote> _generateMockQuotes() {
    final mockCustomer = User(
      id: '1',
      name: 'João Silva',
      email: 'joao@empresa.com',
      phone: '(11) 99999-9999',
      role: UserRole.customer,
      status: UserStatus.online,
      createdAt: DateTime.now(),
    );

    final mockAgent = User(
      id: '2',
      name: 'Maria Santos',
      email: 'maria@bkcrm.com',
      phone: '(11) 88888-8888',
      role: UserRole.agent,
      status: UserStatus.online,
      createdAt: DateTime.now(),
    );

    return [
      Quote(
        id: '1',
        title: 'Sistema de CRM Personalizado',
        description:
            'Desenvolvimento de sistema CRM com funcionalidades específicas',
        status: QuoteStatus.pending,
        priority: QuotePriority.high,
        customer: mockCustomer,
        assignedAgent: mockAgent,
        items: const [
          QuoteItem(
            id: '1',
            description: 'Desenvolvimento Frontend',
            quantity: 40,
            unitPrice: 150.0,
            unit: 'horas',
          ),
          QuoteItem(
            id: '2',
            description: 'Desenvolvimento Backend',
            quantity: 60,
            unitPrice: 180.0,
            unit: 'horas',
          ),
        ],
        taxRate: 10.0,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        validUntil: DateTime.now().add(const Duration(days: 30)),
      ),
      Quote(
        id: '2',
        title: 'Consultoria em Marketing Digital',
        description: 'Estratégia completa de marketing digital',
        status: QuoteStatus.approved,
        priority: QuotePriority.normal,
        customer: mockCustomer,
        assignedAgent: mockAgent,
        items: const [
          QuoteItem(
            id: '3',
            description: 'Auditoria de Marketing',
            quantity: 1,
            unitPrice: 2500.0,
            unit: 'projeto',
          ),
          QuoteItem(
            id: '4',
            description: 'Criação de Campanhas',
            quantity: 3,
            unitPrice: 800.0,
            unit: 'campanhas',
          ),
        ],
        taxRate: 10.0,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        approvedAt: DateTime.now().subtract(const Duration(days: 1)),
        validUntil: DateTime.now().add(const Duration(days: 15)),
      ),
      Quote(
        id: '3',
        title: 'Website Institucional',
        description: 'Desenvolvimento de website responsivo',
        status: QuoteStatus.draft,
        priority: QuotePriority.normal,
        customer: mockCustomer,
        assignedAgent: mockAgent,
        items: const [
          QuoteItem(
            id: '5',
            description: 'Design UI/UX',
            quantity: 20,
            unitPrice: 120.0,
            unit: 'horas',
          ),
          QuoteItem(
            id: '6',
            description: 'Desenvolvimento',
            quantity: 30,
            unitPrice: 150.0,
            unit: 'horas',
          ),
        ],
        taxRate: 10.0,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        validUntil: DateTime.now().add(const Duration(days: 45)),
      ),
    ];
  }
}
