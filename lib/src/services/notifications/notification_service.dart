import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/user.dart';
import '../../models/ticket.dart';
import '../../models/message.dart';

enum NotificationType {
  newMessage,
  newTicket,
  ticketStatusChanged,
  ticketAssigned,
  userMention,
  systemAlert,
  reminder,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;
  final NotificationPriority priority;
  final String? userId;
  final String? actionUrl;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data = const {},
    required this.createdAt,
    this.isRead = false,
    this.priority = NotificationPriority.normal,
    this.userId,
    this.actionUrl,
  });

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    NotificationPriority? priority,
    String? userId,
    String? actionUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.systemAlert,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['imageUrl'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      userId: json['userId'] as String?,
      actionUrl: json['actionUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'priority': priority.name,
      'userId': userId,
      'actionUrl': actionUrl,
    };
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Notification streams
  final StreamController<AppNotification> _notificationController =
      StreamController<AppNotification>.broadcast();
  final StreamController<List<AppNotification>> _notificationListController =
      StreamController<List<AppNotification>>.broadcast();

  // Stored notifications
  final List<AppNotification> _notifications = [];
  final Random _random = Random();
  Timer? _simulationTimer;

  // Settings
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  Map<NotificationType, bool> _typeSettings = {
    for (var type in NotificationType.values) type: true
  };

  // Getters
  Stream<AppNotification> get notificationStream =>
      _notificationController.stream;
  Stream<List<AppNotification>> get notificationListStream =>
      _notificationListController.stream;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;

  // Initialize service
  void initialize() {
    _loadMockNotifications();
    _startSimulation();
    _updateNotificationList();
  }

  // Create notification
  Future<void> showNotification(AppNotification notification) async {
    if (!_notificationsEnabled || !(_typeSettings[notification.type] ?? true)) {
      return;
    }

    _notifications.insert(0, notification);
    _notificationController.add(notification);
    _updateNotificationList();

    if (kDebugMode) {
      print('📱 Notification: ${notification.title}');
    }

    // Simulate system notification
    _simulateSystemNotification(notification);
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _updateNotificationList();
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _updateNotificationList();
  }

  // Clear notification
  Future<void> clearNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    _updateNotificationList();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    _updateNotificationList();
  }

  // Settings
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  void setTypeEnabled(NotificationType type, bool enabled) {
    _typeSettings[type] = enabled;
  }

  bool isTypeEnabled(NotificationType type) {
    return _typeSettings[type] ?? true;
  }

  // Specific notification creators
  Future<void> showNewMessageNotification(Message message) async {
    final notification = AppNotification(
      id: _generateId(),
      type: NotificationType.newMessage,
      title: 'Nova mensagem de ${message.sender.name}',
      body: _truncateMessage(message.content),
      priority: NotificationPriority.normal,
      userId: message.sender.id,
      actionUrl: '/chat/${message.chatId}',
      createdAt: DateTime.now(),
      data: {
        'chatId': message.chatId,
        'messageId': message.id,
        'senderId': message.sender.id,
      },
    );

    await showNotification(notification);
  }

  Future<void> showNewTicketNotification(Ticket ticket) async {
    final notification = AppNotification(
      id: _generateId(),
      type: NotificationType.newTicket,
      title: 'Novo ticket criado',
      body:
          'Ticket #${ticket.id.split('_').last}: ${_truncateMessage(ticket.title)}',
      priority: _mapTicketPriorityToNotification(ticket.priority),
      userId: ticket.customer.id,
      actionUrl: '/tickets/${ticket.id}',
      createdAt: DateTime.now(),
      data: {
        'ticketId': ticket.id,
        'customerId': ticket.customer.id,
        'priority': ticket.priority.name,
        'category': ticket.category.name,
      },
    );

    await showNotification(notification);
  }

  Future<void> showTicketStatusChangedNotification(
      Ticket ticket, TicketStatus oldStatus) async {
    final notification = AppNotification(
      id: _generateId(),
      type: NotificationType.ticketStatusChanged,
      title: 'Status do ticket alterado',
      body:
          'Ticket #${ticket.id.split('_').last} mudou de ${_getStatusText(oldStatus)} para ${_getStatusText(ticket.status)}',
      priority: NotificationPriority.normal,
      actionUrl: '/tickets/${ticket.id}',
      createdAt: DateTime.now(),
      data: {
        'ticketId': ticket.id,
        'oldStatus': oldStatus.name,
        'newStatus': ticket.status.name,
      },
    );

    await showNotification(notification);
  }

  Future<void> showTicketAssignedNotification(Ticket ticket, User agent) async {
    final notification = AppNotification(
      id: _generateId(),
      type: NotificationType.ticketAssigned,
      title: 'Ticket atribuído',
      body:
          'Ticket #${ticket.id.split('_').last} foi atribuído para ${agent.name}',
      priority: NotificationPriority.normal,
      userId: agent.id,
      actionUrl: '/tickets/${ticket.id}',
      createdAt: DateTime.now(),
      data: {
        'ticketId': ticket.id,
        'agentId': agent.id,
        'agentName': agent.name,
      },
    );

    await showNotification(notification);
  }

  Future<void> showUserMentionNotification(
      String mentionedBy, String content, String chatId) async {
    final notification = AppNotification(
      id: _generateId(),
      type: NotificationType.userMention,
      title: 'Você foi mencionado',
      body: '$mentionedBy mencionou você: ${_truncateMessage(content)}',
      priority: NotificationPriority.high,
      actionUrl: '/chat/$chatId',
      createdAt: DateTime.now(),
      data: {
        'chatId': chatId,
        'mentionedBy': mentionedBy,
      },
    );

    await showNotification(notification);
  }

  Future<void> showSystemAlertNotification(String title, String body,
      {NotificationPriority priority = NotificationPriority.normal}) async {
    final notification = AppNotification(
      id: _generateId(),
      type: NotificationType.systemAlert,
      title: title,
      body: body,
      priority: priority,
      createdAt: DateTime.now(),
    );

    await showNotification(notification);
  }

  Future<void> showReminderNotification(
      String title, String body, Map<String, dynamic> data) async {
    final notification = AppNotification(
      id: _generateId(),
      type: NotificationType.reminder,
      title: title,
      body: body,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      data: data,
    );

    await showNotification(notification);
  }

  // Private methods
  void _loadMockNotifications() {
    final mockNotifications = [
      AppNotification(
        id: _generateId(),
        type: NotificationType.newMessage,
        title: 'Nova mensagem de Ana Silva',
        body: 'Olá! Preciso de ajuda com minha conta.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        priority: NotificationPriority.normal,
        actionUrl: '/chat/chat_1',
      ),
      AppNotification(
        id: _generateId(),
        type: NotificationType.newTicket,
        title: 'Novo ticket criado',
        body: 'Ticket #1234: Sistema apresentando lentidão',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        priority: NotificationPriority.high,
        actionUrl: '/tickets/ticket_1',
      ),
      AppNotification(
        id: _generateId(),
        type: NotificationType.ticketAssigned,
        title: 'Ticket atribuído',
        body: 'Ticket #1233 foi atribuído para você',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        priority: NotificationPriority.normal,
        actionUrl: '/tickets/ticket_2',
      ),
      AppNotification(
        id: _generateId(),
        type: NotificationType.systemAlert,
        title: 'Manutenção programada',
        body: 'Sistema será atualizado às 02:00',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        priority: NotificationPriority.normal,
        isRead: true,
      ),
    ];

    _notifications.addAll(mockNotifications);
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_random.nextBool()) {
        _createRandomNotification();
      }
    });
  }

  void _createRandomNotification() {
    final types = [
      NotificationType.newMessage,
      NotificationType.newTicket,
      NotificationType.ticketStatusChanged,
      NotificationType.systemAlert,
    ];

    final type = types[_random.nextInt(types.length)];
    final notifications = _getRandomNotificationData(type);

    final notification = AppNotification(
      id: _generateId(),
      type: type,
      title: notifications['title'],
      body: notifications['body'],
      priority: notifications['priority'],
      createdAt: DateTime.now(),
      actionUrl: notifications['actionUrl'],
      data: notifications['data'] ?? {},
    );

    showNotification(notification);
  }

  Map<String, dynamic> _getRandomNotificationData(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
        final senders = [
          'Ana Silva',
          'João Santos',
          'Maria Costa',
          'Pedro Lima'
        ];
        final messages = [
          'Preciso de ajuda urgente!',
          'Obrigado pelo atendimento.',
          'Quando será resolvido?',
          'Muito satisfeito com o suporte.',
        ];
        final sender = senders[_random.nextInt(senders.length)];
        final message = messages[_random.nextInt(messages.length)];

        return {
          'title': 'Nova mensagem de $sender',
          'body': message,
          'priority': NotificationPriority.normal,
          'actionUrl': '/chat/chat_${_random.nextInt(10)}',
          'data': {'senderId': 'user_${_random.nextInt(100)}'},
        };

      case NotificationType.newTicket:
        final titles = [
          'Sistema apresentando erro',
          'Problema com autenticação',
          'Solicitação de nova funcionalidade',
          'Bug na interface de usuário',
        ];
        final title = titles[_random.nextInt(titles.length)];

        return {
          'title': 'Novo ticket criado',
          'body': 'Ticket #${1000 + _random.nextInt(9000)}: $title',
          'priority': NotificationPriority.normal,
          'actionUrl': '/tickets/ticket_${_random.nextInt(100)}',
          'data': {'ticketId': 'ticket_${_random.nextInt(100)}'},
        };

      case NotificationType.ticketStatusChanged:
        final statuses = ['Em Andamento', 'Resolvido', 'Fechado'];
        final status = statuses[_random.nextInt(statuses.length)];

        return {
          'title': 'Status do ticket alterado',
          'body': 'Ticket #${1000 + _random.nextInt(9000)} mudou para $status',
          'priority': NotificationPriority.normal,
          'actionUrl': '/tickets/ticket_${_random.nextInt(100)}',
          'data': {'newStatus': status.toLowerCase()},
        };

      case NotificationType.systemAlert:
        final alerts = [
          'Nova atualização disponível',
          'Backup realizado com sucesso',
          'Sistema funcionando normalmente',
          'Métricas de performance atualizadas',
        ];
        final alert = alerts[_random.nextInt(alerts.length)];

        return {
          'title': 'Alerta do Sistema',
          'body': alert,
          'priority': NotificationPriority.low,
          'actionUrl': null,
          'data': {'type': 'system'},
        };

      default:
        return {
          'title': 'Notificação',
          'body': 'Você tem uma nova notificação',
          'priority': NotificationPriority.normal,
          'actionUrl': null,
          'data': {},
        };
    }
  }

  void _updateNotificationList() {
    _notificationListController.add(List.from(_notifications));
  }

  void _simulateSystemNotification(AppNotification notification) {
    // Em um app real, aqui seria chamada a API de notificações nativas
    if (kDebugMode) {
      print(
          '🔔 System Notification: ${notification.title} - ${notification.body}');
    }

    // No ambiente web, usar notificações do navegador se disponível
    if (kIsWeb) {
      _showWebNotification(notification);
    }
  }

  // Show web notification
  void _showWebNotification(AppNotification notification) {
    try {
      // Importar dart:html apenas para web
      if (kIsWeb) {
        // Verificar se o navegador suporta notificações
        // Nota: Esta é uma implementação simplificada
        // Em produção, você usaria um package como flutter_local_notifications
        print('🌐 Web notification: ${notification.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao mostrar notificação web: $e');
      }
    }
  }

  String _generateId() {
    return 'notification_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
  }

  String _truncateMessage(String message, {int maxLength = 50}) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}...';
  }

  NotificationPriority _mapTicketPriorityToNotification(
      TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return NotificationPriority.low;
      case TicketPriority.normal:
        return NotificationPriority.normal;
      case TicketPriority.high:
        return NotificationPriority.high;
      case TicketPriority.urgent:
        return NotificationPriority.urgent;
    }
  }

  String _getStatusText(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'Aberto';
      case TicketStatus.inProgress:
        return 'Em Andamento';
      case TicketStatus.resolved:
        return 'Resolvido';
      case TicketStatus.closed:
        return 'Fechado';
      case TicketStatus.waitingCustomer:
        return 'Aguardando Cliente';
    }
  }

  // Cleanup
  void dispose() {
    _simulationTimer?.cancel();
    _notificationController.close();
    _notificationListController.close();
  }
}

// Notification Manager for global access
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final NotificationService _service = NotificationService();

  NotificationService get service => _service;

  void initialize() {
    _service.initialize();
  }

  void cleanup() {
    _service.dispose();
  }
}
