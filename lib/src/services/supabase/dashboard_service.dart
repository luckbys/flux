import 'dart:async';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../../config/app_config.dart';
import 'supabase_service.dart';

class DashboardService {
  final SupabaseService _supabaseService = SupabaseService();

  /// Buscar estatísticas gerais do dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      AppConfig.log('Buscando estatísticas do dashboard...',
          tag: 'DashboardService');

      // Buscar estatísticas em paralelo
      final results = await Future.wait([
        _getTicketStats(),
        _getQuoteStats(),
        _getUserStats(),
        _getRecentActivity(),
      ]);

      final stats = {
        'tickets': results[0],
        'quotes': results[1],
        'users': results[2],
        'recentActivity': results[3],
        'lastUpdated': DateTime.now(),
      };

      AppConfig.log('Estatísticas carregadas com sucesso',
          tag: 'DashboardService');
      return stats;
    } catch (e) {
      AppConfig.log('Erro ao buscar estatísticas: $e', tag: 'DashboardService');
      rethrow;
    }
  }

  /// Estatísticas de tickets
  Future<Map<String, dynamic>> _getTicketStats() async {
    try {
      final response = await _supabaseService.client
          .from('tickets')
          .select('ticket_status, priority, created_at');

      final tickets = response as List;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeek = now.subtract(const Duration(days: 7));

      return {
        'total': tickets.length,
        'open': tickets.where((t) => t['ticket_status'] == 'open').length,
        'inProgress':
            tickets.where((t) => t['ticket_status'] == 'in_progress').length,
        'resolved':
            tickets.where((t) => t['ticket_status'] == 'resolved').length,
        'closed': tickets.where((t) => t['ticket_status'] == 'closed').length,
        'resolvedToday': tickets.where((t) {
          final createdAt = DateTime.parse(t['created_at']);
          return t['ticket_status'] == 'resolved' && createdAt.isAfter(today);
        }).length,
        'createdThisWeek': tickets.where((t) {
          final createdAt = DateTime.parse(t['created_at']);
          return createdAt.isAfter(thisWeek);
        }).length,
        'highPriority': tickets
            .where((t) => t['priority'] == 'high' || t['priority'] == 'urgent')
            .length,
      };
    } catch (e) {
      AppConfig.log('Erro ao buscar estatísticas de tickets: $e',
          tag: 'DashboardService');
      return {
        'total': 0,
        'open': 0,
        'inProgress': 0,
        'resolved': 0,
        'closed': 0,
        'resolvedToday': 0,
        'createdThisWeek': 0,
        'highPriority': 0,
      };
    }
  }

  /// Estatísticas de orçamentos
  Future<Map<String, dynamic>> _getQuoteStats() async {
    try {
      final response = await _supabaseService.client
          .from('quotes')
          .select('status, created_at, valid_until');

      final quotes = response as List;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return {
        'total': quotes.length,
        'draft': quotes.where((q) => q['status'] == 'draft').length,
        'pending': quotes.where((q) => q['status'] == 'pending').length,
        'approved': quotes.where((q) => q['status'] == 'approved').length,
        'rejected': quotes.where((q) => q['status'] == 'rejected').length,
        'converted': quotes.where((q) => q['status'] == 'converted').length,
        'createdToday': quotes.where((q) {
          final createdAt = DateTime.parse(q['created_at']);
          return createdAt.isAfter(today);
        }).length,
        'expiringSoon': quotes.where((q) {
          if (q['valid_until'] == null) return false;
          final validUntil = DateTime.parse(q['valid_until']);
          final inThreeDays = now.add(const Duration(days: 3));
          return validUntil.isBefore(inThreeDays) && validUntil.isAfter(now);
        }).length,
      };
    } catch (e) {
      AppConfig.log('Erro ao buscar estatísticas de orçamentos: $e',
          tag: 'DashboardService');
      return {
        'total': 0,
        'draft': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'converted': 0,
        'createdToday': 0,
        'expiringSoon': 0,
      };
    }
  }

  /// Estatísticas de usuários
  Future<Map<String, dynamic>> _getUserStats() async {
    try {
      final response = await _supabaseService.client
          .from('users')
          .select('role, status, created_at, last_seen');

      final users = response as List;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

      return {
        'total': users.length,
        'customers': users.where((u) => u['role'] == 'customer').length,
        'agents': users.where((u) => u['role'] == 'agent').length,
        'admins': users.where((u) => u['role'] == 'admin').length,
        'online': users.where((u) => u['status'] == 'online').length,
        'offline': users.where((u) => u['status'] == 'offline').length,
        'away': users.where((u) => u['status'] == 'away').length,
        'busy': users.where((u) => u['status'] == 'busy').length,
        'newToday': users.where((u) {
          final createdAt = DateTime.parse(u['created_at']);
          return createdAt.isAfter(today);
        }).length,
        'activeRecently': users.where((u) {
          if (u['last_seen'] == null) return false;
          final lastSeen = DateTime.parse(u['last_seen']);
          return lastSeen.isAfter(fiveMinutesAgo);
        }).length,
      };
    } catch (e) {
      AppConfig.log('Erro ao buscar estatísticas de usuários: $e',
          tag: 'DashboardService');
      return {
        'total': 0,
        'customers': 0,
        'agents': 0,
        'admins': 0,
        'online': 0,
        'offline': 0,
        'away': 0,
        'busy': 0,
        'newToday': 0,
        'activeRecently': 0,
      };
    }
  }

  /// Atividades recentes
  Future<List<Map<String, dynamic>>> _getRecentActivity() async {
    try {
      final activities = <Map<String, dynamic>>[];

      // Buscar tickets recentes
      final recentTickets =
          await _supabaseService.client.from('tickets').select('''
            id,
            title,
            ticket_status,
            created_at,
            customer:users!customer_id(name)
          ''').order('created_at', ascending: false).limit(5);

      for (final ticket in recentTickets) {
        activities.add({
          'type': 'ticket',
          'id': ticket['id'],
          'title': 'Novo ticket: ${ticket['title']}',
          'description': 'Criado por ${ticket['customer']['name']}',
          'timestamp': DateTime.parse(ticket['created_at']),
          'status': ticket['ticket_status'],
        });
      }

      // Buscar orçamentos recentes
      final recentQuotes =
          await _supabaseService.client.from('quotes').select('''
            id,
            title,
            status,
            created_at,
            customer:users!customer_id(name)
          ''').order('created_at', ascending: false).limit(5);

      for (final quote in recentQuotes) {
        activities.add({
          'type': 'quote',
          'id': quote['id'],
          'title': 'Novo orçamento: ${quote['title']}',
          'description': 'Para ${quote['customer']['name']}',
          'timestamp': DateTime.parse(quote['created_at']),
          'status': quote['status'],
        });
      }

      // Buscar mensagens recentes
      final recentMessages =
          await _supabaseService.client.from('messages').select('''
            id,
            content,
            created_at,
            sender:users!sender_id(name)
          ''').order('created_at', ascending: false).limit(3);

      for (final message in recentMessages) {
        activities.add({
          'type': 'message',
          'id': message['id'],
          'title': 'Nova mensagem',
          'description': 'De ${message['sender']['name']}',
          'timestamp': DateTime.parse(message['created_at']),
          'content': message['content'],
        });
      }

      // Ordenar por timestamp (mais recente primeiro)
      activities.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      // Retornar apenas os 10 mais recentes
      return activities.take(10).toList();
    } catch (e) {
      AppConfig.log('Erro ao buscar atividades recentes: $e',
          tag: 'DashboardService');
      return [];
    }
  }

  /// Buscar tickets recentes para o dashboard
  Future<List<Ticket>> getRecentTickets({int limit = 5}) async {
    try {
      AppConfig.log('Buscando tickets recentes...', tag: 'DashboardService');

      final response = await _supabaseService.client.from('tickets').select('''
            *,
            customer:users!customer_id(
              id,
              name,
              email,
              avatar_url,
              phone,
              role,
              status,
              created_at
            ),
            assigned_user:users!assigned_to(
              id,
              name,
              email,
              avatar_url,
              phone,
              role,
              status,
              created_at
            )
          ''').order('created_at', ascending: false).limit(limit);

      final tickets =
          (response as List).map((json) => _mapTicketFromDb(json)).toList();

      AppConfig.log('${tickets.length} tickets recentes carregados',
          tag: 'DashboardService');
      return tickets;
    } catch (e) {
      AppConfig.log('Erro ao buscar tickets recentes: $e',
          tag: 'DashboardService');
      return [];
    }
  }

  /// Buscar usuários online
  Future<List<User>> getOnlineUsers({int limit = 10}) async {
    try {
      AppConfig.log('Buscando usuários online...', tag: 'DashboardService');

      final response = await _supabaseService.client
          .from('users')
          .select('*')
          .eq('status', 'online')
          .order('last_seen', ascending: false)
          .limit(limit);

      final users =
          (response as List).map((json) => _mapUserFromDb(json)).toList();

      AppConfig.log('${users.length} usuários online encontrados',
          tag: 'DashboardService');
      return users;
    } catch (e) {
      AppConfig.log('Erro ao buscar usuários online: $e',
          tag: 'DashboardService');
      return [];
    }
  }

  /// Buscar métricas de performance
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      AppConfig.log('Buscando métricas de performance...',
          tag: 'DashboardService');

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Buscar tickets dos últimos 30 dias
      final ticketsResponse = await _supabaseService.client
          .from('tickets')
          .select('created_at, resolved_at, ticket_status')
          .gte('created_at', thirtyDaysAgo.toIso8601String());

      final tickets = ticketsResponse as List;

      // Calcular tempo médio de resolução
      final resolvedTickets = tickets
          .where((t) =>
              t['resolved_at'] != null && t['ticket_status'] == 'resolved')
          .toList();

      double avgResolutionTime = 0;
      if (resolvedTickets.isNotEmpty) {
        final totalTime = resolvedTickets.fold<int>(0, (sum, ticket) {
          final created = DateTime.parse(ticket['created_at']);
          final resolved = DateTime.parse(ticket['resolved_at']);
          return sum + resolved.difference(created).inHours;
        });
        avgResolutionTime = totalTime / resolvedTickets.length;
      }

      // Taxa de resolução
      final resolutionRate = tickets.isNotEmpty
          ? (resolvedTickets.length / tickets.length) * 100
          : 0.0;

      // Satisfação simulada (em um sistema real, viria de uma tabela de feedback)
      final satisfactionRate =
          85.0 + (DateTime.now().millisecond % 15); // 85-100%

      return {
        'avgResolutionTime': avgResolutionTime,
        'resolutionRate': resolutionRate,
        'satisfactionRate': satisfactionRate,
        'totalTicketsLast30Days': tickets.length,
        'resolvedTicketsLast30Days': resolvedTickets.length,
      };
    } catch (e) {
      AppConfig.log('Erro ao buscar métricas de performance: $e',
          tag: 'DashboardService');
      return {
        'avgResolutionTime': 0.0,
        'resolutionRate': 0.0,
        'satisfactionRate': 0.0,
        'totalTicketsLast30Days': 0,
        'resolvedTicketsLast30Days': 0,
      };
    }
  }

  /// Mapear ticket do banco de dados
  Ticket _mapTicketFromDb(Map<String, dynamic> json) {
    final customerData = json['customer'] as Map<String, dynamic>?;
    final assignedUserData = json['assigned_user'] as Map<String, dynamic>?;

    return Ticket(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: TicketStatus.values.firstWhere(
        (status) => status.name == json['ticket_status'],
        orElse: () => TicketStatus.open,
      ),
      priority: TicketPriority.values.firstWhere(
        (priority) => priority.name == json['priority'],
        orElse: () => TicketPriority.normal,
      ),
      category: TicketCategory.values.firstWhere(
        (category) => category.name == json['category'],
        orElse: () => TicketCategory.general,
      ),
      customer: customerData != null
          ? _mapUserFromDb(customerData)
          : _getDefaultUser(),
      assignedAgent:
          assignedUserData != null ? _mapUserFromDb(assignedUserData) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
    );
  }

  /// Mapear usuário do banco de dados
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

  /// Usuário padrão para casos onde não há dados
  User _getDefaultUser() {
    return User(
      id: 'default',
      name: 'Usuário não encontrado',
      email: 'nao-encontrado@exemplo.com',
      role: UserRole.customer,
      status: UserStatus.offline,
      createdAt: DateTime.now(),
    );
  }
}
