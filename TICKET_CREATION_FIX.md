# Correção do Problema de Criação de Tickets

## 🐛 **Problema Identificado**

Após a criação de um ticket, o modal de sucesso aparecia, mas o ticket não era salvo no banco de dados e não aparecia na lista de tickets.

### **Erro Específico:**
```
PostgrestException(message: new row for relation "tickets" violates check constraint "tickets_priority_check", code: 23514, details: , hint: null)
```

**E posteriormente:**
```
TypeError: null: type 'Null' is not a subtype of type 'String'
```

## 🔍 **Causas Raiz**

### **1. Simulação em vez de Persistência Real**
- O `NewTicketForm` estava usando `Future.delayed` para simular criação
- Não havia integração real com `TicketStore` e `AuthStore`

### **2. Mapeamento Incorreto de Enums**
- **Prioridade**: Enum `TicketPriority.normal` estava sendo mapeado para `'normal'` no banco, mas o schema espera `'medium'`
- **Categoria**: Enum `TicketCategory.complaint` e `TicketCategory.feature` não tinham mapeamento correto para o banco

### **3. Falta de Conversão de Tipos**
- Strings da UI não eram convertidas para enums antes de enviar ao banco
- Ausência de métodos de mapeamento entre UI e banco de dados

### **4. Métodos de Mapeamento Retornando Null**
- Os métodos `_mapPriorityToDb` e `_mapCategoryToDb` não tinham `default` case
- Quando valores inesperados eram passados, retornavam `null`
- Isso causava erro `TypeError: null: type 'Null' is not a subtype of type 'String'`

### **5. Campos Null do Banco de Dados**
- Os campos `category`, `priority` e `ticket_status` podem ser `null` no banco
- Os métodos de mapeamento não estavam preparados para lidar com valores `null`
- Isso causava erro ao tentar converter `null` para `String`

## ✅ **Soluções Implementadas**

### **1. Integração Real com Stores**

#### **`lib/src/screens/new_ticket_form.dart`**
```dart
Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) {
    _showValidationError();
    return;
  }
  
  setState(() { _isLoading = true; });
  
  try {
    final ticketStore = Provider.of<TicketStore>(context, listen: false);
    final authStore = Provider.of<AuthStore>(context, listen: false);
    
    if (authStore.appUser == null) {
      throw Exception('Usuário não autenticado');
    }

    final priority = _convertPriorityString(_selectedPriority);
    final category = _convertCategoryString(_selectedCategory);
    final status = TicketStatus.open;

    final ticket = await ticketStore.createTicket(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      customerId: authStore.appUser!.id,
      priority: priority,
      category: category,
      assignedTo: null,
    );

    if (ticket != null) {
      if (mounted) {
        _showSuccessDialog(ticket.id);
      }
    } else {
      throw Exception('Erro ao criar ticket');
    }
  } catch (e) {
    if (mounted) {
      _showErrorSnackBar('Erro ao criar ticket: $e');
    }
  } finally {
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }
}
```

### **2. Conversão de Strings para Enums**

#### **Métodos de Conversão Adicionados:**
```dart
TicketPriority _convertPriorityString(String priority) {
  switch (priority) {
    case 'Baixa': return TicketPriority.low;
    case 'Média': return TicketPriority.normal;
    case 'Alta': return TicketPriority.high;
    case 'Urgente': return TicketPriority.urgent;
    default: return TicketPriority.normal;
  }
}

TicketCategory _convertCategoryString(String category) {
  switch (category) {
    case 'Técnico': return TicketCategory.technical;
    case 'Financeiro': return TicketCategory.billing;
    case 'Geral': return TicketCategory.general;
    case 'Reclamação': return TicketCategory.complaint;
    case 'Feature': return TicketCategory.feature;
    case 'Suporte': return TicketCategory.general;
    case 'Bug': return TicketCategory.technical;
    case 'Manutenção': return TicketCategory.technical;
    case 'Consulta': return TicketCategory.general;
    default: return TicketCategory.general;
  }
}
```

### **3. Mapeamento Correto para Banco de Dados**

#### **`lib/src/services/supabase/ticket_service.dart`**

##### **Mapeamento de Prioridade:**
```dart
String _mapPriorityToDb(TicketPriority priority) {
  switch (priority) {
    case TicketPriority.low: return 'low';
    case TicketPriority.normal: return 'medium'; // Corrigido: normal -> medium
    case TicketPriority.high: return 'high';
    case TicketPriority.urgent: return 'urgent';
  }
}

TicketPriority _mapPriorityFromDb(String priority) {
  switch (priority) {
    case 'low': return TicketPriority.low;
    case 'medium': return TicketPriority.normal; // Corrigido: medium -> normal
    case 'high': return TicketPriority.high;
    case 'urgent': return TicketPriority.urgent;
    default: return TicketPriority.normal;
  }
}
```

##### **Mapeamento de Categoria:**
```dart
String _mapCategoryToDb(TicketCategory category) {
  switch (category) {
    case TicketCategory.technical: return 'technical';
    case TicketCategory.billing: return 'billing';
    case TicketCategory.general: return 'general';
    case TicketCategory.complaint: return 'feature_request'; // Mapeado para valor existente
    case TicketCategory.feature: return 'feature_request';
  }
}

TicketCategory _mapCategoryFromDb(String category) {
  switch (category) {
    case 'technical': return TicketCategory.technical;
    case 'billing': return TicketCategory.billing;
    case 'general': return TicketCategory.general;
    case 'feature_request': return TicketCategory.feature;
    case 'bug_report': return TicketCategory.technical; // Mapeado para enum existente
    default: return TicketCategory.general;
  }
}
```

### **4. Atualização do Dialog de Sucesso**

#### **Exibição do ID Real:**
```dart
void _showSuccessDialog(String ticketId) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
      title: const Text('Ticket Criado!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Seu ticket foi criado com sucesso.'),
          const SizedBox(height: 8),
          Text(
            'Número: #TK${ticketId}', // Agora mostra o ID real
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Você receberá atualizações por e-mail.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Fechar dialog
            Navigator.of(context).pop(); // Voltar para tela anterior
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

### **5. Correção dos Métodos de Mapeamento**

#### **Adição de Default Cases:**
```dart
String _mapPriorityToDb(TicketPriority priority) {
  switch (priority) {
    case TicketPriority.low: return 'low';
    case TicketPriority.normal: return 'medium';
    case TicketPriority.high: return 'high';
    case TicketPriority.urgent: return 'urgent';
    default: return 'medium'; // ✅ Default para casos inesperados
  }
}

String _mapCategoryToDb(TicketCategory category) {
  switch (category) {
    case TicketCategory.technical: return 'technical';
    case TicketCategory.billing: return 'billing';
    case TicketCategory.general: return 'general';
    case TicketCategory.complaint: return 'feature_request';
    case TicketCategory.feature: return 'feature_request';
    default: return 'general'; // ✅ Default para casos inesperados
  }
}
```

#### **Proteção contra Null no TicketData:**
```dart
final ticketData = {
  'title': title,
  'description': description,
  'customer_id': customerId,
  'priority': mappedPriority,
  'category': mappedCategory ?? 'general', // ✅ Garantir que nunca seja null
  'ticket_status': 'open',
  'assigned_to': assignedTo,
  'metadata': metadata ?? {},
};
```

#### **Logs Detalhados para Debug:**
```dart
// Log dos dados recebidos para debug
AppConfig.log('Dados recebidos:', tag: 'TicketService');
AppConfig.log('  title: $title', tag: 'TicketService');
AppConfig.log('  description: $description', tag: 'TicketService');
AppConfig.log('  customerId: $customerId', tag: 'TicketService');
AppConfig.log('  priority: $priority', tag: 'TicketService');
AppConfig.log('  category: $category', tag: 'TicketService');

// Log dos dados mapeados
AppConfig.log('Dados mapeados:', tag: 'TicketService');
AppConfig.log('  mappedPriority: $mappedPriority', tag: 'TicketService');
AppConfig.log('  mappedCategory: $mappedCategory', tag: 'TicketService');

// Log dos dados finais
AppConfig.log('Dados finais para inserção: $ticketData', tag: 'TicketService');
```

### **6. Correção dos Métodos de Mapeamento para Null**

#### **Métodos Atualizados para Lidar com Null:**
```dart
TicketPriority _mapPriorityFromDb(String? priority) {
  if (priority == null) return TicketPriority.normal;
  
  switch (priority) {
    case 'low': return TicketPriority.low;
    case 'medium': return TicketPriority.normal;
    case 'high': return TicketPriority.high;
    case 'urgent': return TicketPriority.urgent;
    default: return TicketPriority.normal;
  }
}

TicketCategory _mapCategoryFromDb(String? category) {
  if (category == null) return TicketCategory.general;
  
  switch (category) {
    case 'technical': return TicketCategory.technical;
    case 'billing': return TicketCategory.billing;
    case 'general': return TicketCategory.general;
    case 'feature_request': return TicketCategory.feature;
    case 'bug_report': return TicketCategory.technical;
    default: return TicketCategory.general;
  }
}

TicketStatus _mapStatusFromDb(String? status) {
  if (status == null) return TicketStatus.open;
  
  switch (status) {
    case 'open': return TicketStatus.open;
    case 'in_progress': return TicketStatus.inProgress;
    case 'waiting_customer': return TicketStatus.waitingCustomer;
    case 'resolved': return TicketStatus.resolved;
    case 'closed': return TicketStatus.closed;
    default: return TicketStatus.open;
  }
}
```

#### **Logs Detalhados no Mapeamento:**
```dart
Ticket _mapTicketFromDb(Map<String, dynamic> json) {
  // Log para debug
  AppConfig.log('Mapeando ticket do banco:', tag: 'TicketService');
  AppConfig.log('  json recebido: $json', tag: 'TicketService');
  
  try {
    // Log dos campos individuais
    AppConfig.log('  id: ${json['id']}', tag: 'TicketService');
    AppConfig.log('  title: ${json['title']}', tag: 'TicketService');
    AppConfig.log('  priority: ${json['priority']}', tag: 'TicketService');
    AppConfig.log('  category: ${json['category']}', tag: 'TicketService');
    
    // ... resto do mapeamento
  } catch (e) {
    AppConfig.log('Erro ao mapear ticket do banco: $e', tag: 'TicketService');
    AppConfig.log('  json que causou erro: $json', tag: 'TicketService');
    rethrow;
  }
}
```

## 🔧 **Mudanças Técnicas**

### **1. Schema do Banco vs Enum Dart**

#### **Prioridade:**
- **Banco**: `['low', 'medium', 'high', 'urgent']`
- **Dart Enum**: `[low, normal, high, urgent]`
- **Mapeamento**: `normal` ↔ `medium`

#### **Categoria:**
- **Banco**: `['general', 'technical', 'billing', 'feature_request', 'bug_report']`
- **Dart Enum**: `[technical, billing, general, complaint, feature]`
- **Mapeamento**: `complaint` → `feature_request`, `feature` → `feature_request`

### **2. Fluxo de Dados Corrigido**

```
UI String → Enum Dart → String Banco → Persistência
```

**Exemplo:**
1. UI: "Média" 
2. Enum: `TicketPriority.normal`
3. Banco: "medium"
4. Persistência: ✅ Sucesso

## 🧪 **Testes Realizados**

### **1. Criação de Ticket**
- ✅ Formulário preenchido corretamente
- ✅ Validações funcionando
- ✅ Conversão de tipos correta
- ✅ Persistência no banco
- ✅ ID retornado corretamente

### **2. Exibição na Lista**
- ✅ Ticket aparece na lista após criação
- ✅ Dados corretos exibidos
- ✅ Atualização automática da lista

### **3. Mapeamento de Valores**
- ✅ Prioridade "Média" → "medium" no banco
- ✅ Categoria "Reclamação" → "feature_request" no banco
- ✅ Leitura correta do banco para UI

## 🎯 **Resultado**

### **Antes:**
- ❌ Modal de sucesso sem persistência
- ❌ Ticket não aparecia na lista
- ❌ Erro de constraint no banco
- ❌ Simulação em vez de dados reais

### **Depois:**
- ✅ Ticket criado e persistido no banco
- ✅ Modal mostra ID real do ticket
- ✅ Ticket aparece na lista imediatamente
- ✅ Mapeamento correto entre UI e banco
- ✅ Integração completa com stores

## 🚀 **Próximos Passos**

### **Melhorias Sugeridas:**
1. **Validação de Schema**: Verificar se todos os enums estão mapeados corretamente
2. **Testes Automatizados**: Criar testes para mapeamento de tipos
3. **Logs Detalhados**: Adicionar logs para debug de mapeamento
4. **Tratamento de Erros**: Melhorar mensagens de erro para o usuário

### **Monitoramento:**
- Verificar logs de criação de tickets
- Monitorar erros de constraint no banco
- Validar integridade dos dados salvos

## ✅ **Checklist de Correção**

- [x] Remover simulação `Future.delayed`
- [x] Integrar com `TicketStore` e `AuthStore`
- [x] Implementar conversão de strings para enums
- [x] Corrigir mapeamento de prioridade (`normal` ↔ `medium`)
- [x] Corrigir mapeamento de categoria (`complaint` → `feature_request`)
- [x] Atualizar dialog de sucesso com ID real
- [x] Adicionar `default` cases nos métodos de mapeamento
- [x] Proteger contra valores `null` no ticketData
- [x] Adicionar logs detalhados para debug
- [x] Corrigir métodos de mapeamento para lidar com `null` do banco
- [x] Adicionar logs detalhados no mapeamento de resposta
- [x] Testar criação e persistência
- [x] Verificar exibição na lista
- [x] Validar mapeamento bidirecional
- [x] Documentar correções

## 🎉 **Conclusão**

O problema foi **completamente resolvido** através de:

1. **Integração real** com o sistema de stores
2. **Mapeamento correto** entre UI e banco de dados
3. **Conversão adequada** de tipos de dados
4. **Tratamento de erros** robusto

Agora os tickets são **criados, persistidos e exibidos corretamente**! 🎉 