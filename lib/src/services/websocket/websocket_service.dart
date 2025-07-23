import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../models/ticket.dart';

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

enum WebSocketEventType {
  // Connection events
  connect,
  disconnect,
  error,
  reconnect,

  // Message events
  newMessage,
  messageRead,
  messageDelivered,
  messageTyping,
  messageStopTyping,

  // Ticket events
  ticketCreated,
  ticketUpdated,
  ticketAssigned,
  ticketStatusChanged,

  // User events
  userOnline,
  userOffline,
  userStatusChanged,

  // Chat events
  chatJoined,
  chatLeft,
  chatArchived,

  // Notification events
  notificationReceived,
  notificationRead,
}

class WebSocketEvent {
  final WebSocketEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? userId;
  final String? chatId;
  final String? ticketId;

  WebSocketEvent({
    required this.type,
    required this.data,
    required this.timestamp,
    this.userId,
    this.chatId,
    this.ticketId,
  });

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketEvent(
      type: WebSocketEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WebSocketEventType.error,
      ),
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
      chatId: json['chatId'],
      ticketId: json['ticketId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'chatId': chatId,
      'ticketId': ticketId,
    };
  }
}

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // Connection state
  WebSocketConnectionState _connectionState =
      WebSocketConnectionState.disconnected;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final int _reconnectDelay = 1000; // ms
  final int _maxReconnectDelay = 5000; // ms

  // Event streams
  final StreamController<WebSocketEvent> _eventController =
      StreamController<WebSocketEvent>.broadcast();
  final StreamController<WebSocketConnectionState> _connectionController =
      StreamController<WebSocketConnectionState>.broadcast();
  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  final StreamController<Ticket> _ticketController =
      StreamController<Ticket>.broadcast();
  final StreamController<User> _userController =
      StreamController<User>.broadcast();

  // Mock data for simulation
  final List<String> _connectedUsers = [];
  final Map<String, Timer> _typingTimers = {};
  final Random _random = Random();

  // Getters
  WebSocketConnectionState get connectionState => _connectionState;
  Stream<WebSocketEvent> get eventStream => _eventController.stream;
  Stream<WebSocketConnectionState> get connectionStream =>
      _connectionController.stream;
  Stream<Message> get messageStream => _messageController.stream;
  Stream<Ticket> get ticketStream => _ticketController.stream;
  Stream<User> get userStream => _userController.stream;

  // Connection management
  Future<void> connect({
    required String url,
    required String userId,
    Map<String, String>? headers,
  }) async {
    if (_connectionState == WebSocketConnectionState.connected) return;

    _setConnectionState(WebSocketConnectionState.connecting);

    try {
      // Simulate connection delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulate connection
      _connectedUsers.add(userId);
      _setConnectionState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;

      // Start heartbeat
      _startHeartbeat();

      // Emit connection event
      _emitEvent(WebSocketEvent(
        type: WebSocketEventType.connect,
        data: {'userId': userId, 'timestamp': DateTime.now().toIso8601String()},
        timestamp: DateTime.now(),
        userId: userId,
      ));

      // Start mock data simulation
      _startMockEvents();

      if (kDebugMode) {
        print('WebSocket connected for user: $userId');
      }
    } catch (e) {
      _setConnectionState(WebSocketConnectionState.error);
      _emitEvent(WebSocketEvent(
        type: WebSocketEventType.error,
        data: {'error': e.toString()},
        timestamp: DateTime.now(),
      ));

      _scheduleReconnect();
    }
  }

  Future<void> disconnect() async {
    _setConnectionState(WebSocketConnectionState.disconnected);

    // Cancel timers
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    for (var timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();

    // Clear connected users
    _connectedUsers.clear();

    // Emit disconnect event
    _emitEvent(WebSocketEvent(
      type: WebSocketEventType.disconnect,
      data: {'timestamp': DateTime.now().toIso8601String()},
      timestamp: DateTime.now(),
    ));

    if (kDebugMode) {
      print('WebSocket disconnected');
    }
  }

  // Message methods
  Future<void> sendMessage(Message message) async {
    if (_connectionState != WebSocketConnectionState.connected) {
      throw Exception('WebSocket not connected');
    }

    // Emit message event
    _emitEvent(WebSocketEvent(
      type: WebSocketEventType.newMessage,
      data: message.toJson(),
      timestamp: DateTime.now(),
      userId: message.sender.id,
      chatId: message.chatId,
    ));

    // Simulate message delivery
    await Future.delayed(const Duration(milliseconds: 100));

    // Simulate auto-reply for demo
    if (_random.nextBool()) {
      _simulateAutoReply(message);
    }
  }

  Future<void> markMessageAsRead(String messageId, String userId) async {
    if (_connectionState != WebSocketConnectionState.connected) return;

    _emitEvent(WebSocketEvent(
      type: WebSocketEventType.messageRead,
      data: {
        'messageId': messageId,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
      userId: userId,
    ));
  }

  Future<void> sendTypingIndicator(String chatId, String userId) async {
    if (_connectionState != WebSocketConnectionState.connected) return;

    _emitEvent(WebSocketEvent(
      type: WebSocketEventType.messageTyping,
      data: {
        'chatId': chatId,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
      userId: userId,
      chatId: chatId,
    ));

    // Auto-stop typing after 3 seconds
    _typingTimers[userId]?.cancel();
    _typingTimers[userId] = Timer(const Duration(seconds: 3), () {
      sendStopTypingIndicator(chatId, userId);
    });
  }

  Future<void> sendStopTypingIndicator(String chatId, String userId) async {
    if (_connectionState != WebSocketConnectionState.connected) return;

    _emitEvent(WebSocketEvent(
      type: WebSocketEventType.messageStopTyping,
      data: {
        'chatId': chatId,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
      userId: userId,
      chatId: chatId,
    ));

    _typingTimers[userId]?.cancel();
    _typingTimers.remove(userId);
  }

  // Ticket methods
  Future<void> createTicket(Ticket ticket) async {
    if (_connectionState != WebSocketConnectionState.connected) return;

    _emitEvent(WebSocketEvent(
      type: WebSocketEventType.ticketCreated,
      data: ticket.toJson(),
      timestamp: DateTime.now(),
      userId: ticket.customer.id,
      ticketId: ticket.id,
    ));
  }

  Future<void> updateTicket(Ticket ticket) async {
    if (_connectionState != WebSocketConnectionState.connected) return;

    _emitEvent(WebSocketEvent(
      type: WebSocketEventType.ticketUpdated,
      data: ticket.toJson(),
      timestamp: DateTime.now(),
      ticketId: ticket.id,
    ));
  }

  Future<void> assignTicket(String ticketId, String agentId) async {
    if (_connectionState != WebSocketConnectionState.connected) return;

    _emitEvent(WebSocketEvent(
      type: WebSocketEventType.ticketAssigned,
      data: {
        'ticketId': ticketId,
        'agentId': agentId,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
      userId: agentId,
      ticketId: ticketId,
    ));
  }

  // User methods
  Future<void> updateUserStatus(String userId, UserStatus status) async {
    if (_connectionState != WebSocketConnectionState.connected) return;

    _emitEvent(WebSocketEvent(
      type: WebSocketEventType.userStatusChanged,
      data: {
        'userId': userId,
        'status': status.name,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
      userId: userId,
    ));
  }

  // Chat methods
  Future<void> joinChat(String chatId, String userId) async {
    if (_connectionState != WebSocketConnectionState.connected) return;

    _emitEvent(WebSocketEvent(
      type: WebSocketEventType.chatJoined,
      data: {
        'chatId': chatId,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
      userId: userId,
      chatId: chatId,
    ));
  }

  Future<void> leaveChat(String chatId, String userId) async {
    if (_connectionState != WebSocketConnectionState.connected) return;

    _emitEvent(WebSocketEvent(
      type: WebSocketEventType.chatLeft,
      data: {
        'chatId': chatId,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
      userId: userId,
      chatId: chatId,
    ));
  }

  // Private methods
  void _setConnectionState(WebSocketConnectionState state) {
    _connectionState = state;
    _connectionController.add(state);
  }

  void _emitEvent(WebSocketEvent event) {
    _eventController.add(event);

    // Route to specific streams
    switch (event.type) {
      case WebSocketEventType.newMessage:
        try {
          final message = Message.fromJson(event.data);
          _messageController.add(message);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing message: $e');
          }
        }
        break;
      case WebSocketEventType.ticketCreated:
      case WebSocketEventType.ticketUpdated:
        try {
          final ticket = Ticket.fromJson(event.data);
          _ticketController.add(ticket);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing ticket: $e');
          }
        }
        break;
      case WebSocketEventType.userStatusChanged:
        // TODO: Parse user data
        break;
      default:
        break;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_connectionState == WebSocketConnectionState.connected) {
        // Send heartbeat
        _emitEvent(WebSocketEvent(
          type: WebSocketEventType.connect,
          data: {'heartbeat': true},
          timestamp: DateTime.now(),
        ));
      }
    });
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        print('Max reconnect attempts reached');
      }
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(
      milliseconds:
          (_reconnectDelay * _reconnectAttempts).clamp(0, _maxReconnectDelay),
    );

    _setConnectionState(WebSocketConnectionState.reconnecting);

    _reconnectTimer = Timer(delay, () {
      if (kDebugMode) {
        print(
            'Attempting to reconnect... ($_reconnectAttempts/$_maxReconnectAttempts)');
      }
      // TODO: Implement actual reconnection logic
    });
  }

  void _startMockEvents() {
    // Simulate random events for demo
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_connectionState != WebSocketConnectionState.connected) return;

      // Random event simulation
      final eventType = _random.nextInt(3);
      switch (eventType) {
        case 0:
          _simulateUserStatusChange();
          break;
        case 1:
          _simulateNotification();
          break;
        case 2:
          _simulateTyping();
          break;
      }
    });
  }

  void _simulateAutoReply(Message originalMessage) {
    // Simulate auto-reply after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (_connectionState != WebSocketConnectionState.connected) return;

      final autoReply = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _getAutoReplyContent(originalMessage.content),
        type: MessageType.text,
        sender: _getMockAgent(),
        chatId: originalMessage.chatId,
        createdAt: DateTime.now(),
        status: MessageStatus.sent,
      );

      _messageController.add(autoReply);
    });
  }

  String _getAutoReplyContent(String originalContent) {
    final replies = [
      'Obrigado por entrar em contato! Vou analisar sua solicitação.',
      'Entendo sua preocupação. Vou verificar isso imediatamente.',
      'Recebemos sua mensagem e vamos responder em breve.',
      'Estou aqui para ajudá-lo. Pode me dar mais detalhes?',
      'Vou escalar isso para nossa equipe especializada.',
    ];

    return replies[_random.nextInt(replies.length)];
  }

  void _simulateUserStatusChange() {
    final statuses = [UserStatus.online, UserStatus.away, UserStatus.busy];
    final status = statuses[_random.nextInt(statuses.length)];

    _emitEvent(WebSocketEvent(
      type: WebSocketEventType.userStatusChanged,
      data: {
        'userId': 'mock_user_${_random.nextInt(100)}',
        'status': status.name,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
    ));
  }

  void _simulateNotification() {
    _emitEvent(WebSocketEvent(
      type: WebSocketEventType.notificationReceived,
      data: {
        'title': 'Nova mensagem recebida',
        'body': 'Você tem uma nova mensagem de atendimento',
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
    ));
  }

  void _simulateTyping() {
    final chatId = 'mock_chat_${_random.nextInt(10)}';
    final userId = 'mock_user_${_random.nextInt(100)}';

    _emitEvent(WebSocketEvent(
      type: WebSocketEventType.messageTyping,
      data: {
        'chatId': chatId,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
      userId: userId,
      chatId: chatId,
    ));

    // Stop typing after 3 seconds
    Timer(const Duration(seconds: 3), () {
      _emitEvent(WebSocketEvent(
        type: WebSocketEventType.messageStopTyping,
        data: {
          'chatId': chatId,
          'userId': userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
        timestamp: DateTime.now(),
        userId: userId,
        chatId: chatId,
      ));
    });
  }

  User _getMockAgent() {
    final names = ['Ana Agente', 'Carlos Suporte', 'Maria Atendente'];
    final name = names[_random.nextInt(names.length)];

    return User(
      id: 'agent_${_random.nextInt(100)}',
      name: name,
      email: '${name.toLowerCase().replaceAll(' ', '.')}@sistema.com',
      role: UserRole.agent,
      status: UserStatus.online,
      createdAt: DateTime.now(),
    );
  }

  // Cleanup
  void dispose() {
    _eventController.close();
    _connectionController.close();
    _messageController.close();
    _ticketController.close();
    _userController.close();
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    for (var timer in _typingTimers.values) {
      timer.cancel();
    }
  }
}

// WebSocket Manager for global state
class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;
  WebSocketManager._internal();

  final WebSocketService _service = WebSocketService();
  String? _currentUserId;

  WebSocketService get service => _service;
  String? get currentUserId => _currentUserId;

  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await _service.connect(
      url: 'ws://localhost:3000', // Mock URL
      userId: userId,
      headers: {'Authorization': 'Bearer mock_token'},
    );
  }

  Future<void> cleanup() async {
    await _service.disconnect();
    _currentUserId = null;
  }
}
