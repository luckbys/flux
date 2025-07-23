import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../stores/auth_store.dart';
import '../../components/ui/enhanced_text_field.dart';
import '../../components/ui/toast_message.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  late PageController _tipCarouselController;

  int _currentTipIndex = 0;
  Timer? _tipTimer;

  final List<Map<String, dynamic>> _tipCards = [
    {
      'icon': PhosphorIcons.users(),
      'title': 'Gestão de Clientes',
      'description':
          'Centralize todas as informações dos seus clientes em um só lugar. Histórico completo, dados de contato e interações organizadas.',
      'color': const Color(0xFF3B82F6),
      'benefits': ['Histórico completo', 'Dados organizados', 'Fácil acesso']
    },
    {
      'icon': PhosphorIcons.chatCircle(),
      'title': 'Atendimento Integrado',
      'description':
          'Unifique todos os canais de atendimento. WhatsApp, email, telefone e chat web em uma única interface intuitiva.',
      'color': const Color(0xFF10B981),
      'benefits': ['Múltiplos canais', 'Interface única', 'Resposta rápida']
    },
    {
      'icon': PhosphorIcons.chartLine(),
      'title': 'Relatórios Avançados',
      'description':
          'Acompanhe métricas importantes do seu negócio. Dashboards interativos com insights valiosos para tomada de decisão.',
      'color': const Color(0xFF8B5CF6),
      'benefits': [
        'Métricas em tempo real',
        'Insights valiosos',
        'Decisões assertivas'
      ]
    },
    {
      'icon': PhosphorIcons.whatsappLogo(),
      'title': 'Integração WhatsApp Business',
      'description':
          'Conecte seu WhatsApp Business diretamente na plataforma. Gerencie conversas, automatize respostas e mantenha todo o atendimento centralizado.',
      'color': const Color(0xFF059669),
      'benefits': [
        'Conversas centralizadas',
        'Respostas automáticas',
        'Integração nativa'
      ]
    },
    {
      'icon': PhosphorIcons.robot(),
      'title': 'Automação Inteligente',
      'description':
          'Automatize tarefas repetitivas e workflows complexos. Aumente a produtividade da sua equipe com processos inteligentes.',
      'color': const Color(0xFFEF4444),
      'benefits': [
        'Workflows automáticos',
        'Maior produtividade',
        'Menos trabalho manual'
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedCredentials();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _tipCarouselController = PageController();

    _fadeController.forward();
    _slideController.forward();
    _startTipCarousel();
  }

  void _startTipCarousel() {
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_tipCarouselController.hasClients) {
        final nextIndex = (_currentTipIndex + 1) % _tipCards.length;
        _tipCarouselController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onTipPageChanged(int index) {
    setState(() {
      _currentTipIndex = index;
    });
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (rememberMe && savedEmail != null) {
        _emailController.text = savedEmail;
        setState(() {
          _rememberMe = true;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar credenciais: $e');
    }
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authStore = Provider.of<AuthStore>(context, listen: false);

    try {
      _buttonController.forward();

      // Salvar credenciais se solicitado
      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', _emailController.text);
        await prefs.setBool('remember_me', true);
      } else {
        // Limpar credenciais se não marcado
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_email');
        await prefs.setBool('remember_me', false);
      }

      // Tentar login
      final success = await authStore.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success) {
        if (mounted) {
          ToastMessage.show(
            context,
            message: 'Login realizado com sucesso!',
            type: ToastType.success,
          );
          // A navegação é automática através do AuthWrapper
          // O AuthStore já atualiza o estado para AuthState.authenticated
          // e o AuthWrapper redireciona automaticamente para MainLayout
          debugPrint(
              '✅ Login bem-sucedido - AuthWrapper deve redirecionar automaticamente');
        }
      } else {
        setState(() {
          _errorMessage = 'Email ou senha incorretos';
        });
        if (mounted) {
          ToastMessage.show(
            context,
            message: 'Email ou senha incorretos',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão. Tente novamente.';
      });
      if (mounted) {
        ToastMessage.show(
          context,
          message: 'Erro de conexão. Tente novamente.',
          type: ToastType.error,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      _buttonController.reverse();
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Recuperar Senha',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Digite seu email para receber um link de recuperação de senha.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Digite seu email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(PhosphorIcons.envelope()),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implementar envio de email de recuperação
                Navigator.of(context).pop();
                ToastMessage.show(
                  context,
                  message: 'Email de recuperação enviado!',
                  type: ToastType.success,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Enviar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _buttonController.dispose();
    _tipCarouselController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _tipTimer?.cancel();
    super.dispose();
  }

  /// Método estático para limpar dados do "Lembrar de mim"
  static Future<void> clearRememberMeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_email');
      await prefs.remove('remember_me');
    } catch (e) {
      debugPrint('Erro ao limpar dados do "Lembrar de mim": $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStore>(builder: (context, authStore, child) {
      return Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 1200) {
              return _buildDesktopLayout(authStore);
            } else if (constraints.maxWidth > 600) {
              return _buildTabletLayout(authStore);
            } else {
              return _buildMobileLayout(authStore);
            }
          },
        ),
      );
    });
  }

  Widget _buildDesktopLayout(AuthStore authStore) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF334155),
            Color(0xFF475569),
            Color(0xFF1E293B),
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Lado esquerdo - Formulário de login (branco)
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo BKCRM
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF3B82F6),
                                  Color(0xFF1D4ED8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              PhosphorIcons.headset(),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'BKCRM',
                            style: TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // Título
                      const Text(
                        'Entre na sua conta',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bem-vindo de volta! Digite suas informações.',
                        style: TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Formulário
                      _buildCleanLoginForm(authStore),
                    ],
                  ),
                ),
              ),
            ),
            // Lado direito - Carrossel de dicas
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título principal
                      const Text(
                        'Transforme Cliques\nEm Clientes\nFacilmente',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      // Carrossel de cards
                      Expanded(
                        child: PageView.builder(
                          controller: _tipCarouselController,
                          onPageChanged: _onTipPageChanged,
                          itemCount: _tipCards.length,
                          itemBuilder: (context, index) {
                            final tip = _tipCards[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: _buildTipCard(
                                icon: tip['icon'] as IconData,
                                title: tip['title'] as String,
                                description: tip['description'] as String,
                                color: tip['color'] as Color,
                                benefits: tip['benefits'] as List<String>,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Indicadores de página
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _tipCards.length,
                          (index) => GestureDetector(
                            onTap: () {
                              _tipCarouselController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentTipIndex == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: _currentTipIndex == index
                                    ? const Color(0xFF10B981)
                                    : Colors.white.withValues(alpha: 0.2),
                                boxShadow: _currentTipIndex == index
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(AuthStore authStore) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF334155),
            Color(0xFF475569),
            Color(0xFF1E293B),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            margin: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(60.0),
              child: _buildCleanLoginForm(authStore),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(AuthStore authStore) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF334155),
            Color(0xFF475569),
            Color(0xFF1E293B),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // Header
              _buildMobileHeader(),
              const SizedBox(height: 40),
              // Formulário
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: _buildCleanLoginForm(authStore),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        // Logo
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3B82F6),
                    Color(0xFF1D4ED8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                PhosphorIcons.headset(),
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'BKCRM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Título
        const Text(
          'Entre na sua conta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bem-vindo de volta! Digite suas informações.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildCleanLoginForm(AuthStore authStore) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo de email
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: EnhancedTextField(
              controller: _emailController,
              labelText: 'Email',
              hintText: 'Digite seu email',
              prefixIcon: PhosphorIcons.envelope(),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email é obrigatório';
                }
                if (!_validateEmail(value)) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          // Campo de senha
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: EnhancedTextField(
              controller: _passwordController,
              labelText: 'Senha',
              hintText: 'Digite sua senha',
              prefixIcon: PhosphorIcons.lock(),
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? PhosphorIcons.eye()
                      : PhosphorIcons.eyeSlash(),
                  color: const Color(0xFF6B7280),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Senha é obrigatória';
                }
                if (!_validatePassword(value)) {
                  return 'Senha deve ter pelo menos 6 caracteres';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          // Lembrar-me e Esqueci a senha
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: const Color(0xFF3B82F6),
                checkColor: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text(
                'Lembrar por 30 dias',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showForgotPasswordDialog,
                child: const Text(
                  'Esqueci a senha',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          // Mensagem de erro
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFCA5A5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.warning(),
                    color: const Color(0xFFDC2626),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          // Botão de login
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF1D4ED8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Entrar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          // Link para cadastro
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Não tem uma conta? ",
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Implementar navegação para cadastro
                },
                child: const Text(
                  'Cadastre-se',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required List<String> benefits,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícone e título
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color.withValues(alpha: 0.2),
                                color.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Descrição
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Benefícios
                    ...benefits.map((benefit) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      color.withValues(alpha: 0.2),
                                      color.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  PhosphorIcons.check(),
                                  color: color,
                                  size: 10,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
