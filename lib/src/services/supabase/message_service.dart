import '../../models/message.dart';
import '../../models/user.dart';
import '../../config/app_config.dart';
import 'supabase_service.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  final _supabaseService = SupabaseService();

  /// Busca mensagens de uma conversa
  Future<List<Message>> getMessages(String chatId) async {
    try {
      AppConfig.log('Buscando mensagens do chat: $chatId',
          tag: 'MessageService');

      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      // Query real do Supabase
      final response = await _supabaseService
          .from('messages')
          .select('''
            id,
            content,
            type,
            conversation_id,
            created_at,
            updated_at,
            status,
            sender:users!sender_id(
              id,
              name,
              email,
              avatar_url,
              phone,
              role,
              status,
              created_at,
              last_seen
            ),
            attachments:message_attachments(
              id,
              filename,
              file_url,
              file_size,
              mime_type
            )
          ''')
          .eq('conversation_id', chatId)
          .order('created_at', ascending: true);

      final List<dynamic> data = response;

      AppConfig.log('${data.length} mensagens encontradas',
          tag: 'MessageService');

      return data.map((json) => _mapToMessage(json)).toList();
    } catch (e) {
      AppConfig.log('Erro ao buscar mensagens: $e', tag: 'MessageService');

      // Fallback para dados mock se falhar
      return _getMockMessages(chatId);
    }
  }

  /// Envia uma nova mensagem
  Future<Message?> sendMessage({
    required String chatId,
    required String content,
    required MessageType type,
    List<MessageAttachment>? attachments,
  }) async {
    try {
      AppConfig.log('Enviando mensagem para chat: $chatId',
          tag: 'MessageService');

      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      // Inserir mensagem no banco
      final messageResponse = await _supabaseService.from('messages').insert({
        'content': content,
        'type': type.name,
        'conversation_id': chatId,
        'sender_id': userId,
        'status': MessageStatus.sent.name,
      }).select('''
            id,
            content,
            type,
            conversation_id,
            created_at,
            status,
            sender:users!sender_id(
              id,
              name,
              email,
              avatar_url,
              phone,
              role,
              status,
              created_at,
              last_seen
            )
          ''').single();

      final message = _mapToMessage(messageResponse);

      // Adicionar anexos se existirem
      if (attachments != null && attachments.isNotEmpty) {
        final attachmentsData = attachments
            .map((attachment) => {
                  'message_id': message.id,
                  'filename': attachment.name,
                  'file_url': attachment.url,
                  'file_size': attachment.size,
                  'mime_type': attachment.type,
                })
            .toList();

        await _supabaseService
            .from('message_attachments')
            .insert(attachmentsData);
      }

      // Atualizar última mensagem da conversa
      await _supabaseService.from('conversations').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', chatId);

      AppConfig.log('Mensagem enviada com sucesso', tag: 'MessageService');
      return message;
    } catch (e) {
      AppConfig.log('Erro ao enviar mensagem: $e', tag: 'MessageService');

      // Fallback - criar mensagem mock
      return Message(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        type: type,
        sender: _getCurrentUser(),
        chatId: chatId,
        createdAt: DateTime.now(),
        status: MessageStatus.sent,
        attachments: attachments ?? [],
      );
    }
  }

  /// Marca mensagem como lida
  Future<void> markAsRead(String messageId) async {
    try {
      AppConfig.log('Marcando mensagem como lida: $messageId',
          tag: 'MessageService');

      await _supabaseService
          .from('messages')
          .update({'status': MessageStatus.read.name}).eq('id', messageId);

      AppConfig.log('Mensagem marcada como lida', tag: 'MessageService');
    } catch (e) {
      AppConfig.log('Erro ao marcar mensagem como lida: $e',
          tag: 'MessageService');
    }
  }

  /// Marca todas as mensagens de uma conversa como lidas
  Future<void> markAllAsRead(String chatId, String userId) async {
    try {
      AppConfig.log('Marcando todas mensagens como lidas: $chatId',
          tag: 'MessageService');

      await _supabaseService
          .from('messages')
          .update({'status': MessageStatus.read.name})
          .eq('conversation_id', chatId)
          .neq('sender_id', userId);

      AppConfig.log('Todas mensagens marcadas como lidas',
          tag: 'MessageService');
    } catch (e) {
      AppConfig.log('Erro ao marcar mensagens como lidas: $e',
          tag: 'MessageService');
    }
  }

  /// Stream de novas mensagens em tempo real
  Stream<Message> watchNewMessages(String chatId) {
    return _supabaseService.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', chatId)
        .map((data) => _mapToMessage(data.last))
        .handleError((error) {
          AppConfig.log('Erro no stream de mensagens: $error',
              tag: 'MessageService');
        });
  }

  /// Stream de todas as mensagens de uma conversa
  Stream<List<Message>> watchMessages(String chatId) {
    return _supabaseService.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', chatId)
        .asyncMap((_) => getMessages(chatId));
  }

  /// Deleta uma mensagem
  Future<void> deleteMessage(String messageId) async {
    try {
      AppConfig.log('Deletando mensagem: $messageId', tag: 'MessageService');

      // Deletar anexos primeiro
      await _supabaseService
          .from('message_attachments')
          .delete()
          .eq('message_id', messageId);

      // Deletar mensagem
      await _supabaseService.from('messages').delete().eq('id', messageId);

      AppConfig.log('Mensagem deletada', tag: 'MessageService');
    } catch (e) {
      AppConfig.log('Erro ao deletar mensagem: $e', tag: 'MessageService');
      rethrow;
    }
  }

  /// Busca mensagens por termo
  Future<List<Message>> searchMessages(String query, {String? chatId}) async {
    try {
      AppConfig.log('Buscando mensagens: $query', tag: 'MessageService');

      var queryBuilder = _supabaseService
          .from('messages')
          .select('''
            id,
            content,
            type,
            conversation_id,
            created_at,
            status,
            sender:users!sender_id(
              id,
              name,
              email,
              avatar_url,
              phone,
              role,
              status,
              created_at,
              last_seen
            )
          ''')
          .textSearch('content', query)
          .order('created_at', ascending: false);

      // Filtrar por conversa específica se fornecido
      if (chatId != null) {
        // Usar método diretamente na query
        final response = await _supabaseService
            .from('messages')
            .select('''
              id,
              content,
              type,
              conversation_id,
              created_at,
              status,
              sender:users!sender_id(
                id,
                name,
                email,
                avatar_url,
                phone,
                role,
                status,
                created_at,
                last_seen
              )
            ''')
            .eq('conversation_id', chatId)
            .textSearch('content', query)
            .order('created_at', ascending: false);

        final List<dynamic> data = response;
        return data.map((json) => _mapToMessage(json)).toList();
      }

      final response = await queryBuilder;
      final List<dynamic> data = response;

      return data.map((json) => _mapToMessage(json)).toList();
    } catch (e) {
      AppConfig.log('Erro ao buscar mensagens: $e', tag: 'MessageService');
      return [];
    }
  }

  /// Obtém estatísticas de mensagens
  Future<Map<String, int>> getMessageStats(String chatId) async {
    try {
      final response = await _supabaseService
          .from('messages')
          .select('status')
          .eq('conversation_id', chatId);

      final List<dynamic> data = response;

      final stats = <String, int>{
        'total': data.length,
        'read': 0,
        'sent': 0,
        'delivered': 0,
      };

      for (final message in data) {
        final status = message['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      AppConfig.log('Erro ao obter estatísticas: $e', tag: 'MessageService');
      return {'total': 0, 'read': 0, 'sent': 0, 'delivered': 0};
    }
  }

  /// Converte dados do Supabase para modelo Message
  Message _mapToMessage(Map<String, dynamic> json) {
    final senderData = json['sender'] as Map<String, dynamic>;
    final attachmentsData = json['attachments'] as List<dynamic>? ?? [];

    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => MessageType.text,
      ),
      sender: _mapToUser(senderData),
      chatId: json['conversation_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      status: MessageStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      attachments: attachmentsData
          .map((attachment) => _mapToAttachment(attachment))
          .toList(),
    );
  }

  /// Converte dados do usuário
  User _mapToUser(Map<String, dynamic> json) {
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

  /// Converte dados de anexo
  MessageAttachment _mapToAttachment(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'] as String,
      name: json['filename'] as String,
      url: json['file_url'] as String,
      size: json['file_size'] as int,
      type: json['mime_type'] as String,
    );
  }

  /// Dados mock para fallback
  List<Message> _getMockMessages(String chatId) {
    final currentUser = _getCurrentUser();
    final otherUser = User(
      id: 'customer_1',
      name: 'Maria Silva',
      email: 'maria@cliente.com',
      role: UserRole.customer,
      status: UserStatus.online,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    );

    return [
      Message(
        id: 'msg_1',
        content: 'Olá! Como posso ajudá-lo hoje?',
        type: MessageType.text,
        sender: currentUser,
        chatId: chatId,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageStatus.read,
      ),
      Message(
        id: 'msg_2',
        content: 'Estou com problema no meu pedido #1234',
        type: MessageType.text,
        sender: otherUser,
        chatId: chatId,
        createdAt:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
        status: MessageStatus.read,
      ),
      Message(
        id: 'msg_3',
        content: 'Vou verificar seu pedido agora mesmo.',
        type: MessageType.text,
        sender: currentUser,
        chatId: chatId,
        createdAt:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        status: MessageStatus.read,
      ),
      Message(
        id: 'msg_4',
        content: 'Seu pedido foi processado e está a caminho! 📦',
        type: MessageType.text,
        sender: currentUser,
        chatId: chatId,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        status: MessageStatus.sent,
      ),
    ];
  }

  /// Usuário atual mock
  User _getCurrentUser() {
    return User(
      id: 'current_user',
      name: 'Agente BKCRM',
      email: 'agente@bkcrm.com',
      role: UserRole.agent,
      status: UserStatus.online,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
  }
}
