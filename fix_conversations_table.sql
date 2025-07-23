-- Script para corrigir a tabela conversations
-- Execute este script no Supabase SQL Editor

-- Verificar se a tabela conversations existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'conversations') THEN
        -- Criar tabela conversations se não existir
        CREATE TABLE conversations (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            title TEXT,
            type TEXT NOT NULL DEFAULT 'support' CHECK (type IN ('support', 'sales', 'group')),
            status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'archived', 'closed')),
            created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        RAISE NOTICE 'Tabela conversations criada com sucesso';
    ELSE
        -- Verificar se a coluna status existe
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'status') THEN
            -- Adicionar coluna status se não existir
            ALTER TABLE conversations ADD COLUMN status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'archived', 'closed'));
            RAISE NOTICE 'Coluna status adicionada à tabela conversations';
        ELSE
            RAISE NOTICE 'Tabela conversations já existe com a coluna status';
        END IF;
    END IF;
END $$;

-- Verificar se a tabela conversation_participants existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'conversation_participants') THEN
        CREATE TABLE conversation_participants (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            joined_at TIMESTAMPTZ DEFAULT NOW(),
            UNIQUE(conversation_id, user_id)
        );
        RAISE NOTICE 'Tabela conversation_participants criada com sucesso';
    END IF;
END $$;

-- Verificar se a tabela messages existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'messages') THEN
        CREATE TABLE messages (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            content TEXT NOT NULL,
            type TEXT NOT NULL DEFAULT 'text' CHECK (type IN ('text', 'image', 'file', 'audio', 'video')),
            conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
            sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'read')),
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        RAISE NOTICE 'Tabela messages criada com sucesso';
    END IF;
END $$;

-- Criar índices se não existirem
CREATE INDEX IF NOT EXISTS idx_conversations_status ON conversations(status);
CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON conversations(created_by);
CREATE INDEX IF NOT EXISTS idx_conversations_created_at ON conversations(created_at);

CREATE INDEX IF NOT EXISTS idx_conversation_participants_conversation_id ON conversation_participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_user_id ON conversation_participants(user_id);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

-- Criar trigger para updated_at se não existir
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar triggers
DROP TRIGGER IF EXISTS update_conversations_updated_at ON conversations;
CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_messages_updated_at ON messages;
CREATE TRIGGER update_messages_updated_at
    BEFORE UPDATE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Inserir dados de exemplo se a tabela estiver vazia
INSERT INTO conversations (title, type, status, created_by)
SELECT 
    'Conversa de Suporte ' || i,
    'support',
    'active',
    (SELECT id FROM users LIMIT 1)
FROM generate_series(1, 3) i
WHERE NOT EXISTS (SELECT 1 FROM conversations LIMIT 1);

-- Inserir participantes nas conversas
INSERT INTO conversation_participants (conversation_id, user_id)
SELECT 
    c.id,
    u.id
FROM conversations c
CROSS JOIN users u
WHERE u.role = 'customer'
LIMIT 5
ON CONFLICT (conversation_id, user_id) DO NOTHING;

-- Inserir mensagens de exemplo
INSERT INTO messages (content, type, conversation_id, sender_id, status)
SELECT 
    'Olá, preciso de ajuda com o sistema',
    'text',
    c.id,
    u.id,
    'sent'
FROM conversations c
CROSS JOIN users u
WHERE u.role = 'customer'
LIMIT 3
ON CONFLICT DO NOTHING; 