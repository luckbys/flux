import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/ticket.dart';
import '../../widgets/form_components.dart';
import 'ticket_form_modal_refactored.dart';

// =============================================================================
// TICKET MODAL SIDEBAR
// =============================================================================

class TicketModalSidebar extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TicketPriority selectedPriority;
  final TicketCategory selectedCategory;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final bool isLoading;
  final bool isEditing;
  final bool isMinimized;
  final VoidCallback? onToggleMinimize;

  const TicketModalSidebar({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.selectedPriority,
    required this.selectedCategory,
    required this.onSubmit,
    required this.onCancel,
    required this.isLoading,
    required this.isEditing,
    this.isMinimized = false,
    this.onToggleMinimize,
  });

  @override
  State<TicketModalSidebar> createState() => _TicketModalSidebarState();
}

class _TicketModalSidebarState extends State<TicketModalSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _widthAnimation = Tween<double>(
      begin: widget.isMinimized ? 60.0 : 380.0,
      end: widget.isMinimized ? 60.0 : 380.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(TicketModalSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMinimized != widget.isMinimized) {
      _widthAnimation = Tween<double>(
        begin: _widthAnimation.value,
        end: widget.isMinimized ? 60.0 : 380.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[50]!,
                Colors.grey[100]!,
              ],
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            border: Border(
              left: BorderSide(
                color: Colors.grey.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: widget.isMinimized
              ? _buildMinimizedSidebar()
              : Column(
                  children: [
                    _buildSidebarHeader(),
                    Expanded(child: _buildSidebarContent()),
                    _buildSidebarFooter(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildMinimizedSidebar() {
    return Column(
      children: [
        // Header minimizado
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              IconButton(
                onPressed: widget.onToggleMinimize,
                icon: Icon(
                  PhosphorIcons.caretRight(),
                  color: FormComponents.primaryColor,
                  size: 20,
                ),
                tooltip: 'Expandir sidebar',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FormComponents.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIcons.lightbulb(),
                  color: FormComponents.primaryColor,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Botões minimizados
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              IconButton(
                onPressed: widget.onSubmit,
                icon: Icon(
                  widget.isEditing ? PhosphorIcons.pencil() : PhosphorIcons.plus(),
                  color: Colors.white,
                  size: 16,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: FormComponents.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                tooltip: widget.isEditing ? 'Atualizar Ticket' : 'Criar Ticket',
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: widget.onCancel,
                icon: Icon(
                  PhosphorIcons.x(),
                  color: Colors.grey[600],
                  size: 16,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                tooltip: 'Cancelar',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FormComponents.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIcons.lightbulb(),
                  color: FormComponents.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Dicas Rápidas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onToggleMinimize,
                icon: Icon(
                  PhosphorIcons.caretLeft(),
                  color: Colors.grey[600],
                  size: 16,
                ),
                tooltip: 'Minimizar sidebar',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildQuickTip(
            icon: PhosphorIcons.textT(),
            title: 'Título claro',
            description: 'Seja específico sobre o problema',
          ),
          const SizedBox(height: 12),
          _buildQuickTip(
            icon: PhosphorIcons.notepad(),
            title: 'Descrição detalhada',
            description: 'Inclua passos para reproduzir',
          ),
          const SizedBox(height: 12),
          _buildQuickTip(
            icon: PhosphorIcons.flag(),
            title: 'Prioridade correta',
            description: 'Urgente apenas se crítico',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTip({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: FormComponents.primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview do ticket
          if (_shouldShowPreview()) ...[
            _buildTicketPreview(),
            const SizedBox(height: 20),
          ],

          // Estatísticas rápidas
          _buildStatisticsCard(),
        ],
      ),
    );
  }

  bool _shouldShowPreview() {
    return widget.titleController.text.isNotEmpty ||
        widget.descriptionController.text.isNotEmpty;
  }

  Widget _buildTicketPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.eye(),
                size: 16,
                color: FormComponents.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Preview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.titleController.text.isNotEmpty) ...[
            Text(
              widget.titleController.text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              FormComponents.buildStatusChip(
                label: _getPriorityText(widget.selectedPriority),
                color: _getPriorityColor(widget.selectedPriority),
                icon: _getPriorityIcon(widget.selectedPriority),
              ),
              const SizedBox(width: 8),
              FormComponents.buildStatusChip(
                label: _getCategoryText(widget.selectedCategory),
                color: FormComponents.primaryColor,
                icon: PhosphorIcons.tag(),
              ),
            ],
          ),
          if (widget.descriptionController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.descriptionController.text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.chartBar(),
                size: 16,
                color: FormComponents.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Estatísticas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatItem('Tempo médio de resposta', '2h 30min'),
          const SizedBox(height: 8),
          _buildStatItem('Taxa de resolução', '94%'),
          const SizedBox(height: 8),
          _buildStatItem('Tickets hoje', '12'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FormComponents.buildPrimaryButton(
              text: widget.isEditing ? 'Atualizar Ticket' : 'Criar Ticket',
              onPressed: widget.onSubmit,
              icon: widget.isEditing ? PhosphorIcons.pencil() : PhosphorIcons.plus(),
              isLoading: widget.isLoading,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FormComponents.buildSecondaryButton(
              text: 'Cancelar',
              onPressed: widget.onCancel,
              icon: PhosphorIcons.x(),
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

// =============================================================================
// TICKET MODAL FOOTER
// =============================================================================

class TicketModalFooter extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final bool isLoading;
  final bool isEditing;
  final ResponsiveLayout layout;

  const TicketModalFooter({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    required this.isLoading,
    required this.isEditing,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: layout.padding,
      decoration: BoxDecoration(
        color: Colors.grey[25],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(layout.borderRadius),
          bottomRight: Radius.circular(layout.borderRadius),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (layout.isDesktop) ...[
            // Desktop: Botões com largura fixa
            SizedBox(
              width: 140,
              child: FormComponents.buildSecondaryButton(
                text: 'Cancelar',
                onPressed: onCancel,
                icon: PhosphorIcons.x(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 180,
              child: FormComponents.buildPrimaryButton(
                text: isEditing ? 'Atualizar Ticket' : 'Criar Ticket',
                onPressed: onSubmit,
                icon: isEditing ? PhosphorIcons.pencil() : PhosphorIcons.plus(),
                isLoading: isLoading,
              ),
            ),
          ] else ...[
            // Mobile: Layout otimizado
            Expanded(
              child: FormComponents.buildSecondaryButton(
                text: 'Cancelar',
                onPressed: onCancel,
                icon: PhosphorIcons.x(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FormComponents.buildPrimaryButton(
                text: isEditing ? 'Atualizar' : 'Criar',
                onPressed: onSubmit,
                icon: isEditing ? PhosphorIcons.pencil() : PhosphorIcons.plus(),
                isLoading: isLoading,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// TICKET HELP DIALOG
// =============================================================================

class TicketHelpDialog extends StatelessWidget {
  const TicketHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(PhosphorIcons.lightbulb(), color: FormComponents.primaryColor),
          const SizedBox(width: 8),
          const Text('Dicas para um bom ticket'),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _HelpItem(
              icon: PhosphorIcons.textT,
              title: 'Título claro e específico',
              description: 'Descreva o problema em poucas palavras',
            ),
            SizedBox(height: 16),
            _HelpItem(
              icon: PhosphorIcons.envelope,
              title: 'E-mail válido',
              description: 'Para receber atualizações do ticket',
            ),
            SizedBox(height: 16),
            _HelpItem(
              icon: PhosphorIcons.tag,
              title: 'Categoria correta',
              description: 'Ajuda a direcionar para a equipe certa',
            ),
            SizedBox(height: 16),
            _HelpItem(
              icon: PhosphorIcons.flag,
              title: 'Prioridade adequada',
              description:
                  'Baixa: Melhorias\nMédia: Problemas normais\nAlta: Impacta o trabalho\nUrgente: Sistema parado',
            ),
            SizedBox(height: 16),
            _HelpItem(
              icon: PhosphorIcons.notepad,
              title: 'Descrição detalhada',
              description: 'Incluir passos, comportamento esperado e atual',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendi'),
        ),
      ],
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData Function() icon;
  final String title;
  final String description;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: FormComponents.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon(),
            size: 16,
            color: FormComponents.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: FormComponents.textColor.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
