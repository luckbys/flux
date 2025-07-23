import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/chat.dart';
import '../../models/user.dart';
import '../../components/ui/user_avatar.dart';
import '../../styles/app_theme.dart';
import '../../stores/chat_store.dart';
import './chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with TickerProviderStateMixin {
  String _searchQuery = '';
  String _selectedFilter = 'all';
  int _selectedSidebarIndex = 0;
  bool _isDarkMode = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Carregar chats do store
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatStore>().loadChats();
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _updateSearchSuggestions();
      _showSuggestions = _searchQuery.isNotEmpty;
    });
  }

  void _updateSearchSuggestions() {
    final chats = context.read<ChatStore>().chats;
    _searchSuggestions = chats
        .where((chat) => chat
            .getDisplayTitle()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .map((chat) => chat.getDisplayTitle())
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Theme(
      data: _isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
      child: Scaffold(
        backgroundColor:
            _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Consumer<ChatStore>(
              builder: (context, chatStore, child) {
                final filteredChats = _getFilteredChats(chatStore.chats);

                return isDesktop
                    ? _buildDesktopLayout(filteredChats, chatStore)
                    : _buildMobileLayout(filteredChats, chatStore);
              },
            ),
          ),
        ),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardColor: Colors.white,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Color(0xFF1F2937)),
        bodyMedium: TextStyle(color: Color(0xFF6B7280)),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFF1F2937),
      cardColor: const Color(0xFF374151),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Color(0xFFF9FAFB)),
        bodyMedium: TextStyle(color: Color(0xFFD1D5DB)),
      ),
    );
  }

  List<Chat> _getFilteredChats(List<Chat> chats) {
    var filtered = chats;

    // Aplicar filtro de status
    switch (_selectedFilter) {
      case 'active':
        filtered =
            filtered.where((chat) => chat.status == ChatStatus.active).toList();
        break;
      case 'archived':
        filtered = filtered
            .where((chat) => chat.status == ChatStatus.archived)
            .toList();
        break;
      case 'closed':
        filtered =
            filtered.where((chat) => chat.status == ChatStatus.closed).toList();
        break;
    }

    // Aplicar busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((chat) =>
              chat
                  .getDisplayTitle()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (chat.lastMessage?.content ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Widget _buildDesktopLayout(List<Chat> filteredChats, ChatStore chatStore) {
    return Row(
      children: [
        _buildSidebar(),
        Expanded(
          child: Column(
            children: [
              _buildDesktopHeader(filteredChats),
              Expanded(
                child: chatStore.isLoadingChats
                    ? _buildLoadingState()
                    : chatStore.error != null
                        ? _buildErrorState(chatStore.error!)
                        : filteredChats.isEmpty
                            ? _buildEmptyState()
                            : _buildChatsList(filteredChats),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(List<Chat> filteredChats, ChatStore chatStore) {
    return Column(
      children: [
        _buildHeader(filteredChats),
        Expanded(
          child: chatStore.isLoadingChats
              ? _buildLoadingState()
              : chatStore.error != null
                  ? _buildErrorState(chatStore.error!)
                  : filteredChats.isEmpty
                      ? _buildEmptyState()
                      : _buildChatsList(filteredChats),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    final sidebarItems = [
      {
        'icon': PhosphorIcons.chatCircle(),
        'label': 'Conversas Ativas',
        'filter': 'active'
      },
      {
        'icon': PhosphorIcons.archive(),
        'label': 'Arquivadas',
        'filter': 'archived'
      },
      {'icon': PhosphorIcons.x(), 'label': 'Fechadas', 'filter': 'closed'},
      {
        'icon': PhosphorIcons.gear(),
        'label': 'Configurações',
        'filter': 'settings'
      },
    ];

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF374151) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header da sidebar
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ChatApp',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isDarkMode = !_isDarkMode;
                    });
                  },
                  icon: Icon(
                    _isDarkMode ? PhosphorIcons.sun() : PhosphorIcons.moon(),
                    color: _isDarkMode ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Itens da sidebar
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sidebarItems.length,
              itemBuilder: (context, index) {
                final item = sidebarItems[index];
                final isSelected = _selectedSidebarIndex == index;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (_isDarkMode
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF3B82F6))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      item['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : (_isDarkMode
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF6B7280)),
                      size: 20,
                    ),
                    title: Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (_isDarkMode
                                ? const Color(0xFFD1D5DB)
                                : const Color(0xFF374151)),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedSidebarIndex = index;
                        if (item['filter'] != 'settings') {
                          _selectedFilter = item['filter'] as String;
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(List<Chat> filteredChats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF374151) : Colors.white,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conversas',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color:
                          _isDarkMode ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_getActiveChatsCount(filteredChats)} ativas • ${filteredChats.length} total',
                    style: TextStyle(
                      color: _isDarkMode
                          ? const Color(0xFFD1D5DB)
                          : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildFilterChips(),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        context.read<ChatStore>().loadChats();
                      },
                      icon: Icon(
                        PhosphorIcons.arrowClockwise(),
                        color: _isDarkMode
                            ? Colors.white
                            : const Color(0xFF374151),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEnhancedSearchBar(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Todas'},
      {'key': 'active', 'label': 'Ativas'},
      {'key': 'archived', 'label': 'Arquivadas'},
    ];

    return Row(
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter['key'];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(
              filter['label']!,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (_isDarkMode
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF374151)),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = filter['key']!;
              });
            },
            backgroundColor:
                _isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFF3F4F6),
            selectedColor: const Color(0xFF3B82F6),
            checkmarkColor: Colors.white,
            side: BorderSide.none,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEnhancedSearchBar() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color:
                _isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDarkMode
                  ? const Color(0xFF6B7280)
                  : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Buscar conversas, mensagens...',
              hintStyle: TextStyle(
                color: _isDarkMode
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF9CA3AF),
              ),
              prefixIcon: Icon(
                PhosphorIcons.magnifyingGlass(),
                color: _isDarkMode
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF6B7280),
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                      },
                      icon: Icon(
                        PhosphorIcons.x(),
                        color: _isDarkMode
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF6B7280),
                        size: 16,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(
              color: _isDarkMode ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
        ),
        if (_showSuggestions && _searchSuggestions.isNotEmpty)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF374151) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDarkMode
                        ? const Color(0xFF6B7280)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _searchSuggestions[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        PhosphorIcons.clockCounterClockwise(),
                        size: 16,
                        color: _isDarkMode
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      ),
                      title: Text(
                        suggestion,
                        style: TextStyle(
                          color: _isDarkMode
                              ? Colors.white
                              : const Color(0xFF1F2937),
                          fontSize: 14,
                        ),
                      ),
                      onTap: () {
                        _searchController.text = suggestion;
                        setState(() {
                          _showSuggestions = false;
                        });
                        _searchFocusNode.unfocus();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(List<Chat> filteredChats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conversas',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    '${_getActiveChatsCount(filteredChats)} ativas • ${filteredChats.length} total',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    // Recarregar chats
                    context.read<ChatStore>().loadChats();
                  },
                  icon: Icon(
                    PhosphorIcons.arrowClockwise(),
                    color: const Color(0xFF374151),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Buscar conversas...',
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
          ),
          prefixIcon: Icon(
            PhosphorIcons.magnifyingGlass(),
            color: const Color(0xFF6B7280),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppTheme.spacing16),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppTheme.spacing16),
          Text('Carregando conversas...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.warning(),
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'Erro ao carregar conversas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          ElevatedButton(
            onPressed: () => context.read<ChatStore>().loadChats(),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsList(List<Chat> filteredChats) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: filteredChats.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final chat = filteredChats[index];
        final participant = chat.participants.isNotEmpty
            ? chat.participants.first
            : _createDummyUser();
        final unreadCount = _getUnreadCount(chat);
        final hasUnread = unreadCount > 0;

        return _ChatListItem(
          chat: chat,
          participant: participant,
          unreadCount: unreadCount,
          hasUnread: hasUnread,
          isDarkMode: _isDarkMode,
          onTap: () => _openChat(chat),
          formatTime: _formatTime,
          getStatusColor: _getStatusColor,
          getStatusText: _getStatusText,
        );
      },
    );
  }

  int _getUnreadCount(Chat chat) {
    // Simular contagem de mensagens não lidas
    return chat.status == ChatStatus.active ? (chat.id.hashCode % 5) : 0;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.chatCircle(),
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'Nenhuma conversa encontrada',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'As conversas aparecerão aqui quando você receber mensagens',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  int _getActiveChatsCount(List<Chat> chats) {
    return chats.where((chat) => chat.status == ChatStatus.active).length;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  Color _getStatusColor(ChatStatus status) {
    switch (status) {
      case ChatStatus.active:
        return const Color(0xFF22C55E);
      case ChatStatus.archived:
        return const Color(0xFF6B7280);
      case ChatStatus.closed:
        return const Color(0xFFEF4444);
    }
  }

  String _getStatusText(ChatStatus status) {
    switch (status) {
      case ChatStatus.active:
        return 'Ativo';
      case ChatStatus.archived:
        return 'Arquivado';
      case ChatStatus.closed:
        return 'Fechado';
    }
  }

  User _createDummyUser() {
    return User(
      id: 'dummy',
      name: 'Usuário',
      email: 'usuario@exemplo.com',
      role: UserRole.customer,
      status: UserStatus.offline,
      createdAt: DateTime.now(),
    );
  }

  void _openChat(Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(chat: chat),
      ),
    );
  }
}

class _ChatListItem extends StatefulWidget {
  final Chat chat;
  final User participant;
  final int unreadCount;
  final bool hasUnread;
  final bool isDarkMode;
  final VoidCallback onTap;
  final String Function(DateTime) formatTime;
  final Color Function(ChatStatus) getStatusColor;
  final String Function(ChatStatus) getStatusText;

  const _ChatListItem({
    required this.chat,
    required this.participant,
    required this.unreadCount,
    required this.hasUnread,
    required this.isDarkMode,
    required this.onTap,
    required this.formatTime,
    required this.getStatusColor,
    required this.getStatusText,
  });

  @override
  State<_ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<_ChatListItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color:
                    widget.isDarkMode ? const Color(0xFF374151) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: widget.isDarkMode ? 0.2 : 0.08),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 3),
                  ),
                ],
                border: widget.hasUnread
                    ? Border.all(
                        color: const Color(0xFF3B82F6),
                        width: 2,
                      )
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Avatar com status online e badge de notificação
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget
                                        .getStatusColor(widget.chat.status)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: UserAvatar(
                                user: widget.participant,
                                size: 48,
                                showOnlineStatus: false,
                              ),
                            ),
                            // Status online
                            if (widget.participant.status == UserStatus.online)
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    border: Border.all(
                                      color: widget.isDarkMode
                                          ? const Color(0xFF374151)
                                          : Colors.white,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              ),
                            // Badge de mensagens não lidas
                            if (widget.hasUnread)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: widget.isDarkMode
                                          ? const Color(0xFF374151)
                                          : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    widget.unreadCount > 99
                                        ? '99+'
                                        : widget.unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Conteúdo principal
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Linha do título e horário
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.chat.getDisplayTitle(),
                                      style: TextStyle(
                                        fontWeight: widget.hasUnread
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: widget.isDarkMode
                                            ? Colors.white
                                            : const Color(0xFF1F2937),
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    widget.formatTime(widget.chat.updatedAt ??
                                        widget.chat.createdAt),
                                    style: TextStyle(
                                      color: widget.hasUnread
                                          ? const Color(0xFF3B82F6)
                                          : (widget.isDarkMode
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF6B7280)),
                                      fontSize: 12,
                                      fontWeight: widget.hasUnread
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Linha do status e última mensagem
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget
                                          .getStatusColor(widget.chat.status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      widget.getStatusText(widget.chat.status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.chat.lastMessage?.content ??
                                          'Nenhuma mensagem ainda',
                                      style: TextStyle(
                                        color: widget.hasUnread
                                            ? (widget.isDarkMode
                                                ? const Color(0xFFD1D5DB)
                                                : const Color(0xFF374151))
                                            : (widget.isDarkMode
                                                ? const Color(0xFF9CA3AF)
                                                : const Color(0xFF6B7280)),
                                        fontSize: 14,
                                        fontWeight: widget.hasUnread
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Ícone de seta (aparece no hover)
                        AnimatedOpacity(
                          opacity: _isHovered ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            PhosphorIcons.caretRight(),
                            color: widget.isDarkMode
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
