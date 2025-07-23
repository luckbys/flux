import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'enhanced_theme.dart';
import 'micro_animations.dart';
import 'accessible_components.dart';

/// Exemplo de uso do novo sistema de design do BKCRM
/// Demonstra tokens de design, modo escuro, acessibilidade e micro-animações
class DesignSystemExample extends StatefulWidget {
  const DesignSystemExample({super.key});

  @override
  State<DesignSystemExample> createState() => _DesignSystemExampleState();
}

class _DesignSystemExampleState extends State<DesignSystemExample> {
  bool _isDarkMode = false;
  bool _isLoading = false;
  bool _checkboxValue = false;
  String _radioValue = 'option1';
  bool _switchValue = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BKCRM Design System',
      theme: EnhancedTheme.lightTheme,
      darkTheme: EnhancedTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Design System BKCRM'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
              tooltip: _isDarkMode ? 'Modo claro' : 'Modo escuro',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção de Cores
              _buildSection(
                title: 'Cores do Sistema',
                child: _buildColorsSection(),
              ),

              const SizedBox(height: DesignTokens.space32),

              // Seção de Tipografia
              _buildSection(
                title: 'Tipografia',
                child: _buildTypographySection(),
              ),

              const SizedBox(height: DesignTokens.space32),

              // Seção de Botões
              _buildSection(
                title: 'Botões Acessíveis',
                child: _buildButtonsSection(),
              ),

              const SizedBox(height: DesignTokens.space32),

              // Seção de Campos de Input
              _buildSection(
                title: 'Campos de Input',
                child: _buildInputSection(),
              ),

              const SizedBox(height: DesignTokens.space32),

              // Seção de Componentes de Seleção
              _buildSection(
                title: 'Componentes de Seleção',
                child: _buildSelectionSection(),
              ),

              const SizedBox(height: DesignTokens.space32),

              // Seção de Cards e Animações
              _buildSection(
                title: 'Cards e Micro-animações',
                child: _buildCardsSection(),
              ),

              const SizedBox(height: DesignTokens.space32),

              // Seção de Espaçamentos
              _buildSection(
                title: 'Espaçamentos',
                child: _buildSpacingSection(),
              ),

              const SizedBox(height: DesignTokens.space32),

              // Seção de Acessibilidade
              _buildSection(
                title: 'Recursos de Acessibilidade',
                child: _buildAccessibilitySection(),
              ),
            ],
          ),
        ),
        floatingActionButton: MicroAnimations.animatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              AccessibleComponents.snackBar(
                message: 'Exemplo de feedback acessível!',
                actionLabel: 'Desfazer',
                onActionPressed: () {},
              ),
            );
          },
          child: const FloatingActionButton(
            onPressed: null, // Controlado pelo wrapper
            child: Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return MicroAnimations.enterAnimation(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: DesignTokens.space16),
          child,
        ],
      ),
    );
  }

  Widget _buildColorsSection() {
    return Wrap(
      spacing: DesignTokens.space12,
      runSpacing: DesignTokens.space12,
      children: [
        _buildColorCard('Primary', DesignTokens.primary500),
        _buildColorCard('Secondary', DesignTokens.secondary500),
        _buildColorCard('Success', DesignTokens.success500),
        _buildColorCard('Warning', DesignTokens.warning500),
        _buildColorCard('Error', DesignTokens.error500),
        _buildColorCard('Info', DesignTokens.info500),
      ],
    );
  }

  Widget _buildColorCard(String name, Color color) {
    return AccessibleComponents.card(
      semanticLabel: 'Cor $name',
      child: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              color: DesignTokens.getAccessibleTextColor(color),
              fontWeight: DesignTokens.fontWeightMedium,
              fontSize: DesignTokens.fontSize12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypographySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Display Large', style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: DesignTokens.space8),
        Text('Headline Large',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: DesignTokens.space8),
        Text('Title Large', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: DesignTokens.space8),
        Text('Body Large', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: DesignTokens.space8),
        Text('Body Medium', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: DesignTokens.space8),
        Text('Label Small', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _buildButtonsSection() {
    return Wrap(
      spacing: DesignTokens.space12,
      runSpacing: DesignTokens.space12,
      children: [
        AccessibleComponents.primaryButton(
          text: 'Primário',
          onPressed: () {},
          tooltip: 'Botão de ação principal',
          icon: Icons.star,
        ),
        AccessibleComponents.secondaryButton(
          text: 'Secundário',
          onPressed: () {},
          tooltip: 'Botão de ação secundária',
        ),
        AccessibleComponents.textButton(
          text: 'Texto',
          onPressed: () {},
          tooltip: 'Botão de texto',
        ),
        AccessibleComponents.primaryButton(
          text: 'Carregando',
          onPressed: () {},
          isLoading: _isLoading,
          tooltip: 'Botão com estado de carregamento',
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isLoading = !_isLoading;
            });
          },
          child: Text(_isLoading ? 'Parar' : 'Carregar'),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        AccessibleComponents.textField(
          label: 'Nome completo',
          hint: 'Digite seu nome completo',
          helperText: 'Este campo é obrigatório',
          required: true,
        ),
        const SizedBox(height: DesignTokens.space16),
        AccessibleComponents.textField(
          label: 'Email',
          hint: 'exemplo@email.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email),
        ),
        const SizedBox(height: DesignTokens.space16),
        AccessibleComponents.textField(
          label: 'Senha',
          hint: 'Digite sua senha',
          obscureText: true,
          suffixIcon: const Icon(Icons.visibility),
        ),
        const SizedBox(height: DesignTokens.space16),
        AccessibleComponents.textField(
          label: 'Comentários',
          hint: 'Digite seus comentários aqui...',
          maxLines: 3,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildSelectionSection() {
    return Column(
      children: [
        AccessibleComponents.checkbox(
          label: 'Aceito os termos e condições',
          value: _checkboxValue,
          onChanged: (value) {
            setState(() {
              _checkboxValue = value ?? false;
            });
          },
        ),
        const SizedBox(height: DesignTokens.space16),
        AccessibleComponents.radio<String>(
          label: 'Opção 1',
          value: 'option1',
          groupValue: _radioValue,
          onChanged: (value) {
            setState(() {
              _radioValue = value ?? 'option1';
            });
          },
        ),
        AccessibleComponents.radio<String>(
          label: 'Opção 2',
          value: 'option2',
          groupValue: _radioValue,
          onChanged: (value) {
            setState(() {
              _radioValue = value ?? 'option1';
            });
          },
        ),
        const SizedBox(height: DesignTokens.space16),
        AccessibleComponents.switch_(
          label: 'Receber notificações',
          value: _switchValue,
          onChanged: (value) {
            setState(() {
              _switchValue = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCardsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MicroAnimations.fadeIn(
                child: AccessibleComponents.card(
                  semanticLabel: 'Card com fade in',
                  tooltip: 'Card com animação de fade in',
                  child: const Padding(
                    padding: EdgeInsets.all(DesignTokens.space16),
                    child: Column(
                      children: [
                        Icon(Icons.animation, size: 32),
                        SizedBox(height: DesignTokens.space8),
                        Text('Fade In'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.space12),
            Expanded(
              child: MicroAnimations.slideIn(
                child: AccessibleComponents.card(
                  semanticLabel: 'Card com slide in',
                  tooltip: 'Card com animação de slide in',
                  child: const Padding(
                    padding: EdgeInsets.all(DesignTokens.space16),
                    child: Column(
                      children: [
                        Icon(Icons.trending_up, size: 32),
                        SizedBox(height: DesignTokens.space8),
                        Text('Slide In'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.space16),
        Row(
          children: [
            Expanded(
              child: MicroAnimations.scaleIn(
                child: AccessibleComponents.card(
                  semanticLabel: 'Card com scale in',
                  tooltip: 'Card com animação de scale in',
                  child: const Padding(
                    padding: EdgeInsets.all(DesignTokens.space16),
                    child: Column(
                      children: [
                        Icon(Icons.zoom_in, size: 32),
                        SizedBox(height: DesignTokens.space8),
                        Text('Scale In'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.space12),
            Expanded(
              child: MicroAnimations.pulse(
                child: AccessibleComponents.card(
                  semanticLabel: 'Card com pulse',
                  tooltip: 'Card com animação de pulse',
                  child: const Padding(
                    padding: EdgeInsets.all(DesignTokens.space16),
                    child: Column(
                      children: [
                        Icon(Icons.favorite,
                            size: 32, color: DesignTokens.error500),
                        SizedBox(height: DesignTokens.space8),
                        Text('Pulse'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpacingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Espaçamentos do Design System:',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: DesignTokens.space12),
        _buildSpacingExample('XS', DesignTokens.space4),
        _buildSpacingExample('SM', DesignTokens.space8),
        _buildSpacingExample('MD', DesignTokens.space12),
        _buildSpacingExample('LG', DesignTokens.space16),
        _buildSpacingExample('XL', DesignTokens.space24),
        _buildSpacingExample('2XL', DesignTokens.space32),
      ],
    );
  }

  Widget _buildSpacingExample(String name, double spacing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.space4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(name, style: Theme.of(context).textTheme.labelSmall),
          ),
          Container(
            width: spacing,
            height: 20,
            color: DesignTokens.primary500,
          ),
          const SizedBox(width: DesignTokens.space8),
          Text('${spacing.toInt()}px',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildAccessibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recursos implementados:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: DesignTokens.space12),
        _buildAccessibilityFeature(
          'Contraste WCAG 2.1 AA',
          'Todas as cores atendem aos requisitos mínimos de contraste',
          Icons.contrast,
        ),
        _buildAccessibilityFeature(
          'Tamanhos de toque mínimos',
          'Todos os elementos interativos têm pelo menos 44x44px',
          Icons.touch_app,
        ),
        _buildAccessibilityFeature(
          'Navegação por teclado',
          'Todos os componentes são navegáveis via teclado',
          Icons.keyboard,
        ),
        _buildAccessibilityFeature(
          'Leitores de tela',
          'Semântica completa para tecnologias assistivas',
          Icons.accessibility,
        ),
        _buildAccessibilityFeature(
          'Feedback de estado',
          'Estados visuais e semânticos claros para todas as interações',
          Icons.feedback,
        ),
        const SizedBox(height: DesignTokens.space16),
        AccessibleComponents.primaryButton(
          text: 'Testar Dialog Acessível',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AccessibleComponents.dialog(
                title: 'Exemplo de Dialog',
                content:
                    'Este é um exemplo de dialog acessível com navegação por teclado e semântica adequada.',
                confirmText: 'Confirmar',
                cancelText: 'Cancelar',
                onConfirm: () => Navigator.of(context).pop(),
                onCancel: () => Navigator.of(context).pop(),
              ),
            );
          },
          icon: Icons.open_in_new,
        ),
      ],
    );
  }

  Widget _buildAccessibilityFeature(
      String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: DesignTokens.success500,
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
