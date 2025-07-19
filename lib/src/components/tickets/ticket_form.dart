import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../ui/status_badge.dart';
import '../ui/user_avatar.dart';
import '../../styles/app_theme.dart';
import '../../styles/app_constants.dart';
import '../../utils/color_extensions.dart';

class TicketForm extends StatefulWidget {
  final Ticket? ticket;
  final List<User> availableAgents;
  final Function(TicketFormData)? onSubmit;
  final VoidCallback? onCancel;

  const TicketForm({
    Key? key,
    this.ticket,
    this.availableAgents = const [],
    this.onSubmit,
    this.onCancel,
  }) : super(key: key);

  @override
  State<TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends State<TicketForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TicketPriority _selectedPriority = TicketPriority.normal;
  TicketCategory _selectedCategory = TicketCategory.general;
  TicketStatus _selectedStatus = TicketStatus.open;
  User? _selectedAgent;
  List<TicketTag> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
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
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final formData = TicketFormData(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        category: _selectedCategory,
        status: _selectedStatus,
        assignedAgent: _selectedAgent,
        tags: _selectedTags,
      );

      widget.onSubmit?.call(formData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket != null ? 'Editar Ticket' : 'Novo Ticket'),
        actions: [
          TextButton(
            onPressed: _handleSubmit,
            child: const Text('Salvar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleField(),
              const SizedBox(height: AppTheme.spacing16),
              _buildDescriptionField(),
              const SizedBox(height: AppTheme.spacing24),
              _buildPrioritySelector(),
              const SizedBox(height: AppTheme.spacing16),
              _buildCategorySelector(),
              const SizedBox(height: AppTheme.spacing16),
              if (widget.ticket != null) ...[
                _buildStatusSelector(),
                const SizedBox(height: AppTheme.spacing16),
              ],
              _buildAgentSelector(),
              const SizedBox(height: AppTheme.spacing16),
              _buildTagsSelector(),
              const SizedBox(height: AppTheme.spacing32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Título',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Digite o título do ticket',
          ),
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'O título é obrigatório';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descrição',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Descreva o problema ou solicitação',
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'A descrição é obrigatória';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prioridade',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Wrap(
          spacing: AppTheme.spacing8,
          children: TicketPriority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPriority = priority;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing8,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textColor.withValues(alpha:  0.3),
                    width: 1,
                  ),
                ),
                child: TicketPriorityBadge(
                  priority: priority,
                  isOutlined: !isSelected,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoria',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        DropdownButtonFormField<TicketCategory>(
          value: _selectedCategory,
          decoration: InputDecoration(
            prefixIcon: Icon(PhosphorIcons.tag()),
          ),
          items: TicketCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(_getCategoryText(category)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Wrap(
          spacing: AppTheme.spacing8,
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
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing8,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textColor.withValues(alpha:  0.3),
                    width: 1,
                  ),
                ),
                child: TicketStatusBadge(
                  status: status,
                  isOutlined: !isSelected,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAgentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agente Responsável',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        DropdownButtonFormField<User?>(
          value: _selectedAgent,
          decoration: InputDecoration(
            prefixIcon: Icon(PhosphorIcons.userGear()),
            hintText: 'Selecionar agente (opcional)',
          ),
          items: [
            const DropdownMenuItem<User?>(
              value: null,
              child: Text('Nenhum agente'),
            ),
            ...widget.availableAgents.map((agent) {
              return DropdownMenuItem<User?>(
                value: agent,
                child: Row(
                  children: [
                    UserAvatar(
                      user: agent,
                      size: AppConstants.iconMedium,
                      showOnlineStatus: false,
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(agent.name),
                  ],
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedAgent = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTagsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            border: Border.all(
              color: AppTheme.textColor.withValues(alpha:  0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              if (_selectedTags.isNotEmpty) ...[
                Wrap(
                  spacing: AppTheme.spacing8,
                  runSpacing: AppTheme.spacing8,
                  children: _selectedTags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing12,
                        vertical: AppTheme.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            Color(int.parse(tag.color, radix: 16) | 0xFF000000)
                                .withValues(alpha:  0.1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                        border: Border.all(
                          color: Color(
                              int.parse(tag.color, radix: 16) | 0xFF000000),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag.name,
                            style: TextStyle(
                              color: Color(
                                  int.parse(tag.color, radix: 16) | 0xFF000000),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTags.remove(tag);
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Color(
                                  int.parse(tag.color, radix: 16) | 0xFF000000),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.spacing8),
              ],
              GestureDetector(
                onTap: () {
                  // TODO: Implementar seletor de tags
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing12,
                    vertical: AppTheme.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha:  0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha:  0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.add,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: AppTheme.spacing4),
                      Text(
                        'Adicionar Tag',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onCancel ?? () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: ElevatedButton(
            onPressed: _handleSubmit,
            child: Text(widget.ticket != null ? 'Atualizar' : 'Criar Ticket'),
          ),
        ),
      ],
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
}

class TicketFormData {
  final String title;
  final String description;
  final TicketPriority priority;
  final TicketCategory category;
  final TicketStatus status;
  final User? assignedAgent;
  final List<TicketTag> tags;

  const TicketFormData({
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.status,
    this.assignedAgent,
    this.tags = const [],
  });
}
