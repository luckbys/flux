import 'package:flutter/material.dart';
import '../services/supabase/supabase_service.dart';
import '../config/app_config.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.type,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? false,
      type: json['type'] ?? 'info',
    );
  }
}

class NotificationStore extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  List<NotificationItem> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();

  /// Carregar notificações do Supabase
  Future<void> loadNotifications() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      AppConfig.log('Carregando notificações...', tag: 'NotificationStore');

      final response = await _supabaseService.client
          .from('notifications')
          .select('*')
          .order('created_at', ascending: false)
          .limit(50);

      _notifications = (response as List)
          .map((json) => NotificationItem.fromJson(json))
          .toList();

      AppConfig.log('${_notifications.length} notificações carregadas', tag: 'NotificationStore');
    } catch (e) {
      _errorMessage = 'Erro ao carregar notificações: $e';
      AppConfig.log('Erro ao carregar notificações: $e', tag: 'NotificationStore');
      
      // Dados mock para desenvolvimento
      _notifications = _generateMockNotifications();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marcar notificação como lida
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      // Atualizar localmente
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationItem(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          createdAt: _notifications[index].createdAt,
          isRead: true,
          type: _notifications[index].type,
        );
        notifyListeners();
      }
    } catch (e) {
      AppConfig.log('Erro ao marcar notificação como lida: $e', tag: 'NotificationStore');
    }
  }

  /// Marcar todas as notificações como lidas
  Future<void> markAllAsRead() async {
    try {
      await _supabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('is_read', false);

      // Atualizar localmente
      _notifications = _notifications.map((n) => NotificationItem(
        id: n.id,
        title: n.title,
        message: n.message,
        createdAt: n.createdAt,
        isRead: true,
        type: n.type,
      )).toList();
      
      notifyListeners();
    } catch (e) {
      AppConfig.log('Erro ao marcar todas as notificações como lidas: $e', tag: 'NotificationStore');
    }
  }

  /// Gerar notificações mock para desenvolvimento
  List<NotificationItem> _generateMockNotifications() {
    return [
      NotificationItem(
        id: '1',
        title: 'Novo Ticket',
        message: 'Ticket #1234 foi criado',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
        type: 'ticket',
      ),
      NotificationItem(
        id: '2',
        title: 'Ticket Resolvido',
        message: 'Ticket #1230 foi resolvido',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        type: 'ticket',
      ),
      NotificationItem(
        id: '3',
        title: 'Sistema',
        message: 'Backup realizado com sucesso',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
        type: 'system',
      ),
    ];
  }

  /// Limpar notificações
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  /// Refresh das notificações
  Future<void> refresh() async {
    await loadNotifications();
  }
}