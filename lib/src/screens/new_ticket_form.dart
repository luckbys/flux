import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../stores/ticket_store.dart';
import '../stores/auth_store.dart';
import '../models/ticket.dart';
import '../components/ui/toast_message.dart';

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

      // Log para debug
      debugPrint('DEBUG - Valores selecionados:');
      debugPrint('  _selectedPriority: $_selectedPriority');
      debugPrint('  _selectedCategory: $_selectedCategory');
      debugPrint('  priority convertido: $priority');
      debugPrint('  category convertido: $category');

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
}
