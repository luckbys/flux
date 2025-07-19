import 'package:equatable/equatable.dart';
import 'user.dart';

enum QuoteStatus {
  draft,
  pending,
  approved,
  rejected,
  expired,
  converted,
}

enum QuotePriority {
  low,
  normal,
  high,
  urgent,
}

class QuoteItem extends Equatable {
  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  final double discount;
  final String? unit;
  final String? notes;

  const QuoteItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    this.unit,
    this.notes,
  });

  double get subtotal => quantity * unitPrice;
  double get discountAmount => subtotal * (discount / 100);
  double get total => subtotal - discountAmount;

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      id: json['id'] as String,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'unit': unit,
      'notes': notes,
    };
  }

  QuoteItem copyWith({
    String? id,
    String? description,
    double? quantity,
    double? unitPrice,
    double? discount,
    String? unit,
    String? notes,
  }) {
    return QuoteItem(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, description, quantity, unitPrice, discount, unit, notes];
}

class Quote extends Equatable {
  final String id;
  final String title;
  final String? description;
  final QuoteStatus status;
  final QuotePriority priority;
  final User customer;
  final User? assignedAgent;
  final List<QuoteItem> items;
  final double taxRate;
  final double additionalDiscount;
  final String? notes;
  final String? terms;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? validUntil;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? convertedAt;
  final Map<String, dynamic>? metadata;

  const Quote({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.customer,
    this.assignedAgent,
    this.items = const [],
    this.taxRate = 0.0,
    this.additionalDiscount = 0.0,
    this.notes,
    this.terms,
    required this.createdAt,
    this.updatedAt,
    this.validUntil,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.convertedAt,
    this.metadata,
  });

  // Cálculos
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalDiscount => items.fold(0.0, (sum, item) => sum + item.discountAmount) + 
                             (subtotal * (additionalDiscount / 100));
  double get taxableAmount => subtotal - totalDiscount;
  double get taxAmount => taxableAmount * (taxRate / 100);
  double get total => taxableAmount + taxAmount;

  // Status helpers
  bool get isDraft => status == QuoteStatus.draft;
  bool get isPending => status == QuoteStatus.pending;
  bool get isApproved => status == QuoteStatus.approved;
  bool get isRejected => status == QuoteStatus.rejected;
  bool get isExpired => status == QuoteStatus.expired || 
                       (validUntil != null && DateTime.now().isAfter(validUntil!));
  bool get isConverted => status == QuoteStatus.converted;

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: QuoteStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => QuoteStatus.draft,
      ),
      priority: QuotePriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => QuotePriority.normal,
      ),
      customer: User.fromJson(json['customer'] as Map<String, dynamic>),
      assignedAgent: json['assigned_agent'] != null
          ? User.fromJson(json['assigned_agent'] as Map<String, dynamic>)
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => QuoteItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      additionalDiscount: (json['additional_discount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      terms: json['terms'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      convertedAt: json['converted_at'] != null
          ? DateTime.parse(json['converted_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'customer': customer.toJson(),
      'assigned_agent': assignedAgent?.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      'tax_rate': taxRate,
      'additional_discount': additionalDiscount,
      'notes': notes,
      'terms': terms,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'converted_at': convertedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  Quote copyWith({
    String? id,
    String? title,
    String? description,
    QuoteStatus? status,
    QuotePriority? priority,
    User? customer,
    User? assignedAgent,
    List<QuoteItem>? items,
    double? taxRate,
    double? additionalDiscount,
    String? notes,
    String? terms,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? validUntil,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    DateTime? convertedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Quote(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      customer: customer ?? this.customer,
      assignedAgent: assignedAgent ?? this.assignedAgent,
      items: items ?? this.items,
      taxRate: taxRate ?? this.taxRate,
      additionalDiscount: additionalDiscount ?? this.additionalDiscount,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      validUntil: validUntil ?? this.validUntil,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      convertedAt: convertedAt ?? this.convertedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        priority,
        customer,
        assignedAgent,
        items,
        taxRate,
        additionalDiscount,
        notes,
        terms,
        createdAt,
        updatedAt,
        validUntil,
        approvedAt,
        rejectedAt,
        rejectionReason,
        convertedAt,
        metadata,
      ];
}