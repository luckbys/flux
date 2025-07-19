import 'package:equatable/equatable.dart';
import 'user.dart';
import 'message.dart';

enum TicketStatus {
  open,
  inProgress,
  waitingCustomer,
  resolved,
  closed,
}

enum TicketPriority {
  low,
  normal,
  high,
  urgent,
}

enum TicketCategory {
  technical,
  billing,
  general,
  complaint,
  feature,
}

class TicketTag extends Equatable {
  final String id;
  final String name;
  final String color;

  const TicketTag({
    required this.id,
    required this.name,
    required this.color,
  });

  factory TicketTag.fromJson(Map<String, dynamic> json) {
    return TicketTag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }

  @override
  List<Object?> get props => [id, name, color];
}

class Ticket extends Equatable {
  final String id;
  final String title;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final TicketCategory category;
  final User customer;
  final User? assignedAgent;
  final List<TicketTag> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final List<Message> messages;
  final Map<String, dynamic>? metadata;
  final String? chatId;

  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.customer,
    this.assignedAgent,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.closedAt,
    this.messages = const [],
    this.metadata,
    this.chatId,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: TicketStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TicketStatus.open,
      ),
      priority: TicketPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TicketPriority.normal,
      ),
      category: TicketCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TicketCategory.general,
      ),
      customer: User.fromJson(json['customer'] as Map<String, dynamic>),
      assignedAgent: json['assignedAgent'] != null
          ? User.fromJson(json['assignedAgent'] as Map<String, dynamic>)
          : null,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => TicketTag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'] as String)
          : null,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>?,
      chatId: json['chatId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'category': category.name,
      'customer': customer.toJson(),
      'assignedAgent': assignedAgent?.toJson(),
      'tags': tags.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'messages': messages.map((e) => e.toJson()).toList(),
      'metadata': metadata,
      'chatId': chatId,
    };
  }

  Ticket copyWith({
    String? id,
    String? title,
    String? description,
    TicketStatus? status,
    TicketPriority? priority,
    TicketCategory? category,
    User? customer,
    User? assignedAgent,
    List<TicketTag>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    DateTime? closedAt,
    List<Message>? messages,
    Map<String, dynamic>? metadata,
    String? chatId,
  }) {
    return Ticket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      customer: customer ?? this.customer,
      assignedAgent: assignedAgent ?? this.assignedAgent,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
      messages: messages ?? this.messages,
      metadata: metadata ?? this.metadata,
      chatId: chatId ?? this.chatId,
    );
  }

  bool get isOpen => status == TicketStatus.open;
  bool get isResolved => status == TicketStatus.resolved;
  bool get isClosed => status == TicketStatus.closed;
  bool get isAssigned => assignedAgent != null;
  bool get hasChat => chatId != null;
  bool get isUrgent => priority == TicketPriority.urgent;

  Duration get age => DateTime.now().difference(createdAt);

  Duration? get resolutionTime {
    if (resolvedAt != null) {
      return resolvedAt!.difference(createdAt);
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        priority,
        category,
        customer,
        assignedAgent,
        tags,
        createdAt,
        updatedAt,
        resolvedAt,
        closedAt,
        messages,
        metadata,
        chatId,
      ];
}
