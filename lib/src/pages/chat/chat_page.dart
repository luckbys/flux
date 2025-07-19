import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../models/ticket.dart';
import '../../components/chat/messages/message_bubble.dart';
import '../../components/chat/chat_input.dart';
import '../../components/ui/user_avatar.dart';
import '../../services/ai/gemini_service.dart';
import '../../styles/app_theme.dart';
import '../../utils/color_extensions.dart';
import '../../styles/design_tokens.dart';
import '../../components/ui/micro_animations.dart';
import '../../components/ui/toast_message.dart';

class ChatPage extends StatefulWidget {
  final Chat chat;

  const ChatPage({
    Key? key,
    required this.chat,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late Chat _chat;
  final List<Message> _messages = [];
  final List<Message> _filteredMessages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GeminiService _geminiService = GeminiService();

  // Animation Controllers
  late AnimationController _appBarAnimationController;
  late AnimationController _messageAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _suggestionAnimationController;
  late Animation<double> _appBarAnimation;
  late Animation<double> _messageAnimation;
  late Animation<double> _fabAnimation;
  late Animation<double> _suggestionAnimation;

  // State variables
  bool _isTyping = false;
  bool _showAISuggestions = false;
  bool _isSearchMode = false;
  bool _showScrollToBottom = false;
  bool _isOnline = true;
  bool _isLoading = false;
  int _unreadCount = 0;
  String _searchQuery = '';
  Message? _replyingTo;

  List<String> _aiSuggestions = [];
  List<Message> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _chat = widget.chat;

    // Initialize animation controllers
    _appBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _suggestionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Initialize animations
    _appBarAnimation = CurvedAnimation(
      parent: _appBarAnimationController,
      curve: Curves.easeOutCubic,
    );
    _messageAnimation = CurvedAnimation(
      parent: _messageAnimationController,
      curve: Curves.elasticOut,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _suggestionAnimation = CurvedAnimation(
      parent: _suggestionAnimationController,
      curve: Curves.easeOutBack,
    );

    // Setup scroll listener
    _scrollController.addListener(_onScroll);

    // Setup search listener
    _searchController.addListener(_onSearchChanged);

    _loadMessages();
    _loadAISuggestions();

    // Start entrance animations
    _appBarAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      _messageAnimationController.forward();
    });
  }

  void _loadMessages() {
    setState(() {
      _isLoading = true;
    });

    // Mock messages - substituir por dados reais
    User participant = User(
  id: 'participant_1',
  name: 'João Silva',
  email: 'joao@example.com',
  avatarUrl: '',
  role: UserRole.customer,
  status: UserStatus.online,
  createdAt: DateTime.now(),
);
    final currentUser = _getMockCurrentUser();

    _messages.addAll([
      Message(
        id: '1',
        content: 'Olá! Bem-vindo ao suporte. Como posso ajudá-lo hoje?',
        type: MessageType.text,
        sender: participant,
        chatId: _chat.id,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageStatus.read,
      ),
      Message(
        id: '2',
        content: 'Oi, estou enfrentando lentidão no sistema desde manhã. Pode ajudar?',
        type: MessageType.text,
        sender: currentUser,
        chatId: _chat.id,
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
        status: MessageStatus.read,
      ),
      Message(
        id: '3',
        content: 'Entendi. Pode descrever o problema com mais detalhes? Qual parte do sistema está lenta?',
        type: MessageType.text,
        sender: participant,
        chatId: _chat.id,
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        status: MessageStatus.read,
      ),
      Message(
        id: '4',
        content: 'Principalmente ao carregar relatórios. Demora mais de 30 segundos.',
        type: MessageType.text,
        sender: currentUser,
        chatId: _chat.id,
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
        status: MessageStatus.read,
      ),
      Message(
        id: '5',
        content: 'Obrigado. Estamos investigando. Enquanto isso, tente limpar o cache do navegador.',
        type: MessageType.text,
        sender: participant,
        chatId: _chat.id,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        status: MessageStatus.read,
      ),
      Message(
        id: '6',
        content: 'Limpei o cache, mas ainda está lento. Alguma outra sugestão?',
        type: MessageType.text,
        sender: currentUser,
        chatId: _chat.id,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        status: MessageStatus.delivered,
      ),
      Message(
        id: '7',
        content: 'Vamos escalar para a equipe técnica. Você será notificado em breve.',
        type: MessageType.text,
        sender: participant,
        chatId: _chat.id,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        status: MessageStatus.sent,
      ),
    ]);

    setState(() {
      _isLoading = false;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _loadAISuggestions() async {
    if (_messages.isNotEmpty) {
      try {
        final lastMessage = _messages.last;
        final suggestions = await _geminiService.generateResponseSuggestions(
          customerMessage: lastMessage.content,
          conversationHistory: _messages,
          category: TicketCategory.technical,
        );
        setState(() {
          _aiSuggestions = suggestions;
        });

        if (_showAISuggestions && suggestions.isNotEmpty) {
          _suggestionAnimationController.forward();
        }
      } catch (e) {
        // Mock suggestions se a API falhar
        setState(() {
          _aiSuggestions = [
            'Posso ajudá-lo com isso.',
            'Vou verificar imediatamente.',
            'Obrigado por aguardar.',
            'Vou investigar o problema.',
            'Você pode me dar mais detalhes?',
          ];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor:
          isDesktop ? DesignTokens.neutral50 : DesignTokens.neutral100,
      appBar: _buildAppBar(),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      floatingActionButton: _buildScrollToBottomFab(),
    );
  }

  Widget _buildDesktopLayout() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isSearchMode) _buildSearchBar(),
          if (_isSearchMode && _searchResults.isNotEmpty)
            _buildSearchResultsHeader(),
          if (_showAISuggestions && _aiSuggestions.isNotEmpty)
            _buildAISuggestionsBar(),
          Expanded(
            child: Stack(
              children: [
                _buildMessagesList(),
                if (_isLoading) _buildLoadingOverlay(),
              ],
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        if (_isSearchMode) _buildSearchBar(),
        if (_isSearchMode && _searchResults.isNotEmpty)
          _buildSearchResultsHeader(),
        if (_showAISuggestions && _aiSuggestions.isNotEmpty)
          _buildAISuggestionsBar(),
        Expanded(
          child: Stack(
            children: [
              _buildMessagesList(),
              if (_isLoading) _buildLoadingOverlay(),
            ],
          ),
        ),
        if (_isTyping) _buildTypingIndicator(),
        _buildChatInput(),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final participant = _chat.participants.first;
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return PreferredSize(
      preferredSize: Size.fromHeight(isDesktop ? 80 : kToolbarHeight),
      child: AnimatedBuilder(
        animation: _appBarAnimation,
        builder: (context, child) {
          return AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: isDesktop ? 80 : kToolbarHeight,
            leading: MicroAnimations.scaleOnTap(
              child: IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DesignTokens.neutral100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    PhosphorIcons.arrowLeft(),
                    color: DesignTokens.neutral700,
                    size: 20,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                MicroAnimations.slideIn(
                  child: Stack(
                    children: [
                      UserAvatar(
                        user: participant,
                        size: 44,
                        showOnlineStatus: true,
                      ),
                      if (_isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: DesignTokens.success500,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participant.name,
                        style: TextStyle(
                          color: DesignTokens.neutral900,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(participant.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusText(participant.status),
                            style: TextStyle(
                              color: _getStatusColor(participant.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: DesignTokens.error500,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: DesignTokens.error500
                                        .withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Search button
              MicroAnimations.scaleOnTap(
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _toggleSearchMode();
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isSearchMode
                          ? DesignTokens.primary500.withValues(alpha: 0.1)
                          : DesignTokens.neutral100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isSearchMode
                          ? PhosphorIcons.x()
                          : PhosphorIcons.magnifyingGlass(),
                      color: _isSearchMode
                          ? DesignTokens.primary500
                          : DesignTokens.neutral700,
                      size: 20,
                    ),
                  ),
                  tooltip: _isSearchMode ? 'Fechar busca' : 'Buscar mensagens',
                ),
              ),
              // AI suggestions toggle
              MicroAnimations.scaleOnTap(
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _toggleAISuggestions();
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _showAISuggestions
                          ? DesignTokens.primary500.withValues(alpha: 0.1)
                          : DesignTokens.neutral100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      PhosphorIcons.robot(),
                      color: _showAISuggestions
                          ? DesignTokens.primary500
                          : DesignTokens.neutral700,
                      size: 20,
                    ),
                  ),
                  tooltip: _showAISuggestions
                      ? 'Ocultar sugestões IA'
                      : 'Mostrar sugestões IA',
                ),
              ),
              // Menu
              PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DesignTokens.neutral100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    PhosphorIcons.dotsThreeVertical(),
                    color: DesignTokens.neutral700,
                    size: 20,
                  ),
                ),
                tooltip: 'Mais opções',
                color: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.info(),
                          size: 18,
                          color: DesignTokens.neutral700,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Informações do Chat',
                          style: TextStyle(
                            color: DesignTokens.neutral700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'ticket',
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.ticket(),
                          size: 18,
                          color: DesignTokens.neutral700,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Criar Ticket',
                          style: TextStyle(
                            color: DesignTokens.neutral700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.archive(),
                          size: 18,
                          color: DesignTokens.neutral700,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Arquivar Chat',
                          style: TextStyle(
                            color: DesignTokens.neutral700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.trash(),
                          size: 18,
                          color: DesignTokens.error500,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Limpar conversa',
                          style: TextStyle(
                            color: DesignTokens.error500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar mensagens...',
                hintStyle: TextStyle(
                  color: DesignTokens.neutral500,
                ),
                prefixIcon: Icon(
                  PhosphorIcons.magnifyingGlass(),
                  color: DesignTokens.neutral500,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                        icon: Icon(
                          PhosphorIcons.x(),
                          color: DesignTokens.neutral500,
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: DesignTokens.neutral200,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: DesignTokens.primary500,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: DesignTokens.neutral50,
              ),
              style: TextStyle(color: DesignTokens.neutral900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DesignTokens.primary500.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.magnifyingGlass(),
            size: 16,
            color: DesignTokens.primary500,
          ),
          const SizedBox(width: 8),
          Text(
            '${_searchResults.length} resultado(s) encontrado(s)',
            style: TextStyle(
              color: DesignTokens.primary500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollToBottomFab() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton.small(
            onPressed: () {
              HapticFeedback.lightImpact();
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            backgroundColor: DesignTokens.primary500,
            elevation: 4,
            child: Icon(
              PhosphorIcons.arrowDown(),
              color: Colors.white,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAISuggestionsBar() {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return AnimatedBuilder(
      animation: _suggestionAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _suggestionAnimation.value)),
          child: Opacity(
            opacity: _suggestionAnimation.value,
            child: Container(
              height: isDesktop ? 80 : 70,
              padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: isDesktop ? 12 : 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: isDesktop
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: DesignTokens.neutral200,
                          width: 1,
                        ),
                      ),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _aiSuggestions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final suggestion = _aiSuggestions[index];
                  return MicroAnimations.scaleOnTap(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _useSuggestion(suggestion);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              DesignTokens.primary500.withValues(alpha: 0.1),
                              DesignTokens.primary500.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                DesignTokens.primary500.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.primary500
                                  .withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.lightbulb(),
                              size: 16,
                              color: DesignTokens.primary500,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              suggestion,
                              style: TextStyle(
                                color: DesignTokens.primary500,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessagesList() {
    final messagesToShow =
        _isSearchMode && _searchResults.isNotEmpty ? _searchResults : _messages;
    final isDesktop = MediaQuery.of(context).size.width > 768;

    // Agrupar mensagens por data
    Map<DateTime, List<Message>> groupedMessages = {};
    for (var message in messagesToShow) {
      final date = DateTime(message.createdAt.year, message.createdAt.month, message.createdAt.day);
      if (!groupedMessages.containsKey(date)) {
        groupedMessages[date] = [];
      }
      groupedMessages[date]!.add(message);
    }

    // Lista de chaves ordenadas
    final sortedDates = groupedMessages.keys.toList()..sort();

    return AnimatedBuilder(
      animation: _messageAnimationController,
      builder: (context, child) {
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final group = groupedMessages[date]!;

            return Column(
              children: [
                // Cabeçalho de data
                Container(
                  margin: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _formatDate(date),
                    style: TextStyle(
                      color: DesignTokens.neutral500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...group.map((message) {
                  final currentUser = _getMockCurrentUser();
                  final isFromCurrentUser = message.sender.id == currentUser.id;

                  return Container(
                    margin: EdgeInsets.only(bottom: isDesktop ? 16 : 12),
                    constraints: isDesktop ? const BoxConstraints(maxWidth: 800) : null,
                    alignment: isDesktop ? Alignment.center : null,
                    child: _buildSimpleMessageBubble(
                      message, currentUser, isFromCurrentUser,
                    ),
                  );
                }).toList(),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Hoje';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Ontem';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  Widget _buildSimpleMessageBubble(
      Message message, User currentUser, bool isFromCurrentUser) {
    final bubbleColor = isFromCurrentUser ? DesignTokens.primary500 : Colors.green[100];
    final textColor = isFromCurrentUser ? Colors.white : DesignTokens.neutral900;
    final roleLabel = isFromCurrentUser ? 'Atendente' : 'Cliente';
    final borderRadius = isFromCurrentUser
        ? BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment:
          isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isFromCurrentUser)
          UserAvatar(
            user: message.sender,
            size: 32,
            showOnlineStatus: false,
          ),
        Flexible(
          child: Container(
            margin: EdgeInsets.only(
              left: isFromCurrentUser ? 0 : 8,
              right: isFromCurrentUser ? 8 : 0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isFromCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  '$roleLabel: ${message.content}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${message.sender.name} • ${_formatTime(message.createdAt)}',
                  style: TextStyle(
                    color: isFromCurrentUser
                        ? Colors.white.withValues(alpha: 0.7)
                        : DesignTokens.neutral500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isFromCurrentUser)
          UserAvatar(
            user: message.sender,
            size: 32,
            showOnlineStatus: false,
          ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(DesignTokens.primary500),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Carregando mensagens...',
                style: TextStyle(
                  color: DesignTokens.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignTokens.primary500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  PhosphorIcons.copy(),
                  color: DesignTokens.primary500,
                  size: 20,
                ),
              ),
              title: Text(
                'Copiar mensagem',
                style: TextStyle(
                  color: DesignTokens.neutral900,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ToastService.instance.showSuccess(
                  context,
                  message: 'Mensagem copiada para a área de transferência',
                  title: 'Copiado!',
                );
              },
            ),
            if (message.sender.id == 'current_user')
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DesignTokens.error500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    PhosphorIcons.trash(),
                    color: DesignTokens.error500,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Excluir mensagem',
                  style: TextStyle(
                    color: DesignTokens.error500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 48, 71, 108).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  PhosphorIcons.arrowBendUpLeft(),
                  color: DesignTokens.primary500,
                  size: 20,
                ),
              ),
              title: Text(
                'Responder',
                style: TextStyle(
                  color: DesignTokens.neutral900,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _replyToMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      constraints: isDesktop ? const BoxConstraints(maxWidth: 800) : null,
      alignment: isDesktop ? Alignment.center : null,
      child: Row(
        children: [
          UserAvatar(
            user: _chat.participants.first,
            size: isDesktop ? 36 : 32,
            showOnlineStatus: false,
          ),
          SizedBox(width: isDesktop ? 16 : 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.neutral100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: DesignTokens.neutral200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                DesignTokens.neutral500.withValues(alpha: 0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildChatInput() {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, DesignTokens.neutral50],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -6),
            spreadRadius: 0,
          ),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Container(
          constraints: isDesktop ? const BoxConstraints(maxWidth: 800) : null,
          margin: isDesktop ? const EdgeInsets.symmetric(horizontal: 24) : null,
          child: ChatInput(
            onSendMessage: _sendMessage,
            onTyping: _handleTyping,
            onStopTyping: _handleStopTyping,
            aiSuggestions: _showAISuggestions ? _aiSuggestions : [],
            onUseSuggestion: _useSuggestion,
          ),
        ),
      ),
    );
  }

  // Actions
  void _toggleAISuggestions() {
    setState(() {
      _showAISuggestions = !_showAISuggestions;
    });

    if (_showAISuggestions && _aiSuggestions.isNotEmpty) {
      _suggestionAnimationController.forward();
    } else {
      _suggestionAnimationController.reverse();
    }
  }

  void _handleMenuAction(String action) {
    HapticFeedback.lightImpact();
    switch (action) {
      case 'info':
        _showChatInfo();
        break;
      case 'ticket':
        _createTicket();
        break;
      case 'archive':
        _archiveChat();
        break;
      case 'clear':
        _clearConversation();
        break;
    }
  }

  void _showChatInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildChatInfoModal(),
    );
  }

  Widget _buildChatInfoModal() {
    final participant = _chat.participants.first;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: DesignTokens.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          UserAvatar(
            user: participant,
            size: 80,
            showOnlineStatus: true,
          ),
          const SizedBox(height: 16),
          Text(
            participant.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: DesignTokens.neutral900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            participant.email,
            style: TextStyle(
              color: DesignTokens.neutral600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoAction(
                icon: PhosphorIcons.envelope(),
                label: 'Email',
                onTap: () {},
              ),
              _buildInfoAction(
                icon: PhosphorIcons.phone(),
                label: 'Telefone',
                onTap: () {},
              ),
              _buildInfoAction(
                icon: PhosphorIcons.ticket(),
                label: 'Tickets',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.primary500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: DesignTokens.primary500,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: DesignTokens.neutral600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _createTicket() {
    Navigator.pop(context);
    ToastService.instance.showInfo(
      context,
      message: 'Funcionalidade de criação de ticket será implementada em breve',
      title: 'Em desenvolvimento',
    );
  }

  void _archiveChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              PhosphorIcons.archive(),
              color: DesignTokens.primary500,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Arquivar Conversa'),
          ],
        ),
        content: const Text('Tem certeza que deseja arquivar esta conversa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ToastService.instance.showSuccess(
                context,
                message: 'Conversa arquivada com sucesso',
                title: 'Arquivado!',
              );
            },
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );
  }

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              PhosphorIcons.trash(),
              color: DesignTokens.error500,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Limpar Conversa'),
          ],
        ),
        content: const Text(
            'Tem certeza que deseja limpar todas as mensagens desta conversa? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
              });
              ToastService.instance.showSuccess(
                context,
                message: 'Conversa limpa com sucesso',
                title: 'Limpo!',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.error500,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String content, MessageType type) {
    if (content.trim().isEmpty) return;

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      type: type,
      sender: _getMockCurrentUser(),
      chatId: _chat.id,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    setState(() {
      _messages.add(newMessage);
    });

    _scrollToBottom();

    // Simular recebimento de mensagem
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _loadAISuggestions();
      }
    });
  }

  void _handleTyping(String text) {
    setState(() {
      _isTyping = false; // Não mostrar indicador para nós mesmos
    });
  }

  void _handleStopTyping() {
    setState(() {
      _isTyping = false;
    });
  }

  void _useSuggestion(String suggestion) {
    _sendMessage(suggestion, MessageType.text);
  }

  void _replyToMessage(Message message) {
    setState(() {
      _replyingTo = message;
    });
  }

  void _editMessage(Message message) {
    ToastService.instance.showInfo(
      context,
      message: 'Funcionalidade de edição será implementada em breve',
      title: 'Em desenvolvimento',
    );
  }

  void _deleteMessage(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              PhosphorIcons.trash(),
              color: DesignTokens.error500,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Excluir Mensagem'),
          ],
        ),
        content: const Text('Tem certeza que deseja excluir esta mensagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.removeWhere((m) => m.id == message.id);
              });
              ToastService.instance.showSuccess(
                context,
                message: 'Mensagem excluída com sucesso',
                title: 'Excluído!',
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.error500),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Helper methods
  String _getStatusText(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return 'Online';
      case UserStatus.offline:
        return 'Offline';
      case UserStatus.away:
        return 'Ausente';
      case UserStatus.busy:
        return 'Ocupado';
    }
  }

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return DesignTokens.success500;
      case UserStatus.offline:
        return DesignTokens.neutral500;
      case UserStatus.away:
        return DesignTokens.warning500;
      case UserStatus.busy:
        return DesignTokens.error500;
    }
  }

  User _getMockCurrentUser() {
    return User(
      id: 'current_user',
      name: 'Você',
      email: 'you@sistema.com',
      avatarUrl: '',
      role: UserRole.agent,
      status: UserStatus.online,
      createdAt: DateTime.now(),
    );
  }

  // Callback methods
  void _onScroll() {
    final showFab =
        _scrollController.hasClients && _scrollController.offset > 200;

    if (showFab != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = showFab;
      });

      if (showFab) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
        if (query.isEmpty) {
          _searchResults.clear();
        } else {
          _searchResults = _messages.where((message) {
            return message.content.toLowerCase().contains(query) ||
                message.sender.name.toLowerCase().contains(query);
          }).toList();
        }
      });
    }
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _searchResults.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _jumpToMessage(Message message) {
    final index = _messages.indexOf(message);
    if (index != -1) {
      _scrollController.animateTo(
        index * 80.0, // Approximate message height
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _toggleSearchMode();
    }
  }

  @override
  void dispose() {
    _appBarAnimationController.dispose();
    _messageAnimationController.dispose();
    _fabAnimationController.dispose();
    _suggestionAnimationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _messageController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
