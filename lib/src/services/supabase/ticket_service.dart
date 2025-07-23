import 'dart:async';
import '../../models/ticket.dart';
import '../../models/user.dart' as app_user;
import '../../models/message.dart';
import '../../config/app_config.dart';
import 'supabase_service.dart';

class TicketService {
  final SupabaseService _supabaseService = SupabaseService();

  /// Buscar todos os tickets
  Future<List<Ticket>> getTickets({
    TicketStatus? status,
    TicketPriority? priority,
    String? assignedUserId,
    String? customerId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      AppConfig.log('Buscando tickets...', tag: 'TicketService');

      var query = _supabaseService.from('tickets').select('''
            *,
            customer:customer_id(id, name, email, avatar_url, role),
            assigned_agent:assigned_to(id, name, email, avatar_url, role)
          ''');

      // Aplicar filtros
      if (status != null) {
        query = query.eq('ticket_status', _mapStatusToDb(status));
      }
      if (priority != null) {
        query = query.eq('priority', _mapPriorityToDb(priority));
      }
      if (assignedUserId != null) {
        query = query.eq('assigned_to', assignedUserId);
      }
      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final tickets =
          (response as List).map((json) => _mapTicketFromDb(json)).toList();

      AppConfig.log('${tickets.length} tickets carregados',
          tag: 'TicketService');
      return tickets;
    } catch (e) {
      AppConfig.log('Erro ao buscar tickets: $e', tag: 'TicketService');
      rethrow;
    }
  }

  /// Buscar ticket por ID
  Future<Ticket?> getTicketById(String ticketId) async {
    try {
      AppConfig.log('Buscando ticket: $ticketId', tag: 'TicketService');

      final response = await _supabaseService.from('tickets').select('''
            *,
            customer:customer_id(id, name, email, avatar_url, role),
            assigned_agent:assigned_to(id, name, email, avatar_url, role)
          ''').eq('id', ticketId).single();

      final ticket = _mapTicketFromDb(response);
      AppConfig.log('Ticket carregado: ${ticket.title}', tag: 'TicketService');
      return ticket;
    } catch (e) {
      AppConfig.log('Erro ao buscar ticket: $e', tag: 'TicketService');
      return null;
    }
  }

  /// Criar novo ticket
  Future<Ticket> createTicket({
    required String title,
    required String description,
    required String customerId,
    TicketPriority priority = TicketPriority.normal,
    TicketCategory category = TicketCategory.general,
    String? assignedTo,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppConfig.log('Criando ticket: $title', tag: 'TicketService');

      // Log dos dados recebidos para debug
      AppConfig.log('Dados recebidos:', tag: 'TicketService');
      AppConfig.log('  title: $title', tag: 'TicketService');
      AppConfig.log('  description: $description', tag: 'TicketService');
      AppConfig.log('  customerId: $customerId', tag: 'TicketService');
      AppConfig.log('  priority: $priority', tag: 'TicketService');
      AppConfig.log('  category: $category', tag: 'TicketService');
      AppConfig.log('  assignedTo: $assignedTo', tag: 'TicketService');

      final mappedPriority = _mapPriorityToDb(priority);
      final mappedCategory = _mapCategoryToDb(category);

      // Log dos dados mapeados
      AppConfig.log('Dados mapeados:', tag: 'TicketService');
      AppConfig.log('  mappedPriority: $mappedPriority', tag: 'TicketService');
      AppConfig.log('  mappedCategory: $mappedCategory', tag: 'TicketService');

      final ticketData = {
        'title': title,
        'description': description,
        'customer_id': customerId,
        'priority': mappedPriority,
        'category': mappedCategory ?? 'general', // Garantir que nunca seja null
        'ticket_status': 'open',
        'assigned_to': assignedTo,
        'metadata': metadata ?? {},
        // O campo 'number' será gerado automaticamente pela sequência
      };

      // Log dos dados finais
      AppConfig.log('Dados finais para inserção: $ticketData',
          tag: 'TicketService');

      AppConfig.log('Iniciando inserção no banco...', tag: 'TicketService');

      final response =
          await _supabaseService.from('tickets').insert(ticketData).select('''
            *,
            customer:customer_id(id, name, email, avatar_url, role),
            assigned_agent:assigned_to(id, name, email, avatar_url, role)
          ''').single();

      AppConfig.log('Resposta do banco recebida: $response',
          tag: 'TicketService');

      final ticket = _mapTicketFromDb(response);
      AppConfig.log('Ticket criado: ${ticket.id}', tag: 'TicketService');
      return ticket;
    } catch (e) {
      AppConfig.log('Erro ao criar ticket: $e', tag: 'TicketService');
      rethrow;
    }
  }

  /// Atualizar ticket
  Future<Ticket> updateTicket({
    required String ticketId,
    String? title,
    String? description,
    TicketStatus? status,
    TicketPriority? priority,
    TicketCategory? category,
    String? assignedTo,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppConfig.log('Atualizando ticket: $ticketId', tag: 'TicketService');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (status != null) {
        updates['ticket_status'] = _mapStatusToDb(status);
        if (status == TicketStatus.resolved) {
          updates['resolved_at'] = DateTime.now().toIso8601String();
        } else if (status == TicketStatus.closed) {
          updates['closed_at'] = DateTime.now().toIso8601String();
        }
      }
      if (priority != null) updates['priority'] = _mapPriorityToDb(priority);
      if (category != null) updates['category'] = _mapCategoryToDb(category);
      if (assignedTo != null) updates['assigned_to'] = assignedTo;
      if (metadata != null) updates['metadata'] = metadata;

      final response = await _supabaseService
          .from('tickets')
          .update(updates)
          .eq('id', ticketId)
          .select('''
            *,
            customer:customer_id(id, name, email, avatar_url, role),
            assigned_agent:assigned_to(id, name, email, avatar_url, role)
          ''').single();

      final ticket = _mapTicketFromDb(response);
      AppConfig.log('Ticket atualizado: ${ticket.id}', tag: 'TicketService');
      return ticket;
    } catch (e) {
      AppConfig.log('Erro ao atualizar ticket: $e', tag: 'TicketService');
      rethrow;
    }
  }

  /// Deletar ticket
  Future<void> deleteTicket(String ticketId) async {
    try {
      AppConfig.log('Deletando ticket: $ticketId', tag: 'TicketService');

      await _supabaseService.from('tickets').delete().eq('id', ticketId);

      AppConfig.log('Ticket deletado: $ticketId', tag: 'TicketService');
    } catch (e) {
      AppConfig.log('Erro ao deletar ticket: $e', tag: 'TicketService');
      rethrow;
    }
  }

  /// Buscar mensagens de um ticket
  Future<List<Message>> getTicketMessages(String ticketId) async {
    try {
      AppConfig.log('Buscando mensagens do ticket: $ticketId',
          tag: 'TicketService');

      // Primeiro buscar a conversa associada ao ticket
      final ticketResponse = await _supabaseService
          .from('tickets')
          .select('conversation_id')
          .eq('id', ticketId)
          .single();

      final conversationId = ticketResponse['conversation_id'];
      if (conversationId == null) {
        AppConfig.log('Ticket sem conversa associada', tag: 'TicketService');
        return [];
      }

      final response = await _supabaseService
          .from('messages')
          .select('''
            *,
            sender:sender_id(id, name, email, avatar_url, role),
            attachments:message_attachments(*)
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final messages =
          (response as List).map((json) => _mapMessageFromDb(json)).toList();

      AppConfig.log('${messages.length} mensagens carregadas',
          tag: 'TicketService');
      return messages;
    } catch (e) {
      AppConfig.log('Erro ao buscar mensagens: $e', tag: 'TicketService');
      return [];
    }
  }

  /// Enviar mensagem no ticket
  Future<Message> sendTicketMessage({
    required String ticketId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    List<MessageAttachment>? attachments,
  }) async {
    try {
      AppConfig.log('Enviando mensagem no ticket: $ticketId',
          tag: 'TicketService');

      // Buscar ou criar conversa do ticket
      String conversationId = await _getOrCreateTicketConversation(ticketId);

      // Criar mensagem
      final messageData = {
        'content': content,
        'msg_type': type.name,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'msg_status': 'sent',
      };

      final response =
          await _supabaseService.from('messages').insert(messageData).select('''
            *,
            sender:sender_id(id, name, email, avatar_url, role)
          ''').single();

      final message = _mapMessageFromDb(response);

      // Adicionar anexos se houver
      if (attachments != null && attachments.isNotEmpty) {
        await _addMessageAttachments(message.id, attachments);
      }

      AppConfig.log('Mensagem enviada: ${message.id}', tag: 'TicketService');
      return message;
    } catch (e) {
      AppConfig.log('Erro ao enviar mensagem: $e', tag: 'TicketService');
      rethrow;
    }
  }

  /// Buscar estatísticas de tickets
  Future<Map<String, int>> getTicketStats({String? assignedUserId}) async {
    try {
      AppConfig.log('Buscando estatísticas de tickets', tag: 'TicketService');

      var query = _supabaseService.from('tickets').select('ticket_status');

      if (assignedUserId != null) {
        query = query.eq('assigned_to', assignedUserId);
      }

      final response = await query;
      final tickets = response as List;

      final stats = <String, int>{
        'total': tickets.length,
        'open': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0,
      };

      for (final ticket in tickets) {
        final status = ticket['ticket_status'] as String;
        switch (status) {
          case 'open':
            stats['open'] = (stats['open'] ?? 0) + 1;
            break;
          case 'in_progress':
            stats['in_progress'] = (stats['in_progress'] ?? 0) + 1;
            break;
          case 'resolved':
            stats['resolved'] = (stats['resolved'] ?? 0) + 1;
            break;
          case 'closed':
            stats['closed'] = (stats['closed'] ?? 0) + 1;
            break;
        }
      }

      AppConfig.log('Estatísticas carregadas: $stats', tag: 'TicketService');
      return stats;
    } catch (e) {
      AppConfig.log('Erro ao buscar estatísticas: $e', tag: 'TicketService');
      return {
        'total': 0,
        'open': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0
      };
    }
  }

  /// Stream de mudanças em tickets
  Stream<List<Ticket>> watchTickets({String? assignedUserId}) {
    try {
      AppConfig.log('Iniciando watch de tickets', tag: 'TicketService');

      final stream =
          _supabaseService.from('tickets').stream(primaryKey: ['id']);

      if (assignedUserId != null) {
        return stream.eq('assigned_to', assignedUserId).map((data) {
          return (data as List).map((json) => _mapTicketFromDb(json)).toList();
        });
      }

      return stream.map((data) {
        return (data as List).map((json) => _mapTicketFromDb(json)).toList();
      });
    } catch (e) {
      AppConfig.log('Erro no watch de tickets: $e', tag: 'TicketService');
      return Stream.value([]);
    }
  }

  // Métodos auxiliares privados

  String _mapStatusToDb(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'open';
      case TicketStatus.inProgress:
        return 'in_progress';
      case TicketStatus.waitingCustomer:
        return 'waiting_customer';
      case TicketStatus.resolved:
        return 'resolved';
      case TicketStatus.closed:
        return 'closed';
    }
  }

  TicketStatus _mapStatusFromDb(String? status) {
    if (status == null) return TicketStatus.open;

    switch (status) {
      case 'open':
        return TicketStatus.open;
      case 'in_progress':
        return TicketStatus.inProgress;
      case 'waiting_customer':
        return TicketStatus.waitingCustomer;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }

  String _mapPriorityToDb(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return 'low';
      case TicketPriority.normal:
        return 'medium';
      case TicketPriority.high:
        return 'high';
      case TicketPriority.urgent:
        return 'urgent';
      default:
        return 'medium'; // Default para casos inesperados
    }
  }

  TicketPriority _mapPriorityFromDb(String? priority) {
    if (priority == null) return TicketPriority.normal;

    switch (priority) {
      case 'low':
        return TicketPriority.low;
      case 'medium':
        return TicketPriority.normal;
      case 'high':
        return TicketPriority.high;
      case 'urgent':
        return TicketPriority.urgent;
      default:
        return TicketPriority.normal;
    }
  }

  String _mapCategoryToDb(TicketCategory category) {
    switch (category) {
      case TicketCategory.technical:
        return 'technical';
      case TicketCategory.billing:
        return 'billing';
      case TicketCategory.general:
        return 'general';
      case TicketCategory.complaint:
        return 'feature_request'; // Mapeamento temporário
      case TicketCategory.feature:
        return 'feature_request';
      default:
        return 'general'; // Default para casos inesperados
    }
  }

  TicketCategory _mapCategoryFromDb(String? category) {
    if (category == null) return TicketCategory.general;

    switch (category) {
      case 'technical':
        return TicketCategory.technical;
      case 'billing':
        return TicketCategory.billing;
      case 'general':
        return TicketCategory.general;
      case 'feature_request':
        return TicketCategory.feature;
      case 'bug_report':
        return TicketCategory.technical;
      default:
        return TicketCategory.general;
    }
  }

  Ticket _mapTicketFromDb(Map<String, dynamic> json) {
    // Log para debug
    AppConfig.log('Mapeando ticket do banco:', tag: 'TicketService');
    AppConfig.log('  json recebido: $json', tag: 'TicketService');

    try {
      app_user.User customer;
      try {
        customer = json['customer'] != null
            ? app_user.User.fromJson(json['customer'])
            : app_user.User(
                id: json['customer_id']?.toString() ?? '',
                name: 'Cliente',
                email: 'cliente@email.com',
                role: app_user.UserRole.customer,
                status: app_user.UserStatus.offline,
                createdAt: DateTime.now(),
              );
        AppConfig.log('  customer mapeado: ${customer.name}',
            tag: 'TicketService');
      } catch (e) {
        AppConfig.log('  ERRO ao mapear customer: $e', tag: 'TicketService');
        customer = app_user.User(
          id: json['customer_id']?.toString() ?? '',
          name: 'Cliente',
          email: 'cliente@email.com',
          role: app_user.UserRole.customer,
          status: app_user.UserStatus.offline,
          createdAt: DateTime.now(),
        );
      }

      app_user.User? assignedAgent;
      try {
        assignedAgent = json['assigned_agent'] != null
            ? app_user.User.fromJson(json['assigned_agent'])
            : null;
        AppConfig.log(
            '  assignedAgent mapeado: ${assignedAgent?.name ?? 'null'}',
            tag: 'TicketService');
      } catch (e) {
        AppConfig.log('  ERRO ao mapear assignedAgent: $e',
            tag: 'TicketService');
        assignedAgent = null;
      }

      // Log dos campos individuais
      AppConfig.log('  id: ${json['id']} (tipo: ${json['id'].runtimeType})',
          tag: 'TicketService');
      AppConfig.log(
          '  title: ${json['title']} (tipo: ${json['title'].runtimeType})',
          tag: 'TicketService');
      AppConfig.log(
          '  description: ${json['description']} (tipo: ${json['description'].runtimeType})',
          tag: 'TicketService');
      AppConfig.log(
          '  ticket_status: ${json['ticket_status']} (tipo: ${json['ticket_status'].runtimeType})',
          tag: 'TicketService');
      AppConfig.log(
          '  priority: ${json['priority']} (tipo: ${json['priority'].runtimeType})',
          tag: 'TicketService');
      AppConfig.log(
          '  category: ${json['category']} (tipo: ${json['category'].runtimeType})',
          tag: 'TicketService');
      AppConfig.log(
          '  created_at: ${json['created_at']} (tipo: ${json['created_at'].runtimeType})',
          tag: 'TicketService');

      // Mapear campos com logs detalhados e try-catch individual
      String id;
      try {
        id = json['id']?.toString() ?? '';
        AppConfig.log('  id mapeado: $id', tag: 'TicketService');
      } catch (e) {
        AppConfig.log('  ERRO ao mapear id: $e', tag: 'TicketService');
        id = '';
      }

      String title;
      try {
        title = json['title']?.toString() ?? '';
        AppConfig.log('  title mapeado: $title', tag: 'TicketService');
      } catch (e) {
        AppConfig.log('  ERRO ao mapear title: $e', tag: 'TicketService');
        title = '';
      }

      String description;
      try {
        description = json['description']?.toString() ?? '';
        AppConfig.log('  description mapeado: $description',
            tag: 'TicketService');
      } catch (e) {
        AppConfig.log('  ERRO ao mapear description: $e', tag: 'TicketService');
        description = '';
      }

      TicketStatus status;
      try {
        status = _mapStatusFromDb(json['ticket_status']?.toString());
        AppConfig.log('  status mapeado: $status', tag: 'TicketService');
      } catch (e) {
        AppConfig.log('  ERRO ao mapear status: $e', tag: 'TicketService');
        status = TicketStatus.open;
      }

      TicketPriority priority;
      try {
        priority = _mapPriorityFromDb(json['priority']?.toString());
        AppConfig.log('  priority mapeado: $priority', tag: 'TicketService');
      } catch (e) {
        AppConfig.log('  ERRO ao mapear priority: $e', tag: 'TicketService');
        priority = TicketPriority.normal;
      }

      TicketCategory category;
      try {
        category = _mapCategoryFromDb(json['category']?.toString());
        AppConfig.log('  category mapeado: $category', tag: 'TicketService');
      } catch (e) {
        AppConfig.log('  ERRO ao mapear category: $e', tag: 'TicketService');
        category = TicketCategory.general;
      }

      DateTime createdAt;
      try {
        createdAt = json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now();
        AppConfig.log('  createdAt mapeado: $createdAt', tag: 'TicketService');
      } catch (e) {
        AppConfig.log('  ERRO ao mapear createdAt: $e', tag: 'TicketService');
        createdAt = DateTime.now();
      }

      DateTime? updatedAt;
      try {
        updatedAt = json['updated_at'] != null
            ? DateTime.parse(json['updated_at'].toString())
            : null;
        AppConfig.log('  updatedAt mapeado: $updatedAt', tag: 'TicketService');
      } catch (e) {
        AppConfig.log('  ERRO ao mapear updatedAt: $e', tag: 'TicketService');
        updatedAt = null;
      }

      DateTime? resolvedAt;
      try {
        resolvedAt = json['resolved_at'] != null
            ? DateTime.parse(json['resolved_at'].toString())
            : null;
        AppConfig.log('  resolvedAt mapeado: $resolvedAt',
            tag: 'TicketService');
      } catch (e) {
        AppConfig.log('  ERRO ao mapear resolvedAt: $e', tag: 'TicketService');
        resolvedAt = null;
      }

      DateTime? closedAt;
      try {
        closedAt = json['closed_at'] != null
            ? DateTime.parse(json['closed_at'].toString())
            : null;
        AppConfig.log('  closedAt mapeado: $closedAt', tag: 'TicketService');
      } catch (e) {
        AppConfig.log('  ERRO ao mapear closedAt: $e', tag: 'TicketService');
        closedAt = null;
      }

      Map<String, dynamic> metadata;
      try {
        metadata = (json['metadata'] as Map<String, dynamic>?) ?? {};
        AppConfig.log('  metadata mapeado: $metadata', tag: 'TicketService');
      } catch (e) {
        AppConfig.log('  ERRO ao mapear metadata: $e', tag: 'TicketService');
        metadata = {};
      }

      return Ticket(
        id: id,
        title: title,
        description: description,
        status: status,
        priority: priority,
        category: category,
        customer: customer,
        assignedAgent: assignedAgent,
        createdAt: createdAt,
        updatedAt: updatedAt,
        resolvedAt: resolvedAt,
        closedAt: closedAt,
        metadata: metadata,
      );
    } catch (e) {
      AppConfig.log('Erro ao mapear ticket do banco: $e', tag: 'TicketService');
      AppConfig.log('  json que causou erro: $json', tag: 'TicketService');
      rethrow;
    }
  }

  Message _mapMessageFromDb(Map<String, dynamic> json) {
    final sender = json['sender'] != null
        ? app_user.User.fromJson(json['sender'])
        : app_user.User(
            id: json['sender_id'] ?? '',
            name: 'Usuário',
            email: 'usuario@email.com',
            role: app_user.UserRole.customer,
            status: app_user.UserStatus.offline,
            createdAt: DateTime.now(),
          );

    return Message(
      id: json['id'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.name == json['msg_type'],
        orElse: () => MessageType.text,
      ),
      sender: sender,
      chatId: json['conversation_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['msg_status'],
        orElse: () => MessageStatus.sent,
      ),
      attachments: (json['attachments'] as List?)
              ?.map((e) => MessageAttachment.fromJson(e))
              .toList() ??
          [],
    );
  }

  Future<String> _getOrCreateTicketConversation(String ticketId) async {
    // Verificar se ticket já tem conversa
    final ticketResponse = await _supabaseService
        .from('tickets')
        .select('conversation_id')
        .eq('id', ticketId)
        .single();

    if (ticketResponse['conversation_id'] != null) {
      return ticketResponse['conversation_id'];
    }

    // Criar nova conversa para o ticket
    final conversationData = {
      'title': 'Ticket $ticketId',
      'type': 'support',
      'conv_status': 'active',
    };

    final conversationResponse = await _supabaseService
        .from('conversations')
        .insert(conversationData)
        .select('id')
        .single();

    final conversationId = conversationResponse['id'];

    // Associar conversa ao ticket
    await _supabaseService
        .from('tickets')
        .update({'conversation_id': conversationId}).eq('id', ticketId);

    return conversationId;
  }

  Future<void> _addMessageAttachments(
      String messageId, List<MessageAttachment> attachments) async {
    for (final attachment in attachments) {
      final attachmentData = {
        'message_id': messageId,
        'filename': attachment.name,
        'file_url': attachment.url,
        'file_size': attachment.size,
        'mime_type': attachment.type,
      };

      await _supabaseService.from('message_attachments').insert(attachmentData);
    }
  }
}
