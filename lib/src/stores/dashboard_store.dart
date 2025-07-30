import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../models/action_item.dart';
import '../services/supabase/dashboard_service.dart';
import '../config/app_config.dart';
import '../styles/app_theme.dart';
import '../pages/tickets/tickets_page.dart';
import '../pages/chat/chat_list_page.dart';
import '../pages/settings/whatsapp_setup_page.dart';
import '../pages/profile/profile_page.dart';

enum DashboardLoadingState {
  idle,
  loading,
  success,
  error,
}

class DashboardStore extends ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();

  // Estados
  DashboardLoadingState _loadingState = DashboardLoadingState.idle;
  String? _errorMessage;

  // Dados do dashboard
  Map<String, dynamic> _dashboardStats = {};
  List<Ticket> _recentTickets = [];
  List<User> _onlineUsers = [];
  Map<String, dynamic> _performanceMetrics = {};
  List<Map<String, dynamic>> _recentActivity = [];

  // Cache e refresh
  DateTime? _lastRefresh;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  // Getters
  DashboardLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == DashboardLoadingState.loading;
  bool get hasError => _loadingState == DashboardLoadingState.error;

  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<Ticket> get recentTickets => _recentTickets;
  List<User> get onlineUsers => _onlineUsers;
  Map<String, dynamic> get performanceMetrics => _performanceMetrics;
  List<Map<String, dynamic>> get recentActivity => _recentActivity;

  // Estatísticas específicas
  Map<String, dynamic> get ticketStats => _dashboardStats['tickets'] ?? {};
  Map<String, dynamic> get quoteStats => _dashboardStats['quotes'] ?? {};
  Map<String, dynamic> get userStats => _dashboardStats['users'] ?? {};

  DateTime? get lastRefresh => _lastRefresh;
  bool get needsRefresh {
    if (_lastRefresh == null) return true;
    return DateTime.now().difference(_lastRefresh!) > _cacheTimeout;
  }

  // Métodos públicos

  /// Carregar todos os dados do dashboard
  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    if (_loadingState == DashboardLoadingState.loading && !forceRefresh) return;
    if (!forceRefresh && !needsRefresh) return;

    try {
      _setLoadingState(DashboardLoadingState.loading);
      _clearError();

      AppConfig.log('Carregando dados do dashboard...', tag: 'DashboardStore');

      // Carregar dados em paralelo
      final results = await Future.wait([
        _dashboardService.getDashboardStats(),
        _dashboardService.getRecentTickets(limit: 5),
        _dashboardService.getOnlineUsers(limit: 10),
        _dashboardService.getPerformanceMetrics(),
      ]);

      _dashboardStats = results[0] as Map<String, dynamic>;
      _recentTickets = results[1] as List<Ticket>;
      _onlineUsers = results[2] as List<User>;
      _performanceMetrics = results[3] as Map<String, dynamic>;
      _recentActivity =
          _dashboardStats['recentActivity'] as List<Map<String, dynamic>>? ??
              [];

      _lastRefresh = DateTime.now();
      _setLoadingState(DashboardLoadingState.success);

      AppConfig.log('Dados do dashboard carregados com sucesso',
          tag: 'DashboardStore');
    } catch (e) {
      AppConfig.log('Erro ao carregar dashboard: $e', tag: 'DashboardStore');
      _setError('Erro ao carregar dados do dashboard: $e');

      // Em caso de erro, manter dados vazios
      _dashboardStats = {
        'tickets': {},
        'quotes': {},
        'users': {},
        'recentActivity': [],
        'lastUpdated': DateTime.now(),
      };
      _recentTickets = [];
      _onlineUsers = [];
      _performanceMetrics = {};
      _lastRefresh = DateTime.now();
      _setLoadingState(DashboardLoadingState.error);
    }
  }

  /// Carregar apenas estatísticas
  Future<void> loadStats({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && !needsRefresh) return;

      AppConfig.log('Carregando estatísticas...', tag: 'DashboardStore');

      _dashboardStats = await _dashboardService.getDashboardStats();
      _recentActivity =
          _dashboardStats['recentActivity'] as List<Map<String, dynamic>>? ??
              [];

      notifyListeners();
      AppConfig.log('Estatísticas carregadas', tag: 'DashboardStore');
    } catch (e) {
      AppConfig.log('Erro ao carregar estatísticas: $e', tag: 'DashboardStore');
    }
  }

  /// Carregar tickets recentes
  Future<void> loadRecentTickets() async {
    try {
      AppConfig.log('Carregando tickets recentes...', tag: 'DashboardStore');

      _recentTickets = await _dashboardService.getRecentTickets(limit: 5);
      notifyListeners();

      AppConfig.log('${_recentTickets.length} tickets recentes carregados',
          tag: 'DashboardStore');
    } catch (e) {
      AppConfig.log('Erro ao carregar tickets recentes: $e',
          tag: 'DashboardStore');
    }
  }

  /// Carregar usuários online
  Future<void> loadOnlineUsers() async {
    try {
      AppConfig.log('Carregando usuários online...', tag: 'DashboardStore');

      _onlineUsers = await _dashboardService.getOnlineUsers(limit: 10);
      notifyListeners();

      AppConfig.log('${_onlineUsers.length} usuários online carregados',
          tag: 'DashboardStore');
    } catch (e) {
      AppConfig.log('Erro ao carregar usuários online: $e',
          tag: 'DashboardStore');
    }
  }

  /// Carregar métricas de performance
  Future<void> loadPerformanceMetrics() async {
    try {
      AppConfig.log('Carregando métricas de performance...',
          tag: 'DashboardStore');

      _performanceMetrics = await _dashboardService.getPerformanceMetrics();
      notifyListeners();

      AppConfig.log('Métricas de performance carregadas',
          tag: 'DashboardStore');
    } catch (e) {
      AppConfig.log('Erro ao carregar métricas: $e', tag: 'DashboardStore');
    }
  }

  /// Refresh completo dos dados
  Future<void> refresh() async {
    await loadDashboardData(forceRefresh: true);
  }

  /// Refresh rápido (apenas estatísticas)
  Future<void> quickRefresh() async {
    await loadStats(forceRefresh: true);
  }

  // Getters de conveniência para estatísticas

  int get totalTickets => ticketStats['total'] ?? 0;
  int get openTickets => ticketStats['open'] ?? 0;
  int get resolvedToday => ticketStats['resolvedToday'] ?? 0;
  int get highPriorityTickets => ticketStats['highPriority'] ?? 0;

  int get totalQuotes => quoteStats['total'] ?? 0;
  int get pendingQuotes => quoteStats['pending'] ?? 0;
  int get approvedQuotes => quoteStats['approved'] ?? 0;
  int get expiringSoonQuotes => quoteStats['expiringSoon'] ?? 0;

  int get totalUsers => userStats['total'] ?? 0;
  int get onlineUsersCount => userStats['online'] ?? 0;
  int get newUsersToday => userStats['newToday'] ?? 0;
  int get activeUsersRecently => userStats['activeRecently'] ?? 0;

  double get avgResolutionTime =>
      (performanceMetrics['avgResolutionTime'] ?? 0.0).toDouble();
  double get resolutionRate =>
      (performanceMetrics['resolutionRate'] ?? 0.0).toDouble();
  double get satisfactionRate =>
      (performanceMetrics['satisfactionRate'] ?? 0.0).toDouble();

  // Métodos privados

  void _setLoadingState(DashboardLoadingState state) {
    if (_loadingState != state) {
      _loadingState = state;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    _loadingState = DashboardLoadingState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }



  // Ações rápidas do dashboard
  List<ActionItem> getQuickActions(BuildContext context) => [
        ActionItem(
          title: 'Novo Ticket',
          subtitle: 'Criar novo atendimento',
          icon: PhosphorIcons.ticket(),
          color: AppTheme.primaryColor,
          bgColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TicketsPage()),
          ),
        ),
        ActionItem(
          title: 'Iniciar Chat',
          subtitle: 'Conversar com cliente',
          icon: PhosphorIcons.chatCircle(),
          color: AppTheme.successColor,
          bgColor: AppTheme.successColor.withValues(alpha: 0.1),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatListPage()),
          ),
        ),
        ActionItem(
          title: 'WhatsApp',
          subtitle: 'Configurar integração',
          icon: PhosphorIcons.whatsappLogo(),
          color: const Color(0xFF25D366),
          bgColor: const Color(0xFF25D366).withValues(alpha: 0.1),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WhatsAppSetupPage()),
          ),
        ),
        ActionItem(
          title: 'Configurações',
          subtitle: 'Ajustar preferências',
          icon: PhosphorIcons.gear(),
          color: AppTheme.getTextColor(context),
          bgColor: AppTheme.getTextColor(context).withValues(alpha: 0.1),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          ),
        ),
      ];
}
