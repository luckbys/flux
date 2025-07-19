# Sistema de Design BKCRM

Este diretório contém a implementação completa do sistema de design do BKCRM, incluindo tokens de design consistentes, suporte completo ao modo escuro, acessibilidade WCAG 2.1 AA e micro-animações.

## 📁 Estrutura de Arquivos

### Arquivos Principais

- **`design_tokens.dart`** - Tokens de design fundamentais (cores, tipografia, espaçamentos, etc.)
- **`enhanced_theme.dart`** - Implementação do tema aprimorado usando os tokens
- **`micro_animations.dart`** - Componentes de animações micro-interativas
- **`accessible_components.dart`** - Componentes UI com foco em acessibilidade
- **`design_system_example.dart`** - Exemplo completo de uso do sistema

### Arquivos Legados

- **`app_theme.dart`** - Tema original (marcado como depreciado)

## 🎨 Design Tokens

### Cores Semânticas

```dart
// Cores primárias
DesignTokens.primary500    // Azul principal
DesignTokens.secondary500  // Roxo secundário

// Cores de estado
DesignTokens.success500    // Verde de sucesso
DesignTokens.warning500    // Amarelo de aviso
DesignTokens.error500      // Vermelho de erro
DesignTokens.info500       // Azul de informação

// Cores neutras (adaptáveis ao tema)
DesignTokens.neutral50     // Mais claro
DesignTokens.neutral900    // Mais escuro
```

### Tipografia

```dart
// Tamanhos de fonte
DesignTokens.fontSize12    // 12px
DesignTokens.fontSize14    // 14px
DesignTokens.fontSize16    // 16px (base)
DesignTokens.fontSize18    // 18px
DesignTokens.fontSize20    // 20px
DesignTokens.fontSize24    // 24px
DesignTokens.fontSize32    // 32px
DesignTokens.fontSize48    // 48px

// Pesos de fonte
DesignTokens.fontWeightRegular   // 400
DesignTokens.fontWeightMedium    // 500
DesignTokens.fontWeightSemiBold  // 600
DesignTokens.fontWeightBold      // 700

// Altura de linha (otimizada para acessibilidade)
DesignTokens.lineHeightTight     // 1.25
DesignTokens.lineHeightNormal    // 1.5
DesignTokens.lineHeightRelaxed   // 1.75
```

### Espaçamentos

```dart
DesignTokens.space4     // 4px
DesignTokens.space8     // 8px
DesignTokens.space12    // 12px
DesignTokens.space16    // 16px
DesignTokens.space20    // 20px
DesignTokens.space24    // 24px
DesignTokens.space32    // 32px
DesignTokens.space48    // 48px
DesignTokens.space64    // 64px
```

### Bordas e Raios

```dart
DesignTokens.radiusSm   // 4px
DesignTokens.radiusMd   // 8px
DesignTokens.radiusLg   // 12px
DesignTokens.radiusXl   // 16px
DesignTokens.radius2xl  // 24px
DesignTokens.radiusFull // 9999px (circular)

DesignTokens.borderWidth1  // 1px
DesignTokens.borderWidth2  // 2px
DesignTokens.borderWidth4  // 4px
```

## 🌙 Modo Escuro

O sistema suporta modo escuro completo com:

- Cores adaptáveis automaticamente
- Contraste otimizado para cada tema
- Transições suaves entre temas
- Preservação da hierarquia visual

### Uso

```dart
// Configuração do tema
MaterialApp(
  theme: EnhancedTheme.lightTheme,
  darkTheme: EnhancedTheme.darkTheme,
  themeMode: ThemeMode.system, // Segue o sistema
)

// Obter cores adaptáveis
Color backgroundColor = DesignTokens.getBackgroundColor(context);
Color textColor = DesignTokens.getTextColor(context);
```

## ♿ Acessibilidade (WCAG 2.1 AA)

### Recursos Implementados

- **Contraste de cores**: Todas as combinações atendem aos requisitos mínimos
- **Tamanhos de toque**: Mínimo de 44x44px para elementos interativos
- **Navegação por teclado**: Suporte completo
- **Leitores de tela**: Semântica adequada com `Semantics` widgets
- **Estados visuais**: Feedback claro para hover, focus, pressed, disabled

### Componentes Acessíveis

```dart
// Botões
AccessibleComponents.primaryButton(
  text: 'Confirmar',
  onPressed: () {},
  tooltip: 'Confirma a ação',
  icon: Icons.check,
)

// Campos de texto
AccessibleComponents.textField(
  label: 'Email',
  hint: 'Digite seu email',
  required: true,
  helperText: 'Campo obrigatório',
)

// Componentes de seleção
AccessibleComponents.checkbox(
  label: 'Aceito os termos',
  value: checked,
  onChanged: (value) => setState(() => checked = value),
)
```

### Utilitários de Acessibilidade

```dart
// Verificar contraste
bool hasGoodContrast = DesignTokens.meetsContrastRequirement(
  foreground: Colors.white,
  background: Colors.blue,
);

// Obter cor de texto acessível
Color textColor = DesignTokens.getAccessibleTextColor(backgroundColor);

// Tamanhos mínimos
double minTouchSize = DesignTokens.minTouchTarget; // 44px
```

## ✨ Micro-animações

### Animações de Entrada

```dart
// Fade in
MicroAnimations.fadeIn(
  child: YourWidget(),
)

// Slide in
MicroAnimations.slideIn(
  direction: SlideDirection.fromBottom,
  child: YourWidget(),
)

// Scale in
MicroAnimations.scaleIn(
  child: YourWidget(),
)

// Animação combinada
MicroAnimations.enterAnimation(
  child: YourWidget(),
)
```

### Animações de Interação

```dart
// Botão animado
MicroAnimations.animatedButton(
  onPressed: () {},
  child: ElevatedButton(...),
)

// Card animado
MicroAnimations.animatedCard(
  onTap: () {},
  child: Card(...),
)

// Efeitos especiais
MicroAnimations.shimmer(child: YourWidget())
MicroAnimations.pulse(child: YourWidget())
MicroAnimations.bounce(child: YourWidget())
MicroAnimations.shake(child: YourWidget())
```

### Transições de Página

```dart
// Navegação com transição
Navigator.push(
  context,
  MicroAnimations.slidePageRoute(
    page: NextPage(),
    direction: SlideDirection.fromRight,
  ),
);

// Outras transições
MicroAnimations.fadePageRoute(page: NextPage())
MicroAnimations.scalePageRoute(page: NextPage())
```

## 📱 Responsividade

### Breakpoints

```dart
DesignTokens.breakpointMobile   // 0px
DesignTokens.breakpointTablet   // 768px
DesignTokens.breakpointDesktop  // 1024px
DesignTokens.breakpointWide     // 1440px
```

### Uso Responsivo

```dart
// Verificar tamanho da tela
bool isMobile = MediaQuery.of(context).size.width < DesignTokens.breakpointTablet;

// Layout adaptativo
Widget responsiveWidget = LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < DesignTokens.breakpointTablet) {
      return MobileLayout();
    } else {
      return DesktopLayout();
    }
  },
);
```

## 🚀 Como Usar

### 1. Importar os Módulos

```dart
import 'package:your_app/src/styles/design_tokens.dart';
import 'package:your_app/src/styles/enhanced_theme.dart';
import 'package:your_app/src/styles/micro_animations.dart';
import 'package:your_app/src/styles/accessible_components.dart';
```

### 2. Configurar o Tema

```dart
MaterialApp(
  theme: EnhancedTheme.lightTheme,
  darkTheme: EnhancedTheme.darkTheme,
  themeMode: ThemeMode.system,
  home: YourHomePage(),
)
```

### 3. Usar Componentes

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MicroAnimations.enterAnimation(
      child: AccessibleComponents.card(
        semanticLabel: 'Card de exemplo',
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space16),
          child: Column(
            children: [
              Text(
                'Título',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: DesignTokens.space12),
              AccessibleComponents.primaryButton(
                text: 'Ação',
                onPressed: () {},
                tooltip: 'Executa uma ação',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 📋 Exemplo Completo

Veja o arquivo `design_system_example.dart` para um exemplo completo demonstrando todos os recursos do sistema de design.

## 🔄 Migração do Tema Antigo

Para migrar do tema antigo (`app_theme.dart`):

1. **Substitua cores hardcoded** pelos tokens:
   ```dart
   // Antes
   Color(0xFF2196F3)
   
   // Depois
   DesignTokens.primary500
   ```

2. **Use componentes acessíveis**:
   ```dart
   // Antes
   ElevatedButton(
     onPressed: () {},
     child: Text('Botão'),
   )
   
   // Depois
   AccessibleComponents.primaryButton(
     text: 'Botão',
     onPressed: () {},
     tooltip: 'Descrição do botão',
   )
   ```

3. **Adicione animações**:
   ```dart
   // Antes
   Card(child: content)
   
   // Depois
   MicroAnimations.fadeIn(
     child: AccessibleComponents.card(
       child: content,
       semanticLabel: 'Descrição do card',
     ),
   )
   ```

## 🎯 Benefícios

- **Consistência**: Tokens de design garantem uniformidade visual
- **Acessibilidade**: Conformidade com WCAG 2.1 AA
- **Experiência**: Micro-animações melhoram a percepção de qualidade
- **Manutenibilidade**: Código mais organizado e reutilizável
- **Flexibilidade**: Suporte completo a modo escuro
- **Performance**: Animações otimizadas e componentes eficientes

## 📚 Recursos Adicionais

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Material Design 3](https://m3.material.io/)
- [Flutter Accessibility](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [Design Tokens W3C](https://www.w3.org/community/design-tokens/)