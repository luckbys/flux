import 'package:equatable/equatable.dart';
import 'user.dart';
import 'message.dart';

enum ChatType {
  direct,
  group,
  support,
  ticket,
}

enum ChatStatus {
  active,
  archived,
  closed,
}

class Chat extends Equatable {
  final String id;
  final String? title;
  final ChatType type;
  final ChatStatus status;
  final List<User> participants;
  final List<Message> messages;
  final Message? lastMessage;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, DateTime> lastReadBy;
  final Map<String, dynamic>? metadata;
  final String? ticketId;
  final bool isTyping;
  final List<String> typingUsers;

  const Chat({
    required this.id,
    this.title,
    required this.type,
    required this.status,
    required this.participants,
    this.messages = const [],
    this.lastMessage,
    required this.createdAt,
    this.updatedAt,
    this.lastReadBy = const {},
    this.metadata,
    this.ticketId,
    this.isTyping = false,
    this.typingUsers = const [],
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      title: json['title'] as String?,
      type: ChatType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatType.direct,
      ),
      status: ChatStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChatStatus.active,
      ),
      participants: (json['participants'] as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      lastReadBy: (json['lastReadBy'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, DateTime.parse(value as String))) ??
          {},
      metadata: json['metadata'] as Map<String, dynamic>?,
      ticketId: json['ticketId'] as String?,
      isTyping: json['isTyping'] as bool? ?? false,
      typingUsers: (json['typingUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'status': status.name,
      'participants': participants.map((e) => e.toJson()).toList(),
      'messages': messages.map((e) => e.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastReadBy': lastReadBy
          .map((key, value) => MapEntry(key, value.toIso8601String())),
      'metadata': metadata,
      'ticketId': ticketId,
      'isTyping': isTyping,
      'typingUsers': typingUsers,
    };
  }

  Chat copyWith({
    String? id,
    String? title,
    ChatType? type,
    ChatStatus? status,
    List<User>? participants,
    List<Message>? messages,
    Message? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, DateTime>? lastReadBy,
    Map<String, dynamic>? metadata,
    String? ticketId,
    bool? isTyping,
    List<String>? typingUsers,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      messages: messages ?? this.messages,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReadBy: lastReadBy ?? this.lastReadBy,
      metadata: metadata ?? this.metadata,
      ticketId: ticketId ?? this.ticketId,
      isTyping: isTyping ?? this.isTyping,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }

  bool get isActive => status == ChatStatus.active;
  bool get isSupport => type == ChatType.support || type == ChatType.ticket;
  bool get isGroup => type == ChatType.group;
  bool get hasUnreadMessages =>
      lastMessage != null && hasUnreadBy(participants.first.id);
  bool get hasTicket => ticketId != null;

  bool hasUnreadBy(String userId) {
    if (lastMessage == null) return false;
    final lastRead = lastReadBy[userId];
    if (lastRead == null) return true;
    return lastMessage!.createdAt.isAfter(lastRead);
  }

  int getUnreadCount(String userId) {
    final lastRead = lastReadBy[userId];
    if (lastRead == null) return messages.length;

    return messages
        .where((message) =>
            message.createdAt.isAfter(lastRead) && message.sender.id != userId)
        .length;
  }

  String getDisplayTitle() {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }

    if (type == ChatType.support || type == ChatType.ticket) {
      return 'Suporte - ${participants.first.name}';
    }

    if (participants.length == 2) {
      return participants.first.name;
    }

    return participants.map((p) => p.name).join(', ');
  }

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        status,
        participants,
        messages,
        lastMessage,
        createdAt,
        updatedAt,
        lastReadBy,
        metadata,
        ticketId,
        isTyping,
        typingUsers,
      ];
}
