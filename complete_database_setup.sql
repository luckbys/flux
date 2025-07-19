-- Script completo para configurar todas as tabelas necessárias no Supabase
-- Execute este script no SQL Editor do Supabase

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===============================================
-- VERIFICAR E ADICIONAR COLUNA STATUS NA TABELA USERS
-- ===============================================

-- Verificar se a coluna user_status existe e renomeá-la para status
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'user_status'
  ) THEN
    ALTER TABLE users RENAME COLUMN user_status TO status;
  ELSIF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'status'
  ) THEN
    ALTER TABLE users ADD COLUMN status TEXT DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'away', 'busy'));
  END IF;
END
$$;

-- ===============================================
-- VERIFICAR E CRIAR TABELAS FALTANTES
-- ===============================================

-- Tabela de orçamentos (PRINCIPAL PROBLEMA)
CREATE TABLE IF NOT EXISTS quotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending', 'approved', 'rejected', 'converted')),
  priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assigned_agent_id UUID REFERENCES users(id) ON DELETE SET NULL,
  tax_rate DECIMAL(5,2) DEFAULT 0.00,
  additional_discount DECIMAL(10,2) DEFAULT 0.00,
  notes TEXT,
  terms TEXT,
  rejection_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  valid_until TIMESTAMP WITH TIME ZONE,
  approved_at TIMESTAMP WITH TIME ZONE,
  rejected_at TIMESTAMP WITH TIME ZONE,
  converted_at TIMESTAMP WITH TIME ZONE
);

-- Tabela de itens do orçamento (PRINCIPAL PROBLEMA)
CREATE TABLE IF NOT EXISTS quote_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  quantity DECIMAL(10,2) NOT NULL DEFAULT 1.00,
  unit_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  unit TEXT NOT NULL DEFAULT 'unidade',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela profiles (referenciada no supabase_service.dart)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===============================================
-- ÍNDICES PARA PERFORMANCE
-- ===============================================

-- Índices para quotes
CREATE INDEX IF NOT EXISTS idx_quotes_customer_id ON quotes(customer_id);
CREATE INDEX IF NOT EXISTS idx_quotes_assigned_agent_id ON quotes(assigned_agent_id);
CREATE INDEX IF NOT EXISTS idx_quotes_status ON quotes(status);
CREATE INDEX IF NOT EXISTS idx_quotes_priority ON quotes(priority);
CREATE INDEX IF NOT EXISTS idx_quotes_created_at ON quotes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_quotes_valid_until ON quotes(valid_until);

-- Índices para quote_items
CREATE INDEX IF NOT EXISTS idx_quote_items_quote_id ON quote_items(quote_id);

-- Índices para profiles
CREATE INDEX IF NOT EXISTS idx_profiles_updated_at ON profiles(updated_at);

-- ===============================================
-- TRIGGERS PARA UPDATED_AT
-- ===============================================

-- Função para atualizar updated_at (se não existir)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para quotes
DROP TRIGGER IF EXISTS update_quotes_updated_at ON quotes;
CREATE TRIGGER update_quotes_updated_at
    BEFORE UPDATE ON quotes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Triggers para profiles
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- POLÍTICAS DE SEGURANÇA (RLS)
-- ===============================================

-- Habilitar RLS nas novas tabelas
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- ===============================================
-- POLÍTICAS PARA QUOTES
-- ===============================================

-- Política para visualizar orçamentos
DROP POLICY IF EXISTS "Users can view related quotes" ON quotes;
CREATE POLICY "Users can view related quotes" ON quotes
  FOR SELECT USING (
    auth.uid()::text = customer_id::text OR 
    auth.uid()::text = assigned_agent_id::text OR
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- Política para inserir orçamentos (apenas agentes e admins)
DROP POLICY IF EXISTS "Agents can insert quotes" ON quotes;
CREATE POLICY "Agents can insert quotes" ON quotes
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- Política para atualizar orçamentos (apenas agentes e admins)
DROP POLICY IF EXISTS "Agents can update quotes" ON quotes;
CREATE POLICY "Agents can update quotes" ON quotes
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- Política para deletar orçamentos (apenas agentes e admins)
DROP POLICY IF EXISTS "Agents can delete quotes" ON quotes;
CREATE POLICY "Agents can delete quotes" ON quotes
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- ===============================================
-- POLÍTICAS PARA QUOTE_ITEMS
-- ===============================================

-- Política para visualizar itens de orçamento
DROP POLICY IF EXISTS "Users can view related quote items" ON quote_items;
CREATE POLICY "Users can view related quote items" ON quote_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM quotes 
      WHERE quotes.id = quote_items.quote_id 
      AND (
        auth.uid()::text = quotes.customer_id::text OR 
        auth.uid()::text = quotes.assigned_agent_id::text OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
      )
    )
  );

-- Política para inserir itens de orçamento (apenas agentes e admins)
DROP POLICY IF EXISTS "Agents can insert quote items" ON quote_items;
CREATE POLICY "Agents can insert quote items" ON quote_items
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- Política para atualizar itens de orçamento (apenas agentes e admins)
DROP POLICY IF EXISTS "Agents can update quote items" ON quote_items;
CREATE POLICY "Agents can update quote items" ON quote_items
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- Política para deletar itens de orçamento (apenas agentes e admins)
DROP POLICY IF EXISTS "Agents can delete quote items" ON quote_items;
CREATE POLICY "Agents can delete quote items" ON quote_items
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- ===============================================
-- POLÍTICAS PARA PROFILES
-- ===============================================

-- Política para visualizar profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

-- Política para inserir profiles
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Política para atualizar profiles
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- ===============================================
-- INSERIR DADOS DE EXEMPLO (OPCIONAL)
-- ===============================================

-- Inserir usuários de exemplo para testes
INSERT INTO users (id, name, email, phone, role, status, created_at, updated_at)
VALUES 
  ('550e8400-e29b-41d4-a716-446655440001', 'João Silva', 'joao@empresa.com', '(11) 99999-9999', 'customer', 'online', NOW(), NOW()),
  ('550e8400-e29b-41d4-a716-446655440002', 'Maria Santos', 'maria@bkcrm.com', '(11) 88888-8888', 'agent', 'online', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  email = EXCLUDED.email,
  phone = EXCLUDED.phone,
  role = EXCLUDED.role,
  status = EXCLUDED.status,
  updated_at = NOW();

-- Inserir profiles para usuários existentes
INSERT INTO profiles (id)
SELECT id FROM users 
WHERE id NOT IN (SELECT id FROM profiles)
ON CONFLICT (id) DO NOTHING;

-- ===============================================
-- COMENTÁRIOS PARA DOCUMENTAÇÃO
-- ===============================================

COMMENT ON TABLE quotes IS 'Tabela de orçamentos do sistema';
COMMENT ON TABLE quote_items IS 'Itens dos orçamentos';
COMMENT ON TABLE profiles IS 'Perfis dos usuários (tabela auxiliar)';

COMMENT ON COLUMN quotes.status IS 'Status do orçamento: draft, pending, approved, rejected, converted';
COMMENT ON COLUMN quotes.priority IS 'Prioridade: low, normal, high, urgent';
COMMENT ON COLUMN quotes.customer_id IS 'ID do cliente (referência para users)';
COMMENT ON COLUMN quotes.assigned_agent_id IS 'ID do agente responsável (referência para users)';

-- ===============================================
-- VERIFICAÇÃO FINAL
-- ===============================================

-- Verificar se as tabelas foram criadas
SELECT 
  'quotes' as tabela,
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'quotes') 
    THEN '✅ Criada' 
    ELSE '❌ Não encontrada' 
  END as status
UNION ALL
SELECT 
  'quote_items' as tabela,
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'quote_items') 
    THEN '✅ Criada' 
    ELSE '❌ Não encontrada' 
  END as status
UNION ALL
SELECT 
  'profiles' as tabela,
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') 
    THEN '✅ Criada' 
    ELSE '❌ Não encontrada' 
  END as status;

-- Verificar políticas RLS
SELECT 
  tablename,
  COUNT(*) as total_policies
FROM pg_policies 
WHERE tablename IN ('quotes', 'quote_items', 'profiles')
GROUP BY tablename
ORDER BY tablename;

SELECT '🎉 Script executado com sucesso! Verifique os resultados acima.' as resultado;