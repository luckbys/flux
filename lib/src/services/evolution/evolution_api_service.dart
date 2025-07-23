import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../../config/app_config.dart';
import 'evolution_models.dart';

class EvolutionApiService {
  static final EvolutionApiService _instance = EvolutionApiService._internal();
  factory EvolutionApiService() => _instance;
  EvolutionApiService._internal();

  final http.Client _client = http.Client();

  // Instance Management
  Future<EvolutionApiResponse<EvolutionInstance>> getInstanceInfo() async {
    try {
      AppConfig.log('Getting instance info', tag: 'EvolutionAPI');

      final response = await _client
          .get(
            Uri.parse(AppConfig.instanceInfoEndpoint),
            headers: AppConfig.defaultHeaders,
          )
          .timeout(AppConfig.messageTimeout);

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final instances = data['data'] as List<dynamic>;
        final instanceData = instances.firstWhere(
          (instance) => instance['instance'] == AppConfig.evolutionInstanceName,
          orElse: () => null,
        );

        if (instanceData != null) {
          final instance =
              EvolutionInstance.fromJson(instanceData as Map<String, dynamic>);
          AppConfig.log('Instance info retrieved: ${instance.status.name}',
              tag: 'EvolutionAPI');
          return EvolutionApiResponse<EvolutionInstance>(
            success: true,
            data: instance,
            message: 'Instance info retrieved successfully',
          );
        } else {
          return const EvolutionApiResponse<EvolutionInstance>(
            success: false,
            message: 'Instance not found',
          );
        }
      } else {
        return EvolutionApiResponse<EvolutionInstance>(
          success: false,
          message: 'Failed to get instance info',
          error: data,
        );
      }
    } catch (e) {
      AppConfig.log('Error getting instance info: $e', tag: 'EvolutionAPI');
      return EvolutionApiResponse<EvolutionInstance>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  Future<EvolutionApiResponse<String>> getQrCode() async {
    try {
      AppConfig.log('Getting QR Code', tag: 'EvolutionAPI');

      final response = await _client
          .get(
            Uri.parse(AppConfig.qrCodeEndpoint),
            headers: AppConfig.defaultHeaders,
          )
          .timeout(AppConfig.messageTimeout);

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['qrcode'] != null) {
        AppConfig.log('QR Code retrieved', tag: 'EvolutionAPI');
        return EvolutionApiResponse<String>(
          success: true,
          data: data['qrcode'] as String,
          message: 'QR Code retrieved successfully',
        );
      } else {
        return EvolutionApiResponse<String>(
          success: false,
          message: 'Failed to get QR Code',
          error: data,
        );
      }
    } catch (e) {
      AppConfig.log('Error getting QR Code: $e', tag: 'EvolutionAPI');
      return EvolutionApiResponse<String>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Message Sending
  Future<EvolutionApiResponse<Map<String, dynamic>>> sendTextMessage({
    required String phoneNumber,
    required String message,
    Map<String, dynamic>? options,
  }) async {
    try {
      AppConfig.log('Sending text message to $phoneNumber',
          tag: 'EvolutionAPI');

      final request = EvolutionSendTextRequest(
        number: _formatPhoneNumber(phoneNumber),
        text: message,
        options: options,
      );

      final response = await _client
          .post(
            Uri.parse(AppConfig.sendMessageEndpoint),
            headers: AppConfig.defaultHeaders,
            body: json.encode(request.toJson()),
          )
          .timeout(AppConfig.messageTimeout);

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppConfig.log('Text message sent successfully', tag: 'EvolutionAPI');
        return EvolutionApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          message: 'Message sent successfully',
        );
      } else {
        AppConfig.log('Failed to send message: ${response.statusCode}',
            tag: 'EvolutionAPI');
        return EvolutionApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to send message',
          error: data,
        );
      }
    } catch (e) {
      AppConfig.log('Error sending text message: $e', tag: 'EvolutionAPI');
      return EvolutionApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  Future<EvolutionApiResponse<Map<String, dynamic>>> sendMediaMessage({
    required String phoneNumber,
    required String mediaType,
    required String mediaPath, // File path or URL
    String? caption,
    String? filename,
    Map<String, dynamic>? options,
  }) async {
    try {
      AppConfig.log('Sending media message to $phoneNumber',
          tag: 'EvolutionAPI');

      String? mediaData;

      // Check if it's a file path or URL
      if (mediaPath.startsWith('http://') || mediaPath.startsWith('https://')) {
        mediaData = mediaPath; // It's a URL
      } else {
        // It's a file path, convert to base64
        final file = File(mediaPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final base64String = base64Encode(bytes);
          final mimeType = _getMimeType(mediaPath);
          mediaData = 'data:$mimeType;base64,$base64String';
        } else {
          return EvolutionApiResponse<Map<String, dynamic>>(
            success: false,
            message: 'File not found: $mediaPath',
          );
        }
      }

      final request = EvolutionSendMediaRequest(
        number: _formatPhoneNumber(phoneNumber),
        mediatype: mediaType,
        media: mediaData,
        caption: caption,
        filename: filename ?? path.basename(mediaPath),
        options: options,
      );

      final response = await _client
          .post(
            Uri.parse(AppConfig.sendMediaEndpoint),
            headers: AppConfig.defaultHeaders,
            body: json.encode(request.toJson()),
          )
          .timeout(AppConfig.messageTimeout);

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppConfig.log('Media message sent successfully', tag: 'EvolutionAPI');
        return EvolutionApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          message: 'Media message sent successfully',
        );
      } else {
        AppConfig.log('Failed to send media message: ${response.statusCode}',
            tag: 'EvolutionAPI');
        return EvolutionApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to send media message',
          error: data,
        );
      }
    } catch (e) {
      AppConfig.log('Error sending media message: $e', tag: 'EvolutionAPI');
      return EvolutionApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Webhook Management
  Future<EvolutionApiResponse<Map<String, dynamic>>> setupWebhook({
    required String webhookUrl,
    List<String>? events,
  }) async {
    try {
      AppConfig.log('Setting up webhook: $webhookUrl', tag: 'EvolutionAPI');

      final body = {
        'url': webhookUrl,
        'webhook_by_events': true,
        'events': events ??
            [
              'MESSAGES_UPSERT',
              'MESSAGES_UPDATE',
              'CONNECTION_UPDATE',
              'QRCODE_UPDATED',
            ],
      };

      final response = await _client
          .post(
            Uri.parse(AppConfig.webhookSetupEndpoint),
            headers: AppConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(AppConfig.messageTimeout);

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppConfig.log('Webhook setup successful', tag: 'EvolutionAPI');
        return EvolutionApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          message: 'Webhook setup successful',
        );
      } else {
        AppConfig.log('Failed to setup webhook: ${response.statusCode}',
            tag: 'EvolutionAPI');
        return EvolutionApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to setup webhook',
          error: data,
        );
      }
    } catch (e) {
      AppConfig.log('Error setting up webhook: $e', tag: 'EvolutionAPI');
      return EvolutionApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Media Handling
  Future<String?> downloadMedia(String mediaUrl, String saveDirectory) async {
    try {
      AppConfig.log('Downloading media: $mediaUrl', tag: 'EvolutionAPI');

      final response = await _client
          .get(
            Uri.parse(mediaUrl),
            headers: AppConfig.defaultHeaders,
          )
          .timeout(AppConfig.messageTimeout);

      if (response.statusCode == 200) {
        final directory = Directory(saveDirectory);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final filename = path.basename(mediaUrl);
        final filePath = path.join(saveDirectory, filename);
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);

        AppConfig.log('Media downloaded: $filePath', tag: 'EvolutionAPI');
        return filePath;
      } else {
        AppConfig.log('Failed to download media: ${response.statusCode}',
            tag: 'EvolutionAPI');
        return null;
      }
    } catch (e) {
      AppConfig.log('Error downloading media: $e', tag: 'EvolutionAPI');
      return null;
    }
  }

  Future<bool> isMediaValid(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final stats = await file.stat();
      if (stats.size > AppConfig.maxFileSize) return false;

      final extension = path.extension(filePath).toLowerCase().substring(1);

      return AppConfig.allowedImageTypes.contains(extension) ||
          AppConfig.allowedDocumentTypes.contains(extension) ||
          AppConfig.allowedAudioTypes.contains(extension) ||
          AppConfig.allowedVideoTypes.contains(extension);
    } catch (e) {
      AppConfig.log('Error validating media: $e', tag: 'EvolutionAPI');
      return false;
    }
  }

  // Helper Methods
  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-numeric characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Add country code if missing (assuming Brazil +55)
    if (cleaned.length == 11 && cleaned.startsWith('0')) {
      cleaned = '55${cleaned.substring(1)}';
    } else if (cleaned.length == 10) {
      cleaned = '55$cleaned';
    } else if (cleaned.length == 11 && !cleaned.startsWith('55')) {
      cleaned = '55$cleaned';
    }

    return cleaned;
  }

  String _getMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.mp4':
        return 'video/mp4';
      case '.avi':
        return 'video/x-msvideo';
      case '.mov':
        return 'video/quicktime';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.ogg':
        return 'audio/ogg';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  String getMediaType(String filePath) {
    final extension = path.extension(filePath).toLowerCase().substring(1);

    if (AppConfig.allowedImageTypes.contains(extension)) {
      return 'image';
    } else if (AppConfig.allowedVideoTypes.contains(extension)) {
      return 'video';
    } else if (AppConfig.allowedAudioTypes.contains(extension)) {
      return 'audio';
    } else if (AppConfig.allowedDocumentTypes.contains(extension)) {
      return 'document';
    } else {
      return 'document'; // Default fallback
    }
  }

  // Retry mechanism for failed requests
  Future<T> _retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempt++;
        AppConfig.log('Request failed (attempt $attempt/$maxRetries): $e',
            tag: 'EvolutionAPI');

        if (attempt >= maxRetries) {
          rethrow;
        }

        await Future.delayed(delay * attempt);
      }
    }

    throw Exception('Max retries exceeded');
  }

  // Connection test
  Future<bool> testConnection() async {
    try {
      final response = await getInstanceInfo();
      return response.success;
    } catch (e) {
      AppConfig.log('Connection test failed: $e', tag: 'EvolutionAPI');
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
