import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../stores/quote_store.dart';
import '../models/quote.dart';
import '../styles/app_theme.dart';
import '../utils/color_extensions.dart';

import '../components/error_message.dart';
import 'quote_form_page.dart';

class QuoteDetailPage extends StatefulWidget {
  final String quoteId;

  const QuoteDetailPage({
    super.key,
    required this.quoteId,
  });

  @override
  State<QuoteDetailPage> createState() => _QuoteDetailPageState();
}

class _QuoteDetailPageState extends State<QuoteDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuoteStore>().loadQuotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Detalhes do Orçamento'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<QuoteStore>(
        builder: (context, quoteStore, child) {
          if (quoteStore.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (quoteStore.errorMessage != null) {
            return ErrorMessage(
              message: quoteStore.errorMessage!,
              onRetry: () => quoteStore.loadQuotes(),
            );
          }

          final quote = quoteStore.getQuoteById(widget.quoteId);
          if (quote == null) {
            return const Center(
              child: Text('Orçamento não encontrado'),
            );
          }

          final screenWidth = MediaQuery.of(context).size.width;
          final isDesktop = screenWidth > 1200;
          return isDesktop ? _buildDesktopLayout(quote) : _buildMobileLayout(quote);
        },
      ),
    );
  }

  Widget _buildDesktopLayout(Quote quote) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coluna principal
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(quote),
                      const SizedBox(height: 24),
                      _buildCustomerInfo(quote),
                      const SizedBox(height: 24),
                      _buildQuoteItems(quote),
                      const SizedBox(height: 24),
                      _buildAdditionalInfo(quote),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Coluna lateral
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildTotals(quote),
                      const SizedBox(height: 24),
                      _buildActionButtons(quote),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildFixedTotalsBar(quote),
      ],
    );
  }

  Widget _buildMobileLayout(Quote quote) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(quote),
                  const SizedBox(height: 20),
                  _buildCustomerInfo(quote),
                  const SizedBox(height: 20),
                  _buildQuoteItems(quote),
                  const SizedBox(height: 20),
                  _buildTotals(quote),
                  const SizedBox(height: 20),
                  _buildAdditionalInfo(quote),
                  const SizedBox(height: 20),
                  _buildActionButtons(quote),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildEnhancedFixedTotalsBar(quote),
    );
  }

  Widget _buildFixedTotalsBar(Quote quote) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: R\$ ${quote.total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _shareQuote(quote),
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Quote quote) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 4,
        shadowColor: AppTheme.primaryColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppTheme.primaryColor,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Orçamento #${quote.id}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildStatusChip(quote.status),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: _buildInfoItem('ID do Orçamento', '#${quote.id}', Icons.tag)),
                          Expanded(child: _buildInfoItem('Data de Criação', _formatDate(quote.createdAt), Icons.calendar_today)),
                          Expanded(child: _buildInfoItem('Válido até', quote.validUntil != null ? _formatDate(quote.validUntil!) : 'Não definido', Icons.schedule)),
                          Expanded(child: _buildInfoItem('Prioridade', _getPriorityLabel(quote.priority), _getPriorityIcon(quote.priority))),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildInfoItem('ID do Orçamento', '#${quote.id}', Icons.tag)),
                              Expanded(child: _buildInfoItem('Data de Criação', _formatDate(quote.createdAt), Icons.calendar_today)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildInfoItem('Válido até', quote.validUntil != null ? _formatDate(quote.validUntil!) : 'Não definido', Icons.schedule)),
                              Expanded(child: _buildInfoItem('Prioridade', _getPriorityLabel(quote.priority), _getPriorityIcon(quote.priority))),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(Quote quote) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 3,
        shadowColor: AppTheme.primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Informações do Cliente',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildEnhancedInfoRow('Nome', quote.customer.name, Icons.person_outline_rounded),
                const SizedBox(height: 16),
                _buildEnhancedInfoRow('Email', quote.customer.email, Icons.email_outlined),
                const SizedBox(height: 16),
                _buildEnhancedInfoRow('Telefone', quote.customer.phone ?? 'Não informado', Icons.phone_outlined),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteItems(Quote quote) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 3,
        shadowColor: AppTheme.primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Itens do Orçamento',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${quote.items.length} ${quote.items.length == 1 ? 'item' : 'itens'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildItemsList(quote),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList(Quote quote) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 2,
        shadowColor: AppTheme.primaryColor.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
          child: Column(
            children: quote.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == quote.items.length - 1;
              
              return Column(
                children: [
                  _buildEnhancedItemRow(item, index + 1),
                  if (!isLast)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 1,
                      color: AppTheme.borderColor.withOpacity(0.3),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedItemRow(item, int itemNumber) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$itemNumber',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildItemDetail(
                  'Quantidade',
                  '${item.quantity.toStringAsFixed(0)} un',
                  Icons.inventory_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.borderColor.withOpacity(0.3),
              ),
              Expanded(
                child: _buildItemDetail(
                  'Preço Unit.',
                  'R\$ ${item.unitPrice.toStringAsFixed(2)}',
                  Icons.attach_money_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.borderColor.withOpacity(0.3),
              ),
              Expanded(
                child: _buildItemDetail(
                  'Total',
                  'R\$ ${item.total.toStringAsFixed(2)}',
                  Icons.calculate_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor.withOpacity(0.7),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textColor.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTotals(Quote quote) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 3,
        shadowColor: AppTheme.primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calculate_rounded,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Resumo do Orçamento',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildEnhancedTotalRow('Subtotal', quote.subtotal, Icons.receipt_long_rounded, false),
                const SizedBox(height: 12),
                if (quote.additionalDiscount > 0) ...[
                  _buildEnhancedTotalRow('Desconto', quote.additionalDiscount, Icons.discount_rounded, false, isNegative: true),
                  const SizedBox(height: 12),
                ],
                if (quote.taxRate > 0) ...[
                  _buildEnhancedTotalRow('Impostos (${quote.taxRate}%)', quote.taxAmount, Icons.account_balance_rounded, false),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                _buildEnhancedTotalRow('Total', quote.total, Icons.payments_rounded, true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (isTotal ? Theme.of(context).textTheme.headlineSmall : Theme.of(context).textTheme.bodyMedium)?.copyWith(
              color: AppTheme.textColor,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'R\$ ${amount.toStringAsFixed(2)}',
            style: (isTotal ? Theme.of(context).textTheme.headlineSmall : Theme.of(context).textTheme.bodyMedium)?.copyWith(
              color: isTotal ? AppTheme.primaryColor : AppTheme.textColor,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTotalRow(String label, double value, IconData icon, bool isTotal, {bool isNegative = false}) {
    final color = isTotal 
        ? AppTheme.primaryColor 
        : isNegative 
            ? Colors.red.shade600 
            : AppTheme.textColor;
    
    return Container(
      padding: EdgeInsets.all(isTotal ? 16 : 12),
      decoration: BoxDecoration(
        color: isTotal 
            ? AppTheme.primaryColor.withOpacity(0.1) 
            : AppTheme.backgroundColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: isTotal 
            ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1.5)
            : Border.all(color: AppTheme.borderColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: isTotal ? 20 : 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}R\$ ${value.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(Quote quote) {
    if (quote.notes == null && quote.terms == null) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 3,
        shadowColor: AppTheme.primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_rounded,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Informações Adicionais',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (quote.notes != null) ...[
                  _buildInfoSection(
                    'Observações',
                    quote.notes!,
                    Icons.note_rounded,
                  ),
                  if (quote.terms != null) const SizedBox(height: 16),
                ],
                if (quote.terms != null) ...[
                  _buildInfoSection(
                    'Termos e Condições',
                    quote.terms!,
                    Icons.gavel_rounded,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textColor.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Quote quote) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 3,
        shadowColor: AppTheme.primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.touch_app_rounded,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Ações Disponíveis',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isDesktop) ...[
                  if (quote.status == QuoteStatus.draft) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _sendQuote(quote),
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Enviar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _editQuote(quote),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Editar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(color: AppTheme.primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (quote.status == QuoteStatus.pending) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approveQuote(quote),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Aprovar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _rejectQuote(quote),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Rejeitar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                              side: const BorderSide(color: AppTheme.errorColor),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (quote.status == QuoteStatus.approved) ...[
                    ElevatedButton.icon(
                      onPressed: () => _convertQuote(quote),
                      icon: const Icon(Icons.shopping_cart, size: 18),
                      label: const Text('Converter em Pedido'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _duplicateQuote(quote),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Duplicar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: const BorderSide(color: AppTheme.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _printQuote(quote),
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('Imprimir'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: const BorderSide(color: AppTheme.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (quote.status == QuoteStatus.draft) ...[
                        ElevatedButton.icon(
                          onPressed: () => _sendQuote(quote),
                          icon: const Icon(Icons.send),
                          label: const Text('Enviar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                      if (quote.status == QuoteStatus.pending) ...[
                        ElevatedButton.icon(
                          onPressed: () => _approveQuote(quote),
                          icon: const Icon(Icons.check),
                          label: const Text('Aprovar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _rejectQuote(quote),
                          icon: const Icon(Icons.close),
                          label: const Text('Rejeitar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: const BorderSide(color: AppTheme.errorColor),
                          ),
                        ),
                      ],
                      if (quote.status == QuoteStatus.approved) ...[
                        ElevatedButton.icon(
                          onPressed: () => _convertQuote(quote),
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Converter em Pedido'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                      OutlinedButton.icon(
                        onPressed: () => _editQuote(quote),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _duplicateQuote(quote),
                        icon: const Icon(Icons.copy),
                        label: const Text('Duplicar'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _printQuote(quote),
                        icon: const Icon(Icons.print),
                        label: const Text('Imprimir PDF'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _shareQuote(quote),
                        icon: const Icon(Icons.share),
                        label: const Text('Compartilhar'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isPrimary = false,
    bool isOutlined = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isPrimary 
                  ? color 
                  : isOutlined 
                      ? Colors.transparent 
                      : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: isOutlined 
                  ? Border.all(color: color, width: 1.5) 
                  : null,
              boxShadow: isPrimary 
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isPrimary 
                      ? Colors.white 
                      : color,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isPrimary 
                        ? Colors.white 
                        : color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedFixedTotalsBar(Quote quote) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total do Orçamento',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${quote.total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildEnhancedButton(
                onPressed: () => _shareQuote(quote),
                icon: Icons.share_rounded,
                label: 'Compartilhar',
                color: AppTheme.primaryColor,
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(QuoteStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case QuoteStatus.draft:
        color = Colors.grey;
        label = 'Rascunho';
        break;
      case QuoteStatus.pending:
        color = AppTheme.warningColor;
        label = 'Pendente';
        break;
      case QuoteStatus.approved:
        color = AppTheme.successColor;
        label = 'Aprovado';
        break;
      case QuoteStatus.rejected:
        color = AppTheme.errorColor;
        label = 'Rejeitado';
        break;
      case QuoteStatus.converted:
        color = AppTheme.primaryColor;
        label = 'Convertido';
        break;
      case QuoteStatus.expired:
        color = AppTheme.errorColor;
        label = 'Expirado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getPriorityLabel(QuotePriority priority) {
    switch (priority) {
      case QuotePriority.low:
        return 'Baixa';
      case QuotePriority.normal:
        return 'Normal';
      case QuotePriority.high:
        return 'Alta';
      case QuotePriority.urgent:
        return 'Urgente';
    }
  }

  IconData _getPriorityIcon(QuotePriority priority) {
    switch (priority) {
      case QuotePriority.low:
        return Icons.low_priority;
      case QuotePriority.normal:
        return Icons.remove;
      case QuotePriority.high:
        return Icons.priority_high;
      case QuotePriority.urgent:
        return Icons.warning;
    }
  }

  // Action methods
  void _sendQuote(Quote quote) {
    // Implementar envio do orçamento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Orçamento enviado!')),
    );
  }

  void _editQuote(Quote quote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteFormPage(quote: quote),
      ),
    );
  }

  void _approveQuote(Quote quote) {
    context.read<QuoteStore>().updateQuote(
      quoteId: quote.id,
      status: QuoteStatus.approved,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Orçamento aprovado!')),
    );
  }

  void _rejectQuote(Quote quote) {
    context.read<QuoteStore>().updateQuote(
      quoteId: quote.id,
      status: QuoteStatus.rejected,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Orçamento rejeitado!')),
    );
  }

  void _convertQuote(Quote quote) {
    context.read<QuoteStore>().updateQuote(
      quoteId: quote.id,
      status: QuoteStatus.converted,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Orçamento convertido em pedido!')),
    );
  }

  void _duplicateQuote(Quote quote) {
    // Implementar duplicação do orçamento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Orçamento duplicado!')),
    );
  }

  void _printQuote(Quote quote) async {
    try {
      await context.read<QuoteStore>().printQuote(quote);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF gerado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar PDF: $e')),
        );
      }
    }
  }

  void _shareQuote(Quote quote) async {
    try {
      await context.read<QuoteStore>().shareQuotePdf(quote);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar: $e')),
        );
      }
    }
  }
}