import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/supabase/user_service.dart';
import '../config/app_config.dart';

enum UserLoadingState {
  idle,
  loading,
  success,
  error,
}

class UserStore extends ChangeNotifier {
  final UserService _userService = UserService();

  // Estados
  UserLoadingState _loadingState = UserLoadingState.idle;
  String? _errorMessage;

  // Dados
  List<User> _users = [];
  List<User> _customers = [];
  List<User> _agents = [];
  Map<String, int> _userStats = {
    'total': 0,
    'customers': 0,
    'agents': 0,
    'admins': 0,
    'online': 0,
    'offline': 0,
    'away': 0,
    'busy': 0,
  };

  // Filtros
  UserRole? _filterRole;
  UserStatus? _filterStatus;
  String _searchQuery = '';

  // Getters
  UserLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == UserLoadingState.loading;
  bool get hasError => _loadingState == UserLoadingState.error;

  List<User> get users => _applyFilters(_users);
  List<User> get allUsers => _users;
  List<User> get customers => _customers;
  List<User> get agents => _agents;
  Map<String, int> get userStats => _userStats;

  // Filtros
  UserRole? get filterRole => _filterRole;
  UserStatus? get filterStatus => _filterStatus;
  String get searchQuery => _searchQuery;

  // Métodos públicos

  /// Carregar todos os usuários
  Future<void> loadUsers({
    bool forceRefresh = false,
    UserRole? role,
    UserStatus? status,
  }) async {
    if (_loadingState == UserLoadingState.loading && !forceRefresh) return;

    try {
      _setLoadingState(UserLoadingState.loading);
      _clearError();

      AppConfig.log('Carregando usuários...', tag: 'UserStore');

      final users = await _userService.getUsers(
        role: role ?? _filterRole,
        status: status ?? _filterStatus,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      _users = users;
      _setLoadingState(UserLoadingState.success);

      AppConfig.log('${users.length} usuários carregados', tag: 'UserStore');

      // Carregar dados específicos
      await _loadCustomers();
      await _loadAgents();
      await _loadUserStats();
    } catch (e) {
      AppConfig.log('Erro ao carregar usuários: $e', tag: 'UserStore');
      _setError('Erro ao carregar usuários: $e');
    }
  }

  /// Carregar clientes
  Future<void> loadCustomers() async {
    await _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      _customers = await _userService.getCustomers(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      notifyListeners();
    } catch (e) {
      AppConfig.log('Erro ao carregar clientes: $e', tag: 'UserStore');
    }
  }

  /// Carregar agentes
  Future<void> loadAgents() async {
    await _loadAgents();
  }

  Future<void> _loadAgents() async {
    try {
      _agents = await _userService.getAgents(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      notifyListeners();
    } catch (e) {
      AppConfig.log('Erro ao carregar agentes: $e', tag: 'UserStore');
    }
  }

  /// Buscar usuário por ID
  Future<User?> getUserById(String userId) async {
    try {
      AppConfig.log('Buscando usuário: $userId', tag: 'UserStore');

      // Verificar se já está na lista
      final existingUser = _users.where((u) => u.id == userId).firstOrNull;
      if (existingUser != null) {
        return existingUser;
      }

      // Buscar no serviço
      final user = await _userService.getUserById(userId);
      if (user != null) {
        // Adicionar à lista se não existir
        _users.add(user);
        notifyListeners();
      }

      return user;
    } catch (e) {
      AppConfig.log('Erro ao buscar usuário: $e', tag: 'UserStore');
      return null;
    }
  }

  /// Criar novo usuário
  Future<User?> createUser({
    required String name,
    required String email,
    String? phone,
    String? avatarUrl,
    UserRole role = UserRole.customer,
    UserStatus status = UserStatus.offline,
  }) async {
    try {
      _setLoadingState(UserLoadingState.loading);
      _clearError();

      AppConfig.log('Criando usuário: $email', tag: 'UserStore');

      final user = await _userService.createUser(
        name: name,
        email: email,
        phone: phone,
        avatarUrl: avatarUrl,
        role: role,
        status: status,
      );

      // Adicionar à lista
      _users.insert(0, user);
      
      // Atualizar listas específicas
      if (role == UserRole.customer) {
        _customers.insert(0, user);
      } else if (role == UserRole.agent) {
        _agents.insert(0, user);
      }
      
      _setLoadingState(UserLoadingState.success);

      AppConfig.log('Usuário criado: ${user.id}', tag: 'UserStore');
      await _loadUserStats(); // Atualizar estatísticas

      return user;
    } catch (e) {
      AppConfig.log('Erro ao criar usuário: $e', tag: 'UserStore');
      _setError('Erro ao criar usuário: $e');
      return null;
    }
  }

  /// Atualizar usuário
  Future<bool> updateUser({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    UserRole? role,
    UserStatus? status,
  }) async {
    try {
      _setLoadingState(UserLoadingState.loading);
      _clearError();

      AppConfig.log('Atualizando usuário: $userId', tag: 'UserStore');

      final updatedUser = await _userService.updateUser(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        avatarUrl: avatarUrl,
        role: role,
        status: status,
      );

      // Atualizar na lista
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      }

      // Atualizar listas específicas
      await _loadCustomers();
      await _loadAgents();

      _setLoadingState(UserLoadingState.success);
      AppConfig.log('Usuário atualizado: $userId', tag: 'UserStore');
      await _loadUserStats(); // Atualizar estatísticas

      return true;
    } catch (e) {
      AppConfig.log('Erro ao atualizar usuário: $e', tag: 'UserStore');
      _setError('Erro ao atualizar usuário: $e');
      return false;
    }
  }

  /// Atualizar status do usuário
  Future<bool> updateUserStatus(String userId, UserStatus status) async {
    try {
      await _userService.updateUserStatus(userId, status);
      
      // Atualizar na lista local
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(
          status: status,
          lastSeen: status == UserStatus.offline ? DateTime.now() : null,
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      AppConfig.log('Erro ao atualizar status: $e', tag: 'UserStore');
      return false;
    }
  }

  /// Deletar usuário
  Future<bool> deleteUser(String userId) async {
    try {
      _setLoadingState(UserLoadingState.loading);
      _clearError();

      AppConfig.log('Deletando usuário: $userId', tag: 'UserStore');

      await _userService.deleteUser(userId);

      // Remover da lista
      _users.removeWhere((u) => u.id == userId);
      _customers.removeWhere((u) => u.id == userId);
      _agents.removeWhere((u) => u.id == userId);

      _setLoadingState(UserLoadingState.success);
      AppConfig.log('Usuário deletado: $userId', tag: 'UserStore');
      await _loadUserStats(); // Atualizar estatísticas

      return true;
    } catch (e) {
      AppConfig.log('Erro ao deletar usuário: $e', tag: 'UserStore');
      _setError('Erro ao deletar usuário: $e');
      return false;
    }
  }

  /// Verificar se email já existe
  Future<bool> emailExists(String email) async {
    try {
      return await _userService.emailExists(email);
    } catch (e) {
      AppConfig.log('Erro ao verificar email: $e', tag: 'UserStore');
      return false;
    }
  }

  /// Buscar usuário por email
  Future<User?> getUserByEmail(String email) async {
    try {
      return await _userService.getUserByEmail(email);
    } catch (e) {
      AppConfig.log('Erro ao buscar usuário por email: $e', tag: 'UserStore');
      return null;
    }
  }

  /// Buscar usuários online
  Future<List<User>> getOnlineUsers() async {
    try {
      return await _userService.getOnlineUsers();
    } catch (e) {
      AppConfig.log('Erro ao buscar usuários online: $e', tag: 'UserStore');
      return [];
    }
  }

  // Métodos de filtro

  void setRoleFilter(UserRole? role) {
    _filterRole = role;
    notifyListeners();
  }

  void setStatusFilter(UserStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _filterRole = null;
    _filterStatus = null;
    _searchQuery = '';
    notifyListeners();
  }

  // Métodos privados

  void _setLoadingState(UserLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _loadingState = UserLoadingState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  List<User> _applyFilters(List<User> users) {
    var filtered = users;

    // Filtro por role
    if (_filterRole != null) {
      filtered = filtered.where((u) => u.role == _filterRole).toList();
    }

    // Filtro por status
    if (_filterStatus != null) {
      filtered = filtered.where((u) => u.status == _filterStatus).toList();
    }

    // Filtro por busca
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((u) {
        return u.name.toLowerCase().contains(query) ||
               u.email.toLowerCase().contains(query) ||
               (u.phone?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  Future<void> _loadUserStats() async {
    try {
      _userStats = await _userService.getUserStats();
      notifyListeners();
    } catch (e) {
      // Fallback para estatísticas locais
      _userStats = {
        'total': _users.length,
        'customers': _users.where((u) => u.role == UserRole.customer).length,
        'agents': _users.where((u) => u.role == UserRole.agent).length,
        'admins': _users.where((u) => u.role == UserRole.admin).length,
        'online': _users.where((u) => u.status == UserStatus.online).length,
        'offline': _users.where((u) => u.status == UserStatus.offline).length,
        'away': _users.where((u) => u.status == UserStatus.away).length,
        'busy': _users.where((u) => u.status == UserStatus.busy).length,
      };
      notifyListeners();
    }
  }
}