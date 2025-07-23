import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../components/tickets/ticket_form_modal.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../widgets/form_components.dart';

/// Exemplo de tela demonstrando o uso do modal de formulário de ticket aprimorado
class TicketModalExample extends StatefulWidget {
  const TicketModalExample({super.key});

  @override
  State<TicketModalExample> createState() => _TicketModalExampleState();
}

class _TicketModalExampleState extends State<TicketModalExample> {
  final List<Ticket> _tickets = [];
  final List<User> _availableAgents = [
    User(
      id: '1',
      name: 'João Silva',
      email: 'joao@empresa.com',
      avatarUrl: 'https://i.pravatar.cc/150?img=1',
      role: UserRole.agent,
      status: UserStatus.online,
      createdAt: DateTime.now(),
    ),
    User(
      id: '2',
      name: 'Maria Santos',
      email: 'maria@empresa.com',
      avatarUrl: 'https://i.pravatar.cc/150?img=2',
      role: UserRole.agent,
      status: UserStatus.online,
      createdAt: DateTime.now(),
    ),
    User(
      id: '3',
      name: 'Pedro Costa',
      email: 'pedro@empresa.com',
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
      role: UserRole.agent,
      status: UserStatus.online,
      createdAt: DateTime.now(),
    ),
  ];

  void _showCreateTicketModal() {
    TicketFormModal.show(
      context: context,
      availableAgents: _availableAgents,
      onSubmit: (formData) {
        _handleTicketCreated(formData);
      },
    );
  }

  void _showEditTicketModal(Ticket ticket) {
    TicketFormModal.show(
      context: context,
      ticket: ticket,
      availableAgents: _availableAgents,
      onSubmit: (formData) {
        _handleTicketUpdated(ticket, formData);
      },
    );
  }

  void _handleTicketCreated(TicketFormData formData) {
    final newTicket = Ticket(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: formData.title,
      description: formData.description,
      priority: formData.priority,
      category: formData.category,
      status: formData.status,
      assignedAgent: formData.assignedAgent,
      tags: formData.tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      customer: User(
        id: 'current_user',
        name: 'Usuário Atual',
        email: formData.email,
        role: UserRole.customer,
        status: UserStatus.online,
        createdAt: DateTime.now(),
      ),
    );

    setState(() {
      _tickets.insert(0, newTicket);
    });
  }

  void _handleTicketUpdated(Ticket originalTicket, TicketFormData formData) {
    final updatedTicket = originalTicket.copyWith(
      title: formData.title,
      description: formData.description,
      priority: formData.priority,
      category: formData.category,
      status: formData.status,
      assignedAgent: formData.assignedAgent,
      tags: formData.tags,
      updatedAt: DateTime.now(),
    );

    setState(() {
      final index = _tickets.indexWhere((t) => t.id == originalTicket.id);
      if (index != -1) {
        _tickets[index] = updatedTicket;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Modal de Ticket Aprimorado'),
        backgroundColor: FormComponents.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showCreateTicketModal,
            icon: Icon(PhosphorIcons.plus()),
            tooltip: 'Novo Ticket',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com estatísticas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FormComponents.primaryColor,
                  FormComponents.primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sistema de Tickets',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gerencie tickets com o novo modal aprimorado',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatCard(
                      'Total',
                      _tickets.length.toString(),
                      PhosphorIcons.ticket(PhosphorIconsStyle.regular),
                      Colors.white,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Abertos',
                      _tickets
                          .where((t) => t.status == TicketStatus.open)
                          .length
                          .toString(),
                      PhosphorIcons.clock(PhosphorIconsStyle.regular),
                      Colors.orange[100]!,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Resolvidos',
                      _tickets
                          .where((t) => t.status == TicketStatus.resolved)
                          .length
                          .toString(),
                      PhosphorIcons.checkCircle(PhosphorIconsStyle.regular),
                      Colors.green[100]!,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botões de ação
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: FormComponents.buildPrimaryButton(
                    text: 'Criar Novo Ticket',
                    onPressed: _showCreateTicketModal,
                    icon: PhosphorIcons.plus(),
                  ),
                ),
                const SizedBox(width: 16),
                FormComponents.buildSecondaryButton(
                  text: 'Ajuda',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: [
                            Icon(PhosphorIcons.info(),
                                color: FormComponents.primaryColor),
                            const SizedBox(width: 8),
                            const Text('Sobre o Modal Aprimorado'),
                          ],
                        ),
                        content: const Text(
                          'O novo modal de ticket inclui:\n\n'
                          '• Design moderno e responsivo\n'
                          '• Animações suaves\n'
                          '• Validações em tempo real\n'
                          '• Salvamento automático de rascunho\n'
                          '• Dicas contextuais\n'
                          '• Preferências de notificação\n'
                          '• Estados de loading\n'
                          '• Feedback visual aprimorado',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Entendi'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: PhosphorIcons.info(),
                ),
              ],
            ),
          ),

          // Lista de tickets
          Expanded(
            child: _tickets.isEmpty ? _buildEmptyState() : _buildTicketList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color backgroundColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: backgroundColor == Colors.white
                  ? FormComponents.primaryColor
                  : FormComponents.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: backgroundColor == Colors.white
                    ? FormComponents.primaryColor
                    : FormComponents.textColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: backgroundColor == Colors.white
                    ? FormComponents.primaryColor.withValues(alpha: 0.7)
                    : FormComponents.textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: FormComponents.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              PhosphorIcons.ticket(),
              size: 48,
              color: FormComponents.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhum ticket criado ainda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Clique no botão acima para criar seu primeiro ticket\ncom o novo modal aprimorado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FormComponents.textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          FormComponents.buildPrimaryButton(
            text: 'Criar Primeiro Ticket',
            onPressed: _showCreateTicketModal,
            icon: PhosphorIcons.plus(),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: FormComponents.buildFormCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(ticket.priority)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPriorityIcon(ticket.priority),
                    color: _getPriorityColor(ticket.priority),
                    size: 20,
                  ),
                ),
                title: Text(
                  ticket.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      ticket.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FormComponents.buildStatusChip(
                          label: _getCategoryText(ticket.category),
                          color: FormComponents.primaryColor,
                          icon: PhosphorIcons.tag(PhosphorIconsStyle.regular),
                        ),
                        const SizedBox(width: 8),
                        FormComponents.buildStatusChip(
                          label: _getStatusText(ticket.status),
                          color: _getStatusColor(ticket.status),
                          icon: _getStatusIcon(ticket.status),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  icon: Icon(PhosphorIcons.dotsThreeVertical(
                      PhosphorIconsStyle.regular)),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                              PhosphorIcons.pencil(PhosphorIconsStyle.regular)),
                          const SizedBox(width: 8),
                          const Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.trash(PhosphorIconsStyle.regular),
                              color: Colors.red),
                          const SizedBox(width: 8),
                          const Text('Excluir',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditTicketModal(ticket);
                    } else if (value == 'delete') {
                      setState(() {
                        _tickets.remove(ticket);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ticket excluído com sucesso'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
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
        return PhosphorIcons.arrowDown(PhosphorIconsStyle.regular);
      case TicketPriority.normal:
        return PhosphorIcons.minus(PhosphorIconsStyle.regular);
      case TicketPriority.high:
        return PhosphorIcons.arrowUp(PhosphorIconsStyle.regular);
      case TicketPriority.urgent:
        return PhosphorIcons.warning(PhosphorIconsStyle.regular);
    }
  }

  IconData _getStatusIcon(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return PhosphorIcons.clock(PhosphorIconsStyle.regular);
      case TicketStatus.inProgress:
        return PhosphorIcons.gear(PhosphorIconsStyle.regular);
      case TicketStatus.resolved:
        return PhosphorIcons.checkCircle(PhosphorIconsStyle.regular);
      case TicketStatus.closed:
        return PhosphorIcons.x(PhosphorIconsStyle.regular);
      case TicketStatus.waitingCustomer:
        return PhosphorIcons.hourglass(PhosphorIconsStyle.regular);
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

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Colors.blue;
      case TicketStatus.inProgress:
        return Colors.orange;
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.closed:
        return Colors.grey;
      case TicketStatus.waitingCustomer:
        return Colors.purple;
    }
  }
}
