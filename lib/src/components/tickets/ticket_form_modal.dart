import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../../widgets/form_components.dart';

class TicketFormModal extends StatefulWidget {
  final Ticket? ticket;
  final List<User> availableAgents;
  final Function(TicketFormData)? onSubmit;
  final VoidCallback? onCancel;

  const TicketFormModal({
    super.key,
    this.ticket,
    this.availableAgents = const [],
    this.onSubmit,
    this.onCancel,
  });

  @override
  State<TicketFormModal> createState() => _TicketFormModalState();

  static Future<T?> show<T>({
    required BuildContext context,
    Ticket? ticket,
    List<User> availableAgents = const [],
    Function(TicketFormData)? onSubmit,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TicketFormModal(
        ticket: ticket,
        availableAgents: availableAgents,
        onSubmit: onSubmit,
      ),
    );
  }
}

class _TicketFormModalState extends State<TicketFormModal>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  TicketPriority _selectedPriority = TicketPriority.normal;
  TicketCategory _selectedCategory = TicketCategory.general;
  TicketStatus _selectedStatus = TicketStatus.open;
  User? _selectedAgent;
  List<TicketTag> _selectedTags = [];
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _isLoading = false;
  final bool _isDraft = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeForm();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  void _initializeForm() {
    if (widget.ticket != null) {
      final ticket = widget.ticket!;
      _titleController.text = ticket.title;
      _descriptionController.text = ticket.description;
      _selectedPriority = ticket.priority;
      _selectedCategory = ticket.category;
      _selectedStatus = ticket.status;
      _selectedAgent = ticket.assignedAgent;
      _selectedTags = List.from(ticket.tags);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        await Future.delayed(const Duration(milliseconds: 1500)); // Simula API

        final formData = TicketFormData(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          category: _selectedCategory,
          status: _selectedStatus,
          assignedAgent: _selectedAgent,
          tags: _selectedTags,
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          emailNotifications: _emailNotifications,
          smsNotifications: _smsNotifications,
        );

        widget.onSubmit?.call(formData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(widget.ticket != null
                      ? 'Ticket atualizado com sucesso!'
                      : 'Ticket criado com sucesso!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(formData);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Erro ao salvar ticket. Tente novamente.'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(PhosphorIcons.lightbulb(), color: FormComponents.primaryColor),
            const SizedBox(width: 8),
            const Text('Dicas para um bom ticket'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HelpItem(
                icon: PhosphorIcons.textT,
                title: 'Título claro e específico',
                description: 'Descreva o problema em poucas palavras',
              ),
              SizedBox(height: 16),
              _HelpItem(
                icon: PhosphorIcons.envelope,
                title: 'E-mail válido',
                description: 'Para receber atualizações do ticket',
              ),
              SizedBox(height: 16),
              _HelpItem(
                icon: PhosphorIcons.tag,
                title: 'Categoria correta',
                description: 'Ajuda a direcionar para a equipe certa',
              ),
              SizedBox(height: 16),
              _HelpItem(
                icon: PhosphorIcons.flag,
                title: 'Prioridade adequada',
                description:
                    'Baixa: Melhorias\nMédia: Problemas normais\nAlta: Impacta o trabalho\nUrgente: Sistema parado',
              ),
              SizedBox(height: 16),
              _HelpItem(
                icon: PhosphorIcons.notepad,
                title: 'Descrição detalhada',
                description: 'Incluir passos, comportamento esperado e atual',
              ),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;
    final isMobile = screenWidth <= 768;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
              ),
              elevation: isDesktop ? 24 : 16,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth:
                      isDesktop ? 1200 : (isTablet ? 800 : double.infinity),
                  maxHeight: isDesktop ? 900 : (isTablet ? 850 : 950),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: isDesktop ? 32 : 24,
                      offset: Offset(0, isDesktop ? 16 : 12),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: isDesktop ? 16 : 12,
                      offset: Offset(0, isDesktop ? 8 : 6),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Painel esquerdo - Formulário principal
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildMainForm(),
              ),
            ],
          ),
        ),
        // Painel direito - Sidebar com dicas e preview
        Container(
          width: 380,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[50]!,
                Colors.grey[100]!,
              ],
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            border: Border(
              left: BorderSide(
                color: Colors.grey.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildSidebarHeader(),
              Expanded(
                child: _buildSidebarContent(),
              ),
              _buildSidebarFooter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(
          child: _buildBody(),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações Básicas
            FormComponents.buildSectionTitle(
              'Informações Básicas',
              icon: PhosphorIcons.info(),
            ),
            const SizedBox(height: 16),

            FormComponents.buildTextField(
              controller: _titleController,
              label: 'Título do Ticket *',
              hint: 'Ex: Problema no login do sistema',
              icon: PhosphorIcons.textT(),
              validator: (value) =>
                  FormComponents.validateRequired(value, 'Título'),
            ),
            const SizedBox(height: 16),

            FormComponents.buildTextField(
              controller: _emailController,
              label: 'E-mail de Contato *',
              hint: 'seu@email.com',
              icon: PhosphorIcons.envelope(),
              validator: FormComponents.validateEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            FormComponents.buildTextField(
              controller: _phoneController,
              label: 'Telefone',
              hint: '(11) 99999-9999',
              icon: PhosphorIcons.phone(),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Categorização
            FormComponents.buildSectionTitle(
              'Categorização',
              icon: PhosphorIcons.tag(),
            ),
            const SizedBox(height: 16),

            FormComponents.buildDropdown<TicketCategory>(
              value: _selectedCategory,
              label: 'Categoria *',
              icon: PhosphorIcons.tag(),
              items: TicketCategory.values,
              itemLabel: (category) => _getCategoryText(category),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prioridade *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FormComponents.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPrioritySelector(),
              ],
            ),
            const SizedBox(height: 24),

            // Descrição Detalhada
            FormComponents.buildSectionTitle(
              'Descrição Detalhada',
              icon: PhosphorIcons.notepad(),
            ),
            const SizedBox(height: 16),

            FormComponents.buildTextField(
              controller: _descriptionController,
              label: 'Descrição do Problema *',
              hint: 'Descreva detalhadamente o problema ou solicitação...',
              icon: PhosphorIcons.notepad(),
              maxLines: 4,
              validator: (value) =>
                  FormComponents.validateMinLength(value, 20, 'Descrição'),
            ),
            const SizedBox(height: 24),

            // Agente e Tags (apenas para edição)
            if (widget.ticket != null) ...[
              FormComponents.buildSectionTitle(
                'Atribuição',
                icon: PhosphorIcons.userGear(),
              ),
              const SizedBox(height: 16),
              _buildAgentSelector(),
              const SizedBox(height: 16),
              _buildStatusSelector(),
              const SizedBox(height: 24),
            ],

            // Preferências de Notificação
            FormComponents.buildSectionTitle(
              'Preferências de Notificação',
              icon: PhosphorIcons.bell(),
            ),
            const SizedBox(height: 16),

            _buildNotificationPreferences(),

            if (_isDraft) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.save,
                      color: Colors.orange[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rascunho salvo automaticamente',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FormComponents.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIcons.lightbulb(),
                  color: FormComponents.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Dicas Rápidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildQuickTip(
            icon: () => PhosphorIcons.textT(),
            title: 'Título claro',
            description: 'Seja específico sobre o problema',
          ),
          const SizedBox(height: 12),
          _buildQuickTip(
            icon: () => PhosphorIcons.notepad(),
            title: 'Descrição detalhada',
            description: 'Inclua passos para reproduzir',
          ),
          const SizedBox(height: 12),
          _buildQuickTip(
            icon: () => PhosphorIcons.flag(),
            title: 'Prioridade correta',
            description: 'Urgente apenas se crítico',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTip({
    required IconData Function() icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon(),
          size: 14,
          color: FormComponents.primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview do ticket
          if (_titleController.text.isNotEmpty ||
              _descriptionController.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.eye(),
                        size: 16,
                        color: FormComponents.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_titleController.text.isNotEmpty) ...[
                    Text(
                      _titleController.text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      FormComponents.buildStatusChip(
                        label: _getPriorityText(_selectedPriority),
                        color: _getPriorityColor(_selectedPriority),
                        icon: _getPriorityIcon(_selectedPriority),
                      ),
                      const SizedBox(width: 8),
                      FormComponents.buildStatusChip(
                        label: _getCategoryText(_selectedCategory),
                        color: FormComponents.primaryColor,
                        icon: PhosphorIcons.tag(),
                      ),
                    ],
                  ),
                  if (_descriptionController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _descriptionController.text,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Estatísticas rápidas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.chartBar(),
                      size: 16,
                      color: FormComponents.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Estatísticas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatItem('Tempo médio de resposta', '2h 30min'),
                const SizedBox(height: 8),
                _buildStatItem('Taxa de resolução', '94%'),
                const SizedBox(height: 8),
                _buildStatItem('Tickets hoje', '12'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FormComponents.buildPrimaryButton(
              text: widget.ticket != null ? 'Atualizar Ticket' : 'Criar Ticket',
              onPressed: _handleSubmit,
              icon: widget.ticket != null
                  ? PhosphorIcons.pencil()
                  : PhosphorIcons.plus(),
              isLoading: _isLoading,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FormComponents.buildSecondaryButton(
              text: 'Cancelar',
              onPressed: () => Navigator.of(context).pop(),
              icon: PhosphorIcons.x(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações Básicas
            FormComponents.buildSectionTitle(
              'Informações Básicas',
              icon: PhosphorIcons.info(),
            ),
            const SizedBox(height: 24),

            // Layout em duas colunas para desktop
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: FormComponents.buildTextField(
                      controller: _titleController,
                      label: 'Título do Ticket *',
                      hint: 'Ex: Problema no login do sistema',
                      icon: PhosphorIcons.textT(),
                      validator: (value) =>
                          FormComponents.validateRequired(value, 'Título')),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      FormComponents.buildTextField(
                        controller: _emailController,
                        label: 'E-mail de Contato *',
                        hint: 'seu@email.com',
                        icon: PhosphorIcons.envelope(),
                        validator: FormComponents.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      FormComponents.buildTextField(
                        controller: _phoneController,
                        label: 'Telefone',
                        hint: '(11) 99999-9999',
                        icon: PhosphorIcons.phone(),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Categorização
            FormComponents.buildSectionTitle(
              'Categorização',
              icon: PhosphorIcons.tag(),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: FormComponents.buildDropdown<TicketCategory>(
                    value: _selectedCategory,
                    label: 'Categoria *',
                    icon: PhosphorIcons.tag(),
                    items: TicketCategory.values,
                    itemLabel: (category) => _getCategoryText(category),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prioridade *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: FormComponents.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPrioritySelector(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Descrição Detalhada
            FormComponents.buildSectionTitle(
              'Descrição Detalhada',
              icon: PhosphorIcons.notepad(),
            ),
            const SizedBox(height: 20),

            FormComponents.buildTextField(
                controller: _descriptionController,
                label: 'Descrição do Problema *',
                hint: 'Descreva detalhadamente o problema ou solicitação...',
                icon: PhosphorIcons.notepad(),
                maxLines: 5,
                validator: (value) =>
                    FormComponents.validateMinLength(value, 20, 'Descrição')),
            const SizedBox(height: 32),

            // Agente e Tags (apenas para edição)
            if (widget.ticket != null) ...[
              FormComponents.buildSectionTitle(
                'Atribuição',
                icon: PhosphorIcons.userGear(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildAgentSelector(),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatusSelector(),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            // Preferências de Notificação
            FormComponents.buildSectionTitle(
              'Preferências de Notificação',
              icon: PhosphorIcons.bell(),
            ),
            const SizedBox(height: 20),

            _buildNotificationPreferences(),

            if (_isDraft) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.save,
                      color: Colors.orange[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rascunho salvo automaticamente',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FormComponents.primaryColor,
            FormComponents.primaryColor.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isDesktop ? 24 : 20),
          topRight: Radius.circular(isDesktop ? 0 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: FormComponents.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 12 : 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              widget.ticket != null
                  ? PhosphorIcons.pencil()
                  : PhosphorIcons.plus(),
              color: Colors.white,
              size: isDesktop ? 24 : 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ticket != null ? 'Editar Ticket' : 'Novo Ticket',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isDesktop) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.ticket != null
                        ? 'Atualize as informações do ticket'
                        : 'Preencha os dados para criar um novo ticket',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isDesktop) ...[
            IconButton(
              onPressed: _showHelpDialog,
              icon: const Icon(
                Icons.help_outline,
                color: Colors.white,
              ),
              tooltip: 'Ajuda',
            ),
          ],
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.grey[25],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isDesktop ? 24 : 20),
          bottomRight: Radius.circular(isDesktop ? 24 : 20),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (isDesktop) ...[
            // Desktop: Botões com largura fixa e melhor espaçamento
            SizedBox(
              width: 140,
              child: FormComponents.buildSecondaryButton(
                text: 'Cancelar',
                onPressed: () => Navigator.of(context).pop(),
                icon: PhosphorIcons.x(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 180,
              child: FormComponents.buildPrimaryButton(
                text:
                    widget.ticket != null ? 'Atualizar Ticket' : 'Criar Ticket',
                onPressed: _handleSubmit,
                icon: widget.ticket != null
                    ? PhosphorIcons.pencil()
                    : PhosphorIcons.plus(),
                isLoading: _isLoading,
              ),
            ),
          ] else ...[
            // Mobile: Layout otimizado
            Expanded(
              child: FormComponents.buildSecondaryButton(
                text: 'Cancelar',
                onPressed: () => Navigator.of(context).pop(),
                icon: PhosphorIcons.x(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FormComponents.buildPrimaryButton(
                text: widget.ticket != null ? 'Atualizar' : 'Criar',
                onPressed: _handleSubmit,
                icon: widget.ticket != null
                    ? PhosphorIcons.pencil()
                    : PhosphorIcons.plus(),
                isLoading: _isLoading,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrioritySelector() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        border: Border.all(
          color: FormComponents.borderColor.withValues(alpha: 0.2),
          width: 1,
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecione a prioridade:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TicketPriority.values.map((priority) {
              final isSelected = _selectedPriority == priority;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPriority = priority;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? _getPriorityColor(priority) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _getPriorityColor(priority)
                          : _getPriorityColor(priority).withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _getPriorityColor(priority)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPriorityIcon(priority),
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : _getPriorityColor(priority),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getPriorityText(priority),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : _getPriorityColor(priority),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentSelector() {
    final List<User?> agentItems = [null, ...widget.availableAgents];

    return FormComponents.buildDropdown<User?>(
      value: _selectedAgent,
      label: 'Agente Responsável',
      icon: PhosphorIcons.userGear(),
      items: agentItems,
      itemLabel: (agent) => agent?.name ?? 'Nenhum agente',
      onChanged: (value) {
        setState(() {
          _selectedAgent = value;
        });
      },
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: FormComponents.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TicketStatus.values.map((status) {
            final isSelected = _selectedStatus == status;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStatus = status;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? FormComponents.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? FormComponents.primaryColor
                        : FormComponents.borderColor,
                  ),
                ),
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(
                    color: isSelected ? Colors.white : FormComponents.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotificationPreferences() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 8),
        border: Border.all(
          color: FormComponents.borderColor,
        ),
        color: Colors.grey[25],
        boxShadow: isDesktop
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 10 : 8),
                decoration: BoxDecoration(
                  color: FormComponents.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
                ),
                child: Icon(
                  PhosphorIcons.envelope(),
                  size: isDesktop ? 22 : 20,
                  color: FormComponents.primaryColor,
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notificações por E-mail',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isDesktop ? 15 : 14,
                        color: FormComponents.textColor,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 4 : 2),
                    Text(
                      'Receber atualizações do ticket por e-mail',
                      style: TextStyle(
                        fontSize: isDesktop ? 13 : 12,
                        color: FormComponents.textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: isDesktop ? 1.1 : 1.0,
                child: Switch(
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                  },
                  activeColor: FormComponents.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 10 : 8),
                decoration: BoxDecoration(
                  color: FormComponents.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
                ),
                child: Icon(
                  PhosphorIcons.chatCircle(),
                  size: isDesktop ? 22 : 20,
                  color: FormComponents.primaryColor,
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notificações por SMS',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isDesktop ? 15 : 14,
                        color: FormComponents.textColor,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 4 : 2),
                    Text(
                      'Receber notificações importantes por SMS',
                      style: TextStyle(
                        fontSize: isDesktop ? 13 : 12,
                        color: FormComponents.textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: isDesktop ? 1.1 : 1.0,
                child: Switch(
                  value: _smsNotifications,
                  onChanged: (value) {
                    setState(() {
                      _smsNotifications = value;
                    });
                  },
                  activeColor: FormComponents.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCategoryText(TicketCategory category) {
    switch (category) {
      case TicketCategory.technical:
        return 'Técnico';
      case TicketCategory.billing:
        return 'Financeiro';
      case TicketCategory.general:
        return 'Geral';
      case TicketCategory.complaint:
        return 'Reclamação';
      case TicketCategory.feature:
        return 'Feature';
    }
  }

  String _getPriorityText(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return 'Baixa';
      case TicketPriority.normal:
        return 'Normal';
      case TicketPriority.high:
        return 'Alta';
      case TicketPriority.urgent:
        return 'Urgente';
    }
  }

  String _getStatusText(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'Aberto';
      case TicketStatus.inProgress:
        return 'Em Andamento';
      case TicketStatus.resolved:
        return 'Resolvido';
      case TicketStatus.closed:
        return 'Fechado';
      case TicketStatus.waitingCustomer:
        return 'Aguardando Cliente';
    }
  }

  IconData _getPriorityIcon(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return PhosphorIcons.arrowDown();
      case TicketPriority.normal:
        return PhosphorIcons.minus();
      case TicketPriority.high:
        return PhosphorIcons.arrowUp();
      case TicketPriority.urgent:
        return PhosphorIcons.warning();
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return Colors.green;
      case TicketPriority.normal:
        return Colors.blue;
      case TicketPriority.high:
        return Colors.orange;
      case TicketPriority.urgent:
        return Colors.red;
    }
  }
}

class _HelpItem extends StatelessWidget {
  final IconData Function() icon;
  final String title;
  final String description;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: FormComponents.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon(),
            size: 16,
            color: FormComponents.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: FormComponents.textColor.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TicketFormData {
  final String title;
  final String description;
  final TicketPriority priority;
  final TicketCategory category;
  final TicketStatus status;
  final User? assignedAgent;
  final List<TicketTag> tags;
  final String email;
  final String phone;
  final bool emailNotifications;
  final bool smsNotifications;

  const TicketFormData({
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.status,
    this.assignedAgent,
    this.tags = const [],
    required this.email,
    this.phone = '',
    this.emailNotifications = true,
    this.smsNotifications = false,
  });
}
