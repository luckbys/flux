# 🔧 Guia de Configuração do Supabase - BKCRM Flutter

## 📋 Visão Geral

Este app BKCRM Flutter requer configuração do Supabase para funcionar corretamente. Este guia te ajudará a configurar tudo do zero.

## 🚀 Passo a Passo

### 1. Criar Conta no Supabase

1. Acesse [https://supabase.com](https://supabase.com)
2. Clique em **"Start your project"**
3. Faça login com GitHub, Google ou crie uma conta

### 2. Criar Novo Projeto

1. No painel do Supabase, clique em **"New Project"**
2. Escolha uma organização (ou crie uma nova)
3. Defina:
   - **Name**: `bkcrm-flutter` (ou qualquer nome)
   - **Database Password**: Uma senha forte
   - **Region**: Escolha a região mais próxima
4. Clique em **"Create new project"**
5. ⏳ Aguarde uns 2 minutos para o projeto ser criado

### 3. Obter as Credenciais

1. No painel do projeto, vá em **Settings** > **API**
2. Copie as seguintes informações:
   - **URL**: `https://seu-projeto-id.supabase.co`
   - **anon/public key**: `eyJhbGciOiJI...` (chave longa)

### 4. Configurar o App Flutter

1. Abra o arquivo `lib/src/config/app_config.dart`
2. Substitua as constantes:

```dart
// ANTES (exemplo):
static const String supabaseUrl = 'https://SEU_PROJETO_ID.supabase.co';
static const String supabaseAnonKey = 'SUA_CHAVE_ANONIMA_AQUI';

// DEPOIS (com suas credenciais reais):
static const String supabaseUrl = 'https://abcdefghijklmnop.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

### 5. Criar as Tabelas no Banco

Execute os seguintes comandos SQL no **SQL Editor** do Supabase:

#### 5.1. Tabela de Usuários
```sql
-- Criar tabela de usuários
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  role TEXT DEFAULT 'customer' CHECK (role IN ('admin', 'agent', 'customer')),
  user_status TEXT DEFAULT 'offline' CHECK (user_status IN ('online', 'offline', 'away', 'busy')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS (Row Level Security)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own data" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);
```

#### 5.2. Tabela de Tickets
```sql
-- Criar tabela de tickets
CREATE TABLE tickets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  customer_id UUID REFERENCES users(id),
  agent_id UUID REFERENCES users(id),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  ticket_status TEXT DEFAULT 'open' CHECK (ticket_status IN ('open', 'in_progress', 'resolved', 'closed')),
  tags TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE
);

-- RLS
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own tickets" ON tickets
  FOR SELECT USING (
    auth.uid() = customer_id OR 
    auth.uid() = agent_id OR
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role IN ('admin', 'agent')
    )
  );

CREATE POLICY "Users can insert tickets" ON tickets
  FOR INSERT WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Agents can update tickets" ON tickets
  FOR UPDATE USING (
    auth.uid() = agent_id OR
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role IN ('admin', 'agent')
    )
  );
```

#### 5.3. Tabela de Mensagens
```sql
-- Criar tabela de mensagens
CREATE TABLE messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id),
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'audio')),
  file_url TEXT,
  file_name TEXT,
  file_size INTEGER,
  is_internal BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read ticket messages" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = ticket_id AND (
        auth.uid() = t.customer_id OR 
        auth.uid() = t.agent_id OR
        EXISTS (
          SELECT 1 FROM users 
          WHERE id = auth.uid() AND role IN ('admin', 'agent')
        )
      )
    )
  );

CREATE POLICY "Users can insert messages" ON messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM tickets t
      WHERE t.id = ticket_id AND (
        auth.uid() = t.customer_id OR 
        auth.uid() = t.agent_id OR
        EXISTS (
          SELECT 1 FROM users 
          WHERE id = auth.uid() AND role IN ('admin', 'agent')
        )
      )
    )
  );
```

#### 5.4. Triggers para Updated_at
```sql
-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_tickets_updated_at BEFORE UPDATE ON tickets
  FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
```

### 6. Configurar Autenticação

1. No painel do Supabase, vá em **Authentication** > **Settings**
2. Configure as opções conforme necessário:
   - **Enable email confirmations**: Desabilitar para desenvolvimento
   - **Email templates**: Personalizar se desejar

### 7. Testar a Configuração

1. Reinicie o app Flutter
2. Tente fazer login/cadastro
3. Se aparecer o erro de configuração, verifique:
   - ✅ URLs estão corretas no `app_config.dart`
   - ✅ Chaves estão corretas
   - ✅ Projeto Supabase está ativo
   - ✅ Tabelas foram criadas

## 🔍 Troubleshooting

### Erro: "Failed host lookup"
- ✅ Verifique se a URL está correta
- ✅ Verifique sua conexão com internet
- ✅ Confirme que o projeto não foi pausado/deletado

### Erro: "Invalid JWT"
- ✅ Verifique se a `anonKey` está correta
- ✅ Confirme que copiou a chave completa

### Erro: "Table doesn't exist"
- ✅ Execute os scripts SQL fornecidos
- ✅ Verifique se as tabelas aparecem no **Table Editor**

### Erro: "Row Level Security"
- ✅ Confirme que as policies foram criadas
- ✅ Teste com um usuário autenticado

## 📞 Suporte

Se continuar com problemas:
1. Verifique os logs no console do Flutter
2. Verifique os logs no **Logs** do Supabase
3. Confirme que seguiu todos os passos

## 🎉 Pronto!

Agora seu app BKCRM Flutter deve estar funcionando perfeitamente com o Supabase! 🚀 