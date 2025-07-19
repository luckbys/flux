import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/supabase/chat_service.dart';
import '../services/supabase/message_service.dart';
import '../config/app_config.dart';

class ChatStore extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final MessageService _messageService = MessageService();

  // Estado dos chats
  List<Chat> _chats = [];
  Chat? _selectedChat;
  Map<String, List<Message>> _chatMessages = {};

  // Estados de carregamento
  bool _isLoadingChats = false;
  bool _isLoadingMessages = false;
  bool _isSendingMessage = false;

  // Estados de erro
  String? _error;

  // Getters
  List<Chat> get chats => _chats;
  Chat? get selectedChat => _selectedChat;
  bool get isLoadingChats => _isLoadingChats;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSendingMessage => _isSendingMessage;
  String? get error => _error;

  /// Mensagens do chat selecionado
  List<Message> get selectedChatMessages {
    if (_selectedChat == null) return [];
    return _chatMessages[_selectedChat!.id] ?? [];
  }

  /// Carrega todos os chats
  Future<void> loadChats() async {
    try {
      _setLoading(true, type: 'chats');
      _clearError();

      AppConfig.log('Carregando chats...', tag: 'ChatStore');

      final chats = await _chatService.getChats();
      _chats = chats;

      AppConfig.log('${chats.length} chats carregados', tag: 'ChatStore');
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar conversas: $e');
      AppConfig.log('Erro ao carregar chats: $e', tag: 'ChatStore');
    } finally {
      _setLoading(false, type: 'chats');
    }
  }

  /// Seleciona um chat e carrega suas mensagens
  Future<void> selectChat(String chatId) async {
    try {
      AppConfig.log('Selecionando chat: $chatId', tag: 'ChatStore');

      // Encontrar o chat na lista
      final chat = _chats.where((c) => c.id == chatId).firstOrNull;
      if (chat == null) {
        throw Exception('Chat não encontrado');
      }

      _selectedChat = chat;
      notifyListeners();

      // Carregar mensagens se ainda não foram carregadas
      if (!_chatMessages.containsKey(chatId)) {
        await loadMessages(chatId);
      }
    } catch (e) {
      _setError('Erro ao selecionar conversa: $e');
      AppConfig.log('Erro ao selecionar chat: $e', tag: 'ChatStore');
    }
  }

  /// Carrega mensagens de um chat específico
  Future<void> loadMessages(String chatId) async {
    try {
      _setLoading(true, type: 'messages');
      _clearError();

      AppConfig.log('Carregando mensagens do chat: $chatId', tag: 'ChatStore');

      final messages = await _messageService.getMessages(chatId);
      _chatMessages[chatId] = messages;

      AppConfig.log('${messages.length} mensagens carregadas',
          tag: 'ChatStore');
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar mensagens: $e');
      AppConfig.log('Erro ao carregar mensagens: $e', tag: 'ChatStore');
    } finally {
      _setLoading(false, type: 'messages');
    }
  }

  /// Envia uma nova mensagem
  Future<void> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    List<MessageAttachment>? attachments,
  }) async {
    try {
      _setLoading(true, type: 'sending');
      _clearError();

      AppConfig.log('Enviando mensagem para chat: $chatId', tag: 'ChatStore');

      final message = await _messageService.sendMessage(
        chatId: chatId,
        content: content,
        type: type,
        attachments: attachments,
      );

      if (message != null) {
        // Adicionar mensagem à lista local
        if (!_chatMessages.containsKey(chatId)) {
          _chatMessages[chatId] = [];
        }
        _chatMessages[chatId]!.add(message);

        // Atualizar último mensagem do chat
        final chatIndex = _chats.indexWhere((c) => c.id == chatId);
        if (chatIndex != -1) {
          _chats[chatIndex] = _chats[chatIndex].copyWith(
            lastMessage: message,
            updatedAt: DateTime.now(),
          );
        }

        AppConfig.log('Mensagem enviada com sucesso', tag: 'ChatStore');
        notifyListeners();
      }
    } catch (e) {
      _setError('Erro ao enviar mensagem: $e');
      AppConfig.log('Erro ao enviar mensagem: $e', tag: 'ChatStore');
    } finally {
      _setLoading(false, type: 'sending');
    }
  }

  /// Marca mensagem como lida
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _messageService.markAsRead(messageId);
      AppConfig.log('Mensagem marcada como lida: $messageId', tag: 'ChatStore');
    } catch (e) {
      AppConfig.log('Erro ao marcar mensagem como lida: $e', tag: 'ChatStore');
    }
  }

  /// Cria um novo chat
  Future<Chat?> createChat({
    required String title,
    required ChatType type,
    required List<String> participantIds,
  }) async {
    try {
      _clearError();

      AppConfig.log('Criando novo chat: $title', tag: 'ChatStore');

      final chat = await _chatService.createChat(
        title: title,
        type: type,
        participantIds: participantIds,
      );

      if (chat != null) {
        _chats.insert(0, chat);
        AppConfig.log('Chat criado com sucesso', tag: 'ChatStore');
        notifyListeners();
      }

      return chat;
    } catch (e) {
      _setError('Erro ao criar conversa: $e');
      AppConfig.log('Erro ao criar chat: $e', tag: 'ChatStore');
      return null;
    }
  }

  /// Busca chats por termo
  List<Chat> searchChats(String query) {
    if (query.isEmpty) return _chats;

    return _chats.where((chat) {
      final title = chat.title?.toLowerCase() ?? '';
      final participantNames =
          chat.participants.map((p) => p.name.toLowerCase()).join(' ');

      final searchQuery = query.toLowerCase();
      return title.contains(searchQuery) ||
          participantNames.contains(searchQuery);
    }).toList();
  }

  /// Obtém contagem de mensagens não lidas
  int get totalUnreadCount {
    return _chats.fold(0, (total, chat) {
      final messages = _chatMessages[chat.id] ?? [];
      return total +
          messages
              .where((m) =>
                  m.status != MessageStatus.read &&
                  m.sender.id != 'current_user')
              .length;
    });
  }

  /// Limpa chat selecionado
  void clearSelectedChat() {
    _selectedChat = null;
    notifyListeners();
  }

  /// Atualiza estado de carregamento
  void _setLoading(bool loading, {required String type}) {
    switch (type) {
      case 'chats':
        _isLoadingChats = loading;
        break;
      case 'messages':
        _isLoadingMessages = loading;
        break;
      case 'sending':
        _isSendingMessage = loading;
        break;
    }
    notifyListeners();
  }

  /// Define erro
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Limpa erro
  void _clearError() {
    _error = null;
  }

  /// Limpa todos os dados
  void clear() {
    _chats.clear();
    _chatMessages.clear();
    _selectedChat = null;
    _isLoadingChats = false;
    _isLoadingMessages = false;
    _isSendingMessage = false;
    _error = null;
    notifyListeners();
  }
}
