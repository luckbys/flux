import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../../widgets/form_components.dart';
import 'ticket_modal_components.dart';
import 'ticket_modal_sidebar.dart';

// =============================================================================
// TICKET FORM MODAL - VERSÃO REFATORADA
// =============================================================================

class TicketFormModal extends StatefulWidget {
  final Ticket? ticket;
  final List<User> availableAgents;
  final Function(TicketFormData)? onSubmit;
  final VoidCallback? onCancel;

  const TicketFormModal({
    super.key,
    this.ticket,
    this.availableAgents = const [],
    this.onSubmit,
    this.onCancel,
  });

  @override
  State<TicketFormModal> createState() => _TicketFormModalState();

  static Future<T?> show<T>({
    required BuildContext context,
    Ticket? ticket,
    List<User> availableAgents = const [],
    Function(TicketFormData)? onSubmit,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TicketFormModal(
        ticket: ticket,
        availableAgents: availableAgents,
        onSubmit: onSubmit,
      ),
    );
  }
}

class _TicketFormModalState extends State<TicketFormModal>
    with TickerProviderStateMixin {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Form State
  TicketPriority _selectedPriority = TicketPriority.normal;
  TicketCategory _selectedCategory = TicketCategory.general;
  TicketStatus _selectedStatus = TicketStatus.open;
  User? _selectedAgent;
  List<TicketTag> _selectedTags = [];
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _isLoading = false;
  final bool _isDraft = false;

  // Animations
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Responsive
  late ResponsiveLayout _layout;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeForm();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateLayout();
  }

  void _updateLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    _layout = ResponsiveLayout.fromScreenWidth(screenWidth);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
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
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        await Future.delayed(const Duration(milliseconds: 1500));

        final formData = TicketFormData(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          category: _selectedCategory,
          status: _selectedStatus,
          assignedAgent: _selectedAgent,
          tags: _selectedTags,
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          emailNotifications: _emailNotifications,
          smsNotifications: _smsNotifications,
        );

        widget.onSubmit?.call(formData);

        if (mounted) {
          _showSuccessMessage();
          Navigator.of(context).pop(formData);
        }
      } catch (e) {
        if (mounted) {
          _showErrorMessage();
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(widget.ticket != null
                ? 'Ticket atualizado com sucesso!'
                : 'Ticket criado com sucesso!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Text('Erro ao salvar ticket. Tente novamente.'),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_layout.borderRadius),
              ),
              elevation: _layout.elevation,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: _layout.constraints,
                decoration: _layout.decoration,
                child: _layout.isDesktop
                    ? _buildDesktopLayout()
                    : _buildMobileLayout(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Formulário Principal
        Expanded(
          flex: 3,
          child: Column(
            children: [
              TicketModalHeader(
                ticket: widget.ticket,
                onClose: () => Navigator.of(context).pop(),
                onHelp: _showHelpDialog,
                layout: _layout,
              ),
              Expanded(
                child: TicketFormContent(
                  formKey: _formKey,
                  titleController: _titleController,
                  descriptionController: _descriptionController,
                  emailController: _emailController,
                  phoneController: _phoneController,
                  selectedPriority: _selectedPriority,
                  selectedCategory: _selectedCategory,
                  selectedStatus: _selectedStatus,
                  selectedAgent: _selectedAgent,
                  availableAgents: widget.availableAgents,
                  emailNotifications: _emailNotifications,
                  smsNotifications: _smsNotifications,
                  isDraft: _isDraft,
                  isEditing: widget.ticket != null,
                  onPriorityChanged: (priority) =>
                      setState(() => _selectedPriority = priority),
                  onCategoryChanged: (category) =>
                      setState(() => _selectedCategory = category),
                  onStatusChanged: (status) =>
                      setState(() => _selectedStatus = status),
                  onAgentChanged: (agent) =>
                      setState(() => _selectedAgent = agent),
                  onEmailNotificationsChanged: (value) =>
                      setState(() => _emailNotifications = value),
                  onSmsNotificationsChanged: (value) =>
                      setState(() => _smsNotifications = value),
                  layout: _layout,
                ),
              ),
            ],
          ),
        ),
        // Sidebar
        TicketModalSidebar(
          titleController: _titleController,
          descriptionController: _descriptionController,
          selectedPriority: _selectedPriority,
          selectedCategory: _selectedCategory,
          onSubmit: _handleSubmit,
          onCancel: () => Navigator.of(context).pop(),
          isLoading: _isLoading,
          isEditing: widget.ticket != null,
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TicketModalHeader(
          ticket: widget.ticket,
          onClose: () => Navigator.of(context).pop(),
          onHelp: _showHelpDialog,
          layout: _layout,
        ),
        Flexible(
          child: TicketFormContent(
            formKey: _formKey,
            titleController: _titleController,
            descriptionController: _descriptionController,
            emailController: _emailController,
            phoneController: _phoneController,
            selectedPriority: _selectedPriority,
            selectedCategory: _selectedCategory,
            selectedStatus: _selectedStatus,
            selectedAgent: _selectedAgent,
            availableAgents: widget.availableAgents,
            emailNotifications: _emailNotifications,
            smsNotifications: _smsNotifications,
            isDraft: _isDraft,
            isEditing: widget.ticket != null,
            onPriorityChanged: (priority) =>
                setState(() => _selectedPriority = priority),
            onCategoryChanged: (category) =>
                setState(() => _selectedCategory = category),
            onStatusChanged: (status) =>
                setState(() => _selectedStatus = status),
            onAgentChanged: (agent) => setState(() => _selectedAgent = agent),
            onEmailNotificationsChanged: (value) =>
                setState(() => _emailNotifications = value),
            onSmsNotificationsChanged: (value) =>
                setState(() => _smsNotifications = value),
            layout: _layout,
          ),
        ),
        TicketModalFooter(
          onSubmit: _handleSubmit,
          onCancel: () => Navigator.of(context).pop(),
          isLoading: _isLoading,
          isEditing: widget.ticket != null,
          layout: _layout,
        ),
      ],
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => const TicketHelpDialog(),
    );
  }
}

// =============================================================================
// RESPONSIVE LAYOUT
// =============================================================================

class ResponsiveLayout {
  final bool isDesktop;
  final bool isTablet;
  final bool isMobile;
  final double maxWidth;
  final double maxHeight;
  final double borderRadius;
  final double elevation;
  final EdgeInsets padding;
  final double spacing;

  ResponsiveLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.isMobile,
    required this.maxWidth,
    required this.maxHeight,
    required this.borderRadius,
    required this.elevation,
    required this.padding,
    required this.spacing,
  });

  factory ResponsiveLayout.fromScreenWidth(double screenWidth) {
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;
    final isMobile = screenWidth <= 768;

    return ResponsiveLayout(
      isDesktop: isDesktop,
      isTablet: isTablet,
      isMobile: isMobile,
      maxWidth: isDesktop ? 1200 : (isTablet ? 800 : double.infinity),
      maxHeight: isDesktop ? 900 : (isTablet ? 850 : 950),
      borderRadius: isDesktop ? 24 : 20,
      elevation: isDesktop ? 24 : 16,
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      spacing: isDesktop ? 24 : 16,
    );
  }

  BoxConstraints get constraints => BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

  BoxDecoration get decoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: elevation,
            offset: Offset(0, elevation / 2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: elevation / 2,
            offset: Offset(0, elevation / 4),
            spreadRadius: 0,
          ),
        ],
      );
}

// =============================================================================
// TICKET FORM DATA
// =============================================================================

class TicketFormData {
  final String title;
  final String description;
  final TicketPriority priority;
  final TicketCategory category;
  final TicketStatus status;
  final User? assignedAgent;
  final List<TicketTag> tags;
  final String email;
  final String phone;
  final bool emailNotifications;
  final bool smsNotifications;

  const TicketFormData({
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.status,
    this.assignedAgent,
    this.tags = const [],
    required this.email,
    this.phone = '',
    this.emailNotifications = true,
    this.smsNotifications = false,
  });
}
