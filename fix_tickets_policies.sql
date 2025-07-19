-- Adicionar políticas de INSERT, UPDATE e DELETE para a tabela tickets
-- Estas políticas estavam faltando no schema original

-- Política para inserir tickets (clientes podem criar seus próprios tickets, agentes podem criar para qualquer cliente)
DROP POLICY IF EXISTS "Users can insert tickets" ON tickets;
CREATE POLICY "Users can insert tickets" ON tickets
  FOR INSERT WITH CHECK (
    auth.uid()::text = customer_id::text OR
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- Política para atualizar tickets (apenas agentes e admins podem atualizar)
DROP POLICY IF EXISTS "Agents can update tickets" ON tickets;
CREATE POLICY "Agents can update tickets" ON tickets
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- Política para deletar tickets (apenas agentes e admins podem deletar)
DROP POLICY IF EXISTS "Agents can delete tickets" ON tickets;
CREATE POLICY "Agents can delete tickets" ON tickets
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('agent', 'admin'))
  );

-- Verificar se as políticas foram criadas
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE tablename = 'tickets'
ORDER BY cmd;

SELECT '✅ Políticas de tickets criadas com sucesso!' as resultado;