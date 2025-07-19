import 'package:equatable/equatable.dart';
import 'user.dart';

enum MessageType {
  text,
  image,
  file,
  audio,
  system,
  aiSuggestion,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class MessageAttachment extends Equatable {
  final String id;
  final String name;
  final String url;
  final String type;
  final int size;

  const MessageAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      type: json['type'] as String,
      size: json['size'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'size': size,
    };
  }

  @override
  List<Object?> get props => [id, name, url, type, size];
}

class Message extends Equatable {
  final String id;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final User sender;
  final String chatId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Message? replyTo;
  final List<MessageAttachment> attachments;
  final Map<String, dynamic>? metadata;
  final bool isEdited;

  const Message({
    required this.id,
    required this.content,
    required this.type,
    required this.status,
    required this.sender,
    required this.chatId,
    required this.createdAt,
    this.updatedAt,
    this.replyTo,
    this.attachments = const [],
    this.metadata,
    this.isEdited = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      sender: User.fromJson(json['sender'] as Map<String, dynamic>),
      chatId: json['chatId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      replyTo: json['replyTo'] != null
          ? Message.fromJson(json['replyTo'] as Map<String, dynamic>)
          : null,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map(
                  (e) => MessageAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>?,
      isEdited: json['isEdited'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'status': status.name,
      'sender': sender.toJson(),
      'chatId': chatId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'replyTo': replyTo?.toJson(),
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'metadata': metadata,
      'isEdited': isEdited,
    };
  }

  Message copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageStatus? status,
    User? sender,
    String? chatId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Message? replyTo,
    List<MessageAttachment>? attachments,
    Map<String, dynamic>? metadata,
    bool? isEdited,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      sender: sender ?? this.sender,
      chatId: chatId ?? this.chatId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replyTo: replyTo ?? this.replyTo,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  bool get isSystemMessage => type == MessageType.system;
  bool get isAiSuggestion => type == MessageType.aiSuggestion;
  bool get hasAttachments => attachments.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        content,
        type,
        status,
        sender,
        chatId,
        createdAt,
        updatedAt,
        replyTo,
        attachments,
        metadata,
        isEdited,
      ];
}
