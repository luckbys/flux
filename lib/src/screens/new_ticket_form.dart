import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../stores/ticket_store.dart';
import '../stores/auth_store.dart';
import '../models/ticket.dart';
import '../components/ui/loading_overlay.dart';
import '../components/ui/toast_message.dart';
import '../widgets/form_components.dart';

class NewTicketForm extends StatefulWidget {
  const NewTicketForm({super.key});

  @override
  State<NewTicketForm> createState() => _NewTicketFormState();
}

class _NewTicketFormState extends State<NewTicketForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedPriority = 'Média';
  String _selectedCategory = 'Geral';
  String _selectedDepartment = 'TI';
  final bool _isLoading = false;
  bool _notifyByEmail = true;
  bool _notifyBySms = false;
  bool _isSubmitting = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _priorities = ['Baixa', 'Média', 'Alta', 'Urgente'];
  final List<String> _categories = [
    'Geral',
    'Técnico',
    'Financeiro',
    'Suporte',
    'Bug',
    'Feature',
    'Manutenção',
    'Consulta'
  ];
  final List<String> _departments = [
    'TI',
    'RH',
    'Financeiro',
    'Vendas',
    'Marketing',
    'Operações',
    'Jurídico'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Novo Ticket',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              PhosphorIcons.arrowLeft(),
              color: const Color(0xFF374151),
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF1D4ED8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _isSubmitting ? null : _submitForm,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      PhosphorIcons.check(),
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormSection(
                      title: 'Informações Básicas',
                      icon: PhosphorIcons.ticket(),
                      children: [
                        _buildTextField(
                          controller: _titleController,
                          label: 'Título do Ticket',
                          hint: 'Digite um título descritivo',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, digite um título';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Descrição',
                          hint:
                              'Descreva detalhadamente o problema ou solicitação',
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, digite uma descrição';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildFormSection(
                      title: 'Classificação',
                      icon: PhosphorIcons.tag(),
                      children: [
                        _buildDropdownField(
                          label: 'Prioridade',
                          value: _selectedPriority,
                          items: _priorities,
                          onChanged: (value) {
                            setState(() {
                              _selectedPriority = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: 'Categoria',
                          value: _selectedCategory,
                          items: _categories,
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: 'Departamento',
                          value: _selectedDepartment,
                          items: _departments,
                          onChanged: (value) {
                            setState(() {
                              _selectedDepartment = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildFormSection(
                      title: 'Informações de Contato',
                      icon: PhosphorIcons.user(),
                      children: [
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'email@exemplo.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, digite um email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Por favor, digite um email válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Telefone (opcional)',
                          hint: '(11) 99999-9999',
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildFormSection(
                      title: 'Notificações',
                      icon: PhosphorIcons.bell(),
                      children: [
                        _buildSwitchTile(
                          title: 'Notificar por Email',
                          subtitle: 'Receber atualizações por email',
                          value: _notifyByEmail,
                          onChanged: (value) {
                            setState(() {
                              _notifyByEmail = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildSwitchTile(
                          title: 'Notificar por SMS',
                          subtitle: 'Receber atualizações por SMS',
                          value: _notifyBySms,
                          onChanged: (value) {
                            setState(() {
                              _notifyBySms = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return const LoadingOverlay(
      message: 'Criando ticket...',
      showBackground: true,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Novo Ticket',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: FormComponents.textColor,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: FormComponents.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Ajuda',
            color: FormComponents.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return FormComponents.buildFormCard(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FormComponents.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: FormComponents.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: FormComponents.primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.confirmation_number,
                color: FormComponents.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Criar Novo Ticket',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: FormComponents.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Preencha as informações abaixo para criar seu ticket de suporte',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormComponents.buildSectionTitle('Informações Básicas',
            icon: Icons.person),
        const SizedBox(height: 16),
        FormComponents.buildFormCard(
          children: [
            FormComponents.buildTextField(
              controller: _titleController,
              label: 'Título do Ticket *',
              hint: 'Descreva brevemente o problema ou solicitação',
              icon: Icons.title,
              validator: (value) =>
                  FormComponents.validateMinLength(value, 5, 'título'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FormComponents.buildTextField(
                    controller: _emailController,
                    label: 'E-mail de Contato *',
                    hint: 'seu.email@exemplo.com',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: FormComponents.validateEmail,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormComponents.buildTextField(
                    controller: _phoneController,
                    label: 'Telefone',
                    hint: '(11) 99999-9999',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorizationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormComponents.buildSectionTitle('Categorização', icon: Icons.category),
        const SizedBox(height: 16),
        FormComponents.buildFormCard(
          children: [
            Row(
              children: [
                Expanded(
                  child: FormComponents.buildDropdown<String>(
                    label: 'Categoria *',
                    value: _selectedCategory,
                    items: _categories,
                    icon: Icons.category,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormComponents.buildDropdown<String>(
                    label: 'Departamento *',
                    value: _selectedDepartment,
                    items: _departments,
                    icon: Icons.business,
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartment = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FormComponents.buildDropdown<String>(
                    label: 'Prioridade *',
                    value: _selectedPriority,
                    items: _priorities,
                    icon: Icons.priority_high,
                    onChanged: (value) {
                      setState(() {
                        _selectedPriority = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview da Prioridade',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: FormComponents.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FormComponents.buildStatusChip(
                        label: _selectedPriority,
                        color: _selectedPriority.priorityColor,
                        icon: _selectedPriority.priorityIcon,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormComponents.buildSectionTitle('Descrição Detalhada',
            icon: Icons.description),
        const SizedBox(height: 16),
        FormComponents.buildFormCard(
          children: [
            FormComponents.buildTextField(
              controller: _descriptionController,
              label: 'Descrição do Problema *',
              hint:
                  'Descreva detalhadamente o problema, incluindo:\n• Passos para reproduzir\n• Comportamento esperado\n• Comportamento atual\n• Informações adicionais relevantes\n• Screenshots ou logs (se aplicável)',
              icon: Icons.description,
              maxLines: 8,
              validator: (value) =>
                  FormComponents.validateMinLength(value, 20, 'descrição'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dica: Quanto mais detalhes você fornecer, mais rápido poderemos resolver seu problema!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormComponents.buildSectionTitle('Preferências de Notificação',
            icon: Icons.notifications),
        const SizedBox(height: 16),
        FormComponents.buildFormCard(
          children: [
            CheckboxListTile(
              title: const Text('Receber notificações por e-mail'),
              subtitle: const Text('Atualizações sobre o status do ticket'),
              value: _notifyByEmail,
              onChanged: (value) {
                setState(() {
                  _notifyByEmail = value ?? false;
                });
              },
              activeColor: FormComponents.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Receber notificações por SMS'),
              subtitle: const Text('Apenas para atualizações urgentes'),
              value: _notifyBySms,
              onChanged: (value) {
                setState(() {
                  _notifyBySms = value ?? false;
                });
              },
              activeColor: FormComponents.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        FormComponents.buildPrimaryButton(
          text: 'Criar Ticket',
          onPressed: _submitForm,
          isLoading: _isSubmitting,
          icon: Icons.send,
        ),
        const SizedBox(height: 12),
        FormComponents.buildSecondaryButton(
          text: 'Salvar Rascunho',
          onPressed: _saveDraft,
          icon: Icons.save,
        ),
      ],
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como criar um bom ticket?'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  '📝 **Título claro e específico**\nDescreva o problema em poucas palavras'),
              SizedBox(height: 12),
              Text('📧 **E-mail válido**\nPara receber atualizações do ticket'),
              SizedBox(height: 12),
              Text(
                  '🏷️ **Categoria correta**\nAjuda a direcionar para a equipe certa'),
              SizedBox(height: 12),
              Text(
                  '⚡ **Prioridade adequada**\n• Baixa: Melhorias\n• Média: Problemas normais\n• Alta: Impacta o trabalho\n• Urgente: Sistema parado'),
              SizedBox(height: 12),
              Text(
                  '📋 **Descrição detalhada**\nIncluir passos, comportamento esperado e atual'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final ticketStore = Provider.of<TicketStore>(context, listen: false);
      final authStore = Provider.of<AuthStore>(context, listen: false);

      // Converter strings para enums
      final priority = _convertPriorityString(_selectedPriority);
      final category = _convertCategoryString(_selectedCategory);
      const status = TicketStatus.open;

      // Log para debug
      print('DEBUG - Valores selecionados:');
      print('  _selectedPriority: $_selectedPriority');
      print('  _selectedCategory: $_selectedCategory');
      print('  priority convertido: $priority');
      print('  category convertido: $category');

      // Criar o ticket usando o TicketStore
      final ticket = await ticketStore.createTicket(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        customerId: authStore.appUser!.id,
        priority: priority,
        category: category,
        assignedTo: null, // Será atribuído pelo backend
      );

      if (ticket != null) {
        // Mostrar dialog de sucesso
        _showSuccessDialog(ticket.id);

        // Limpar formulário
        _formKey.currentState!.reset();
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedPriority = 'Média';
          _selectedCategory = 'Geral';
          _notifyByEmail = true;
          _notifyBySms = false;
        });
      } else {
        throw Exception('Erro ao criar ticket');
      }
    } catch (e) {
      // Mostrar erro
      ToastMessage.show(
        context,
        message: 'Erro ao criar ticket: $e',
        type: ToastType.error,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  TicketPriority _convertPriorityString(String priority) {
    switch (priority) {
      case 'Baixa':
        return TicketPriority.low;
      case 'Média':
        return TicketPriority.normal;
      case 'Alta':
        return TicketPriority.high;
      case 'Urgente':
        return TicketPriority.urgent;
      default:
        return TicketPriority.normal;
    }
  }

  TicketCategory _convertCategoryString(String category) {
    switch (category) {
      case 'Técnico':
        return TicketCategory.technical;
      case 'Financeiro':
        return TicketCategory.billing;
      case 'Geral':
        return TicketCategory.general;
      case 'Reclamação':
        return TicketCategory.complaint;
      case 'Feature':
        return TicketCategory.feature;
      case 'Suporte':
        return TicketCategory.general;
      case 'Bug':
        return TicketCategory.technical;
      case 'Manutenção':
        return TicketCategory.technical;
      case 'Consulta':
        return TicketCategory.general;
      default:
        return TicketCategory.general;
    }
  }

  Future<void> _saveDraft() async {
    // Implementar lógica de salvar rascunho
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rascunho salvo com sucesso!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showValidationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Por favor, corrija os erros no formulário'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(String ticketId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Ticket Criado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Seu ticket foi criado com sucesso.'),
            const SizedBox(height: 8),
            Text(
              'Número: #TK$ticketId',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Você receberá atualizações por e-mail.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fechar dialog
              Navigator.of(context).pop(); // Voltar para tela anterior
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Tentar Novamente',
          textColor: Colors.white,
          onPressed: _submitForm,
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF3B82F6),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }
}
