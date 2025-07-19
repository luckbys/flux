import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../stores/quote_store.dart';
import '../models/quote.dart';
import '../models/user.dart';
import '../styles/app_theme.dart';
import '../utils/color_extensions.dart';
import '../components/loading_indicator.dart';

class QuoteFormPage extends StatefulWidget {
  final Quote? quote;

  const QuoteFormPage({
    super.key,
    this.quote,
  });

  @override
  State<QuoteFormPage> createState() => _QuoteFormPageState();
}

class _QuoteFormPageState extends State<QuoteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _discountController = TextEditingController();
  
  QuotePriority _selectedPriority = QuotePriority.normal;
  DateTime? _validUntil;
  List<QuoteItem> _items = [];
  bool _isLoading = false;
  
  // Mock customer data - in a real app, this would come from a customer selection
  late User _selectedCustomer;
  late User _selectedAgent;

  @override
  void initState() {
    super.initState();
    _initializeMockData();
    _initializeForm();
  }

  void _initializeMockData() {
    _selectedCustomer = User(
      id: '550e8400-e29b-41d4-a716-446655440001',
      name: 'João Silva',
      email: 'joao@empresa.com',
      phone: '(11) 99999-9999',
      role: UserRole.customer,
      status: UserStatus.online,
      createdAt: DateTime.now(),
    );
    
    _selectedAgent = User(
      id: '550e8400-e29b-41d4-a716-446655440002',
      name: 'Maria Santos',
      email: 'maria@bkcrm.com',
      phone: '(11) 88888-8888',
      role: UserRole.agent,
      status: UserStatus.online,
      createdAt: DateTime.now(),
    );
  }

  void _initializeForm() {
    if (widget.quote != null) {
      final quote = widget.quote!;
      _titleController.text = quote.title;
      _descriptionController.text = quote.description ?? '';
      _notesController.text = quote.notes ?? '';
      _termsController.text = quote.terms ?? '';
      _taxRateController.text = quote.taxRate.toString();
      _discountController.text = quote.additionalDiscount.toString();
      _selectedPriority = quote.priority;
      _validUntil = quote.validUntil;
      _items = List.from(quote.items);
      _selectedCustomer = quote.customer;
      _selectedAgent = quote.assignedAgent ?? _selectedAgent;
    } else {
      _taxRateController.text = '10.0';
      _discountController.text = '0.0';
      _validUntil = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    _taxRateController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.quote != null ? 'Editar Orçamento' : 'Novo Orçamento'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColor,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveQuote,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildCustomerInfo(),
              const SizedBox(height: 24),
              _buildItemsSection(),
              const SizedBox(height: 24),
              _buildFinancialInfo(),
              const SizedBox(height: 24),
              _buildAdditionalInfo(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Básicas',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                 color: AppTheme.textColor,
                ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título do Orçamento *',
                border: OutlineInputBorder(),
                hintText: 'Ex: Sistema de CRM Personalizado',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'O título é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
                hintText: 'Descreva brevemente o orçamento',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<QuotePriority>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Prioridade',
                      border: OutlineInputBorder(),
                    ),
                    items: QuotePriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(_getPriorityLabel(priority)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedPriority = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectValidUntilDate(),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Válido até',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _validUntil != null
                            ? _formatDate(_validUntil!)
                            : 'Selecionar data',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                           color: _validUntil != null
                               ? AppTheme.textColor
                               : AppTheme.textColor.withValues(alpha: 0.7),
                         ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cliente e Responsável',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      _selectedCustomer.name.substring(0, 1).toUpperCase(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                         color: AppTheme.primaryColor,
                       ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCustomer.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                             color: AppTheme.textColor,
                             fontWeight: FontWeight.w500,
                           ),
                        ),
                        Text(
                          _selectedCustomer.email,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                             color: AppTheme.textColor.withValues(alpha: 0.7),
                           ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // In a real app, this would open a customer selection dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Seleção de cliente em desenvolvimento'),
                        ),
                      );
                    },
                    child: const Text('Alterar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
                    child: Text(
                      _selectedAgent.name.substring(0, 1).toUpperCase(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                         color: AppTheme.successColor,
                       ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Responsável: ${_selectedAgent.name}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                             color: AppTheme.textColor,
                             fontWeight: FontWeight.w500,
                           ),
                        ),
                        Text(
                          _selectedAgent.email,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                             color: AppTheme.textColor.withValues(alpha: 0.7),
                           ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Itens do Orçamento',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                     color: AppTheme.textColor,
                   ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: AppTheme.textColor.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum item adicionado',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                           color: AppTheme.textColor.withValues(alpha: 0.7),
                         ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Clique em "Adicionar Item" para começar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                           color: AppTheme.textColor.withValues(alpha: 0.7),
                         ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Descrição',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                               color: AppTheme.textColor.withValues(alpha: 0.7),
                               fontWeight: FontWeight.w500,
                             ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Qtd.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                               color: AppTheme.textColor.withValues(alpha: 0.7),
                               fontWeight: FontWeight.w500,
                             ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Preço Unit.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textColor.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Total',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textColor.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _buildItemRow(item, index);
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(QuoteItem item, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                     color: AppTheme.textColor,
                     fontWeight: FontWeight.w500,
                   ),
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.notes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                       color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
                     ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${item.quantity} ${item.unit}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                 color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
               ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'R\$ ${item.unitPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                 color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
               ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'R\$ ${item.total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                 color: AppTheme.getTextColor(context),
                 fontWeight: FontWeight.w500,
               ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _editItem(index),
                  icon: const Icon(Icons.edit, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialInfo() {
    final subtotal = _items.fold<double>(0, (sum, item) => sum + item.total);
    final taxRate = double.tryParse(_taxRateController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    final taxAmount = subtotal * (taxRate / 100);
    final total = subtotal + taxAmount - discount;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Financeiras',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                 color: AppTheme.textColor,
               ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _taxRateController,
                    decoration: const InputDecoration(
                      labelText: 'Taxa de Impostos (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    decoration: const InputDecoration(
                      labelText: 'Desconto Adicional',
                      border: OutlineInputBorder(),
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  _buildTotalRow('Subtotal', subtotal),
                  if (discount > 0) _buildTotalRow('Desconto', -discount),
                  if (taxRate > 0) _buildTotalRow('Impostos ($taxRate%)', taxAmount),
                  const Divider(),
                  _buildTotalRow('Total', total, isTotal: true),
                ],
              ),
            ),
          ],
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

  Widget _buildAdditionalInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Adicionais',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                border: OutlineInputBorder(),
                hintText: 'Observações internas sobre o orçamento',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _termsController,
              decoration: const InputDecoration(
                labelText: 'Termos e Condições',
                border: OutlineInputBorder(),
                hintText: 'Termos e condições do orçamento',
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveQuote,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(widget.quote != null ? 'Atualizar' : 'Criar Orçamento'),
          ),
        ),
      ],
    );
  }

  void _selectValidUntilDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() => _validUntil = date);
    }
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _ItemFormDialog(
        onSave: (item) {
          setState(() {
            _items.add(item);
          });
        },
      ),
    );
  }

  void _editItem(int index) {
    showDialog(
      context: context,
      builder: (context) => _ItemFormDialog(
        item: _items[index],
        onSave: (item) {
          setState(() {
            _items[index] = item;
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _saveQuote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um item ao orçamento'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quoteStore = context.read<QuoteStore>();
      
      if (widget.quote != null) {
        // Atualizar orçamento existente
        final success = await quoteStore.updateQuote(
          quoteId: widget.quote!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          priority: _selectedPriority,
          items: _items,
          taxRate: double.tryParse(_taxRateController.text) ?? 0,
          additionalDiscount: double.tryParse(_discountController.text) ?? 0,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          terms: _termsController.text.trim().isEmpty
              ? null
              : _termsController.text.trim(),
          validUntil: _validUntil,
        );
        
        if (success && mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Orçamento atualizado com sucesso!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        // Criar novo orçamento
        final quote = await quoteStore.createQuote(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          customer: _selectedCustomer,
          assignedAgent: _selectedAgent,
          priority: _selectedPriority,
          items: _items,
          taxRate: double.tryParse(_taxRateController.text) ?? 0,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          terms: _termsController.text.trim().isEmpty
              ? null
              : _termsController.text.trim(),
          validUntil: _validUntil,
        );
        
        if (quote != null && mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Orçamento criado com sucesso!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar orçamento: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
}

class _ItemFormDialog extends StatefulWidget {
  final QuoteItem? item;
  final Function(QuoteItem) onSave;

  const _ItemFormDialog({
    this.item,
    required this.onSave,
  });

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _unitController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      final item = widget.item!;
      _descriptionController.text = item.description;
      _quantityController.text = item.quantity.toString();
      _unitPriceController.text = item.unitPrice.toString();
      _unitController.text = item.unit ?? '';
      _notesController.text = item.notes ?? '';
    } else {
      _unitController.text = 'unidade';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item != null ? 'Editar Item' : 'Adicionar Item'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'A descrição é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'A quantidade é obrigatória';
                        }
                        final quantity = double.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return 'Quantidade inválida';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unidade *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'A unidade é obrigatória';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitPriceController,
                decoration: const InputDecoration(
                  labelText: 'Preço Unitário *',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O preço unitário é obrigatório';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price < 0) {
                    return 'Preço inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveItem,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final item = QuoteItem(
      id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      description: _descriptionController.text.trim(),
      quantity: double.parse(_quantityController.text),
      unitPrice: double.parse(_unitPriceController.text),
      unit: _unitController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    widget.onSave(item);
    Navigator.of(context).pop();
  }
}