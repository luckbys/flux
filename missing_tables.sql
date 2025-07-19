-- Script para adicionar as tabelas faltantes no Supabase
-- Execute este script no SQL Editor do Supabase

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabela de orçamentos
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

-- Tabela de itens do orçamento
CREATE TABLE IF NOT EXISTS quote_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  quantity DECIMAL(10,2) NOT NULL DEFAULT 1.00,
  unit_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  unit TEXT NOT NULL DEFAULT 'unidade',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_quotes_customer_id ON quotes(customer_id);
CREATE INDEX IF NOT EXISTS idx_quotes_assigned_agent_id ON quotes(assigned_agent_id);
CREATE INDEX IF NOT EXISTS idx_quotes_status ON quotes(status);
CREATE INDEX IF NOT EXISTS idx_quotes_created_at ON quotes(created_at);
CREATE INDEX IF NOT EXISTS idx_quote_items_quote_id ON quote_items(quote_id);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar trigger na tabela quotes
DROP TRIGGER IF EXISTS update_quotes_updated_at ON quotes;
CREATE TRIGGER update_quotes_updated_at
    BEFORE UPDATE ON quotes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Políticas de segurança RLS (Row Level Security)
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_items ENABLE ROW LEVEL SECURITY;

-- Política para orçamentos: clientes veem seus orçamentos, agentes veem todos
CREATE POLICY "Users can view related quotes" ON quotes
  FOR SELECT USING (
    auth.uid()::text = customer_id::text OR 
    auth.uid()::text = assigned_agent_id::text OR
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- Política para inserir orçamentos (apenas agentes e admins)
CREATE POLICY "Agents can insert quotes" ON quotes
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- Política para atualizar orçamentos (apenas agentes e admins)
CREATE POLICY "Agents can update quotes" ON quotes
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- Política para deletar orçamentos (apenas agentes e admins)
CREATE POLICY "Agents can delete quotes" ON quotes
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- Itens de orçamento seguem a mesma regra dos orçamentos
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
CREATE POLICY "Agents can insert quote items" ON quote_items
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- Política para atualizar itens de orçamento (apenas agentes e admins)
CREATE POLICY "Agents can update quote items" ON quote_items
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- Política para deletar itens de orçamento (apenas agentes e admins)
CREATE POLICY "Agents can delete quote items" ON quote_items
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- Comentários para documentação
COMMENT ON TABLE quotes IS 'Tabela de orçamentos';
COMMENT ON TABLE quote_items IS 'Itens dos orçamentos';
COMMENT ON COLUMN quotes.status IS 'Status do orçamento: draft, pending, approved, rejected, converted';
COMMENT ON COLUMN quotes.priority IS 'Prioridade: low, normal, high, urgent';

-- Inserir alguns dados de exemplo para teste (opcional)
-- Certifique-se de que os usuários existem antes de executar
/*
INSERT INTO quotes (id, title, description, status, priority, customer_id, assigned_agent_id, notes, terms) VALUES
  (gen_random_uuid(), 'Orçamento Teste 1', 'Descrição do orçamento teste', 'draft', 'normal', 
   '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 
   'Notas do orçamento', 'Termos e condições')
ON CONFLICT DO NOTHING;
*/

SELECT 'Tabelas quotes e quote_items criadas com sucesso!' as resultado;