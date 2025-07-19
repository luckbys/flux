# 📱 BKCRM - Sistema de CRM Flutter

Um sistema completo de Customer Relationship Management (CRM) desenvolvido em Flutter com interface moderna, chat em tempo real, gerenciamento de tickets e integração com IA.

## ✨ Funcionalidades Principais

### 🔐 **Autenticação**
- **Login e Cadastro** com validação completa
- **Interface moderna** com animações suaves
- **Login social** (Google, Microsoft) - Em desenvolvimento
- **Recuperação de senha** - Em desenvolvimento

### 📊 **Dashboard**
- **Visão geral** com métricas em tempo real
- **Estatísticas de tickets** (total, pendentes, resolvidos)
- **Indicadores de performance** (tempo médio, satisfação)
- **Ações rápidas** para criar tickets e iniciar chats
- **Tickets recentes** com filtros e ordenação
- **Chat ativo** com participantes online

### 🎫 **Gerenciamento de Tickets**
- **Lista completa** com busca e filtros avançados
- **Filtros por**: Status, Prioridade, Categoria
- **Ordenação por**: Data, Prioridade, Status
- **Detalhes completos** do ticket com histórico
- **Comentários e atividades** em tempo real
- **Sugestões de IA** para respostas automáticas
- **Tags personalizadas** e categorização
- **Atribuição de agentes** e status tracking

### 💬 **Sistema de Chat**
- **Lista de conversas** com status online
- **Chat individual** com interface moderna
- **Mensagens em tempo real** (simulado)
- **Indicador de digitação** e status de leitura
- **Sugestões de IA** para respostas rápidas
- **Anexos e mídia** - Em desenvolvimento
- **Histórico completo** de conversas

### 👤 **Perfil do Usuário**
- **Edição de informações** pessoais
- **Configurações de notificações** e aparência
- **Estatísticas pessoais** (tickets, chats, resoluções)
- **Gestão de preferências** e privacidade
- **Troca de avatar** e personalização

### 🤖 **Integração com IA (Google Gemini)**
- **Análise de sentimento** automática
- **Classificação de tickets** por categoria
- **Sugestões de resposta** contextuais
- **Tradução automática** - Em desenvolvimento
- **Detecção de spam** e priorização

### 🌐 **WebSocket (Simulado)**
- **Comunicação em tempo real** para mensagens
- **Atualizações de status** de usuários
- **Notificações push** simuladas
- **Sincronização automática** de dados
- **Reconexão automática** em caso de falha

## 🎨 Design System

### **Cores**
- **Primary**: #3B82F6 (Azul)
- **Success**: #10B981 (Verde)
- **Warning**: #F59E0B (Laranja)
- **Error**: #EF4444 (Vermelho)
- **Background**: #F8FAFC (Cinza claro)
- **Text**: #1F2937 (Cinza escuro)

### **Tipografia**
- **Fonte**: Inter (Google Fonts)
- **Pesos**: 400, 500, 600, 700
- **Escalas**: 12px, 14px, 16px, 18px, 20px, 24px, 32px

### **Espaçamentos**
- **Base**: 4px
- **Escalas**: 2, 4, 8, 12, 16, 20, 24, 32, 48, 64px

### **Componentes**
- **Cards** com sombras suaves e bordas arredondadas
- **Botões** com estados hover e loading
- **Inputs** com validação visual e feedback
- **Avatares** com status online e iniciais coloridas
- **Badges** para status, prioridades e categorias

## 🏗️ Arquitetura

### **Estrutura de Pastas**
```
lib/
├── src/
│   ├── components/           # Componentes reutilizáveis
│   │   ├── chat/            # Componentes de chat
│   │   ├── tickets/         # Componentes de tickets
│   │   └── ui/              # Componentes de UI base
│   ├── models/              # Modelos de dados
│   ├── pages/               # Páginas da aplicação
│   │   ├── auth/           # Autenticação
│   │   ├── chat/           # Chat e conversas
│   │   ├── dashboard/      # Dashboard principal
│   │   ├── profile/        # Perfil do usuário
│   │   └── tickets/        # Gerenciamento de tickets
│   ├── services/            # Serviços e APIs
│   │   ├── ai/             # Integração com IA
│   │   └── websocket/      # Comunicação em tempo real
│   ├── styles/              # Temas e estilos
│   └── utils/               # Utilitários gerais
```

### **Padrões Implementados**
- **BKCRM Rules**: Seguindo rigorosamente as regras estabelecidas
- **Clean Architecture**: Separação clara de responsabilidades
- **Provider Pattern**: Gerenciamento de estado reativo
- **Repository Pattern**: Abstração de dados
- **Adapter Pattern**: Integração com serviços externos

## 📦 Dependências

```yaml
dependencies:
  flutter: ">=3.0.0"
  
  # UI e Design
  google_fonts: ^6.1.0
  phosphor_flutter: ^2.0.0
  
  # Estado e Dados
  provider: ^6.1.1
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Utilitários
  equatable: ^2.0.5
  
  # IA e APIs
  google_generative_ai: ^0.2.2
  
  # Comunicação (Simulada)
  # socket_io_client: ^2.0.3+1
```

## 🚀 Como Executar

### **Pré-requisitos**
- Flutter SDK 3.0.0 ou superior
- Dart 3.0.0 ou superior
- Android Studio / VS Code
- Emulador Android / iOS ou dispositivo físico

### **Instalação**
```bash
# 1. Clone o repositório
git clone https://github.com/seu-usuario/bkcrm-flutter.git
cd bkcrm-flutter

# 2. Instale as dependências
flutter pub get

# 3. Execute o aplicativo
flutter run
```

### **Configuração da IA (Opcional)**
```bash
# Configure a API Key do Google Gemini
export GEMINI_API_KEY="sua_api_key_aqui"
```

## 📱 Telas Implementadas

### **1. Splash Screen**
- Animação de entrada com logo
- Carregamento e transição suave
- Configuração inicial do app

### **2. Login / Cadastro**
- Formulários completos com validação
- Animações e micro-interações
- Opções de login social

### **3. Dashboard**
- Métricas e estatísticas em tempo real
- Cartões informativos e ações rápidas
- Lista de tickets recentes
- Chat ativo com participantes

### **4. Lista de Tickets**
- Busca avançada e filtros múltiplos
- Ordenação por diferentes critérios
- Cards informativos com status visual
- Paginação e loading states

### **5. Detalhes do Ticket**
- Informações completas e histórico
- Sistema de comentários
- Sugestões de IA contextuais
- Ações de gerenciamento

### **6. Lista de Conversas**
- Status online dos usuários
- Contadores de mensagens não lidas
- Busca por participantes
- Indicadores visuais de atividade

### **7. Chat Individual**
- Interface moderna de mensagens
- Indicadores de digitação
- Sugestões de IA em tempo real
- Informações do participante

### **8. Perfil**
- Edição de informações pessoais
- Configurações e preferências
- Estatísticas do usuário
- Gestão de conta

## 🎯 Funcionalidades Avançadas

### **Sistema de Notificações**
- Push notifications simuladas
- Badges de contadores não lidos
- Alertas contextuais
- Sistema de preferências

### **Offline Support**
- Cache local com Hive
- Sincronização automática
- Estados de conectividade
- Dados persistentes

### **Acessibilidade**
- Suporte a leitores de tela
- Navegação por teclado
- Contraste adequado (WCAG 2.1 AA)
- Redução de movimento

### **Performance**
- Lazy loading de componentes
- Virtualização de listas
- Debounce em busca (300ms)
- Throttle em scroll (100ms)

## 🧪 Dados Simulados

O app utiliza dados simulados (mock) para demonstração:

- **15 tickets** com diferentes status e prioridades
- **8 conversas** com usuários fictícios
- **Atividades em tempo real** via WebSocket simulado
- **Sugestões de IA** com respostas pré-definidas
- **Usuários online** com status dinâmicos

## 🔄 WebSocket Simulado

Implementação completa de comunicação em tempo real:

### **Eventos Suportados**
- `newMessage` - Novas mensagens
- `messageRead` - Confirmação de leitura
- `messageTyping` - Indicador de digitação
- `ticketCreated` - Novos tickets
- `ticketUpdated` - Atualizações de tickets
- `userStatusChanged` - Mudança de status
- `notificationReceived` - Notificações

### **Funcionalidades**
- Reconexão automática (5 tentativas)
- Heartbeat para manter conexão
- Eventos tipados e validados
- Streams reativas para UI
- Estado de conexão em tempo real

## 🤖 Integração com IA

### **Google Gemini Features**
- **Análise de sentimento**: Detecta emoções nas mensagens
- **Classificação automática**: Categoriza tickets por tipo
- **Sugestões de resposta**: Gera respostas contextuais
- **Priorização inteligente**: Define prioridades automaticamente
- **Tradução automática**: Suporte multilíngue (em desenvolvimento)

### **Configuração**
```dart
// Serviço configurado em src/services/ai/gemini_service.dart
final geminiService = GeminiService();
await geminiService.analyzeSentiment("Texto para análise");
```

## 📈 Métricas e Analytics

### **Dashboard Metrics**
- Total de tickets (156)
- Tickets pendentes (23)
- Taxa de resolução (91%)
- Tempo médio de resposta (2h 15min)
- Satisfação do cliente (4.8/5)

### **Performance Tracking**
- Tempo de carregamento de telas
- Taxa de conversão de tickets
- Eficiência dos agentes
- Uso de funcionalidades

## 🔒 Segurança

### **Autenticação**
- Validação robusta de formulários
- Criptografia de senhas (simulada)
- Tokens de sessão seguros
- Logout automático por inatividade

### **Autorização**
- Roles de usuário (Admin, Agent, Customer)
- Permissões granulares
- Acesso baseado em contexto
- Auditoria de ações

## 🌐 Internacionalização

### **Idiomas Suportados**
- Português (BR) - Padrão
- Inglês - Em desenvolvimento
- Espanhol - Em desenvolvimento

### **Configuração**
```dart
// Configurado para expansão futura
class AppLocalizations {
  static const supportedLocales = [
    Locale('pt', 'BR'),
    Locale('en', 'US'),
    Locale('es', 'ES'),
  ];
}
```

## 📋 Roadmap

### **Versão 2.0**
- [ ] Integração com APIs reais
- [ ] WebSocket real com Socket.IO
- [ ] Notificações push nativas
- [ ] Modo offline completo
- [ ] Suporte a anexos e mídia

### **Versão 2.1**
- [ ] Videochamadas integradas
- [ ] IA voice-to-text
- [ ] Dashboard personalizável
- [ ] Relatórios avançados
- [ ] Integração com CRMs externos

### **Versão 2.2**
- [ ] App para desktop (Windows/macOS)
- [ ] Temas customizáveis
- [ ] Plugin system
- [ ] API pública
- [ ] Marketplace de integrações

## 🐛 Problemas Conhecidos

1. **WebSocket**: Implementação simulada (não conecta a servidor real)
2. **IA**: Depende de API Key do Google Gemini
3. **Notificações**: Simuladas (não são push reais)
4. **Anexos**: Interface pronta, funcionalidade em desenvolvimento

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👨‍💻 Desenvolvedor

Desenvolvido seguindo rigorosamente as **Regras BKCRM v1.0.0** com foco em:
- Estrutura de diretórios padronizada
- Nomenclatura consistente
- Design system com glassmorphism
- Integração completa com IA
- Performance otimizada
- Acessibilidade WCAG 2.1 AA
- Documentação completa

---

## 📱 Screenshots

*As imagens serão adicionadas quando o app estiver executando no dispositivo.*

### Dashboard
![Dashboard](screenshots/dashboard.png)

### Lista de Tickets
![Tickets](screenshots/tickets.png)

### Chat
![Chat](screenshots/chat.png)

### Perfil
![Profile](screenshots/profile.png)

---

**📞 Contato**: [seu-email@exemplo.com](mailto:seu-email@exemplo.com)

**🌐 Website**: [https://seu-site.com](https://seu-site.com)

**📱 Demo**: [Link para demo online](https://demo-link.com) 