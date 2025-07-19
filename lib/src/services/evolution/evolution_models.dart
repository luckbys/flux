import 'package:equatable/equatable.dart';

// Enums
enum EvolutionMessageType {
  text,
  image,
  audio,
  video,
  document,
  location,
  contact,
  sticker,
}

enum EvolutionMessageStatus {
  pending,
  sent,
  delivered,
  read,
  failed,
}

enum EvolutionInstanceStatus {
  connecting,
  open,
  closed,
  qr,
}

enum EvolutionWebhookEvent {
  messageCreate,
  messageUpdate,
  messageDelete,
  instanceConnect,
  instanceDisconnect,
  qrcode,
  connectionUpdate,
}

// Main Evolution Message Model
class EvolutionMessage extends Equatable {
  final String key;
  final String pushName;
  final String message;
  final String messageTimestamp;
  final String owner;
  final String from;
  final String to;
  final String participant;
  final EvolutionMessageType messageType;
  final EvolutionMessageStatus status;
  final EvolutionMessageData? data;
  final bool fromMe;
  final String? quotedMessage;
  final EvolutionMediaData? media;

  const EvolutionMessage({
    required this.key,
    required this.pushName,
    required this.message,
    required this.messageTimestamp,
    required this.owner,
    required this.from,
    required this.to,
    required this.participant,
    required this.messageType,
    required this.status,
    this.data,
    required this.fromMe,
    this.quotedMessage,
    this.media,
  });

  factory EvolutionMessage.fromJson(Map<String, dynamic> json) {
    return EvolutionMessage(
      key: json['key'] as String,
      pushName: json['pushName'] as String? ?? '',
      message: json['message'] as String? ?? '',
      messageTimestamp: json['messageTimestamp'] as String,
      owner: json['owner'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      participant: json['participant'] as String? ?? '',
      messageType: _parseMessageType(json['messageType'] as String?),
      status: _parseMessageStatus(json['status'] as String?),
      data: json['data'] != null
          ? EvolutionMessageData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      fromMe: json['fromMe'] as bool? ?? false,
      quotedMessage: json['quotedMessage'] as String?,
      media: json['media'] != null
          ? EvolutionMediaData.fromJson(json['media'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'pushName': pushName,
      'message': message,
      'messageTimestamp': messageTimestamp,
      'owner': owner,
      'from': from,
      'to': to,
      'participant': participant,
      'messageType': messageType.name,
      'status': status.name,
      'data': data?.toJson(),
      'fromMe': fromMe,
      'quotedMessage': quotedMessage,
      'media': media?.toJson(),
    };
  }

  static EvolutionMessageType _parseMessageType(String? type) {
    switch (type?.toLowerCase()) {
      case 'text':
        return EvolutionMessageType.text;
      case 'image':
        return EvolutionMessageType.image;
      case 'audio':
        return EvolutionMessageType.audio;
      case 'video':
        return EvolutionMessageType.video;
      case 'document':
        return EvolutionMessageType.document;
      case 'location':
        return EvolutionMessageType.location;
      case 'contact':
        return EvolutionMessageType.contact;
      case 'sticker':
        return EvolutionMessageType.sticker;
      default:
        return EvolutionMessageType.text;
    }
  }

  static EvolutionMessageStatus _parseMessageStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return EvolutionMessageStatus.pending;
      case 'sent':
        return EvolutionMessageStatus.sent;
      case 'delivered':
        return EvolutionMessageStatus.delivered;
      case 'read':
        return EvolutionMessageStatus.read;
      case 'failed':
        return EvolutionMessageStatus.failed;
      default:
        return EvolutionMessageStatus.pending;
    }
  }

  @override
  List<Object?> get props => [
        key,
        pushName,
        message,
        messageTimestamp,
        owner,
        from,
        to,
        participant,
        messageType,
        status,
        data,
        fromMe,
        quotedMessage,
        media,
      ];
}

// Message Data Model
class EvolutionMessageData extends Equatable {
  final String? text;
  final Map<String, dynamic>? quotedMessage;
  final Map<String, dynamic>? contextInfo;

  const EvolutionMessageData({
    this.text,
    this.quotedMessage,
    this.contextInfo,
  });

  factory EvolutionMessageData.fromJson(Map<String, dynamic> json) {
    return EvolutionMessageData(
      text: json['text'] as String?,
      quotedMessage: json['quotedMessage'] as Map<String, dynamic>?,
      contextInfo: json['contextInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'quotedMessage': quotedMessage,
      'contextInfo': contextInfo,
    };
  }

  @override
  List<Object?> get props => [text, quotedMessage, contextInfo];
}

// Media Data Model
class EvolutionMediaData extends Equatable {
  final String? url;
  final String? mimetype;
  final String? filename;
  final String? caption;
  final int? fileLength;
  final String? base64;
  final String? thumbnailBase64;

  const EvolutionMediaData({
    this.url,
    this.mimetype,
    this.filename,
    this.caption,
    this.fileLength,
    this.base64,
    this.thumbnailBase64,
  });

  factory EvolutionMediaData.fromJson(Map<String, dynamic> json) {
    return EvolutionMediaData(
      url: json['url'] as String?,
      mimetype: json['mimetype'] as String?,
      filename: json['filename'] as String?,
      caption: json['caption'] as String?,
      fileLength: json['fileLength'] as int?,
      base64: json['base64'] as String?,
      thumbnailBase64: json['thumbnailBase64'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'mimetype': mimetype,
      'filename': filename,
      'caption': caption,
      'fileLength': fileLength,
      'base64': base64,
      'thumbnailBase64': thumbnailBase64,
    };
  }

  @override
  List<Object?> get props => [
        url,
        mimetype,
        filename,
        caption,
        fileLength,
        base64,
        thumbnailBase64,
      ];
}

// Webhook Models
class EvolutionWebhook extends Equatable {
  final EvolutionWebhookEvent event;
  final String instance;
  final Map<String, dynamic> data;
  final String? serverUrl;
  final String? apikey;
  final DateTime timestamp;

  const EvolutionWebhook({
    required this.event,
    required this.instance,
    required this.data,
    this.serverUrl,
    this.apikey,
    required this.timestamp,
  });

  factory EvolutionWebhook.fromJson(Map<String, dynamic> json) {
    return EvolutionWebhook(
      event: _parseWebhookEvent(json['event'] as String),
      instance: json['instance'] as String,
      data: json['data'] as Map<String, dynamic>,
      serverUrl: json['server_url'] as String?,
      apikey: json['apikey'] as String?,
      timestamp: DateTime.parse(json['date_time'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': event.name,
      'instance': instance,
      'data': data,
      'server_url': serverUrl,
      'apikey': apikey,
      'date_time': timestamp.toIso8601String(),
    };
  }

  static EvolutionWebhookEvent _parseWebhookEvent(String event) {
    switch (event.toLowerCase()) {
      case 'messages.upsert':
      case 'message.create':
        return EvolutionWebhookEvent.messageCreate;
      case 'messages.update':
      case 'message.update':
        return EvolutionWebhookEvent.messageUpdate;
      case 'messages.delete':
      case 'message.delete':
        return EvolutionWebhookEvent.messageDelete;
      case 'connection.update':
        return EvolutionWebhookEvent.connectionUpdate;
      case 'qrcode.updated':
        return EvolutionWebhookEvent.qrcode;
      case 'instance.connect':
        return EvolutionWebhookEvent.instanceConnect;
      case 'instance.disconnect':
        return EvolutionWebhookEvent.instanceDisconnect;
      default:
        return EvolutionWebhookEvent.messageCreate;
    }
  }

  @override
  List<Object?> get props => [
        event,
        instance,
        data,
        serverUrl,
        apikey,
        timestamp,
      ];
}

// Instance Status Model
class EvolutionInstance extends Equatable {
  final String name;
  final EvolutionInstanceStatus status;
  final String? qrcode;
  final String? ownerJid;
  final String? profileName;
  final String? profilePictureUrl;
  final DateTime? connectedAt;
  final DateTime? lastSeen;

  const EvolutionInstance({
    required this.name,
    required this.status,
    this.qrcode,
    this.ownerJid,
    this.profileName,
    this.profilePictureUrl,
    this.connectedAt,
    this.lastSeen,
  });

  factory EvolutionInstance.fromJson(Map<String, dynamic> json) {
    return EvolutionInstance(
      name: json['instance'] as String,
      status: _parseInstanceStatus(json['state'] as String?),
      qrcode: json['qrcode'] as String?,
      ownerJid: json['owner'] as String?,
      profileName: json['profileName'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      connectedAt: json['connectedAt'] != null
          ? DateTime.parse(json['connectedAt'] as String)
          : null,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instance': name,
      'state': status.name,
      'qrcode': qrcode,
      'owner': ownerJid,
      'profileName': profileName,
      'profilePictureUrl': profilePictureUrl,
      'connectedAt': connectedAt?.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  static EvolutionInstanceStatus _parseInstanceStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'connecting':
        return EvolutionInstanceStatus.connecting;
      case 'open':
        return EvolutionInstanceStatus.open;
      case 'close':
      case 'closed':
        return EvolutionInstanceStatus.closed;
      case 'qr':
        return EvolutionInstanceStatus.qr;
      default:
        return EvolutionInstanceStatus.closed;
    }
  }

  bool get isConnected => status == EvolutionInstanceStatus.open;
  bool get needsQrCode => status == EvolutionInstanceStatus.qr;

  @override
  List<Object?> get props => [
        name,
        status,
        qrcode,
        ownerJid,
        profileName,
        profilePictureUrl,
        connectedAt,
        lastSeen,
      ];
}

// Send Message Request Models
class EvolutionSendTextRequest extends Equatable {
  final String number;
  final String text;
  final Map<String, dynamic>? options;

  const EvolutionSendTextRequest({
    required this.number,
    required this.text,
    this.options,
  });

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'textMessage': {
        'text': text,
      },
      'options': options ?? {},
    };
  }

  @override
  List<Object?> get props => [number, text, options];
}

class EvolutionSendMediaRequest extends Equatable {
  final String number;
  final String mediatype;
  final String? media; // URL or base64
  final String? caption;
  final String? filename;
  final Map<String, dynamic>? options;

  const EvolutionSendMediaRequest({
    required this.number,
    required this.mediatype,
    this.media,
    this.caption,
    this.filename,
    this.options,
  });

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'mediaMessage': {
        'mediatype': mediatype,
        'media': media,
        'caption': caption,
        'filename': filename,
      },
      'options': options ?? {},
    };
  }

  @override
  List<Object?> get props =>
      [number, mediatype, media, caption, filename, options];
}

// API Response Models
class EvolutionApiResponse<T> extends Equatable {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? error;

  const EvolutionApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory EvolutionApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return EvolutionApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'] as Map<String, dynamic>)
          : json['data'] as T?,
      error: json['error'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'error': error,
    };
  }

  @override
  List<Object?> get props => [success, message, data, error];
}
