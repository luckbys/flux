# 🔧 Correção: Tabelas de Orçamentos Faltantes

## 🚨 Problema Identificado

O aplicativo está apresentando os seguintes erros:

```
PostgrestException(message: Could not find a relationship between 'quotes' and 'users' in the schema cache, code: PGRST200)
```

```
PostgrestException(message: {}, code: 404, details: , hint: null)
```

**Causa**: As tabelas `quotes` e `quote_items` não foram criadas no banco de dados Supabase.

## 🛠️ Solução

### Passo 1: Acessar o SQL Editor do Supabase

1. Acesse seu projeto no [Supabase Dashboard](https://app.supabase.com)
2. No menu lateral, clique em **"SQL Editor"**
3. Clique em **"New query"**

### Passo 2: Executar o Script de Correção

1. Copie todo o conteúdo do arquivo `missing_tables.sql`
2. Cole no SQL Editor do Supabase
3. Clique em **"Run"** para executar o script

### Passo 3: Verificar se as Tabelas foram Criadas

1. No menu lateral, clique em **"Table Editor"**
2. Verifique se as seguintes tabelas aparecem:
   - ✅ `quotes` (Orçamentos)
   - ✅ `quote_items` (Itens dos Orçamentos)

### Passo 4: Verificar as Políticas de Segurança

1. No SQL Editor, execute a seguinte consulta para verificar as políticas:

```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('quotes', 'quote_items')
ORDER BY tablename, policyname;
```

2. Você deve ver políticas como:
   - `Users can view related quotes`
   - `Agents can insert quotes`
   - `Agents can update quotes`
   - `Agents can delete quotes`
   - E políticas similares para `quote_items`

### Passo 5: Testar o Aplicativo

1. Reinicie o aplicativo Flutter
2. Tente acessar a seção de orçamentos
3. Tente criar um novo orçamento

## 📋 Estrutura das Tabelas Criadas

### Tabela `quotes`
- `id` (UUID, Primary Key)
- `title` (TEXT, NOT NULL)
- `description` (TEXT)
- `status` (TEXT, CHECK: draft, pending, approved, rejected, converted)
- `priority` (TEXT, CHECK: low, normal, high, urgent)
- `customer_id` (UUID, FK para users)
- `assigned_agent_id` (UUID, FK para users)
- `tax_rate` (DECIMAL)
- `additional_discount` (DECIMAL)
- `notes` (TEXT)
- `terms` (TEXT)
- `rejection_reason` (TEXT)
- `created_at`, `updated_at`, `valid_until`, `approved_at`, `rejected_at`, `converted_at` (TIMESTAMP)

### Tabela `quote_items`
- `id` (UUID, Primary Key)
- `quote_id` (UUID, FK para quotes)
- `description` (TEXT, NOT NULL)
- `quantity` (DECIMAL)
- `unit_price` (DECIMAL)
- `unit` (TEXT)
- `created_at` (TIMESTAMP)

## 🔐 Políticas de Segurança (RLS)

### Para Orçamentos (`quotes`):
- **Visualização**: Clientes veem seus orçamentos, agentes/admins veem todos
- **Inserção**: Apenas agentes e admins
- **Atualização**: Apenas agentes e admins
- **Exclusão**: Apenas agentes e admins

### Para Itens de Orçamento (`quote_items`):
- **Visualização**: Segue as mesmas regras dos orçamentos
- **Inserção/Atualização/Exclusão**: Apenas agentes e admins

## 🚨 Troubleshooting

### Se ainda houver erros após executar o script:

1. **Verificar se o usuário tem permissões**:
   ```sql
   SELECT * FROM users WHERE id = auth.uid();
   ```

2. **Verificar se as foreign keys estão corretas**:
   ```sql
   SELECT * FROM users LIMIT 5;
   ```

3. **Testar uma consulta simples**:
   ```sql
   SELECT COUNT(*) FROM quotes;
   ```

4. **Verificar logs de erro no Supabase**:
   - Vá em **Logs** > **Database**
   - Procure por erros relacionados às tabelas

### Se o erro 404 persistir:

1. Verifique se as políticas RLS estão ativas:
   ```sql
   SELECT tablename, rowsecurity 
   FROM pg_tables 
   WHERE tablename IN ('quotes', 'quote_items');
   ```

2. Teste desabilitando temporariamente o RLS (apenas para debug):
   ```sql
   ALTER TABLE quotes DISABLE ROW LEVEL SECURITY;
   ALTER TABLE quote_items DISABLE ROW LEVEL SECURITY;
   ```
   
   **⚠️ IMPORTANTE**: Reative o RLS após o teste:
   ```sql
   ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
   ALTER TABLE quote_items ENABLE ROW LEVEL SECURITY;
   ```

## ✅ Verificação Final

Após executar o script, você deve conseguir:
- ✅ Visualizar a lista de orçamentos sem erros
- ✅ Criar novos orçamentos
- ✅ Editar orçamentos existentes
- ✅ Ver estatísticas de orçamentos no dashboard

## 📞 Suporte

Se os problemas persistirem:
1. Verifique os logs do Flutter (`flutter logs`)
2. Verifique os logs do Supabase (Dashboard > Logs)
3. Confirme que todas as dependências estão atualizadas
4. Teste com um usuário que tenha role 'agent' ou 'admin'

---

**Nota**: Este script é seguro para executar múltiplas vezes, pois usa `CREATE TABLE IF NOT EXISTS` e `CREATE POLICY` com verificações de existência.