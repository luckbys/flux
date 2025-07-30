import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../components/tickets/ticket_card.dart';
import '../styles/app_theme.dart';

class TicketDashboard extends StatefulWidget {
  const TicketDashboard({super.key});

  @override
  State<TicketDashboard> createState() => _TicketDashboardState();
}

class _TicketDashboardState extends State<TicketDashboard> {
  final List<Ticket> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadSampleTickets();
  }

  void _loadSampleTickets() {
    final customer = User(
      id: '1',
      name: 'João Silva',
      email: 'joao@exemplo.com',
      status: UserStatus.online,
      role: UserRole.customer,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );

    final agent = User(
      id: '2',
      name: 'Maria Santos',
      email: 'maria@empresa.com',
      status: UserStatus.online,
      role: UserRole.agent,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    );

    _tickets.addAll([
      Ticket(
        id: 'TKT-2024-001',
        title: 'Problema com login no sistema',
        description:
            'Não consigo fazer login no sistema desde ontem. Aparece erro de credenciais inválidas mesmo com a senha correta.',
        status: TicketStatus.open,
        priority: TicketPriority.high,
        category: TicketCategory.technical,
        customer: customer,
        assignedAgent: agent,
        tags: const [
          TicketTag(id: '1', name: 'Login', color: '#3B82F6'),
          TicketTag(id: '2', name: 'Urgente', color: '#EF4444'),
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        messages: [
          Message(
            id: '1',
            content: 'Olá, preciso de ajuda com meu login.',
            type: MessageType.text,
            status: MessageStatus.read,
            sender: customer,
            chatId: 'chat-1',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          Message(
            id: '2',
            content:
                'Olá João! Vou ajudá-lo com isso. Pode me enviar uma captura de tela do erro?',
            type: MessageType.text,
            status: MessageStatus.read,
            sender: agent,
            chatId: 'chat-1',
            createdAt:
                DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          ),
        ],
      ),
      Ticket(
        id: 'TKT-2024-002',
        title: 'Dúvida sobre faturamento',
        description:
            'Gostaria de entender melhor como funciona o sistema de faturamento mensal.',
        status: TicketStatus.inProgress,
        priority: TicketPriority.normal,
        category: TicketCategory.billing,
        customer: User(
          id: '3',
          name: 'Ana Costa',
          email: 'ana@exemplo.com',
          status: UserStatus.online,
          role: UserRole.customer,
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
        ),
        assignedAgent: agent,
        tags: const [
          TicketTag(id: '3', name: 'Faturamento', color: '#F59E0B'),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Ticket(
        id: 'TKT-2024-003',
        title: 'Sugestão de nova funcionalidade',
        description:
            'Seria muito útil ter um relatório de vendas em tempo real no dashboard.',
        status: TicketStatus.waitingCustomer,
        priority: TicketPriority.low,
        category: TicketCategory.feature,
        customer: User(
          id: '4',
          name: 'Carlos Oliveira',
          email: 'carlos@exemplo.com',
          status: UserStatus.offline,
          role: UserRole.customer,
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
        ),
        tags: const [
          TicketTag(id: '4', name: 'Sugestão', color: '#10B981'),
          TicketTag(id: '5', name: 'Dashboard', color: '#8B5CF6'),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Ticket(
        id: 'TKT-2024-004',
        title: 'Reclamação sobre atendimento',
        description:
            'O atendimento que recebi ontem foi muito ruim. O agente não resolveu meu problema.',
        status: TicketStatus.open,
        priority: TicketPriority.urgent,
        category: TicketCategory.complaint,
        customer: User(
          id: '5',
          name: 'Fernanda Lima',
          email: 'fernanda@exemplo.com',
          status: UserStatus.online,
          role: UserRole.customer,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
        tags: const [
          TicketTag(id: '6', name: 'Reclamação', color: '#EF4444'),
          TicketTag(id: '7', name: 'Crítico', color: '#DC2626'),
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 30)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ]);
  }

  void _onTicketTap(Ticket ticket) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ticket ${ticket.id} selecionado'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _onEditTicket(Ticket ticket) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando ticket ${ticket.id}'),
        backgroundColor: AppTheme.warningColor,
      ),
    );
  }

  void _onAssignTicket(Ticket ticket) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Atribuindo ticket ${ticket.id}'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _onChatTicket(Ticket ticket) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abrindo chat do ticket ${ticket.id}'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Tickets'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.getBackgroundColor(context),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header com estatísticas
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        _tickets.length.toString(),
                        AppTheme.primaryColor,
                        PhosphorIcons.ticket(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Abertos',
                        _tickets
                            .where((t) => t.status == TicketStatus.open)
                            .length
                            .toString(),
                        AppTheme.warningColor,
                        PhosphorIcons.warning(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Urgentes',
                        _tickets
                            .where((t) => t.priority == TicketPriority.urgent)
                            .length
                            .toString(),
                        AppTheme.errorColor,
                        PhosphorIcons.warning(),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de tickets com layout responsivo
              Expanded(
                child: isMobile
                    ? _buildMobileLayout()
                    : _buildDesktopLayout(isTablet, isDesktop),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        return TicketCard(
          ticket: ticket,
          onTap: () => _onTicketTap(ticket),
          onEdit: () => _onEditTicket(ticket),
          onAssign: () => _onAssignTicket(ticket),
          onChat: () => _onChatTicket(ticket),
          showActions: true,
        );
      },
    );
  }

  Widget _buildDesktopLayout(bool isTablet, bool isDesktop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Layout em grid usando Wrap para evitar problemas de ParentDataWidget
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.start,
            children: _tickets.map((ticket) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 650 : double.infinity,
                  minWidth: isDesktop ? 600 : double.infinity,
                ),
                child: TicketCard(
                  ticket: ticket,
                  onTap: () => _onTicketTap(ticket),
                  onEdit: () => _onEditTicket(ticket),
                  onAssign: () => _onAssignTicket(ticket),
                  onChat: () => _onChatTicket(ticket),
                  showActions: true,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
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
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
