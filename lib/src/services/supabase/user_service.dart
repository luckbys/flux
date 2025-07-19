import 'dart:async';
import '../../models/user.dart';
import '../../config/app_config.dart';
import 'supabase_service.dart';

class UserService {
  final SupabaseService _supabaseService = SupabaseService();

  /// Buscar todos os usuários
  Future<List<User>> getUsers({
    UserRole? role,
    UserStatus? status,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      AppConfig.log('Buscando usuários...', tag: 'UserService');

      var queryBuilder = _supabaseService.client
          .from('users')
          .select('*');

      if (role != null) {
        queryBuilder = queryBuilder.eq('role', role.name);
      }

      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status.name);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryBuilder = queryBuilder.or('name.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final users = (response as List).map((json) => _mapUserFromDb(json)).toList();

      AppConfig.log('${users.length} usuários carregados', tag: 'UserService');
      return users;
    } catch (e) {
      AppConfig.log('Erro ao buscar usuários: $e', tag: 'UserService');
      rethrow;
    }
  }

  /// Buscar usuário por ID
  Future<User?> getUserById(String userId) async {
    try {
      AppConfig.log('Buscando usuário: $userId', tag: 'UserService');

      final response = await _supabaseService.client
          .from('users')
          .select('*')
          .filter('id', 'eq', userId)
          .single();

      return _mapUserFromDb(response);
    } catch (e) {
      AppConfig.log('Erro ao buscar usuário: $e', tag: 'UserService');
      return null;
    }
  }

  /// Buscar usuários por role (clientes, agentes, etc.)
  Future<List<User>> getUsersByRole(UserRole role) async {
    return getUsers(role: role);
  }

  /// Buscar clientes
  Future<List<User>> getCustomers({String? searchQuery}) async {
    return getUsers(role: UserRole.customer, searchQuery: searchQuery);
  }

  /// Buscar agentes
  Future<List<User>> getAgents({String? searchQuery}) async {
    return getUsers(role: UserRole.agent, searchQuery: searchQuery);
  }

  /// Criar novo usuário
  Future<User> createUser({
    required String name,
    required String email,
    String? phone,
    String? avatarUrl,
    UserRole role = UserRole.customer,
    UserStatus status = UserStatus.offline,
  }) async {
    try {
      AppConfig.log('Criando usuário: $email', tag: 'UserService');

      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'avatar_url': avatarUrl,
        'role': role.name,
        'status': status.name,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from('users')
          .insert(userData)
          .select()
          .single();

      final user = _mapUserFromDb(response);
      AppConfig.log('Usuário criado: ${user.id}', tag: 'UserService');
      return user;
    } catch (e) {
      AppConfig.log('Erro ao criar usuário: $e', tag: 'UserService');
      rethrow;
    }
  }

  /// Atualizar usuário
  Future<User> updateUser({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    UserRole? role,
    UserStatus? status,
    DateTime? lastSeen,
  }) async {
    try {
      AppConfig.log('Atualizando usuário: $userId', tag: 'UserService');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (role != null) updateData['role'] = role.name;
      if (status != null) updateData['status'] = status.name;
      if (lastSeen != null) updateData['last_seen'] = lastSeen.toIso8601String();

      final response = await _supabaseService.client
          .from('users')
          .update(updateData)
          .filter('id', 'eq', userId)
          .select()
          .single();

      final user = _mapUserFromDb(response);
      AppConfig.log('Usuário atualizado: $userId', tag: 'UserService');
      return user;
    } catch (e) {
      AppConfig.log('Erro ao atualizar usuário: $e', tag: 'UserService');
      rethrow;
    }
  }

  /// Atualizar status do usuário
  Future<void> updateUserStatus(String userId, UserStatus status) async {
    try {
      await updateUser(
        userId: userId,
        status: status,
        lastSeen: status == UserStatus.offline ? DateTime.now() : null,
      );
    } catch (e) {
      AppConfig.log('Erro ao atualizar status do usuário: $e', tag: 'UserService');
      rethrow;
    }
  }

  /// Deletar usuário
  Future<void> deleteUser(String userId) async {
    try {
      AppConfig.log('Deletando usuário: $userId', tag: 'UserService');

      await _supabaseService.client
          .from('users')
          .delete()
          .filter('id', 'eq', userId);

      AppConfig.log('Usuário deletado: $userId', tag: 'UserService');
    } catch (e) {
      AppConfig.log('Erro ao deletar usuário: $e', tag: 'UserService');
      rethrow;
    }
  }

  /// Buscar estatísticas de usuários
  Future<Map<String, int>> getUserStats() async {
    try {
      AppConfig.log('Buscando estatísticas de usuários', tag: 'UserService');

      final response = await _supabaseService.client
          .from('users')
          .select('role, status');

      final users = response as List;

      final stats = <String, int>{
        'total': users.length,
        'customers': 0,
        'agents': 0,
        'admins': 0,
        'online': 0,
        'offline': 0,
        'away': 0,
        'busy': 0,
      };

      for (final user in users) {
        final role = user['role'] as String;
        final status = user['status'] as String;
        
        // Contar por role
        if (role == 'customer') stats['customers'] = (stats['customers'] ?? 0) + 1;
        if (role == 'agent') stats['agents'] = (stats['agents'] ?? 0) + 1;
        if (role == 'admin') stats['admins'] = (stats['admins'] ?? 0) + 1;
        
        // Contar por status
        stats[status] = (stats[status] ?? 0) + 1;
      }

      AppConfig.log('Estatísticas carregadas: $stats', tag: 'UserService');
      return stats;
    } catch (e) {
      AppConfig.log('Erro ao buscar estatísticas: $e', tag: 'UserService');
      rethrow;
    }
  }

  /// Buscar usuários online
  Future<List<User>> getOnlineUsers() async {
    return getUsers(status: UserStatus.online);
  }

  /// Verificar se email já existe
  Future<bool> emailExists(String email) async {
    try {
      final response = await _supabaseService.client
          .from('users')
          .select('id')
          .eq('email', email)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      AppConfig.log('Erro ao verificar email: $e', tag: 'UserService');
      return false;
    }
  }

  /// Buscar usuário por email
  Future<User?> getUserByEmail(String email) async {
    try {
      final response = await _supabaseService.client
          .from('users')
          .select('*')
          .eq('email', email)
          .single();

      return _mapUserFromDb(response);
    } catch (e) {
      AppConfig.log('Usuário não encontrado para email: $email', tag: 'UserService');
      return null;
    }
  }

  /// Mapear dados do banco para modelo User
  User _mapUserFromDb(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.customer,
      ),
      status: UserStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => UserStatus.offline,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
    );
  }
}