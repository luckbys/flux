import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../../widgets/form_components.dart';
import 'ticket_form_modal_refactored.dart';

// =============================================================================
// TICKET MODAL HEADER
// =============================================================================

class TicketModalHeader extends StatelessWidget {
  final Ticket? ticket;
  final VoidCallback onClose;
  final VoidCallback onHelp;
  final ResponsiveLayout layout;

  const TicketModalHeader({
    super.key,
    this.ticket,
    required this.onClose,
    required this.onHelp,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: layout.padding,
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
          topLeft: Radius.circular(layout.borderRadius),
          topRight: Radius.circular(layout.isDesktop ? 0 : layout.borderRadius),
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
          _buildIcon(),
          const SizedBox(width: 16),
          Expanded(child: _buildTitle()),
          if (!layout.isDesktop) _buildHelpButton(),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: EdgeInsets.all(layout.isDesktop ? 12 : 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(layout.isDesktop ? 16 : 14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(
        ticket != null ? PhosphorIcons.pencil() : PhosphorIcons.plus(),
        color: Colors.white,
        size: layout.isDesktop ? 24 : 22,
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ticket != null ? 'Editar Ticket' : 'Novo Ticket',
          style: TextStyle(
            color: Colors.white,
            fontSize: layout.isDesktop ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!layout.isDesktop) ...[
          const SizedBox(height: 4),
          Text(
            ticket != null
                ? 'Atualize as informações do ticket'
                : 'Preencha os dados para criar um novo ticket',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHelpButton() {
    return IconButton(
      onPressed: onHelp,
      icon: const Icon(Icons.help_outline, color: Colors.white),
      tooltip: 'Ajuda',
    );
  }

  Widget _buildCloseButton() {
    return IconButton(
      onPressed: onClose,
      icon: const Icon(Icons.close, color: Colors.white),
      tooltip: 'Fechar',
    );
  }
}

// =============================================================================
// TICKET FORM CONTENT
// =============================================================================

class TicketFormContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TicketPriority selectedPriority;
  final TicketCategory selectedCategory;
  final TicketStatus selectedStatus;
  final User? selectedAgent;
  final List<User> availableAgents;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool isDraft;
  final bool isEditing;
  final Function(TicketPriority) onPriorityChanged;
  final Function(TicketCategory) onCategoryChanged;
  final Function(TicketStatus) onStatusChanged;
  final Function(User?) onAgentChanged;
  final Function(bool) onEmailNotificationsChanged;
  final Function(bool) onSmsNotificationsChanged;
  final ResponsiveLayout layout;

  const TicketFormContent({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.emailController,
    required this.phoneController,
    required this.selectedPriority,
    required this.selectedCategory,
    required this.selectedStatus,
    required this.selectedAgent,
    required this.availableAgents,
    required this.emailNotifications,
    required this.smsNotifications,
    required this.isDraft,
    required this.isEditing,
    required this.onPriorityChanged,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onAgentChanged,
    required this.onEmailNotificationsChanged,
    required this.onSmsNotificationsChanged,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: layout.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(),
            SizedBox(height: layout.spacing * 2),
            _buildCategorizationSection(),
            SizedBox(height: layout.spacing * 2),
            _buildDescriptionSection(),
            if (isEditing) ...[
              SizedBox(height: layout.spacing * 2),
              _buildAssignmentSection(),
            ],
            SizedBox(height: layout.spacing * 2),
            _buildNotificationSection(),
            if (isDraft) ...[
              SizedBox(height: layout.spacing),
              _buildDraftIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormComponents.buildSectionTitle(
          'Informações Básicas',
          icon: PhosphorIcons.info(),
        ),
        SizedBox(height: layout.spacing),
        if (layout.isDesktop) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildTitleField(),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildEmailField(),
                    const SizedBox(height: 20),
                    _buildPhoneField(),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          _buildTitleField(),
          SizedBox(height: layout.spacing),
          _buildEmailField(),
          SizedBox(height: layout.spacing),
          _buildPhoneField(),
        ],
      ],
    );
  }

  Widget _buildTitleField() {
    return FormComponents.buildTextField(
      controller: titleController,
      label: 'Título do Ticket *',
      hint: 'Ex: Problema no login do sistema',
      icon: PhosphorIcons.textT(),
      validator: (value) => FormComponents.validateRequired(value, 'Título'),
    );
  }

  Widget _buildEmailField() {
    return FormComponents.buildTextField(
      controller: emailController,
      label: 'E-mail de Contato *',
      hint: 'seu@email.com',
      icon: PhosphorIcons.envelope(),
      validator: FormComponents.validateEmail,
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPhoneField() {
    return FormComponents.buildTextField(
      controller: phoneController,
      label: 'Telefone',
      hint: '(11) 99999-9999',
      icon: PhosphorIcons.phone(),
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildCategorizationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormComponents.buildSectionTitle(
          'Categorização',
          icon: PhosphorIcons.tag(),
        ),
        SizedBox(height: layout.spacing),
        Row(
          children: [
            Expanded(
              child: _buildCategoryDropdown(),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildPrioritySelector(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return FormComponents.buildDropdown<TicketCategory>(
      value: selectedCategory,
      label: 'Categoria *',
      icon: PhosphorIcons.tag(),
      items: TicketCategory.values,
      itemLabel: (category) => _getCategoryText(category),
      onChanged: (value) {
        if (value != null) onCategoryChanged(value);
      },
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
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
        _buildPriorityChips(),
      ],
    );
  }

  Widget _buildPriorityChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
              final isSelected = selectedPriority == priority;
              return _buildPriorityChip(priority, isSelected);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(TicketPriority priority, bool isSelected) {
    return GestureDetector(
      onTap: () => onPriorityChanged(priority),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _getPriorityColor(priority) : Colors.white,
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
                    color: _getPriorityColor(priority).withValues(alpha: 0.3),
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
              color: isSelected ? Colors.white : _getPriorityColor(priority),
            ),
            const SizedBox(width: 8),
            Text(
              _getPriorityText(priority),
              style: TextStyle(
                color: isSelected ? Colors.white : _getPriorityColor(priority),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormComponents.buildSectionTitle(
          'Descrição Detalhada',
          icon: PhosphorIcons.notepad(),
        ),
        SizedBox(height: layout.spacing),
        FormComponents.buildTextField(
          controller: descriptionController,
          label: 'Descrição do Problema *',
          hint: 'Descreva detalhadamente o problema ou solicitação...',
          icon: PhosphorIcons.notepad(),
          maxLines: layout.isDesktop ? 5 : 4,
          validator: (value) =>
              FormComponents.validateMinLength(value, 20, 'Descrição'),
        ),
      ],
    );
  }

  Widget _buildAssignmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormComponents.buildSectionTitle(
          'Atribuição',
          icon: PhosphorIcons.userGear(),
        ),
        SizedBox(height: layout.spacing),
        Row(
          children: [
            Expanded(child: _buildAgentSelector()),
            const SizedBox(width: 20),
            Expanded(child: _buildStatusSelector()),
          ],
        ),
      ],
    );
  }

  Widget _buildAgentSelector() {
    final List<User?> agentItems = [null, ...availableAgents];

    return FormComponents.buildDropdown<User?>(
      value: selectedAgent,
      label: 'Agente Responsável',
      icon: PhosphorIcons.userGear(),
      items: agentItems,
      itemLabel: (agent) => agent?.name ?? 'Nenhum agente',
      onChanged: onAgentChanged,
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
            final isSelected = selectedStatus == status;
            return GestureDetector(
              onTap: () => onStatusChanged(status),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormComponents.buildSectionTitle(
          'Preferências de Notificação',
          icon: PhosphorIcons.bell(),
        ),
        SizedBox(height: layout.spacing),
        _buildNotificationPreferences(),
      ],
    );
  }

  Widget _buildNotificationPreferences() {
    return Container(
      padding: EdgeInsets.all(layout.isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.isDesktop ? 16 : 8),
        border: Border.all(color: FormComponents.borderColor),
        color: Colors.grey[25],
        boxShadow: layout.isDesktop
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
          _buildNotificationOption(
            icon: PhosphorIcons.envelope(),
            title: 'Notificações por E-mail',
            subtitle: 'Receber atualizações do ticket por e-mail',
            value: emailNotifications,
            onChanged: onEmailNotificationsChanged,
          ),
          SizedBox(height: layout.isDesktop ? 20 : 16),
          _buildNotificationOption(
            icon: PhosphorIcons.chatCircle(),
            title: 'Notificações por SMS',
            subtitle: 'Receber notificações importantes por SMS',
            value: smsNotifications,
            onChanged: onSmsNotificationsChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(layout.isDesktop ? 10 : 8),
          decoration: BoxDecoration(
            color: FormComponents.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(layout.isDesktop ? 12 : 8),
          ),
          child: Icon(
            icon,
            size: layout.isDesktop ? 22 : 20,
            color: FormComponents.primaryColor,
          ),
        ),
        SizedBox(width: layout.isDesktop ? 16 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: layout.isDesktop ? 15 : 14,
                  color: FormComponents.textColor,
                ),
              ),
              SizedBox(height: layout.isDesktop ? 4 : 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: layout.isDesktop ? 13 : 12,
                  color: FormComponents.textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: layout.isDesktop ? 1.1 : 1.0,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: FormComponents.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDraftIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.save, color: Colors.orange[700], size: 16),
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
    );
  }

  // Helper methods
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
