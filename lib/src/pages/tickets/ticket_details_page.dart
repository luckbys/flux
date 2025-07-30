import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/ticket.dart';
import '../../models/message.dart';
import '../../models/chat.dart';
import '../../models/user.dart';
import '../../components/ui/user_avatar.dart';
import '../../components/tickets/ticket_form.dart';
import '../../services/ai/gemini_service.dart';
import '../../stores/ticket_store.dart';
import '../../stores/auth_store.dart';
import '../../stores/chat_store.dart';
import '../../styles/app_theme.dart';
import 'dart:async';

class TicketDetailsPage extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailsPage({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage>
    with TickerProviderStateMixin {
  late Ticket _ticket;
  List<Message> _messages = [];
  Chat? _ticketChat;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;
  bool _isSendingMessage = false;
  bool _showAISuggestions = false;
  bool _isTyping = false;
  bool _showParticipants = false;
  bool _showQuickActions = false;
  bool _isRefreshing = false;
  List<String> _aiSuggestions = [];
  Timer? _typingTimer;
  Timer? _autoRefreshTimer;
  late TabController _tabController;

  // Controladores de animação aprimorados
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _scaleAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _shimmerAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  // Estados para micro-interações
  bool _isHoveringSend = false;
  bool _isHoveringAttach = false;
  int _selectedSuggestionIndex = -1;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _tabController = TabController(length: 2, vsync: this);

    // Inicializar controladores de animação aprimorados
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Configurar animações
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerAnimationController,
      curve: Curves.easeInOut,
    ));

    _loadTicketChat();
    _loadMessages();
    _loadAISuggestions();
    _messageController.addListener(_onMessageChanged);
    _setupAutoRefresh();

    // Iniciar animações sequenciais
    _startEntranceAnimations();
  }

  void _startEntranceAnimations() async {
    await _fadeAnimationController.forward();
    await _slideAnimationController.forward();
    await _scaleAnimationController.forward();

    // Aguardar um frame antes de iniciar animações contínuas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pulseAnimationController.repeat(reverse: true);
        _shimmerAnimationController.repeat();
      }
    });
  }

  void _setupAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _tabController.index == 1) {
        _refreshMessages();
      }
    });
  }

  Future<void> _refreshMessages() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadMessages();
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _messagesScrollController.dispose();
    _messageFocusNode.dispose();
    _typingTimer?.cancel();
    _autoRefreshTimer?.cancel();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _scaleAnimationController.dispose();
    _pulseAnimationController.dispose();
    _shimmerAnimationController.dispose();
    super.dispose();
  }

  void _onMessageChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isTyping = true;
          });
        }
      });
      _startTypingIndicator();
    } else if (_messageController.text.isEmpty && _isTyping) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isTyping = false;
          });
        }
      });
      _stopTypingIndicator();
    }
  }

  void _startTypingIndicator() {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        _isTyping = false;
      });
    });
  }

  void _stopTypingIndicator() {
    _typingTimer?.cancel();
  }

  Future<void> _loadTicketChat() async {
    try {
      final chatStore = context.read<ChatStore>();

      // Carregar todos os chats primeiro
      await chatStore.loadChats();

      // Procurar por um chat existente para este ticket
      final existingChat = chatStore.chats
          .where((chat) => chat.ticketId == _ticket.id)
          .firstOrNull;

      if (existingChat != null) {
        setState(() {
          _ticketChat = existingChat;
        });

        // Carregar mensagens do chat
        await chatStore.loadMessages(existingChat.id);
      } else {
        // Criar um novo chat para o ticket
        final newChat = await chatStore.createChat(
          title: 'Ticket #${_ticket.id}',
          type: ChatType.ticket,
          participantIds: [
            _ticket.customer.id
          ], // Adicionar outros participantes conforme necessário
        );

        if (newChat != null) {
          setState(() {
            _ticketChat = newChat;
          });
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadMessages() async {
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

      // Scroll para o final após carregar mensagens
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  PhosphorIcons.warning(),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Erro ao carregar mensagens: $e',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _loadMessages,
                  child: const Text(
                    'Tentar novamente',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
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
      _isTyping = false;
      _selectedSuggestionIndex = -1;
    });

    _stopTypingIndicator();

    try {
      final success = await ticketStore.sendTicketMessage(
        ticketId: _ticket.id,
        senderId: authStore.appUser!.id,
        content: content,
      );

      if (success) {
        _messageController.clear();

        // Mostrar feedback de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.check(),
                      color: const Color(0xFF10B981),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Flexible(
                    child: Text(
                      'Mensagem enviada com sucesso!',
                      style: TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        // Recarregar mensagens
        await _loadMessages();

        // Mudar para a aba de chat se não estiver nela
        if (_tabController.index != 1) {
          _tabController.animateTo(1);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    PhosphorIcons.warning(),
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Flexible(
                    child: Text(
                      'Erro ao enviar mensagem',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _sendMessage,
                    child: const Text(
                      'Tentar novamente',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  PhosphorIcons.warning(),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Erro: $e',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFEFF6FF),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _fadeAnimation,
              _slideAnimation,
              _scaleAnimation,
            ]),
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildEnhancedTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildEnhancedTicketDetailsTab(),
                            _buildEnhancedChatTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF1D4ED8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _showQuickActions
                  ? null
                  : () {
                      setState(() {
                        _showQuickActions = !_showQuickActions;
                      });
                    },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Icon(
                _showQuickActions ? PhosphorIcons.x() : PhosphorIcons.plus(),
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF6B7280),
          indicator: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorPadding: const EdgeInsets.all(6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.ticket(), size: 18),
                  const SizedBox(width: 8),
                  const Text('Detalhes', overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Icon(PhosphorIcons.chatCircle(), size: 18),
                      if (_messages.isNotEmpty)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _messages.length > 9
                                    ? '9+'
                                    : '${_messages.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Text('Chat', overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTicketDetailsTab() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildEnhancedTicketInfoCard(),
                const SizedBox(height: 20),
                _buildEnhancedDescriptionCard(),
                const SizedBox(height: 20),
                _buildActivityTimeline(),
                const SizedBox(height: 20),
                _buildEnhancedAISuggestionsSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedTicketInfoCard() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFF8FAFC),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com título e ID
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3B82F6),
                              Color(0xFF1D4ED8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          PhosphorIcons.ticket(),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ticket #${_ticket.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Text(
                                _ticket.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2937),
                                  letterSpacing: -0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Badges de status e prioridade
                  Row(
                    children: [
                      _buildEnhancedBadge(
                        _getStatusName(_ticket.status),
                        _getStatusColor(_ticket.status),
                        _getStatusIcon(_ticket.status),
                      ),
                      const SizedBox(width: 12),
                      _buildEnhancedBadge(
                        _getPriorityName(_ticket.priority),
                        _getPriorityColor(_ticket.priority),
                        _getPriorityIcon(_ticket.priority),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.clock(),
                              size: 14,
                              color: const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(_ticket.createdAt),
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Informações do cliente
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF3B82F6),
                                Color(0xFF1D4ED8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _ticket.customer.name
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Cliente',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Flexible(
                                child: Text(
                                  _ticket.customer.name,
                                  style: const TextStyle(
                                    color: Color(0xFF1F2937),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Flexible(
                                child: Text(
                                  _ticket.customer.email,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            PhosphorIcons.user(),
                            color: const Color(0xFF10B981),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedDescriptionCard() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFFAFBFC),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF4F46E5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          PhosphorIcons.fileText(),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Descrição do Problema',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      _ticket.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF374151),
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedChatTab() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _fadeAnimation,
        _slideAnimation,
        _shimmerAnimation,
      ]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFEFF6FF),
                ],
              ),
            ),
            child: Column(
              children: [
                _buildChatHeader(),
                if (_showParticipants) _buildParticipantsHeader(),
                Expanded(
                  child: _buildChatMessagesSection(),
                ),
                _buildChatInputSection(),
                if (_showAISuggestions && _aiSuggestions.isNotEmpty)
                  _buildAISuggestionsBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF1D4ED8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              PhosphorIcons.chatCircle(),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Conversa do Ticket',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Flexible(
                  child: Text(
                    '${_messages.length} mensagens',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildChatActionButton(
                icon: PhosphorIcons.users(),
                onPressed: () {
                  setState(() {
                    _showParticipants = !_showParticipants;
                  });
                },
                isActive: _showParticipants,
                tooltip: 'Participantes',
              ),
              const SizedBox(width: 8),
              _buildChatActionButton(
                icon: PhosphorIcons.robot(),
                onPressed: () {
                  setState(() {
                    _showAISuggestions = !_showAISuggestions;
                  });
                },
                isActive: _showAISuggestions,
                tooltip: 'Sugestões IA',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
    String? tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
          size: 18,
        ),
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildAISuggestionsBar() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  const Color(0xFF3B82F6).withValues(alpha: 0.1),
                ],
              ),
              border: const Border(
                top: BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.robot(),
                      color: const Color(0xFF8B5CF6),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Sugestões de IA',
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _aiSuggestions.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              _messageController.text = _aiSuggestions[index];
                              setState(() {
                                _selectedSuggestionIndex = index;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedSuggestionIndex == index
                                    ? const Color(0xFF8B5CF6)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _aiSuggestions[index].length > 30
                                    ? '${_aiSuggestions[index].substring(0, 30)}...'
                                    : _aiSuggestions[index],
                                style: TextStyle(
                                  color: _selectedSuggestionIndex == index
                                      ? Colors.white
                                      : const Color(0xFF8B5CF6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFEFF6FF),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
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
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            PhosphorIcons.arrowLeft(),
            color: const Color(0xFF374151),
            size: 20,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(_ticket.status).withValues(alpha: 0.1),
                      _getStatusColor(_ticket.status).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color:
                        _getStatusColor(_ticket.status).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Ticket #${_ticket.id.substring(0, 6)}',
                  style: TextStyle(
                    color: _getStatusColor(_ticket.status),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _ticket.title,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: _getStatusColor(_ticket.status),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(_ticket.status)
                          .withValues(alpha: 0.4),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  _getStatusName(_ticket.status),
                  style: TextStyle(
                    color: _getStatusColor(_ticket.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: _getPriorityColor(_ticket.priority)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: _getPriorityColor(_ticket.priority)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _getPriorityName(_ticket.priority),
                  style: TextStyle(
                    color: _getPriorityColor(_ticket.priority),
                    fontWeight: FontWeight.w600,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: Row(
            children: [
              _buildActionButton(
                icon: PhosphorIcons.arrowClockwise(),
                color: const Color(0xFF10B981),
                onPressed: _refreshMessages,
                isLoading: _isRefreshing,
                tooltip: 'Atualizar',
              ),
              const SizedBox(width: 4),
              _buildActionButton(
                icon: PhosphorIcons.pencil(),
                color: const Color(0xFF3B82F6),
                onPressed: _editTicket,
                tooltip: 'Editar',
              ),
              const SizedBox(width: 4),
              _buildActionButton(
                icon: PhosphorIcons.dotsThreeVertical(),
                color: const Color(0xFF6B7280),
                onPressed: () => _showActionMenu(context),
                tooltip: 'Mais opções',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isLoading = false,
    String? tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Icon(
                icon,
                color: color,
                size: 16,
              ),
        tooltip: tooltip,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildActionMenu(),
    );
  }

  Widget _buildActionMenu() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF000000),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_ticket.status != TicketStatus.inProgress)
                  _buildMenuAction(
                    'Iniciar Atendimento',
                    PhosphorIcons.play(),
                    const Color(0xFF3B82F6),
                    () => _handleMenuAction('in_progress'),
                  ),
                if (_ticket.status != TicketStatus.resolved)
                  _buildMenuAction(
                    'Marcar como Resolvido',
                    PhosphorIcons.check(),
                    const Color(0xFF10B981),
                    () => _handleMenuAction('resolved'),
                  ),
                if (_ticket.status != TicketStatus.closed)
                  _buildMenuAction(
                    'Fechar Ticket',
                    PhosphorIcons.x(),
                    const Color(0xFF6B7280),
                    () => _handleMenuAction('closed'),
                  ),
                _buildMenuAction(
                  'Compartilhar',
                  PhosphorIcons.share(),
                  const Color(0xFF8B5CF6),
                  () => _shareTicket(),
                ),
                _buildMenuAction(
                  'Exportar',
                  PhosphorIcons.download(),
                  const Color(0xFFF59E0B),
                  () => _exportTicket(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuAction(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Icon(
                  PhosphorIcons.arrowRight(),
                  color: const Color(0xFF6B7280),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareTicket() {
    // Implementar compartilhamento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compartilhamento em desenvolvimento'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _exportTicket() {
    // Implementar exportação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportação em desenvolvimento'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  Widget _buildParticipantsHeader() {
    final participants = _ticketChat?.participants ?? [];
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Participantes (${participants.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showParticipants = false;
                  });
                },
                icon: Icon(
                  PhosphorIcons.x(),
                  size: 20,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: participants.map((participant) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserAvatar(
                      user: participant,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      participant.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessagesSection() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                PhosphorIcons.chatCircle(),
                size: 40,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma mensagem ainda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicie uma conversa com o cliente',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _messagesScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isFromCurrentUser =
            message.sender.id == context.read<AuthStore>().appUser?.id;
        return ChatMessageBubble(
          message: message,
          isFromCurrentUser: isFromCurrentUser,
        );
      },
    );
  }

  Widget _buildChatInputSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _fadeAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (_isTyping)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Digitando...',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildInputActionButton(
                    icon: PhosphorIcons.paperclip(),
                    onPressed: _showAttachmentOptions,
                    isHovering: _isHoveringAttach,
                    onHoverChanged: (hovering) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _isHoveringAttach = hovering;
                          });
                        }
                      });
                    },
                    tooltip: 'Anexar arquivo',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxHeight: 80,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF8FAFC),
                            Color(0xFFEFF6FF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        onSubmitted: (_) => _sendMessage(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1F2937),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Digite sua mensagem...',
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildSendButton(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isHovering,
    required ValueChanged<bool> onHoverChanged,
    String? tooltip,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isHovering
              ? [
                  const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                ]
              : [
                  const Color(0xFFF8FAFC),
                  const Color(0xFFEFF6FF),
                ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHovering
              ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: isHovering
            ? [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: MouseRegion(
        onEnter: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onHoverChanged(true);
          });
        },
        onExit: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onHoverChanged(false);
          });
        },
        child: IconButton(
          onPressed: onPressed,
          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              color: isHovering
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF6B7280),
              size: 16,
            ),
          ),
          tooltip: tooltip,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final hasText = _messageController.text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasText && !_isSendingMessage
              ? [
                  const Color(0xFF3B82F6),
                  const Color(0xFF1D4ED8),
                ]
              : [
                  const Color(0xFFE5E7EB),
                  const Color(0xFFD1D5DB),
                ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: hasText && !_isSendingMessage
            ? [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: MouseRegion(
        onEnter: (_) {
          if (hasText && !_isSendingMessage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isHoveringSend = true;
                });
              }
            });
          }
        },
        onExit: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isHoveringSend = false;
              });
            }
          });
        },
        child: IconButton(
          onPressed: (hasText && !_isSendingMessage) ? _sendMessage : null,
          icon: _isSendingMessage
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isHoveringSend
                        ? PhosphorIcons.paperPlaneTilt()
                        : PhosphorIcons.paperPlaneRight(),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
          tooltip: 'Enviar mensagem',
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF000000),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAttachmentOption(
                    'Imagem',
                    PhosphorIcons.image(),
                    const Color(0xFF10B981),
                    () => _selectImage(),
                  ),
                  _buildAttachmentOption(
                    'Documento',
                    PhosphorIcons.fileText(),
                    const Color(0xFF3B82F6),
                    () => _selectDocument(),
                  ),
                  _buildAttachmentOption(
                    'Localização',
                    PhosphorIcons.mapPin(),
                    const Color(0xFFF59E0B),
                    () => _shareLocation(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Icon(
                  PhosphorIcons.arrowRight(),
                  color: const Color(0xFF6B7280),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectImage() {
    // Implementar seleção de imagem
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seleção de imagem em desenvolvimento'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _selectDocument() {
    // Implementar seleção de documento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seleção de documento em desenvolvimento'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _shareLocation() {
    // Implementar compartilhamento de localização
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compartilhamento de localização em desenvolvimento'),
        backgroundColor: Color(0xFFF59E0B),
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
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ticket atualizado com sucesso!'),
                    backgroundColor: Color(0xFF22C55E),
                  ),
                );
              }
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
      case 'resolved':
        _updateTicketStatus(TicketStatus.resolved);
        break;
      case 'closed':
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

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return const Color(0xFF10B981); // Green
      case TicketPriority.normal:
        return const Color(0xFF3B82F6); // Blue
      case TicketPriority.high:
        return const Color(0xFFF59E0B); // Orange
      case TicketPriority.urgent:
        return const Color(0xFFEF4444); // Red
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m atrás';
      }
      return '${difference.inHours}h atrás';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Métodos auxiliares para ícones
  IconData _getStatusIcon(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return PhosphorIcons.clockCounterClockwise();
      case TicketStatus.inProgress:
        return PhosphorIcons.gear();
      case TicketStatus.waitingCustomer:
        return PhosphorIcons.userCheck();
      case TicketStatus.resolved:
        return PhosphorIcons.checkCircle();
      case TicketStatus.closed:
        return PhosphorIcons.xCircle();
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

  // Widget para badges modernos
  Widget _buildModernBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para badges aprimorados
  Widget _buildEnhancedBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para cards de usuário
  Widget _buildUserCard(String title, User? user, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (user != null) ...[
            Row(
              children: [
                UserAvatar(
                  user: user,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.userMinus(),
                    size: 16,
                    color: const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Não atribuído',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Widget para timeline de atividades
  Widget _buildActivityTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.05),
            const Color(0xFF3B82F6).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  PhosphorIcons.clockCounterClockwise(),
                  color: const Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Timeline de Atividades',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            'Ticket criado',
            _formatDateForTimeline(_ticket.createdAt),
            PhosphorIcons.plus(),
            const Color(0xFF3B82F6),
            isFirst: true,
          ),
          if (_ticket.status != TicketStatus.open)
            _buildTimelineItem(
              'Status alterado para ${_getStatusName(_ticket.status)}',
              _formatDateForTimeline(_ticket.updatedAt),
              _getStatusIcon(_ticket.status),
              _getStatusColor(_ticket.status),
            ),
          if (_ticket.assignedAgent != null)
            _buildTimelineItem(
              'Atribuído para ${_ticket.assignedAgent!.name}',
              _formatDateForTimeline(_ticket.updatedAt),
              PhosphorIcons.userGear(),
              const Color(0xFF10B981),
            ),
          _buildTimelineItem(
            'Última atualização',
            _formatDateForTimeline(_ticket.updatedAt),
            PhosphorIcons.clockCounterClockwise(),
            const Color(0xFF6B7280),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String time,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 12,
                color: const Color(0xFFE5E7EB),
              ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 16,
                color: color,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 12,
                color: const Color(0xFFE5E7EB),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateForTimeline(DateTime? date) {
    if (date == null) return 'Data não disponível';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _formatMessageTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Hoje';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Ontem';
    } else if (now.difference(messageDate).inDays < 7) {
      final weekdays = [
        'Segunda',
        'Terça',
        'Quarta',
        'Quinta',
        'Sexta',
        'Sábado',
        'Domingo'
      ];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _scrollToBottom() {
    if (_messagesScrollController.hasClients) {
      _messagesScrollController.animateTo(
        _messagesScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildEnhancedAISuggestionsSection() {
    if (_aiSuggestions.isEmpty || !_showAISuggestions) {
      return Container();
    }

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                  const Color(0xFF3B82F6).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF8B5CF6),
                              Color(0xFF7C3AED),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          PhosphorIcons.robot(),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Sugestões Inteligentes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10B981).withValues(alpha: 0.1),
                              const Color(0xFF059669).withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.sparkle(),
                              color: const Color(0xFF10B981),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'IA',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...(_aiSuggestions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final suggestion = entry.value;
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.white,
                            Color(0xFFFAFBFC),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            _messageController.text = suggestion;
                            setState(() {
                              _showAISuggestions = false;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF8B5CF6)
                                            .withValues(alpha: 0.1),
                                        const Color(0xFF3B82F6)
                                            .withValues(alpha: 0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF8B5CF6)
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Color(0xFF8B5CF6),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    suggestion,
                                    style: const TextStyle(
                                      color: Color(0xFF374151),
                                      fontSize: 15,
                                      height: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  PhosphorIcons.arrowRight(),
                                  color: const Color(0xFF8B5CF6),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  })),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ChatMessageBubble extends StatelessWidget {
  final Message message;
  final bool isFromCurrentUser;
  const ChatMessageBubble(
      {super.key, required this.message, required this.isFromCurrentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromCurrentUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  message.sender.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isFromCurrentUser ? const Color(0xFF3B82F6) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isFromCurrentUser ? 12 : 4),
                  bottomRight: Radius.circular(isFromCurrentUser ? 4 : 12),
                ),
                border: Border.all(
                  color: isFromCurrentUser
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isFromCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        message.sender.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isFromCurrentUser
                          ? Colors.white
                          : const Color(0xFF1F2937),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isFromCurrentUser
                          ? Colors.white.withOpacity(0.7)
                          : const Color(0xFF6B7280),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromCurrentUser) ...[
            const SizedBox(width: 6),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  message.sender.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
