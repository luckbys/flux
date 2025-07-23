import 'package:flutter/material.dart';
import '../styles/design_tokens.dart';
import '../styles/micro_animations.dart';
import '../styles/accessible_components.dart';

/// Página de demonstração do novo sistema de design do BKCRM
/// Mostra todos os componentes, tokens e funcionalidades implementadas
class DesignShowcasePage extends StatefulWidget {
  const DesignShowcasePage({super.key});

  @override
  State<DesignShowcasePage> createState() => _DesignShowcasePageState();
}

class _DesignShowcasePageState extends State<DesignShowcasePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isDarkMode = false;
  bool _isLoading = false;
  bool _checkboxValue = false;
  String _radioValue = 'option1';
  bool _switchValue = false;
  double _sliderValue = 50.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Design BKCRM'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
              // Aqui você implementaria a mudança de tema real
              ScaffoldMessenger.of(context).showSnackBar(
                AccessibleComponents.snackBar(
                  message: _isDarkMode
                      ? 'Modo escuro ativado'
                      : 'Modo claro ativado',
                  actionLabel: 'Desfazer',
                  onActionPressed: () {
                    setState(() {
                      _isDarkMode = !_isDarkMode;
                    });
                  },
                ),
              );
            },
            tooltip: _isDarkMode ? 'Ativar modo claro' : 'Ativar modo escuro',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AccessibleComponents.dialog(
                  title: 'Sobre o Sistema de Design',
                  content:
                      'Este sistema implementa tokens de design consistentes, '
                      'modo escuro completo, acessibilidade WCAG 2.1 AA e '
                      'micro-animações para uma experiência superior.',
                  confirmText: 'Entendi',
                  onConfirm: () => Navigator.of(context).pop(),
                ),
              );
            },
            tooltip: 'Informações sobre o sistema de design',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Cores', icon: Icon(Icons.palette)),
            Tab(text: 'Tipografia', icon: Icon(Icons.text_fields)),
            Tab(text: 'Botões', icon: Icon(Icons.smart_button)),
            Tab(text: 'Formulários', icon: Icon(Icons.input)),
            Tab(text: 'Cards', icon: Icon(Icons.view_agenda)),
            Tab(text: 'Animações', icon: Icon(Icons.animation)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildColorsTab(),
          _buildTypographyTab(),
          _buildButtonsTab(),
          _buildFormsTab(),
          _buildCardsTab(),
          _buildAnimationsTab(),
        ],
      ),
      floatingActionButton: MicroAnimations.animatedButton(
        onPressed: () {
          _showDesignSystemInfo();
        },
        child: const FloatingActionButton.extended(
          onPressed: null, // Controlado pelo wrapper
          icon: Icon(Icons.help_outline),
          label: Text('Ajuda'),
        ),
      ),
    );
  }

  Widget _buildColorsTab() {
    return MicroAnimations.fadeIn(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Cores Primárias'),
            const SizedBox(height: DesignTokens.space16),
            _buildColorPalette('Primary', [
              DesignTokens.primary50,
              DesignTokens.primary100,
              DesignTokens.primary200,
              DesignTokens.primary300,
              DesignTokens.primary400,
              DesignTokens.primary500,
              DesignTokens.primary600,
              DesignTokens.primary700,
              DesignTokens.primary800,
              DesignTokens.primary900,
            ]),
            const SizedBox(height: DesignTokens.space24),
            _buildSectionTitle('Cores Secundárias'),
            const SizedBox(height: DesignTokens.space16),
            _buildColorPalette('Secondary', [
              DesignTokens.secondary50,
              DesignTokens.secondary100,
              DesignTokens.secondary200,
              DesignTokens.secondary300,
              DesignTokens.secondary400,
              DesignTokens.secondary500,
              DesignTokens.secondary600,
              DesignTokens.secondary700,
              DesignTokens.secondary800,
              DesignTokens.secondary900,
            ]),
            const SizedBox(height: DesignTokens.space24),
            _buildSectionTitle('Cores de Estado'),
            const SizedBox(height: DesignTokens.space16),
            Row(
              children: [
                Expanded(
                    child: _buildColorCard('Success', DesignTokens.success500)),
                const SizedBox(width: DesignTokens.space12),
                Expanded(
                    child: _buildColorCard('Warning', DesignTokens.warning500)),
                const SizedBox(width: DesignTokens.space12),
                Expanded(
                    child: _buildColorCard('Error', DesignTokens.error500)),
                const SizedBox(width: DesignTokens.space12),
                Expanded(child: _buildColorCard('Info', DesignTokens.info500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypographyTab() {
    return MicroAnimations.slideIn(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Hierarquia Tipográfica'),
            const SizedBox(height: DesignTokens.space24),
            _buildTypographyExample(
                'Display Large', Theme.of(context).textTheme.displayLarge),
            _buildTypographyExample(
                'Display Medium', Theme.of(context).textTheme.displayMedium),
            _buildTypographyExample(
                'Display Small', Theme.of(context).textTheme.displaySmall),
            _buildTypographyExample(
                'Headline Large', Theme.of(context).textTheme.headlineLarge),
            _buildTypographyExample(
                'Headline Medium', Theme.of(context).textTheme.headlineMedium),
            _buildTypographyExample(
                'Headline Small', Theme.of(context).textTheme.headlineSmall),
            _buildTypographyExample(
                'Title Large', Theme.of(context).textTheme.titleLarge),
            _buildTypographyExample(
                'Title Medium', Theme.of(context).textTheme.titleMedium),
            _buildTypographyExample(
                'Title Small', Theme.of(context).textTheme.titleSmall),
            _buildTypographyExample(
                'Body Large', Theme.of(context).textTheme.bodyLarge),
            _buildTypographyExample(
                'Body Medium', Theme.of(context).textTheme.bodyMedium),
            _buildTypographyExample(
                'Body Small', Theme.of(context).textTheme.bodySmall),
            _buildTypographyExample(
                'Label Large', Theme.of(context).textTheme.labelLarge),
            _buildTypographyExample(
                'Label Medium', Theme.of(context).textTheme.labelMedium),
            _buildTypographyExample(
                'Label Small', Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonsTab() {
    return MicroAnimations.scaleIn(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Botões Acessíveis'),
            const SizedBox(height: DesignTokens.space24),
            _buildSubsectionTitle('Botões Primários'),
            const SizedBox(height: DesignTokens.space12),
            Wrap(
              spacing: DesignTokens.space12,
              runSpacing: DesignTokens.space12,
              children: [
                AccessibleComponents.primaryButton(
                  text: 'Primário',
                  onPressed: () {},
                  tooltip: 'Botão de ação principal',
                ),
                AccessibleComponents.primaryButton(
                  text: 'Com Ícone',
                  onPressed: () {},
                  icon: Icons.star,
                  tooltip: 'Botão primário com ícone',
                ),
                AccessibleComponents.primaryButton(
                  text: 'Carregando',
                  onPressed: () {},
                  isLoading: _isLoading,
                  tooltip: 'Botão com estado de carregamento',
                ),
                AccessibleComponents.primaryButton(
                  text: 'Desabilitado',
                  onPressed: null,
                  tooltip: 'Botão desabilitado',
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space24),
            _buildSubsectionTitle('Botões Secundários'),
            const SizedBox(height: DesignTokens.space12),
            Wrap(
              spacing: DesignTokens.space12,
              runSpacing: DesignTokens.space12,
              children: [
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
              ],
            ),
            const SizedBox(height: DesignTokens.space24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = !_isLoading;
                });
              },
              child: Text(
                  _isLoading ? 'Parar Carregamento' : 'Iniciar Carregamento'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormsTab() {
    return MicroAnimations.enterAnimation(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Componentes de Formulário'),
            const SizedBox(height: DesignTokens.space24),
            _buildSubsectionTitle('Campos de Texto'),
            const SizedBox(height: DesignTokens.space12),
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
            const SizedBox(height: DesignTokens.space24),
            _buildSubsectionTitle('Componentes de Seleção'),
            const SizedBox(height: DesignTokens.space12),
            AccessibleComponents.checkbox(
              label: 'Aceito os termos e condições',
              value: _checkboxValue,
              onChanged: (value) {
                setState(() {
                  _checkboxValue = value ?? false;
                });
              },
            ),
            const SizedBox(height: DesignTokens.space12),
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
            const SizedBox(height: DesignTokens.space12),
            AccessibleComponents.switch_(
              label: 'Receber notificações',
              value: _switchValue,
              onChanged: (value) {
                setState(() {
                  _switchValue = value;
                });
              },
            ),
            const SizedBox(height: DesignTokens.space24),
            _buildSubsectionTitle('Slider'),
            const SizedBox(height: DesignTokens.space12),
            Semantics(
              label: 'Controle deslizante de valor',
              value: 'Valor atual: ${_sliderValue.round()}',
              child: Slider(
                value: _sliderValue,
                min: 0,
                max: 100,
                divisions: 10,
                label: _sliderValue.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsTab() {
    return MicroAnimations.fadeIn(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Cards e Componentes'),
            const SizedBox(height: DesignTokens.space24),
            _buildSubsectionTitle('Cards Básicos'),
            const SizedBox(height: DesignTokens.space12),
            AccessibleComponents.card(
              semanticLabel: 'Card de exemplo',
              tooltip: 'Card com conteúdo de exemplo',
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Título do Card',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: DesignTokens.space8),
                    Text(
                      'Este é um exemplo de card acessível com semântica adequada '
                      'e suporte a navegação por teclado.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: DesignTokens.space16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AccessibleComponents.textButton(
                          text: 'Cancelar',
                          onPressed: () {},
                        ),
                        const SizedBox(width: DesignTokens.space8),
                        AccessibleComponents.primaryButton(
                          text: 'Confirmar',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space24),
            _buildSubsectionTitle('List Tiles'),
            const SizedBox(height: DesignTokens.space12),
            AccessibleComponents.listTile(
              title: 'Item de Lista 1',
              subtitle: 'Descrição do primeiro item',
              leading: const Icon(Icons.person),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
            const SizedBox(height: DesignTokens.space8),
            AccessibleComponents.listTile(
              title: 'Item de Lista 2',
              subtitle: 'Descrição do segundo item',
              leading: const Icon(Icons.settings),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationsTab() {
    return MicroAnimations.slideIn(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Micro-animações'),
            const SizedBox(height: DesignTokens.space24),
            _buildSubsectionTitle('Animações de Entrada'),
            const SizedBox(height: DesignTokens.space12),
            Row(
              children: [
                Expanded(
                  child: MicroAnimations.fadeIn(
                    child: _buildAnimationCard('Fade In', Icons.visibility),
                  ),
                ),
                const SizedBox(width: DesignTokens.space12),
                Expanded(
                  child: MicroAnimations.slideIn(
                    child: _buildAnimationCard('Slide In', Icons.trending_up),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space12),
            Row(
              children: [
                Expanded(
                  child: MicroAnimations.scaleIn(
                    child: _buildAnimationCard('Scale In', Icons.zoom_in),
                  ),
                ),
                const SizedBox(width: DesignTokens.space12),
                Expanded(
                  child: MicroAnimations.enterAnimation(
                    child: _buildAnimationCard('Combined', Icons.auto_awesome),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space24),
            _buildSubsectionTitle('Animações de Interação'),
            const SizedBox(height: DesignTokens.space12),
            Row(
              children: [
                Expanded(
                  child: MicroAnimations.pulse(
                    child: _buildAnimationCard('Pulse', Icons.favorite,
                        color: DesignTokens.error500),
                  ),
                ),
                const SizedBox(width: DesignTokens.space12),
                Expanded(
                  child: MicroAnimations.bounce(
                    child: _buildAnimationCard(
                        'Bounce', Icons.sports_basketball,
                        color: DesignTokens.warning500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space12),
            Row(
              children: [
                Expanded(
                  child: MicroAnimations.shake(
                    child: _buildAnimationCard('Shake', Icons.vibration,
                        color: DesignTokens.info500),
                  ),
                ),
                const SizedBox(width: DesignTokens.space12),
                Expanded(
                  child: MicroAnimations.shimmer(
                    child: _buildAnimationCard('Shimmer', Icons.auto_fix_high,
                        color: DesignTokens.success500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space24),
            _buildSubsectionTitle('Botões Animados'),
            const SizedBox(height: DesignTokens.space12),
            Center(
              child: MicroAnimations.animatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    AccessibleComponents.snackBar(
                      message: 'Botão animado pressionado!',
                      actionLabel: 'OK',
                      onActionPressed: () {},
                    ),
                  );
                },
                child: ElevatedButton.icon(
                  onPressed: null, // Controlado pelo wrapper
                  icon: const Icon(Icons.touch_app),
                  label: const Text('Botão Animado'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightBold,
          ),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
    );
  }

  Widget _buildColorPalette(String name, List<Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: DesignTokens.space8),
        Row(
          children: colors.map((color) {
            final index = colors.indexOf(color);
            final shade = (index + 1) * 100;
            if (index == 4) {
              // 500 é o índice 4
              return Expanded(
                child: _buildColorCard('$shade', color, isMain: true),
              );
            }
            return Expanded(
              child: _buildColorCard('$shade', color),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorCard(String name, Color color, {bool isMain = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: AspectRatio(
        aspectRatio: isMain ? 1.2 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            border: isMain
                ? Border.all(
                    color: DesignTokens.getAccessibleTextColor(color),
                    width: DesignTokens.borderWidth2,
                  )
                : null,
          ),
          child: Center(
            child: Text(
              name,
              style: TextStyle(
                color: DesignTokens.getAccessibleTextColor(color),
                fontWeight: isMain
                    ? DesignTokens.fontWeightBold
                    : DesignTokens.fontWeightMedium,
                fontSize:
                    isMain ? DesignTokens.fontSize12 : DesignTokens.fontSize10,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypographyExample(String name, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            'The quick brown fox jumps over the lazy dog',
            style: style,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationCard(String title, IconData icon, {Color? color}) {
    return AccessibleComponents.card(
      semanticLabel: 'Card de animação $title',
      tooltip: 'Demonstração da animação $title',
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: color ?? DesignTokens.primary500,
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showDesignSystemInfo() {
    showDialog(
      context: context,
      builder: (context) => AccessibleComponents.dialog(
        title: 'Sistema de Design BKCRM',
        content: 'Este sistema implementa:\n\n'
            '• Tokens de design consistentes\n'
            '• Modo escuro completo\n'
            '• Acessibilidade WCAG 2.1 AA\n'
            '• Micro-animações\n'
            '• Componentes reutilizáveis\n'
            '• Tipografia otimizada\n'
            '• Paleta de cores semântica',
        confirmText: 'Fechar',
        onConfirm: () => Navigator.of(context).pop(),
      ),
    );
  }
}
