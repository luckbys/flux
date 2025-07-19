import 'dart:async';
import '../../models/quote.dart';
import '../../models/user.dart';
import '../../config/app_config.dart';
import 'supabase_service.dart';

class QuoteService {
  final SupabaseService _supabaseService = SupabaseService();

  /// Buscar todos os orçamentos
  Future<List<Quote>> getQuotes({
    QuoteStatus? status,
    QuotePriority? priority,
    String? assignedUserId,
    String? customerId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      AppConfig.log('Buscando orçamentos...', tag: 'QuoteService');

      var query = _supabaseService.client
          .from('quotes')
          .select('''
            *,
            customer:users!customer_id(
              id,
              name,
              email,
              avatar_url,
              phone,
              role,
              status,
              created_at
            ),
            assigned_agent:users!assigned_agent_id(
              id,
              name,
              email,
              avatar_url,
              phone,
              role,
              status,
              created_at
            ),
            quote_items(
              id,
              description,
              quantity,
              unit_price,
              unit
            )
          ''')
;

      if (status != null) {
        query = query.filter('status', 'eq', status.name);
      }

      if (priority != null) {
        query = query.filter('priority', 'eq', priority.name);
      }

      if (assignedUserId != null) {
        query = query.filter('assigned_agent_id', 'eq', assignedUserId);
      }

      if (customerId != null) {
        query = query.filter('customer_id', 'eq', customerId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final quotes = (response as List).map((json) => _mapQuoteFromDb(json)).toList();

      AppConfig.log('${quotes.length} orçamentos carregados', tag: 'QuoteService');
      return quotes;
    } catch (e) {
      AppConfig.log('Erro ao buscar orçamentos: $e', tag: 'QuoteService');
      rethrow;
    }
  }

  /// Buscar orçamento por ID
  Future<Quote?> getQuoteById(String quoteId) async {
    try {
      AppConfig.log('Buscando orçamento: $quoteId', tag: 'QuoteService');

      final response = await _supabaseService.client
          .from('quotes')
          .select('''
            *,
            customer:users!customer_id(
              id,
              name,
              email,
              avatar_url,
              phone,
              role,
              status,
              created_at
            ),
            assigned_agent:users!assigned_agent_id(
              id,
              name,
              email,
              avatar_url,
              phone,
              role,
              status,
              created_at
            ),
            quote_items(
              id,
              description,
              quantity,
              unit_price,
              unit
            )
          ''')
          .filter('id', 'eq', quoteId)
          .single();

      return _mapQuoteFromDb(response);
    } catch (e) {
      AppConfig.log('Erro ao buscar orçamento: $e', tag: 'QuoteService');
      return null;
    }
  }

  /// Criar novo orçamento
  Future<Quote> createQuote({
    required String title,
    String? description,
    required String customerId,
    String? assignedAgentId,
    QuotePriority priority = QuotePriority.normal,
    List<QuoteItem> items = const [],
    double taxRate = 0.0,
    double additionalDiscount = 0.0,
    String? notes,
    String? terms,
    DateTime? validUntil,
  }) async {
    try {
      AppConfig.log('Criando orçamento: $title', tag: 'QuoteService');

      // Criar orçamento
      final quoteData = {
        'title': title,
        'description': description,
        'status': QuoteStatus.draft.name,
        'priority': priority.name,
        'customer_id': customerId,
        'assigned_agent_id': assignedAgentId,
        'tax_rate': taxRate,
        'additional_discount': additionalDiscount,
        'notes': notes,
        'terms': terms,
        'valid_until': validUntil?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final quoteResponse = await _supabaseService.client
          .from('quotes')
          .insert(quoteData)
          .select()
          .single();

      final quoteId = quoteResponse['id'] as String;

      // Criar itens do orçamento
      if (items.isNotEmpty) {
        final itemsData = items.map((item) => {
          'quote_id': quoteId,
          'description': item.description,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'unit': item.unit,
        }).toList();

        await _supabaseService.client
            .from('quote_items')
            .insert(itemsData);
      }

      AppConfig.log('Orçamento criado: $quoteId', tag: 'QuoteService');
      
      // Buscar orçamento completo
      final createdQuote = await getQuoteById(quoteId);
      return createdQuote!;
    } catch (e) {
      AppConfig.log('Erro ao criar orçamento: $e', tag: 'QuoteService');
      rethrow;
    }
  }

  /// Atualizar orçamento
  Future<Quote> updateQuote({
    required String quoteId,
    String? title,
    String? description,
    QuoteStatus? status,
    QuotePriority? priority,
    List<QuoteItem>? items,
    double? taxRate,
    double? additionalDiscount,
    String? notes,
    String? terms,
    DateTime? validUntil,
    String? rejectionReason,
  }) async {
    try {
      AppConfig.log('Atualizando orçamento: $quoteId', tag: 'QuoteService');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (status != null) {
        updateData['status'] = status.name;
        if (status == QuoteStatus.approved) {
          updateData['approved_at'] = DateTime.now().toIso8601String();
        } else if (status == QuoteStatus.rejected) {
          updateData['rejected_at'] = DateTime.now().toIso8601String();
          if (rejectionReason != null) {
            updateData['rejection_reason'] = rejectionReason;
          }
        } else if (status == QuoteStatus.converted) {
          updateData['converted_at'] = DateTime.now().toIso8601String();
        }
      }
      if (priority != null) updateData['priority'] = priority.name;
      if (taxRate != null) updateData['tax_rate'] = taxRate;
      if (additionalDiscount != null) updateData['additional_discount'] = additionalDiscount;
      if (notes != null) updateData['notes'] = notes;
      if (terms != null) updateData['terms'] = terms;
      if (validUntil != null) updateData['valid_until'] = validUntil.toIso8601String();

      await _supabaseService.client
          .from('quotes')
          .update(updateData)
          .filter('id', 'eq', quoteId);

      // Atualizar itens se fornecidos
      if (items != null) {
        // Deletar itens existentes
        await _supabaseService.client
            .from('quote_items')
            .delete()
            .filter('quote_id', 'eq', quoteId);

        // Inserir novos itens
        if (items.isNotEmpty) {
          final itemsData = items.map((item) => {
            'quote_id': quoteId,
            'description': item.description,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'unit': item.unit,
          }).toList();

          await _supabaseService.client
              .from('quote_items')
              .insert(itemsData);
        }
      }

      AppConfig.log('Orçamento atualizado: $quoteId', tag: 'QuoteService');
      
      // Buscar orçamento atualizado
      final updatedQuote = await getQuoteById(quoteId);
      return updatedQuote!;
    } catch (e) {
      AppConfig.log('Erro ao atualizar orçamento: $e', tag: 'QuoteService');
      rethrow;
    }
  }

  /// Deletar orçamento
  Future<void> deleteQuote(String quoteId) async {
    try {
      AppConfig.log('Deletando orçamento: $quoteId', tag: 'QuoteService');

      // Deletar itens primeiro (devido à foreign key)
      await _supabaseService.client
          .from('quote_items')
          .delete()
          .filter('quote_id', 'eq', quoteId);

      // Deletar orçamento
      await _supabaseService.client
          .from('quotes')
          .delete()
          .filter('id', 'eq', quoteId);

      AppConfig.log('Orçamento deletado: $quoteId', tag: 'QuoteService');
    } catch (e) {
      AppConfig.log('Erro ao deletar orçamento: $e', tag: 'QuoteService');
      rethrow;
    }
  }

  /// Buscar estatísticas de orçamentos
  Future<Map<String, int>> getQuoteStats({String? assignedUserId}) async {
    try {
      AppConfig.log('Buscando estatísticas de orçamentos', tag: 'QuoteService');

      var query = _supabaseService.client.from('quotes').select('status');

      if (assignedUserId != null) {
        query = query.filter('assigned_agent_id', 'eq', assignedUserId);
      }

      final response = await query;
      final quotes = response as List;

      final stats = <String, int>{
        'total': quotes.length,
        'draft': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'converted': 0,
        'expired': 0,
      };

      for (final quote in quotes) {
        final status = quote['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      AppConfig.log('Estatísticas carregadas: $stats', tag: 'QuoteService');
      return stats;
    } catch (e) {
      AppConfig.log('Erro ao buscar estatísticas: $e', tag: 'QuoteService');
      rethrow;
    }
  }

  /// Mapear dados do banco para modelo Quote
  Quote _mapQuoteFromDb(Map<String, dynamic> json) {
    final customerData = json['customer'] as Map<String, dynamic>?;
    final assignedAgentData = json['assigned_agent'] as Map<String, dynamic>?;
    final itemsData = json['quote_items'] as List<dynamic>? ?? [];

    return Quote(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: QuoteStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => QuoteStatus.draft,
      ),
      priority: QuotePriority.values.firstWhere(
        (priority) => priority.name == json['priority'],
        orElse: () => QuotePriority.normal,
      ),
      customer: customerData != null ? _mapUserFromDb(customerData) : _getDefaultUser(),
      assignedAgent: assignedAgentData != null ? _mapUserFromDb(assignedAgentData) : null,
      items: itemsData.map((item) => _mapQuoteItemFromDb(item)).toList(),
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      additionalDiscount: (json['additional_discount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      terms: json['terms'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
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
    );
  }

  /// Mapear dados do banco para modelo User
  User _mapUserFromDb(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.customer,
      ),
      status: UserStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => UserStatus.offline,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Mapear dados do banco para modelo QuoteItem
  QuoteItem _mapQuoteItemFromDb(Map<String, dynamic> json) {
    return QuoteItem(
      id: json['id'] as String,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }

  /// Usuário padrão para casos onde não há customer
  User _getDefaultUser() {
    return User(
      id: 'default',
      name: 'Cliente não encontrado',
      email: 'nao-encontrado@exemplo.com',
      role: UserRole.customer,
      status: UserStatus.offline,
      createdAt: DateTime.now(),
    );
  }
}