import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../../config/app_config.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import 'evolution_models.dart';

class EvolutionWebhookHandler {
  static final EvolutionWebhookHandler _instance =
      EvolutionWebhookHandler._internal();
  factory EvolutionWebhookHandler() => _instance;
  EvolutionWebhookHandler._internal();

  // Callback functions
  Function(Message)? onNewMessage;
  Function(Message)? onMessageUpdate;
  Function(String)? onMessageDelete;
  Function(EvolutionInstance)? onInstanceStatusChange;
  Function(String)? onQrCodeUpdate;
  Function(String, String)? onConnectionUpdate;

  // Process incoming webhook
  Future<Map<String, dynamic>> processWebhook(
    Map<String, String> headers,
    String body,
  ) async {
    try {
      AppConfig.log('Processing webhook', tag: 'WebhookHandler');

      // Validate webhook if security is enabled
      if (AppConfig.enableWebhookValidation) {
        if (!_validateWebhookSignature(headers, body)) {
          AppConfig.log('Invalid webhook signature', tag: 'WebhookHandler');
          return _createResponse(false, 'Invalid signature');
        }
      }

      // Parse webhook data
      final webhookData = json.decode(body) as Map<String, dynamic>;
      final webhook = EvolutionWebhook.fromJson(webhookData);

      AppConfig.log('Processing webhook event: ${webhook.event.name}',
          tag: 'WebhookHandler');

      // Process based on event type
      switch (webhook.event) {
        case EvolutionWebhookEvent.messageCreate:
          await _handleMessageCreate(webhook);
          break;

        case EvolutionWebhookEvent.messageUpdate:
          await _handleMessageUpdate(webhook);
          break;

        case EvolutionWebhookEvent.messageDelete:
          await _handleMessageDelete(webhook);
          break;

        case EvolutionWebhookEvent.connectionUpdate:
          await _handleConnectionUpdate(webhook);
          break;

        case EvolutionWebhookEvent.qrcode:
          await _handleQrCodeUpdate(webhook);
          break;

        case EvolutionWebhookEvent.instanceConnect:
        case EvolutionWebhookEvent.instanceDisconnect:
          await _handleInstanceStatusChange(webhook);
          break;
      }

      return _createResponse(true, 'Webhook processed successfully');
    } catch (e) {
      AppConfig.log('Error processing webhook: $e', tag: 'WebhookHandler');
      return _createResponse(false, 'Error processing webhook: $e');
    }
  }

  // Handle new message
  Future<void> _handleMessageCreate(EvolutionWebhook webhook) async {
    try {
      final messageData = webhook.data;

      // Check if it's a valid message
      if (messageData['key'] == null || messageData['message'] == null) {
        AppConfig.log('Invalid message data received', tag: 'WebhookHandler');
        return;
      }

      final evolutionMessage = EvolutionMessage.fromJson(messageData);

      // Skip messages sent by us
      if (evolutionMessage.fromMe) {
        AppConfig.log('Skipping message sent by us', tag: 'WebhookHandler');
        return;
      }

      // Convert to app message format
      final message = await _convertToAppMessage(evolutionMessage);

      if (message != null) {
        AppConfig.log('New message converted successfully',
            tag: 'WebhookHandler');
        onNewMessage?.call(message);
      }
    } catch (e) {
      AppConfig.log('Error handling message create: $e', tag: 'WebhookHandler');
    }
  }

  // Handle message update (status changes)
  Future<void> _handleMessageUpdate(EvolutionWebhook webhook) async {
    try {
      final messageData = webhook.data;
      final evolutionMessage = EvolutionMessage.fromJson(messageData);

      // Convert to app message format
      final message = await _convertToAppMessage(evolutionMessage);

      if (message != null) {
        AppConfig.log('Message update processed', tag: 'WebhookHandler');
        onMessageUpdate?.call(message);
      }
    } catch (e) {
      AppConfig.log('Error handling message update: $e', tag: 'WebhookHandler');
    }
  }

  // Handle message delete
  Future<void> _handleMessageDelete(EvolutionWebhook webhook) async {
    try {
      final messageData = webhook.data;
      final messageKey = messageData['key'] as String?;

      if (messageKey != null) {
        AppConfig.log('Message delete processed', tag: 'WebhookHandler');
        onMessageDelete?.call(messageKey);
      }
    } catch (e) {
      AppConfig.log('Error handling message delete: $e', tag: 'WebhookHandler');
    }
  }

  // Handle connection status updates
  Future<void> _handleConnectionUpdate(EvolutionWebhook webhook) async {
    try {
      final connectionData = webhook.data;
      final state = connectionData['state'] as String?;
      final reason = connectionData['reason'] as String?;

      if (state != null) {
        AppConfig.log('Connection update: $state', tag: 'WebhookHandler');
        onConnectionUpdate?.call(state, reason ?? '');
      }
    } catch (e) {
      AppConfig.log('Error handling connection update: $e',
          tag: 'WebhookHandler');
    }
  }

  // Handle QR code updates
  Future<void> _handleQrCodeUpdate(EvolutionWebhook webhook) async {
    try {
      final qrData = webhook.data;
      final qrcode = qrData['qrcode'] as String?;

      if (qrcode != null) {
        AppConfig.log('QR Code updated', tag: 'WebhookHandler');
        onQrCodeUpdate?.call(qrcode);
      }
    } catch (e) {
      AppConfig.log('Error handling QR code update: $e', tag: 'WebhookHandler');
    }
  }

  // Handle instance status changes
  Future<void> _handleInstanceStatusChange(EvolutionWebhook webhook) async {
    try {
      final instanceData = webhook.data;
      final instance = EvolutionInstance.fromJson(instanceData);

      AppConfig.log('Instance status change: ${instance.status.name}',
          tag: 'WebhookHandler');
      onInstanceStatusChange?.call(instance);
    } catch (e) {
      AppConfig.log('Error handling instance status change: $e',
          tag: 'WebhookHandler');
    }
  }

  // Convert Evolution message to app message
  Future<Message?> _convertToAppMessage(
      EvolutionMessage evolutionMessage) async {
    try {
      // Create or get user
      final user = await _createUserFromEvolutionMessage(evolutionMessage);

      // Determine message type
      final messageType = _convertMessageType(evolutionMessage.messageType);

      // Get message content
      String content = '';
      List<MessageAttachment> attachments = [];

      switch (evolutionMessage.messageType) {
        case EvolutionMessageType.text:
          content = evolutionMessage.message;
          break;

        case EvolutionMessageType.image:
        case EvolutionMessageType.video:
        case EvolutionMessageType.audio:
        case EvolutionMessageType.document:
          content = evolutionMessage.media?.caption ?? 'Arquivo enviado';
          if (evolutionMessage.media != null) {
            attachments = [
              await _createAttachmentFromMedia(evolutionMessage.media!)
            ];
          }
          break;

        case EvolutionMessageType.location:
          content = 'Localização compartilhada';
          break;

        case EvolutionMessageType.contact:
          content = 'Contato compartilhado';
          break;

        case EvolutionMessageType.sticker:
          content = 'Sticker enviado';
          break;
      }

      // Create message
      final message = Message(
        id: evolutionMessage.key,
        content: content,
        type: messageType,
        sender: user,
        chatId: 'whatsapp_${evolutionMessage.from}',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          int.parse(evolutionMessage.messageTimestamp) * 1000,
        ),
        status: _convertMessageStatus(evolutionMessage.status),
        attachments: attachments,
      );

      return message;
    } catch (e) {
      AppConfig.log('Error converting Evolution message: $e',
          tag: 'WebhookHandler');
      return null;
    }
  }

  // Create user from Evolution message
  Future<User> _createUserFromEvolutionMessage(
      EvolutionMessage evolutionMessage) async {
    final phoneNumber = evolutionMessage.from.replaceAll('@s.whatsapp.net', '');
    final name = evolutionMessage.pushName.isNotEmpty
        ? evolutionMessage.pushName
        : phoneNumber;

    return User(
      id: 'whatsapp_$phoneNumber',
      name: name,
      email: '$phoneNumber@whatsapp.user',
      role: UserRole.customer,
      status: UserStatus.online,
      createdAt: DateTime.now(),
    );
  }

  // Create attachment from media
  Future<MessageAttachment> _createAttachmentFromMedia(
      EvolutionMediaData media) async {
    return MessageAttachment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _getAttachmentTypeString(media.mimetype ?? ''),
      name: media.filename ?? 'arquivo',
      url: media.url ?? '',
      size: media.fileLength ?? 0,
    );
  }

  // Convert message types
  MessageType _convertMessageType(EvolutionMessageType evolutionType) {
    switch (evolutionType) {
      case EvolutionMessageType.text:
        return MessageType.text;
      case EvolutionMessageType.image:
      case EvolutionMessageType.video:
      case EvolutionMessageType.audio:
      case EvolutionMessageType.document:
      case EvolutionMessageType.sticker:
        return MessageType.file;
      case EvolutionMessageType.location:
      case EvolutionMessageType.contact:
        return MessageType.system;
    }
  }

  // Convert message status
  MessageStatus _convertMessageStatus(EvolutionMessageStatus evolutionStatus) {
    switch (evolutionStatus) {
      case EvolutionMessageStatus.pending:
        return MessageStatus.sending;
      case EvolutionMessageStatus.sent:
        return MessageStatus.sent;
      case EvolutionMessageStatus.delivered:
        return MessageStatus.delivered;
      case EvolutionMessageStatus.read:
        return MessageStatus.read;
      case EvolutionMessageStatus.failed:
        return MessageStatus.failed;
    }
  }

  // Get attachment type from mime type
  String _getAttachmentTypeString(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return 'image';
    } else if (mimeType.startsWith('video/')) {
      return 'video';
    } else if (mimeType.startsWith('audio/')) {
      return 'audio';
    } else {
      return 'file';
    }
  }

  // Validate webhook signature
  bool _validateWebhookSignature(Map<String, String> headers, String body) {
    try {
      final signature = headers['x-evolution-signature'] ??
          headers['X-Evolution-Signature'] ??
          headers['signature'];

      if (signature == null || AppConfig.webhookSecret.isEmpty) {
        return !AppConfig
            .enableWebhookValidation; // Allow if validation is disabled
      }

      final expectedSignature =
          _generateSignature(body, AppConfig.webhookSecret);
      return signature == expectedSignature;
    } catch (e) {
      AppConfig.log('Error validating webhook signature: $e',
          tag: 'WebhookHandler');
      return false;
    }
  }

  // Generate signature for validation
  String _generateSignature(String body, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(body);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return 'sha256=${digest.toString()}';
  }

  // Create response
  Map<String, dynamic> _createResponse(bool success, String message) {
    return {
      'success': success,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Extract phone number from WhatsApp JID
  String extractPhoneNumber(String jid) {
    return jid.replaceAll(RegExp(r'@.*'), '');
  }

  // Format phone number for display
  String formatPhoneNumberForDisplay(String phoneNumber) {
    // Brazilian phone number formatting
    if (phoneNumber.startsWith('55') && phoneNumber.length >= 12) {
      final countryCode = phoneNumber.substring(0, 2);
      final areaCode = phoneNumber.substring(2, 4);
      final number = phoneNumber.substring(4);

      if (number.length == 9) {
        final part1 = number.substring(0, 5);
        final part2 = number.substring(5);
        return '+$countryCode ($areaCode) $part1-$part2';
      } else if (number.length == 8) {
        final part1 = number.substring(0, 4);
        final part2 = number.substring(4);
        return '+$countryCode ($areaCode) $part1-$part2';
      }
    }

    return phoneNumber;
  }

  // Cleanup resources
  void dispose() {
    onNewMessage = null;
    onMessageUpdate = null;
    onMessageDelete = null;
    onInstanceStatusChange = null;
    onQrCodeUpdate = null;
    onConnectionUpdate = null;
  }
}
