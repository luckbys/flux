-- ===============================================
-- BKCRM - Script de Configuração do Supabase
-- ===============================================

-- Remover tabelas se existirem (ordem reversa por causa das dependências)
DROP TABLE IF EXISTS message_reads CASCADE;
DROP TABLE IF EXISTS message_attachments CASCADE;  
DROP TABLE IF EXISTS tickets CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversation_participants CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ===============================================
-- TABELA: users
-- ===============================================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  phone TEXT,
  role TEXT DEFAULT 'customer' CHECK (role IN ('admin', 'agent', 'customer')),
  user_status TEXT DEFAULT 'offline' CHECK (user_status IN ('online', 'offline', 'away', 'busy')),
  department TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_seen TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===============================================
-- TABELA: conversations
-- ===============================================
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT,
  type TEXT DEFAULT 'direct' CHECK (type IN ('direct', 'group', 'support', 'ticket')),
  conv_status TEXT DEFAULT 'active' CHECK (conv_status IN ('active', 'archived', 'closed')),
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}',
  whatsapp_chat_id TEXT,
  evolution_instance_id TEXT
);

-- ===============================================
-- TABELA: conversation_participants
-- ===============================================
CREATE TABLE conversation_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member', 'observer')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  left_at TIMESTAMP WITH TIME ZONE,
  notifications_enabled BOOLEAN DEFAULT TRUE,
  is_muted BOOLEAN DEFAULT FALSE,
  UNIQUE(conversation_id, user_id)
);

-- ===============================================
-- TABELA: messages
-- ===============================================
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT NOT NULL,
  msg_type TEXT DEFAULT 'text' CHECK (msg_type IN ('text', 'image', 'video', 'audio', 'file', 'location', 'contact', 'system')),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  msg_status TEXT DEFAULT 'sent' CHECK (msg_status IN ('sending', 'sent', 'delivered', 'read', 'failed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,
  metadata JSONB DEFAULT '{}',
  whatsapp_message_id TEXT,
  evolution_message_id TEXT
);

-- ===============================================
-- TABELA: message_attachments
-- ===============================================
CREATE TABLE message_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  filename TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size INTEGER,
  mime_type TEXT NOT NULL,
  width INTEGER,
  height INTEGER,
  duration INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===============================================
-- TABELA: message_reads
-- ===============================================
CREATE TABLE message_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(message_id, user_id)
);

-- ===============================================
-- TABELA: tickets
-- ===============================================
CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  number SERIAL UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  ticket_status TEXT DEFAULT 'open' CHECK (ticket_status IN ('open', 'in_progress', 'resolved', 'closed')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  category TEXT,
  customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
  conversation_id UUID REFERENCES conversations(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE,
  closed_at TIMESTAMP WITH TIME ZONE,
  metadata JSONB DEFAULT '{}'
);

-- ===============================================
-- ÍNDICES PARA PERFORMANCE
-- ===============================================

-- Users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Conversations  
CREATE INDEX idx_conversations_status ON conversations(conv_status);
CREATE INDEX idx_conversations_type ON conversations(type);
CREATE INDEX idx_conversations_updated ON conversations(updated_at DESC);

-- Participants
CREATE INDEX idx_participants_conversation ON conversation_participants(conversation_id);
CREATE INDEX idx_participants_user ON conversation_participants(user_id);

-- Messages
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_content_search ON messages USING gin(to_tsvector('portuguese', content));

-- Message Reads
CREATE INDEX idx_message_reads_message ON message_reads(message_id);
CREATE INDEX idx_message_reads_user ON message_reads(user_id);

-- Tickets
CREATE INDEX idx_tickets_customer ON tickets(customer_id);
CREATE INDEX idx_tickets_status ON tickets(ticket_status);
CREATE INDEX idx_tickets_created ON tickets(created_at DESC);

-- ===============================================
-- TRIGGERS PARA UPDATED_AT
-- ===============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversations_updated_at 
    BEFORE UPDATE ON conversations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at 
    BEFORE UPDATE ON messages 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tickets_updated_at 
    BEFORE UPDATE ON tickets 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- DADOS INICIAIS
-- ===============================================

INSERT INTO users (id, name, email, role, user_status) VALUES 
('00000000-0000-0000-0000-000000000001', 'Administrador', 'admin@bkcrm.com', 'admin', 'online'),
('00000000-0000-0000-0000-000000000002', 'Agente Suporte', 'agente@bkcrm.com', 'agent', 'online');

-- Conversa de exemplo
INSERT INTO conversations (id, title, type, created_by) VALUES 
('00000000-0000-0000-0000-000000000001', 'Suporte Geral', 'support', '00000000-0000-0000-0000-000000000001');

-- Participantes da conversa
INSERT INTO conversation_participants (conversation_id, user_id, role) VALUES 
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'admin'),
('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'member');

-- Mensagens de exemplo
INSERT INTO messages (content, conversation_id, sender_id) VALUES 
('Bem-vindo ao BKCRM! Como posso ajudar?', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002'),
('Sistema funcionando perfeitamente!', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001');

-- ===============================================
-- RLS (ROW LEVEL SECURITY)
-- ===============================================

-- Habilitar RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

-- Políticas básicas (permitir tudo por enquanto)
CREATE POLICY "Users can view all users" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid()::text = id::text);

CREATE POLICY "Users can view conversations they participate in" ON conversations FOR SELECT USING (true);
CREATE POLICY "Users can create conversations" ON conversations FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view participants" ON conversation_participants FOR SELECT USING (true);
CREATE POLICY "Users can manage participants" ON conversation_participants FOR ALL USING (true);

CREATE POLICY "Users can view messages" ON messages FOR SELECT USING (true);
CREATE POLICY "Users can send messages" ON messages FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can manage message reads" ON message_reads FOR ALL USING (true);

CREATE POLICY "Users can view tickets" ON tickets FOR SELECT USING (true);
CREATE POLICY "Users can create tickets" ON tickets FOR INSERT WITH CHECK (true);

-- ===============================================
-- VIEWS ÚTEIS
-- ===============================================

CREATE OR REPLACE VIEW conversation_with_participants AS
SELECT 
    c.*,
    array_agg(
        json_build_object(
            'user_id', u.id,
            'name', u.name,
            'email', u.email,
            'role', cp.role,
            'joined_at', cp.joined_at
        )
    ) as participants
FROM conversations c
LEFT JOIN conversation_participants cp ON c.id = cp.conversation_id
LEFT JOIN users u ON cp.user_id = u.id
WHERE cp.left_at IS NULL
GROUP BY c.id;

-- ===============================================
-- CONFIGURAÇÃO COMPLETA!
-- =============================================== 