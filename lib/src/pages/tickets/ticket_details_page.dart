import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../../models/message.dart';
import '../../components/ui/user_avatar.dart';
import '../../components/ui/status_badge.dart';
import '../../components/tickets/ticket_form.dart';
import '../../services/ai/gemini_service.dart';
import '../../stores/ticket_store.dart';
import '../../stores/auth_store.dart';
import '../../styles/app_theme.dart';
import '../../styles/app_constants.dart';
import '../../utils/color_extensions.dart';

class TicketDetailsPage extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailsPage({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> {
  late Ticket _ticket;
  List<Message> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;
  bool _isSendingMessage = false;
  bool _showAISuggestions = false;
  List<String> _aiSuggestions = [];

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _loadMessages();
    _loadAISuggestions();
  }

  void _loadMessages() async {
    final ticketStore = context.read<TicketStore>();
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await ticketStore.loadTicketMessages(_ticket.id);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadAISuggestions() async {
    if (_ticket.assignedAgent != null) {
      try {
        final suggestions = await _geminiService.generateResponseSuggestions(
          customerMessage: _ticket.description,
          conversationHistory: [],
          category: _ticket.category,
        );
        setState(() {
          _aiSuggestions = suggestions;
        });
      } catch (e) {
        // Mock suggestions se a API falhar
        setState(() {
          _aiSuggestions = [
            'Obrigado por entrar em contato. Vamos analisar sua solicitação.',
            'Entendo sua preocupação. Vou verificar isso imediatamente.',
            'Vou encaminhar seu caso para nossa equipe técnica especializada.',
          ];
        });
      }
    }
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final authStore = context.read<AuthStore>();
    final ticketStore = context.read<TicketStore>();

    if (authStore.appUser == null) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      final success = await ticketStore.sendTicketMessage(
        ticketId: _ticket.id,
        senderId: authStore.appUser!.id,
        content: content,
      );

      if (success) {
        _messageController.clear();
        // Recarregar mensagens
        _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao enviar mensagem'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSendingMessage = false;
      });
    }
  }

  void _updateTicketStatus(TicketStatus newStatus) async {
    final ticketStore = context.read<TicketStore>();

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ticketStore.updateTicket(
        ticketId: _ticket.id,
        status: newStatus,
      );

      if (success) {
        final updatedTicket = await ticketStore.getTicketById(_ticket.id);
        if (updatedTicket != null) {
          setState(() {
            _ticket = updatedTicket;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Status atualizado para ${_getStatusName(newStatus)}'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTicketHeader(),
                  _buildTicketContent(),
                  _buildAISuggestionsSection(),
                  _buildMessagesSection(),
                ],
              ),
            ),
          ),
          _buildMessageInputSection(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha:  0.1),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          PhosphorIcons.arrowLeft(),
          color: const Color(0xFF374151),
        ),
      ),
      title: Text(
        'Ticket #${_ticket.id.split('-').last.substring(0, 8)}',
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _editTicket,
          icon: Icon(
            PhosphorIcons.pencil(),
            color: const Color(0xFF6B7280),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          icon: Icon(
            PhosphorIcons.dotsThreeVertical(),
            color: const Color(0xFF6B7280),
          ),
          itemBuilder: (context) => [
            if (_ticket.status != TicketStatus.inProgress)
              PopupMenuItem(
                value: 'in_progress',
                child: Row(
                  children: [
                    Icon(PhosphorIcons.play(), size: 16),
                    const SizedBox(width: 8),
                    const Text('Iniciar Progresso'),
                  ],
                ),
              ),
            if (_ticket.status != TicketStatus.resolved)
              PopupMenuItem(
                value: 'resolve',
                child: Row(
                  children: [
                    Icon(PhosphorIcons.check(), size: 16),
                    const SizedBox(width: 8),
                    const Text('Resolver'),
                  ],
                ),
              ),
            if (_ticket.status != TicketStatus.closed)
              PopupMenuItem(
                value: 'close',
                child: Row(
                  children: [
                    Icon(PhosphorIcons.x(), size: 16),
                    const SizedBox(width: 8),
                    const Text('Fechar Ticket'),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTicketHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppTheme.spacing16),
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:  0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ticket.title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Row(
                      children: [
                        StatusBadge(
                          text: _getStatusName(_ticket.status),
                          color: _getStatusColor(_ticket.status),
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        StatusBadge(
                          text: _getPriorityName(_ticket.priority),
                          color: _getPriorityColor(_ticket.priority),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(_ticket.createdAt),
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              UserAvatar(
                user: _ticket.customer,
                size: 32,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ticket.customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      _ticket.customer.email,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_ticket.assignedAgent != null) ...[
                const Text(
                  'Atribuído a:',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                UserAvatar(
                  user: _ticket.assignedAgent!,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacing4),
                Text(
                  _ticket.assignedAgent!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketContent() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:  0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descrição',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            _ticket.description,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISuggestionsSection() {
    if (_aiSuggestions.isEmpty || !_showAISuggestions) {
      return Container();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppTheme.spacing16),
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD1D5DB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.robot(),
                color: const Color(0xFF6366F1),
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Sugestões de IA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          ...(_aiSuggestions.map((suggestion) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
                child: GestureDetector(
                  onTap: () {
                    _messageController.text = suggestion;
                    setState(() {
                      _showAISuggestions = false;
                    });
                  },
                  child: Text(
                    suggestion,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 14,
                    ),
                  ),
                ),
              ))),
        ],
      ),
    );
  }

  Widget _buildMessagesSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppTheme.spacing16),
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:  0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Conversas (${_messages.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
              ),
              if (_aiSuggestions.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAISuggestions = !_showAISuggestions;
                    });
                  },
                  icon: Icon(
                    PhosphorIcons.robot(),
                    size: 16,
                    color: const Color(0xFF6366F1),
                  ),
                  label: Text(
                    _showAISuggestions ? 'Ocultar IA' : 'Sugestões IA',
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_messages.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing32),
                child: Text(
                  'Nenhuma mensagem ainda',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _messages.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppTheme.spacing12),
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageItem(message);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                user: message.sender,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                message.sender.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                _formatMessageTime(message.createdAt),
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            message.content,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem...',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5E7EB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5E7EB),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _isSendingMessage ? null : _sendMessage,
              icon: _isSendingMessage
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      PhosphorIcons.paperPlaneTilt(),
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares

  void _editTicket() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketForm(
          ticket: _ticket,
          onSubmit: (formData) async {
            Navigator.pop(context);

            final ticketStore = context.read<TicketStore>();
            final success = await ticketStore.updateTicket(
              ticketId: _ticket.id,
              title: formData.title,
              description: formData.description,
              priority: formData.priority,
              category: formData.category,
              status: formData.status,
            );

            if (success) {
              final updatedTicket = await ticketStore.getTicketById(_ticket.id);
              if (updatedTicket != null) {
                setState(() {
                  _ticket = updatedTicket;
                });
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ticket atualizado com sucesso!'),
                  backgroundColor: Color(0xFF22C55E),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'in_progress':
        _updateTicketStatus(TicketStatus.inProgress);
        break;
      case 'resolve':
        _updateTicketStatus(TicketStatus.resolved);
        break;
      case 'close':
        _updateTicketStatus(TicketStatus.closed);
        break;
    }
  }

  String _getStatusName(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'Aberto';
      case TicketStatus.inProgress:
        return 'Em Andamento';
      case TicketStatus.waitingCustomer:
        return 'Aguardando Cliente';
      case TicketStatus.resolved:
        return 'Resolvido';
      case TicketStatus.closed:
        return 'Fechado';
    }
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return const Color(0xFF22C55E);
      case TicketStatus.inProgress:
        return const Color(0xFFF59E0B);
      case TicketStatus.waitingCustomer:
        return const Color(0xFF8B5CF6);
      case TicketStatus.resolved:
        return const Color(0xFF3B82F6);
      case TicketStatus.closed:
        return const Color(0xFF6B7280);
    }
  }

  String _getPriorityName(TicketPriority priority) {
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

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return const Color(0xFF22C55E);
      case TicketPriority.normal:
        return const Color(0xFF3B82F6);
      case TicketPriority.high:
        return const Color(0xFFF59E0B);
      case TicketPriority.urgent:
        return const Color(0xFFEF4444);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }

  String _formatMessageTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
