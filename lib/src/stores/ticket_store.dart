import 'package:flutter/foundation.dart';
import '../models/ticket.dart';
import '../models/message.dart';
import '../services/supabase/ticket_service.dart';
import '../config/app_config.dart';

enum TicketLoadingState {
  idle,
  loading,
  success,
  error,
}

class TicketStore extends ChangeNotifier {
  final TicketService _ticketService = TicketService();

  // Estados
  TicketLoadingState _loadingState = TicketLoadingState.idle;
  String? _errorMessage;

  // Dados
  List<Ticket> _tickets = [];
  final Map<String, List<Message>> _ticketMessages = {};
  Map<String, int> _ticketStats = {
    'total': 0,
    'open': 0,
    'in_progress': 0,
    'resolved': 0,
    'closed': 0,
  };

  // Filtros
  TicketStatus? _filterStatus;
  TicketPriority? _filterPriority;
  String? _filterAssignedUser;
  String _searchQuery = '';

  // Getters
  TicketLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == TicketLoadingState.loading;
  bool get hasError => _loadingState == TicketLoadingState.error;

  List<Ticket> get tickets => _applyFilters(_tickets);
  List<Ticket> get allTickets => _tickets;
  Map<String, int> get ticketStats => _ticketStats;

  // Filtros
  TicketStatus? get filterStatus => _filterStatus;
  TicketPriority? get filterPriority => _filterPriority;
  String? get filterAssignedUser => _filterAssignedUser;
  String get searchQuery => _searchQuery;

  // Métodos públicos

  /// Carregar todos os tickets
  Future<void> loadTickets({
    bool forceRefresh = false,
    TicketStatus? status,
    String? assignedUserId,
  }) async {
    if (_loadingState == TicketLoadingState.loading && !forceRefresh) return;

    try {
      _setLoadingState(TicketLoadingState.loading);
      _clearError();

      AppConfig.log('Carregando tickets...', tag: 'TicketStore');

      final tickets = await _ticketService.getTickets(
        status: status ?? _filterStatus,
        assignedUserId: assignedUserId ?? _filterAssignedUser,
      );

      _tickets = tickets;
      _setLoadingState(TicketLoadingState.success);

      AppConfig.log('${tickets.length} tickets carregados', tag: 'TicketStore');

      // Carregar estatísticas
      await _loadTicketStats();
    } catch (e) {
      AppConfig.log('Erro ao carregar tickets: $e', tag: 'TicketStore');
      _setError('Erro ao carregar tickets: $e');
    }
  }

  /// Buscar ticket por ID
  Future<Ticket?> getTicketById(String ticketId) async {
    try {
      AppConfig.log('Buscando ticket: $ticketId', tag: 'TicketStore');

      // Verificar se já está na lista
      // Verificar se já existe na lista local
      final existingTicketIndex = _tickets.indexWhere((t) => t.id == ticketId);
      if (existingTicketIndex != -1) {
        return _tickets[existingTicketIndex];
      }

      // Buscar no Supabase
      final ticket = await _ticketService.getTicketById(ticketId);
      if (ticket != null) {
        // Adicionar à lista se não existir
        _tickets.add(ticket);
        notifyListeners();
      }

      return ticket;
    } catch (e) {
      AppConfig.log('Erro ao buscar ticket: $e', tag: 'TicketStore');
      return null;
    }
  }

  /// Criar novo ticket
  Future<Ticket?> createTicket({
    required String title,
    required String description,
    required String customerId,
    TicketPriority priority = TicketPriority.normal,
    TicketCategory category = TicketCategory.general,
    String? assignedTo,
  }) async {
    try {
      _setLoadingState(TicketLoadingState.loading);
      _clearError();

      AppConfig.log('Criando ticket: $title', tag: 'TicketStore');

      final ticket = await _ticketService.createTicket(
        title: title,
        description: description,
        customerId: customerId,
        priority: priority,
        category: category,
        assignedTo: assignedTo,
      );

      // Adicionar à lista
      _tickets.insert(0, ticket);
      _setLoadingState(TicketLoadingState.success);

      AppConfig.log('Ticket criado: ${ticket.id}', tag: 'TicketStore');
      await _loadTicketStats(); // Atualizar estatísticas

      return ticket;
    } catch (e) {
      AppConfig.log('Erro ao criar ticket: $e', tag: 'TicketStore');
      _setError('Erro ao criar ticket: $e');
      return null;
    }
  }

  /// Atualizar ticket
  Future<bool> updateTicket({
    required String ticketId,
    String? title,
    String? description,
    TicketStatus? status,
    TicketPriority? priority,
    TicketCategory? category,
    String? assignedTo,
  }) async {
    try {
      _setLoadingState(TicketLoadingState.loading);
      _clearError();

      AppConfig.log('Atualizando ticket: $ticketId', tag: 'TicketStore');

      final updatedTicket = await _ticketService.updateTicket(
        ticketId: ticketId,
        title: title,
        description: description,
        status: status,
        priority: priority,
        category: category,
        assignedTo: assignedTo,
      );

      // Atualizar na lista
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index] = updatedTicket;
      }

      _setLoadingState(TicketLoadingState.success);
      AppConfig.log('Ticket atualizado: $ticketId', tag: 'TicketStore');
      await _loadTicketStats(); // Atualizar estatísticas

      return true;
    } catch (e) {
      AppConfig.log('Erro ao atualizar ticket: $e', tag: 'TicketStore');
      _setError('Erro ao atualizar ticket: $e');
      return false;
    }
  }

  /// Deletar ticket
  Future<bool> deleteTicket(String ticketId) async {
    try {
      _setLoadingState(TicketLoadingState.loading);
      _clearError();

      AppConfig.log('Deletando ticket: $ticketId', tag: 'TicketStore');

      await _ticketService.deleteTicket(ticketId);

      // Remover da lista
      _tickets.removeWhere((t) => t.id == ticketId);
      _ticketMessages.remove(ticketId);

      _setLoadingState(TicketLoadingState.success);
      AppConfig.log('Ticket deletado: $ticketId', tag: 'TicketStore');
      await _loadTicketStats(); // Atualizar estatísticas

      return true;
    } catch (e) {
      AppConfig.log('Erro ao deletar ticket: $e', tag: 'TicketStore');
      _setError('Erro ao deletar ticket: $e');
      return false;
    }
  }

  /// Carregar mensagens de um ticket
  Future<List<Message>> loadTicketMessages(String ticketId) async {
    try {
      AppConfig.log('Carregando mensagens do ticket: $ticketId',
          tag: 'TicketStore');

      final messages = await _ticketService.getTicketMessages(ticketId);
      _ticketMessages[ticketId] = messages;
      notifyListeners();

      AppConfig.log('${messages.length} mensagens carregadas',
          tag: 'TicketStore');
      return messages;
    } catch (e) {
      AppConfig.log('Erro ao carregar mensagens: $e', tag: 'TicketStore');
      return [];
    }
  }

  /// Enviar mensagem em um ticket
  Future<bool> sendTicketMessage({
    required String ticketId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    List<MessageAttachment>? attachments,
  }) async {
    try {
      AppConfig.log('Enviando mensagem no ticket: $ticketId',
          tag: 'TicketStore');

      final message = await _ticketService.sendTicketMessage(
        ticketId: ticketId,
        senderId: senderId,
        content: content,
        type: type,
        attachments: attachments,
      );

      // Adicionar à lista de mensagens
      if (_ticketMessages[ticketId] != null) {
        _ticketMessages[ticketId]!.add(message);
      } else {
        _ticketMessages[ticketId] = [message];
      }

      notifyListeners();
      AppConfig.log('Mensagem enviada: ${message.id}', tag: 'TicketStore');
      return true;
    } catch (e) {
      AppConfig.log('Erro ao enviar mensagem: $e', tag: 'TicketStore');
      _setError('Erro ao enviar mensagem: $e');
      return false;
    }
  }

  /// Obter mensagens de um ticket
  List<Message> getTicketMessages(String ticketId) {
    return _ticketMessages[ticketId] ?? [];
  }

  /// Aplicar filtros
  void setFilters({
    TicketStatus? status,
    TicketPriority? priority,
    String? assignedUser,
  }) {
    _filterStatus = status;
    _filterPriority = priority;
    _filterAssignedUser = assignedUser;
    notifyListeners();
  }

  /// Limpar filtros
  void clearFilters() {
    _filterStatus = null;
    _filterPriority = null;
    _filterAssignedUser = null;
    _searchQuery = '';
    notifyListeners();
  }

  /// Buscar tickets
  void search(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  /// Estatísticas por status
  int getTicketCountByStatus(TicketStatus status) {
    return tickets.where((t) => t.status == status).length;
  }

  /// Tickets atribuídos a um usuário
  List<Ticket> getTicketsByAssignee(String userId) {
    return tickets.where((t) => t.assignedAgent?.id == userId).toList();
  }

  /// Tickets de um cliente
  List<Ticket> getTicketsByCustomer(String customerId) {
    return tickets.where((t) => t.customer.id == customerId).toList();
  }

  // Métodos privados

  void _setLoadingState(TicketLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setLoadingState(TicketLoadingState.error);
  }

  void _clearError() {
    _errorMessage = null;
  }

  List<Ticket> _applyFilters(List<Ticket> tickets) {
    var filteredTickets = tickets;

    // Filtro por status
    if (_filterStatus != null) {
      filteredTickets =
          filteredTickets.where((t) => t.status == _filterStatus).toList();
    }

    // Filtro por prioridade
    if (_filterPriority != null) {
      filteredTickets =
          filteredTickets.where((t) => t.priority == _filterPriority).toList();
    }

    // Filtro por usuário atribuído
    if (_filterAssignedUser != null && _filterAssignedUser!.isNotEmpty) {
      filteredTickets = filteredTickets
          .where((t) => t.assignedAgent?.id == _filterAssignedUser)
          .toList();
    }

    // Filtro por busca
    if (_searchQuery.isNotEmpty) {
      filteredTickets = filteredTickets.where((t) {
        return t.title.toLowerCase().contains(_searchQuery) ||
            t.description.toLowerCase().contains(_searchQuery) ||
            t.customer.name.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return filteredTickets;
  }

  Future<void> _loadTicketStats() async {
    try {
      final stats = await _ticketService.getTicketStats(
        assignedUserId: _filterAssignedUser,
      );
      _ticketStats = stats;
      notifyListeners();
    } catch (e) {
      AppConfig.log('Erro ao carregar estatísticas: $e', tag: 'TicketStore');
    }
  }

  /// Limpar dados
  void clear() {
    _tickets.clear();
    _ticketMessages.clear();
    _ticketStats = {
      'total': 0,
      'open': 0,
      'in_progress': 0,
      'resolved': 0,
      'closed': 0,
    };
    clearFilters();
    _setLoadingState(TicketLoadingState.idle);
    _clearError();
  }
}
