import 'dart:async';
import 'dart:io';
import '../../config/app_config.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../websocket/websocket_service.dart';
import 'evolution_api_service.dart';
import 'evolution_webhook_handler.dart';
import 'evolution_models.dart';

class WhatsAppIntegrationService {
  static final WhatsAppIntegrationService _instance =
      WhatsAppIntegrationService._internal();
  factory WhatsAppIntegrationService() => _instance;
  WhatsAppIntegrationService._internal();

  final EvolutionApiService _apiService = EvolutionApiService();
  final EvolutionWebhookHandler _webhookHandler = EvolutionWebhookHandler();
  final WebSocketService _webSocketService = WebSocketService();

  // Stream controllers for real-time updates
  final StreamController<Message> _newMessageController =
      StreamController<Message>.broadcast();
  final StreamController<Message> _messageUpdateController =
      StreamController<Message>.broadcast();
  final StreamController<Chat> _chatUpdateController =
      StreamController<Chat>.broadcast();
  final StreamController<EvolutionInstance> _instanceStatusController =
      StreamController<EvolutionInstance>.broadcast();
  final StreamController<String> _qrCodeController =
      StreamController<String>.broadcast();

  // Streams
  Stream<Message> get newMessageStream => _newMessageController.stream;
  Stream<Message> get messageUpdateStream => _messageUpdateController.stream;
  Stream<Chat> get chatUpdateStream => _chatUpdateController.stream;
  Stream<EvolutionInstance> get instanceStatusStream =>
      _instanceStatusController.stream;
  Stream<String> get qrCodeStream => _qrCodeController.stream;

  // Cache para chats ativos
  final Map<String, Chat> _activeChats = {};
  final Map<String, User> _users = {};

  // Status da conexão
  bool _isInitialized = false;
  EvolutionInstance? _currentInstance;

  // Initialize the integration
  Future<bool> initialize() async {
    if (_isInitialized) {
      AppConfig.log('WhatsApp integration already initialized',
          tag: 'WhatsAppIntegration');
      return true;
    }

    try {
      AppConfig.log('Initializing WhatsApp integration',
          tag: 'WhatsAppIntegration');

      // Setup webhook handlers
      _setupWebhookHandlers();

      // Setup webhook endpoint
      await _setupWebhook();

      // Check instance status
      await _checkInstanceStatus();

      _isInitialized = true;
      AppConfig.log('WhatsApp integration initialized successfully',
          tag: 'WhatsAppIntegration');
      return true;
    } catch (e) {
      AppConfig.log('Failed to initialize WhatsApp integration: $e',
          tag: 'WhatsAppIntegration');
      return false;
    }
  }

  // Setup webhook handlers
  void _setupWebhookHandlers() {
    _webhookHandler.onNewMessage = _handleNewMessage;
    _webhookHandler.onMessageUpdate = _handleMessageUpdate;
    _webhookHandler.onMessageDelete = _handleMessageDelete;
    _webhookHandler.onInstanceStatusChange = _handleInstanceStatusChange;
    _webhookHandler.onQrCodeUpdate = _handleQrCodeUpdate;
    _webhookHandler.onConnectionUpdate = _handleConnectionUpdate;
  }

  // Setup webhook endpoint
  Future<void> _setupWebhook() async {
    try {
      final response = await _apiService.setupWebhook(
        webhookUrl: AppConfig.evolutionWebhookUrl,
        events: [
          'MESSAGES_UPSERT',
          'MESSAGES_UPDATE',
          'CONNECTION_UPDATE',
          'QRCODE_UPDATED',
        ],
      );

      if (response.success) {
        AppConfig.log('Webhook setup successful', tag: 'WhatsAppIntegration');
      } else {
        AppConfig.log('Webhook setup failed: ${response.message}',
            tag: 'WhatsAppIntegration');
      }
    } catch (e) {
      AppConfig.log('Error setting up webhook: $e', tag: 'WhatsAppIntegration');
    }
  }

  // Check instance status
  Future<void> _checkInstanceStatus() async {
    try {
      final response = await _apiService.getInstanceInfo();

      if (response.success && response.data != null) {
        _currentInstance = response.data!;
        _instanceStatusController.add(_currentInstance!);

        AppConfig.log('Instance status: ${_currentInstance!.status.name}',
            tag: 'WhatsAppIntegration');

        // If instance needs QR code, get it
        if (_currentInstance!.needsQrCode) {
          await _getQrCode();
        }
      }
    } catch (e) {
      AppConfig.log('Error checking instance status: $e',
          tag: 'WhatsAppIntegration');
    }
  }

  // Get QR code for connection
  Future<void> _getQrCode() async {
    try {
      final response = await _apiService.getQrCode();

      if (response.success && response.data != null) {
        _qrCodeController.add(response.data!);
        AppConfig.log('QR Code retrieved', tag: 'WhatsAppIntegration');
      }
    } catch (e) {
      AppConfig.log('Error getting QR code: $e', tag: 'WhatsAppIntegration');
    }
  }

  // Send text message
  Future<bool> sendTextMessage({
    required String phoneNumber,
    required String message,
    String? chatId,
  }) async {
    try {
      AppConfig.log('Sending text message to $phoneNumber',
          tag: 'WhatsAppIntegration');

      final response = await _apiService.sendTextMessage(
        phoneNumber: phoneNumber,
        message: message,
      );

      if (response.success) {
        // Create local message for immediate UI update
        final localMessage = await _createLocalMessage(
          phoneNumber: phoneNumber,
          content: message,
          type: MessageType.text,
          chatId: chatId,
        );

        if (localMessage != null) {
          _newMessageController.add(localMessage);
          await _updateOrCreateChat(localMessage);
        }

        AppConfig.log('Text message sent successfully',
            tag: 'WhatsAppIntegration');
        return true;
      } else {
        AppConfig.log('Failed to send text message: ${response.message}',
            tag: 'WhatsAppIntegration');
        return false;
      }
    } catch (e) {
      AppConfig.log('Error sending text message: $e',
          tag: 'WhatsAppIntegration');
      return false;
    }
  }

  // Send media message
  Future<bool> sendMediaMessage({
    required String phoneNumber,
    required String mediaPath,
    String? caption,
    String? chatId,
  }) async {
    try {
      AppConfig.log('Sending media message to $phoneNumber',
          tag: 'WhatsAppIntegration');

      // Validate media file
      if (!await _apiService.isMediaValid(mediaPath)) {
        AppConfig.log('Invalid media file: $mediaPath',
            tag: 'WhatsAppIntegration');
        return false;
      }

      final mediaType = _apiService.getMediaType(mediaPath);

      final response = await _apiService.sendMediaMessage(
        phoneNumber: phoneNumber,
        mediaType: mediaType,
        mediaPath: mediaPath,
        caption: caption,
      );

      if (response.success) {
        // Create local message for immediate UI update
        final localMessage = await _createLocalMessage(
          phoneNumber: phoneNumber,
          content: caption ?? 'Arquivo enviado',
          type: MessageType.file,
          chatId: chatId,
          mediaPath: mediaPath,
        );

        if (localMessage != null) {
          _newMessageController.add(localMessage);
          await _updateOrCreateChat(localMessage);
        }

        AppConfig.log('Media message sent successfully',
            tag: 'WhatsAppIntegration');
        return true;
      } else {
        AppConfig.log('Failed to send media message: ${response.message}',
            tag: 'WhatsAppIntegration');
        return false;
      }
    } catch (e) {
      AppConfig.log('Error sending media message: $e',
          tag: 'WhatsAppIntegration');
      return false;
    }
  }

  // Handle new incoming message
  void _handleNewMessage(Message message) async {
    try {
      AppConfig.log('Handling new incoming message',
          tag: 'WhatsAppIntegration');

      // Store user if not exists
      _users[message.sender.id] = message.sender;

      // Update or create chat
      await _updateOrCreateChat(message);

      // Emit to streams
      _newMessageController.add(message);

      // Send to WebSocket for real-time updates (simplified)
      // _webSocketService.sendMessage('new_whatsapp_message');

      AppConfig.log('New message processed successfully',
          tag: 'WhatsAppIntegration');
    } catch (e) {
      AppConfig.log('Error handling new message: $e',
          tag: 'WhatsAppIntegration');
    }
  }

  // Handle message update
  void _handleMessageUpdate(Message message) async {
    try {
      AppConfig.log('Handling message update', tag: 'WhatsAppIntegration');

      _messageUpdateController.add(message);

      // Send to WebSocket (simplified)
      // _webSocketService.sendMessage('whatsapp_message_update');
    } catch (e) {
      AppConfig.log('Error handling message update: $e',
          tag: 'WhatsAppIntegration');
    }
  }

  // Handle message delete
  void _handleMessageDelete(String messageKey) async {
    try {
      AppConfig.log('Handling message delete: $messageKey',
          tag: 'WhatsAppIntegration');

      // Send to WebSocket (simplified)
      // _webSocketService.sendMessage('whatsapp_message_delete');
    } catch (e) {
      AppConfig.log('Error handling message delete: $e',
          tag: 'WhatsAppIntegration');
    }
  }

  // Handle instance status change
  void _handleInstanceStatusChange(EvolutionInstance instance) async {
    try {
      AppConfig.log('Instance status changed: ${instance.status.name}',
          tag: 'WhatsAppIntegration');

      _currentInstance = instance;
      _instanceStatusController.add(instance);

      // If instance needs QR code, get it
      if (instance.needsQrCode) {
        await _getQrCode();
      }
    } catch (e) {
      AppConfig.log('Error handling instance status change: $e',
          tag: 'WhatsAppIntegration');
    }
  }

  // Handle QR code update
  void _handleQrCodeUpdate(String qrCode) {
    AppConfig.log('QR Code updated', tag: 'WhatsAppIntegration');
    _qrCodeController.add(qrCode);
  }

  // Handle connection update
  void _handleConnectionUpdate(String state, String reason) {
    AppConfig.log('Connection update: $state - $reason',
        tag: 'WhatsAppIntegration');
  }

  // Create local message for immediate UI feedback
  Future<Message?> _createLocalMessage({
    required String phoneNumber,
    required String content,
    required MessageType type,
    String? chatId,
    String? mediaPath,
  }) async {
    try {
      // Get current user (the sender - us)
      final currentUser = await _getCurrentUser();

      // Create attachments if media
      List<MessageAttachment> attachments = [];
      if (mediaPath != null && type == MessageType.file) {
        attachments = [
          MessageAttachment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: _getAttachmentTypeFromPath(mediaPath),
            name: mediaPath.split('/').last,
            url: mediaPath,
            size: await File(mediaPath).length(),
          ),
        ];
      }

      return Message(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        type: type,
        sender: currentUser,
        chatId: chatId ?? 'whatsapp_$phoneNumber',
        createdAt: DateTime.now(),
        status: MessageStatus.sending,
        attachments: attachments,
      );
    } catch (e) {
      AppConfig.log('Error creating local message: $e',
          tag: 'WhatsAppIntegration');
      return null;
    }
  }

  // Update or create chat
  Future<void> _updateOrCreateChat(Message message) async {
    try {
      final chatId = message.chatId;

      Chat chat;
      if (_activeChats.containsKey(chatId)) {
        // Update existing chat
        chat = _activeChats[chatId]!.copyWith(
          lastMessage: message,
          updatedAt: DateTime.now(),
        );
      } else {
        // Create new chat
        chat = Chat(
          id: chatId,
          type: ChatType.support,
          status: ChatStatus.active,
          participants: [message.sender],
          lastMessage: message,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          metadata: {
            'platform': 'whatsapp',
            'phone_number':
                _webhookHandler.extractPhoneNumber(message.sender.id),
          },
        );
      }

      _activeChats[chatId] = chat;
      _chatUpdateController.add(chat);
    } catch (e) {
      AppConfig.log('Error updating chat: $e', tag: 'WhatsAppIntegration');
    }
  }

  // Get current user (agent/system user)
  Future<User> _getCurrentUser() async {
    return User(
      id: 'system_agent',
      name: AppConfig.whatsappBusinessName,
      email: 'agent@bkcrm.com',
      role: UserRole.agent,
      status: UserStatus.online,
      createdAt: DateTime.now(),
    );
  }

  // Get attachment type from file path
  String _getAttachmentTypeFromPath(String path) {
    final extension = path.split('.').last.toLowerCase();

    if (AppConfig.allowedImageTypes.contains(extension)) {
      return 'image';
    } else if (AppConfig.allowedVideoTypes.contains(extension)) {
      return 'video';
    } else if (AppConfig.allowedAudioTypes.contains(extension)) {
      return 'audio';
    } else {
      return 'file';
    }
  }

  // Process webhook (to be called from HTTP server)
  Future<Map<String, dynamic>> processWebhook(
    Map<String, String> headers,
    String body,
  ) async {
    return await _webhookHandler.processWebhook(headers, body);
  }

  // Get current instance status
  EvolutionInstance? get currentInstance => _currentInstance;

  // Check if WhatsApp is connected
  bool get isWhatsAppConnected => _currentInstance?.isConnected ?? false;

  // Get active chats
  List<Chat> get activeChats => _activeChats.values.toList();

  // Get chat by ID
  Chat? getChatById(String chatId) => _activeChats[chatId];

  // Test connection
  Future<bool> testConnection() async {
    return await _apiService.testConnection();
  }

  // Disconnect and cleanup
  Future<void> disconnect() async {
    try {
      AppConfig.log('Disconnecting WhatsApp integration',
          tag: 'WhatsAppIntegration');

      _isInitialized = false;
      _currentInstance = null;
      _activeChats.clear();
      _users.clear();

      await _newMessageController.close();
      await _messageUpdateController.close();
      await _chatUpdateController.close();
      await _instanceStatusController.close();
      await _qrCodeController.close();

      _webhookHandler.dispose();
      _apiService.dispose();

      AppConfig.log('WhatsApp integration disconnected',
          tag: 'WhatsAppIntegration');
    } catch (e) {
      AppConfig.log('Error disconnecting: $e', tag: 'WhatsAppIntegration');
    }
  }

  // Dispose resources
  void dispose() {
    disconnect();
  }
}
