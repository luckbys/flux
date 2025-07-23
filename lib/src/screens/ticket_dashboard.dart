import 'package:flutter/material.dart';
import 'new_ticket_form.dart';
import '../widgets/form_components.dart';

class TicketDashboard extends StatefulWidget {
  const TicketDashboard({super.key});

  @override
  State<TicketDashboard> createState() => _TicketDashboardState();
}

class _TicketDashboardState extends State<TicketDashboard> {
  final List<TicketModel> _tickets = [
    TicketModel(
      id: 'TK001',
      title: 'Problema no login do sistema',
      status: 'Aberto',
      priority: 'Alta',
      category: 'Técnico',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TicketModel(
      id: 'TK002',
      title: 'Solicitação de novo usuário',
      status: 'Em Andamento',
      priority: 'Média',
      category: 'RH',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TicketModel(
      id: 'TK003',
      title: 'Bug na tela de relatórios',
      status: 'Resolvido',
      priority: 'Baixa',
      category: 'Bug',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FormComponents.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Central de Tickets',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: FormComponents.textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implementar busca
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Implementar filtros
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildTicketsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NewTicketForm(),
            ),
          );
        },
        backgroundColor: FormComponents.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Novo Ticket'),
      ),
    );
  }

  Widget _buildStatsSection() {
    return FormComponents.buildFormCard(
      children: [
        FormComponents.buildSectionTitle('Resumo dos Tickets',
            icon: Icons.analytics),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total',
                value: '${_tickets.length}',
                color: Colors.blue,
                icon: Icons.confirmation_number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Abertos',
                value: '${_tickets.where((t) => t.status == 'Aberto').length}',
                color: Colors.orange,
                icon: Icons.pending,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Resolvidos',
                value:
                    '${_tickets.where((t) => t.status == 'Resolvido').length}',
                color: Colors.green,
                icon: Icons.check_circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return FormComponents.buildFormCard(
      children: [
        FormComponents.buildSectionTitle('Ações Rápidas', icon: Icons.flash_on),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                title: 'Novo Ticket',
                subtitle: 'Criar solicitação',
                icon: Icons.add_circle_outline,
                color: FormComponents.primaryColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NewTicketForm(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                title: 'Meus Tickets',
                subtitle: 'Ver histórico',
                icon: Icons.history,
                color: Colors.green,
                onTap: () {
                  // Implementar navegação para meus tickets
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                title: 'FAQ',
                subtitle: 'Perguntas frequentes',
                icon: Icons.help_center,
                color: Colors.orange,
                onTap: () {
                  // Implementar navegação para FAQ
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormComponents.buildSectionTitle('Tickets Recentes',
              icon: Icons.list),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _tickets.length,
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                return _buildTicketCard(ticket);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TicketModel ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: FormComponents.buildFormCard(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          ticket.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FormComponents.buildStatusChip(
                          label: ticket.status,
                          color: _getStatusColor(ticket.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ticket.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FormComponents.buildStatusChip(
                          label: ticket.priority,
                          color: ticket.priority.priorityColor,
                          icon: ticket.priority.priorityIcon,
                        ),
                        const SizedBox(width: 8),
                        FormComponents.buildStatusChip(
                          label: ticket.category,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Criado em ${_formatDate(ticket.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () {
                  // Implementar navegação para detalhes do ticket
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aberto':
        return Colors.orange;
      case 'em andamento':
        return Colors.blue;
      case 'resolvido':
        return Colors.green;
      case 'fechado':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} dia${difference.inDays > 1 ? 's' : ''} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''} atrás';
    } else {
      return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''} atrás';
    }
  }
}

class TicketModel {
  final String id;
  final String title;
  final String status;
  final String priority;
  final String category;
  final DateTime createdAt;

  TicketModel({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.category,
    required this.createdAt,
  });
}
