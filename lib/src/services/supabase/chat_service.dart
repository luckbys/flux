import '../../models/chat.dart';
import '../../models/user.dart';
import '../../config/app_config.dart';
import 'supabase_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _supabaseService = SupabaseService();

  /// Busca todas as conversas do usuário atual
  Future<List<Chat>> getChats() async {
    try {
      AppConfig.log('Buscando conversas...', tag: 'ChatService');

      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      // Query real do Supabase
      final response = await _supabaseService
          .from('conversations')
          .select('''
            id,
            title,
            type,
            status,
            created_at,
            updated_at,
            conversation_participants!inner(
              user_id,
              role,
              users(
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
            ),
            last_message:messages(
              content,
              created_at
            )
          ''')
          .eq('conversation_participants.user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1, referencedTable: 'messages');

      final List<dynamic> data = response;

      AppConfig.log('${data.length} conversas encontradas', tag: 'ChatService');

      return data.map((json) => _mapToChat(json)).toList();
    } catch (e) {
      AppConfig.log('Erro ao buscar conversas: $e', tag: 'ChatService');

      // Fallback para dados mock se falhar
      return _getMockChats();
    }
  }

  /// Busca uma conversa específica por ID
  Future<Chat?> getChatById(String chatId) async {
    try {
      AppConfig.log('Buscando conversa: $chatId', tag: 'ChatService');

      final response = await _supabaseService.from('conversations').select('''
            id,
            title,
            type,
            status,
            created_at,
            updated_at,
            conversation_participants(
              user_id,
              role,
              users(
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
            )
          ''').eq('id', chatId).single();

      return _mapToChat(response);
    } catch (e) {
      AppConfig.log('Erro ao buscar conversa: $e', tag: 'ChatService');

      // Fallback para mock
      final mockChats = _getMockChats();
      return mockChats.where((chat) => chat.id == chatId).firstOrNull;
    }
  }

  /// Cria uma nova conversa
  Future<Chat?> createChat({
    required String title,
    required ChatType type,
    required List<String> participantIds,
  }) async {
    try {
      AppConfig.log('Criando nova conversa: $title', tag: 'ChatService');

      final userId = _supabaseService.currentUserId;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      // Criar conversa
      final chatResponse = await _supabaseService
          .from('conversations')
          .insert({
            'title': title,
            'type': type.name,
            'status': ChatStatus.active.name,
            'created_by': userId,
          })
          .select()
          .single();

      final chatId = chatResponse['id'] as String;

      // Adicionar participantes (incluindo o criador)
      final allParticipants = [...participantIds];
      if (!allParticipants.contains(userId)) {
        allParticipants.add(userId);
      }

      final participantsData = allParticipants
          .map((participantId) => {
                'conversation_id': chatId,
                'user_id': participantId,
                'role': participantId == userId ? 'admin' : 'member',
              })
          .toList();

      await _supabaseService
          .from('conversation_participants')
          .insert(participantsData);

      AppConfig.log('Conversa criada com sucesso: $chatId', tag: 'ChatService');

      // Buscar a conversa criada com todos os dados
      return await getChatById(chatId);
    } catch (e) {
      AppConfig.log('Erro ao criar conversa: $e', tag: 'ChatService');
      return null;
    }
  }

  /// Adiciona participante à conversa
  Future<void> addParticipant({
    required String chatId,
    required String userId,
    String role = 'member',
  }) async {
    try {
      AppConfig.log('Adicionando participante $userId à conversa $chatId',
          tag: 'ChatService');

      await _supabaseService.from('conversation_participants').insert({
        'conversation_id': chatId,
        'user_id': userId,
        'role': role,
      });

      AppConfig.log('Participante adicionado com sucesso', tag: 'ChatService');
    } catch (e) {
      AppConfig.log('Erro ao adicionar participante: $e', tag: 'ChatService');
      rethrow;
    }
  }

  /// Remove participante da conversa
  Future<void> removeParticipant({
    required String chatId,
    required String userId,
  }) async {
    try {
      AppConfig.log('Removendo participante $userId da conversa $chatId',
          tag: 'ChatService');

      await _supabaseService
          .from('conversation_participants')
          .delete()
          .eq('conversation_id', chatId)
          .eq('user_id', userId);

      AppConfig.log('Participante removido com sucesso', tag: 'ChatService');
    } catch (e) {
      AppConfig.log('Erro ao remover participante: $e', tag: 'ChatService');
      rethrow;
    }
  }

  /// Atualiza última mensagem da conversa
  Future<void> updateLastMessage({
    required String chatId,
    required String lastMessage,
  }) async {
    try {
      await _supabaseService.from('conversations').update({
        'last_message': lastMessage,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', chatId);
    } catch (e) {
      AppConfig.log('Erro ao atualizar última mensagem: $e',
          tag: 'ChatService');
    }
  }

  /// Stream de atualizações de conversas em tempo real
  Stream<List<Chat>> watchChats() {
    final userId = _supabaseService.currentUserId;
    if (userId == null) {
      return const Stream.empty();
    }

    return _supabaseService.client
        .from('conversations')
        .stream(primaryKey: ['id']).asyncMap((_) => getChats());
  }

  /// Converte dados do Supabase para modelo Chat
  Chat _mapToChat(Map<String, dynamic> json) {
    final participantsData =
        json['conversation_participants'] as List<dynamic>? ?? [];
    final participants = participantsData
        .map((p) => _mapToUser(p['users'] as Map<String, dynamic>))
        .toList();

    // Última mensagem
    final lastMessageData = json['last_message'] as List<dynamic>?;
    String? lastMessageContent;
    DateTime? lastMessageAt;

    if (lastMessageData != null && lastMessageData.isNotEmpty) {
      final lastMsg = lastMessageData.first as Map<String, dynamic>;
      lastMessageContent = lastMsg['content'] as String?;
      lastMessageAt = lastMsg['created_at'] != null
          ? DateTime.parse(lastMsg['created_at'] as String)
          : null;
    }

    return Chat(
      id: json['id'] as String,
      title: json['title'] as String?,
      type: ChatType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => ChatType.direct,
      ),
      status: ChatStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ChatStatus.active,
      ),
      participants: participants,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      // Construir lastMessage se existir
      lastMessage: lastMessageContent != null
          ? _createMockMessage(lastMessageContent, lastMessageAt!)
          : null,
    );
  }

  /// Converte dados do usuário do Supabase para modelo User
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

  /// Cria uma mensagem mock simples para lastMessage
  dynamic _createMockMessage(String content, DateTime createdAt) {
    // Retorna um objeto simples que será interpretado pelo Chat model
    return {
      'content': content,
      'createdAt': createdAt,
    };
  }

  /// Dados mock para fallback
  List<Chat> _getMockChats() {
    final currentUser = User(
      id: 'current_user',
      name: 'Usuário Atual',
      email: 'usuario@exemplo.com',
      role: UserRole.agent,
      status: UserStatus.online,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );

    final customer1 = User(
      id: 'customer_1',
      name: 'Maria Silva',
      email: 'maria@cliente.com',
      role: UserRole.customer,
      status: UserStatus.online,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      phone: '+55 11 99999-1111',
    );

    final customer2 = User(
      id: 'customer_2',
      name: 'João Santos',
      email: 'joao@cliente.com',
      role: UserRole.customer,
      status: UserStatus.away,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      phone: '+55 11 99999-2222',
    );

    return [
      Chat(
        id: 'chat_1',
        title: 'Suporte - Maria Silva',
        type: ChatType.support,
        status: ChatStatus.active,
        participants: [currentUser, customer1],
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      Chat(
        id: 'chat_2',
        title: 'Dúvida sobre produto',
        type: ChatType.direct,
        status: ChatStatus.active,
        participants: [currentUser, customer2],
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }
}
