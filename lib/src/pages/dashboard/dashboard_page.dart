import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../../models/chat.dart';
import '../../components/ui/user_avatar.dart';
import '../../styles/app_theme.dart';
import '../../utils/color_extensions.dart';
import '../../stores/dashboard_store.dart';
import '../tickets/tickets_page.dart';
import '../tickets/ticket_details_page.dart';
import '../chat/chat_list_page.dart';
import '../chat/chat_page.dart';
import '../profile/profile_page.dart';
import '../settings/whatsapp_setup_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardStore _dashboardStore;
  
  @override
  void initState() {
    super.initState();
    _dashboardStore = DashboardStore();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    await _dashboardStore.loadDashboardData();
  }
  
  @override
  void dispose() {
    _dashboardStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determinar se estamos em um layout desktop/tablet ou mobile
            final isDesktop = constraints.maxWidth > 1100;
            final isTablet = constraints.maxWidth > 600 && constraints.maxWidth <= 1100;
            
            if (isDesktop) {
              // Layout para desktop
              return _buildDesktopLayout(constraints);
            } else if (isTablet) {
              // Layout para tablet
              return _buildTabletLayout(constraints);
            } else {
              // Layout para mobile (original)
              return _buildMobileLayout();
            }
          },
        ),
      ),
    );
  }
  
  // Layout para dispositivos móveis
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(),
                const SizedBox(height: AppTheme.spacing24),
                _buildStatsGrid(),
                const SizedBox(height: AppTheme.spacing32),
                _buildQuickActions(),
                const SizedBox(height: AppTheme.spacing32),
                _buildRecentTickets(isDesktop: false),
                const SizedBox(height: AppTheme.spacing32),
                _buildActiveChats(),
                const SizedBox(height: AppTheme.spacing24),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Layout para tablets
  Widget _buildTabletLayout(BoxConstraints constraints) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(),
                const SizedBox(height: AppTheme.spacing32),
                // Grid de estatísticas com 2 itens por linha
                _buildStatsGrid(crossAxisCount: 2),
                const SizedBox(height: AppTheme.spacing32),
                // Ações rápidas em 2 colunas
                _buildQuickActions(isTablet: true),
                const SizedBox(height: AppTheme.spacing32),
                // Layout de 2 colunas para tickets e chats
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildRecentTickets(isDesktop: false),
                    ),
                    const SizedBox(width: AppTheme.spacing24),
                    Expanded(
                      flex: 2,
                      child: _buildActiveChats(isVertical: true),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing24),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Layout para desktop
  Widget _buildDesktopLayout(BoxConstraints constraints) {
    return Row(
      children: [
        // Sidebar (pode ser implementada posteriormente)
        // Conteúdo principal
        Expanded(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacing32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Coluna da esquerda (60% da largura)
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildWelcomeSection(),
                                const SizedBox(height: AppTheme.spacing32),
                                // Grid de estatísticas com 4 itens por linha
                                _buildStatsGrid(crossAxisCount: 4),
                                const SizedBox(height: AppTheme.spacing32),
                                // Ações rápidas em uma linha
                                _buildQuickActions(isDesktop: true),
                                const SizedBox(height: AppTheme.spacing32),
                                _buildRecentTickets(isDesktop: true),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing32),
                          // Coluna da direita (40% da largura)
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Widgets adicionais podem ser adicionados aqui
                                _buildActiveChats(isVertical: true),
                                const SizedBox(height: AppTheme.spacing32),
                                // Área para notificações ou outros widgets
                                _buildNotificationsWidget(),
                              ],
                            ),
                          ),
                        ],
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
  
  // Widget para notificações (apenas para desktop)
  Widget _buildNotificationsWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                'Notificações Recentes',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
              ),
              IconButton(
                onPressed: _showNotifications,
                icon: Icon(
                  PhosphorIcons.bell(),
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          // Lista de notificações
          _buildNotificationItem(
            icon: PhosphorIcons.ticket(),
            color: AppTheme.primaryColor,
            title: 'Novo ticket #1234',
            subtitle: 'Cliente relatou problema urgente',
            time: '10 min atrás',
          ),
          const Divider(),
          _buildNotificationItem(
            icon: PhosphorIcons.chatCircle(),
            color: AppTheme.successColor,
            title: 'Nova mensagem',
            subtitle: 'Maria Silva enviou uma mensagem',
            time: '30 min atrás',
          ),
          const Divider(),
          _buildNotificationItem(
            icon: PhosphorIcons.checkCircle(),
            color: AppTheme.warningColor,
            title: 'Ticket resolvido',
            subtitle: 'Ticket #1230 foi marcado como resolvido',
            time: '1 hora atrás',
          ),
        ],
      ),
    );
  }
  
  // Item de notificação
  Widget _buildNotificationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getTextColor(context).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextColor(context),
                    ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                'Bem-vindo ao BKCRM',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.getBackgroundColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _showNotifications,
              icon: Stack(
                children: [
                  Icon(
                    PhosphorIcons.bell(),
                    color: AppTheme.getTextColor(context),
                    size: 24,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: AppTheme.getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.waving_hand,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, João!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextColor(context),
                        ),
                  ),
                  Text(
                    'Tenha um ótimo dia de trabalho',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppTheme.getBackgroundColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.getBorderColor(context),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildWelcomeItem(
                        'Pendentes',
                        '12',
                        AppTheme.warningColor,
                        AppTheme.warningColor.withValues(alpha: 0.1),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: AppTheme.getBorderColor(context),
                    ),
                    Expanded(
                      child: _buildWelcomeItem(
                        'Ativos',
                        '3',
                        AppTheme.successColor,
                        AppTheme.successColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeItem(
      String label, String value, Color color, Color bgColor) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid({int crossAxisCount = 2}) {
    return AnimatedBuilder(
      animation: _dashboardStore,
      builder: (context, child) {
        final stats = [
          _StatItem(
            title: 'Tickets Abertos',
            value: '${_dashboardStore.openTickets}',
            icon: PhosphorIcons.ticket(),
            color: AppTheme.primaryColor,
            bgColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            trend: '+5%',
            isPositive: true,
          ),
          _StatItem(
            title: 'Resolvidos Hoje',
            value: '${_dashboardStore.resolvedToday}',
            icon: PhosphorIcons.checkCircle(),
            color: AppTheme.successColor,
            bgColor: AppTheme.successColor.withValues(alpha: 0.1),
            trend: '+12%',
            isPositive: true,
          ),
          _StatItem(
            title: 'Tempo Médio',
            value: '${_dashboardStore.avgResolutionTime.toStringAsFixed(1)}h',
            icon: PhosphorIcons.clock(),
            color: AppTheme.warningColor,
            bgColor: AppTheme.warningColor.withValues(alpha: 0.1),
            trend: '-8%',
            isPositive: false,
          ),
          _StatItem(
            title: 'Satisfação',
            value: '${_dashboardStore.satisfactionRate.toStringAsFixed(0)}%',
            icon: PhosphorIcons.smiley(),
            color: AppTheme.primaryColor,
            bgColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            trend: '+3%',
            isPositive: true,
          ),
        ];
        
        if (_dashboardStore.isLoading) {
          return _buildLoadingGrid(crossAxisCount);
        }
        
        if (_dashboardStore.hasError) {
           return _buildErrorGrid(crossAxisCount);
         }

        // Ajustar o childAspectRatio com base no número de colunas
        double childAspectRatio = crossAxisCount == 4 ? 1.6 : 1.4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppTheme.spacing16,
            mainAxisSpacing: AppTheme.spacing16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return GestureDetector(
              onTap: () => _onStatCardTap(stat.title),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: AppTheme.getCardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: stat.bgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            stat.icon,
                            color: stat.color,
                            size: 20,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing8,
                            vertical: AppTheme.spacing4,
                          ),
                          decoration: BoxDecoration(
                            color: stat.isPositive
                                ? AppTheme.successColor.withValues(alpha: 0.1)
                                : AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stat.trend,
                            style: TextStyle(
                              color: stat.isPositive
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    Text(
                      stat.value,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getTextColor(context),
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      stat.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions({bool isDesktop = false, bool isTablet = false}) {
    // Lista de ações rápidas
    final actions = [
      {
        'title': 'Novo Ticket',
        'subtitle': 'Criar novo atendimento',
        'icon': PhosphorIcons.plus(),
        'color': AppTheme.primaryColor,
        'bgColor': AppTheme.primaryColor.withValues(alpha: 0.1),
        'onTap': _navigateToNewTicket,
      },
      {
        'title': 'Iniciar Chat',
        'subtitle': 'Conversa em tempo real',
        'icon': PhosphorIcons.chatCircle(),
        'color': AppTheme.successColor,
        'bgColor': AppTheme.successColor.withValues(alpha: 0.1),
        'onTap': _navigateToChats,
      },
      {
        'title': 'WhatsApp',
        'subtitle': 'Configurar integração',
        'icon': PhosphorIcons.whatsappLogo(),
        'color': const Color(0xFF25D366),
        'bgColor': const Color(0xFF25D366).withValues(alpha: 0.1),
        'onTap': _navigateToWhatsAppSetup,
      },
      {
        'title': 'Configurações',
        'subtitle': 'Ajustar preferências',
        'icon': PhosphorIcons.gear(),
        'color': AppTheme.getTextColor(context).withValues(alpha: 0.7),
        'bgColor': AppTheme.getTextColor(context).withValues(alpha: 0.1),
        'onTap': _navigateToSettings,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context),
              ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        if (isDesktop)
          // Layout para desktop: todos os cards em uma única linha
          Row(
            children: actions.map((action) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacing16),
                  child: _buildActionCard(
                    title: action['title'] as String,
                    subtitle: action['subtitle'] as String,
                    icon: action['icon'] as IconData,
                    color: action['color'] as Color,
                    bgColor: action['bgColor'] as Color,
                    onTap: action['onTap'] as VoidCallback,
                  ),
                ),
              );
            }).toList(),
          )
        else if (isTablet)
          // Layout para tablet: grid de 2x2
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: actions[0]['title'] as String,
                      subtitle: actions[0]['subtitle'] as String,
                      icon: actions[0]['icon'] as IconData,
                      color: actions[0]['color'] as Color,
                      bgColor: actions[0]['bgColor'] as Color,
                      onTap: actions[0]['onTap'] as VoidCallback,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: _buildActionCard(
                      title: actions[1]['title'] as String,
                      subtitle: actions[1]['subtitle'] as String,
                      icon: actions[1]['icon'] as IconData,
                      color: actions[1]['color'] as Color,
                      bgColor: actions[1]['bgColor'] as Color,
                      onTap: actions[1]['onTap'] as VoidCallback,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: actions[2]['title'] as String,
                      subtitle: actions[2]['subtitle'] as String,
                      icon: actions[2]['icon'] as IconData,
                      color: actions[2]['color'] as Color,
                      bgColor: actions[2]['bgColor'] as Color,
                      onTap: actions[2]['onTap'] as VoidCallback,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: _buildActionCard(
                      title: actions[3]['title'] as String,
                      subtitle: actions[3]['subtitle'] as String,
                      icon: actions[3]['icon'] as IconData,
                      color: actions[3]['color'] as Color,
                      bgColor: actions[3]['bgColor'] as Color,
                      onTap: actions[3]['onTap'] as VoidCallback,
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          // Layout para mobile: 2 linhas com 2 cards cada
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: actions[0]['title'] as String,
                      subtitle: actions[0]['subtitle'] as String,
                      icon: actions[0]['icon'] as IconData,
                      color: actions[0]['color'] as Color,
                      bgColor: actions[0]['bgColor'] as Color,
                      onTap: actions[0]['onTap'] as VoidCallback,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: _buildActionCard(
                      title: actions[1]['title'] as String,
                      subtitle: actions[1]['subtitle'] as String,
                      icon: actions[1]['icon'] as IconData,
                      color: actions[1]['color'] as Color,
                      bgColor: actions[1]['bgColor'] as Color,
                      onTap: actions[1]['onTap'] as VoidCallback,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: actions[2]['title'] as String,
                      subtitle: actions[2]['subtitle'] as String,
                      icon: actions[2]['icon'] as IconData,
                      color: actions[2]['color'] as Color,
                      bgColor: actions[2]['bgColor'] as Color,
                      onTap: actions[2]['onTap'] as VoidCallback,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: _buildActionCard(
                      title: actions[3]['title'] as String,
                      subtitle: actions[3]['subtitle'] as String,
                      icon: actions[3]['icon'] as IconData,
                      color: actions[3]['color'] as Color,
                      bgColor: actions[3]['bgColor'] as Color,
                      onTap: actions[3]['onTap'] as VoidCallback,
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: AppTheme.getCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTickets({bool isDesktop = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tickets Recentes',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
            ),
            TextButton(
              onPressed: _navigateToAllTickets,
              child: Text(
                'Ver Todos',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        Container(
          decoration: AppTheme.getCardDecoration(context),
          child: isDesktop
              // Layout de tabela para desktop
              ? Column(
                  children: [
                    // Cabeçalho da tabela
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      child: Row(
                        children: [
                          const SizedBox(width: 56), // Espaço para o ícone
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Título',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Cliente',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Status',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48), // Espaço para ações
                        ],
                      ),
                    ),
                    Divider(height: 1, color: AppTheme.getBorderColor(context)),
                    // Linhas da tabela
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: AppTheme.getBorderColor(context),
                      ),
                      itemBuilder: (context, index) {
                        final ticket = index < _dashboardStore.recentTickets.length 
                            ? _dashboardStore.recentTickets[index] 
                            : _getMockTicket(index);
                        return InkWell(
                          onTap: () => _navigateToTicketDetails(ticket),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacing16),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getTicketColor(ticket.status).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    PhosphorIcons.ticket(),
                                    color: _getTicketColor(ticket.status),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacing16),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    ticket.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.getTextColor(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    ticket.customer.name,
                                    style: TextStyle(
                                      color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacing8,
                                        vertical: AppTheme.spacing4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getTicketColor(ticket.status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _getTicketStatusText(ticket.status),
                                        style: TextStyle(
                                          color: _getTicketColor(ticket.status),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    PhosphorIcons.arrowRight(),
                                    color: AppTheme.primaryColor,
                                  ),
                                  onPressed: () => _navigateToTicketDetails(ticket),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                )
              // Layout original para mobile e tablet
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: AppTheme.getBorderColor(context),
                  ),
                  itemBuilder: (context, index) {
                    final ticket = index < _dashboardStore.recentTickets.length 
                        ? _dashboardStore.recentTickets[index] 
                        : _getMockTicket(index);
                    return ListTile(
                      contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              _getTicketColor(ticket.status).withValues(alpha:  0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          PhosphorIcons.ticket(),
                          color: _getTicketColor(ticket.status),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        ticket.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      subtitle: Text(
                        ticket.customer.name,
                        style: TextStyle(
                          color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing8,
                          vertical: AppTheme.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _getTicketColor(ticket.status).withValues(alpha:  0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getTicketStatusText(ticket.status),
                          style: TextStyle(
                            color: _getTicketColor(ticket.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      onTap: () => _navigateToTicketDetails(ticket),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActiveChats({bool isVertical = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Conversas Ativas',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
            ),
            TextButton(
              onPressed: _navigateToAllChats,
              child: Text(
                'Ver Todos',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        if (isVertical)
          // Layout vertical para desktop/tablet
          Container(
            decoration: AppTheme.getCardDecoration(context),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppTheme.getBorderColor(context),
              ),
              itemBuilder: (context, index) {
                final user = index < _dashboardStore.onlineUsers.length 
                    ? _dashboardStore.onlineUsers[index] 
                    : _getMockUser(index);
                return ListTile(
                  contentPadding: const EdgeInsets.all(AppTheme.spacing12),
                  leading: Stack(
                    children: [
                      UserAvatar(
                        user: user,
                        size: 40,
                        showOnlineStatus: false,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getUserStatusColor(user.status),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.getCardColor(context),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    user.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  subtitle: Text(
                    _getUserStatusText(user.status),
                    style: TextStyle(
                      color: _getUserStatusColor(user.status),
                      fontSize: 12,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      PhosphorIcons.chatCircle(),
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () => _navigateToChat(user),
                  ),
                  onTap: () => _navigateToChat(user),
                );
              },
            ),
          )
        else
          // Layout horizontal para mobile (original)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                final user = index < _dashboardStore.onlineUsers.length 
                  ? _dashboardStore.onlineUsers[index] 
                  : _getMockUser(index);
                return GestureDetector(
                  onTap: () => _navigateToChat(user),
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: AppTheme.spacing12),
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: AppTheme.getCardDecoration(context),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            UserAvatar(
                              user: user,
                              size: 40,
                              showOnlineStatus: false,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getUserStatusColor(user.status),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.getCardColor(context),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextColor(context),
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
  
  // Função auxiliar para obter texto do status do usuário
  String _getUserStatusText(UserStatus status) {
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

  // Navigation Functions
  void _navigateToNewTicket() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TicketsPage(),
      ),
    );
    // Aqui você pode implementar um modal para criar novo ticket
    // ou navegar direto para a página de criação
  }

  void _navigateToChats() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatListPage(),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
      ),
    );
  }

  void _navigateToWhatsAppSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WhatsAppSetupPage(),
      ),
    );
  }

  void _navigateToAllTickets() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TicketsPage(),
      ),
    );
  }

  void _navigateToAllChats() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatListPage(),
      ),
    );
  }

  void _navigateToTicketDetails(Ticket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailsPage(ticket: ticket),
      ),
    );
  }

  void _navigateToChat(User user) {
    // Criar um mock chat para navegar
    final chat = _createMockChat(user);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(chat: chat),
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificações'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(PhosphorIcons.ticket(), color: AppTheme.primaryColor),
              title: const Text('Novo ticket #1234'),
              subtitle: const Text('Cliente relatou problema urgente'),
            ),
            ListTile(
              leading: Icon(PhosphorIcons.chatCircle(), color: AppTheme.successColor),
              title: const Text('Nova mensagem'),
              subtitle: const Text('Maria Silva enviou uma mensagem'),
            ),
            ListTile(
              leading: Icon(PhosphorIcons.checkCircle(), color: AppTheme.warningColor),
              title: const Text('Ticket resolvido'),
              subtitle: const Text('Ticket #1230 foi marcado como resolvido'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showReports() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relatórios'),
        content: const Text(
          'Funcionalidade de relatórios em desenvolvimento.\n\n'
          'Em breve você poderá visualizar:\n'
          '• Relatórios de tickets\n'
          '• Métricas de atendimento\n'
          '• Análises de satisfação\n'
          '• Dashboards personalizados',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onStatCardTap(String statTitle) {
    switch (statTitle) {
      case 'Tickets Abertos':
        _navigateToAllTickets();
        break;
      case 'Resolvidos Hoje':
        _navigateToAllTickets();
        break;
      case 'Tempo Médio':
        _showReports();
        break;
      case 'Satisfação':
        _showReports();
        break;
    }
  }

  // Helper Functions
  Color _getTicketColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return AppTheme.primaryColor;
      case TicketStatus.inProgress:
        return AppTheme.warningColor;
      case TicketStatus.resolved:
        return AppTheme.successColor;
      case TicketStatus.closed:
        return AppTheme.getTextColor(context).withValues(alpha: 0.5);
      case TicketStatus.waitingCustomer:
        return AppTheme.secondaryColor;
    }
  }

  String _getTicketStatusText(TicketStatus status) {
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

  Color _getUserStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return AppTheme.successColor;
      case UserStatus.offline:
        return AppTheme.getTextColor(context).withValues(alpha: 0.5);
      case UserStatus.away:
        return AppTheme.warningColor;
      case UserStatus.busy:
        return AppTheme.errorColor;
    }
  }

  // Loading e Error widgets
  Widget _buildLoadingGrid(int crossAxisCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppTheme.spacing16,
        mainAxisSpacing: AppTheme.spacing16,
        childAspectRatio: crossAxisCount == 4 ? 1.6 : 1.4,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: AppTheme.getCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.getBorderColor(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7280)),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.getBorderColor(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),
              Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.getBorderColor(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.getBorderColor(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorGrid(int crossAxisCount) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: AppTheme.getCardDecoration(context),
      child: Column(
        children: [
          Icon(
            PhosphorIcons.warning(),
            color: AppTheme.errorColor,
            size: 48,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'Erro ao carregar estatísticas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            _dashboardStore.errorMessage ?? 'Erro desconhecido',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.getTextColor(context).withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing16),
          ElevatedButton(
            onPressed: () => _dashboardStore.refresh(),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  // Mock data functions
  Ticket _getMockTicket(int index) {
    return Ticket(
      id: 'ticket_${index + 1}',
      title: 'Problema com sistema ${index + 1}',
      description: 'Descrição do problema...',
      status: TicketStatus.values[index % TicketStatus.values.length],
      priority: TicketPriority.values[index % TicketPriority.values.length],
      category: TicketCategory.technical,
      customer: _getMockUser(index),
      createdAt: DateTime.now().subtract(Duration(hours: index + 1)),
    );
  }

  User _getMockUser(int index) {
    return User(
      id: 'user_${index + 1}',
      name: 'Cliente ${index + 1}',
      email: 'cliente${index + 1}@example.com',
      role: UserRole.customer,
      status: UserStatus.values[index % UserStatus.values.length],
      createdAt: DateTime.now(),
    );
  }

  // Função para criar um mock chat
  Chat _createMockChat(User user) {
    return Chat(
      id: 'chat_${user.id}',
      type: ChatType.support,
      status: ChatStatus.active,
      participants: [user],
      createdAt: DateTime.now(),
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String trend;
  final bool isPositive;

  _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.trend,
    required this.isPositive,
  });
}
