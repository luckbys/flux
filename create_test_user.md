# 🔧 Criar Usuário de Teste - BKCRM

Para testar o login no aplicativo BKCRM, você precisa criar um usuário de teste no Supabase Auth.

## Método 1: Via Dashboard do Supabase (Recomendado)

1. **Acesse o Dashboard do Supabase**
   - Vá para: https://app.supabase.com
   - Faça login na sua conta
   - Selecione seu projeto BKCRM

2. **Criar Usuário de Teste**
   - No menu lateral, clique em **"Authentication"**
   - Clique na aba **"Users"**
   - Clique no botão **"Add user"**
   - Preencha os dados:
     - **Email**: `teste@bkcrm.com`
     - **Password**: `123456789`
     - **Email Confirm**: ✅ (marque como confirmado)
   - Clique em **"Create user"**

3. **Verificar Criação**
   - O usuário deve aparecer na lista
   - Status deve estar como "Confirmed"

## Método 2: Via SQL (Alternativo)

Se preferir, execute este comando SQL no **SQL Editor** do Supabase:

```sql
-- Inserir usuário de teste no auth.users
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'teste@bkcrm.com',
  crypt('123456789', gen_salt('bf')),
  NOW(),
  NOW(),
  NOW(),
  '{"provider": "email", "providers": ["email"]}',
  '{}',
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
);
```

## Dados para Login

Após criar o usuário, use estes dados para fazer login no app:

- **Email**: `teste@bkcrm.com`
- **Senha**: `123456789`

## Verificar se Funcionou

1. **Abra o aplicativo Flutter**
2. **Digite os dados de login**
3. **Clique em "Entrar"**
4. **Deve redirecionar para o dashboard**

## Troubleshooting

Se o login não funcionar:

1. **Verifique os logs do Supabase**:
   - Dashboard > Logs > Auth

2. **Verifique se o usuário foi criado**:
   - Dashboard > Authentication > Users

3. **Teste a conexão**:
   ```sql
   SELECT * FROM auth.users WHERE email = 'teste@bkcrm.com';
   ```

4. **Verifique as credenciais no app**:
   - Arquivo: `lib/src/config/app_config.dart`
   - URL e chaves devem estar corretas

## Usuários Adicionais

Para criar mais usuários de teste, repita o processo com emails diferentes:
- `admin@bkcrm.com` (para testar como admin)
- `agente@bkcrm.com` (para testar como agente)
- `cliente@bkcrm.com` (para testar como cliente)

---

✅ **Após criar o usuário, o login deve funcionar normalmente!**