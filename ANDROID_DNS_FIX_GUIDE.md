# 🔧 Guia de Correção - Erro de DNS no Android APK

## 🚨 Problema Identificado

O erro `ClientException with SocketException: Failed host lookup: 'inhaxsjsjybpxtohfgmp.supabase.co'` indica que o aplicativo Android não consegue resolver o DNS do Supabase.

## ✅ Soluções Implementadas

### 1. Configuração de Segurança de Rede

Criado arquivo `android/app/src/main/res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">supabase.co</domain>
        <domain includeSubdomains="true">inhaxsjsjybpxtohfgmp.supabase.co</domain>
        <domain includeSubdomains="true">evochat.devsible.com.br</domain>
    </domain-config>
    
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system"/>
        </trust-anchors>
    </base-config>
</network-security-config>
```

### 2. Permissões de Rede no AndroidManifest.xml

Adicionadas as seguintes permissões:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 3. Configuração da Aplicação

Adicionado no `<application>`:
```xml
android:networkSecurityConfig="@xml/network_security_config"
android:usesCleartextTraffic="false"
```

## 🔍 Possíveis Causas Adicionais

### 1. **Problema de DNS do Dispositivo**
- Alguns dispositivos Android têm problemas com DNS específicos
- Solução: Configurar DNS público (8.8.8.8 ou 1.1.1.1) no Wi-Fi

### 2. **Restrições de Rede da Operadora**
- Algumas operadoras bloqueiam certos domínios
- Solução: Testar com Wi-Fi diferente ou dados móveis

### 3. **Projeto Supabase Inativo**
- Verificar se o projeto está ativo no painel do Supabase
- Status: https://status.supabase.com

### 4. **Configuração de Proxy/VPN**
- Desabilitar VPN ou proxy durante os testes
- Verificar configurações de rede corporativa

## 🛠️ Passos para Testar

### 1. Recompilar o APK
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### 2. Testar Conectividade
- Abrir navegador no celular
- Acessar: `https://inhaxsjsjybpxtohfgmp.supabase.co`
- Deve carregar uma página do Supabase

### 3. Verificar Logs
```bash
flutter logs
# ou
adb logcat | grep -i supabase
```

## 🔧 Soluções Alternativas

### 1. **Usar IP Direto (Temporário)**
```dart
// Em app_config.dart - APENAS PARA TESTE
static const String supabaseUrl = 'https://[IP_DO_SUPABASE]';
```

### 2. **Configurar DNS Customizado**
```dart
// Adicionar no main.dart
import 'dart:io';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
```

### 3. **Verificar Configuração do Supabase**
```dart
// Testar conectividade básica
try {
  final response = await Dio().get('https://inhaxsjsjybpxtohfgmp.supabase.co');
  print('Supabase acessível: ${response.statusCode}');
} catch (e) {
  print('Erro de conectividade: $e');
}
```

## 📱 Teste em Diferentes Cenários

1. **Wi-Fi Doméstico**: Testar em casa
2. **Dados Móveis**: Testar com 4G/5G
3. **Wi-Fi Público**: Testar em local público
4. **Diferentes Dispositivos**: Testar em vários celulares

## 🚀 Próximos Passos

1. Recompilar o APK com as novas configurações
2. Instalar e testar no dispositivo
3. Se persistir, verificar logs detalhados
4. Considerar usar um domínio personalizado para o Supabase

## 📞 Suporte

Se o problema persistir:
1. Verificar status do Supabase: https://status.supabase.com
2. Testar em emulador Android
3. Verificar configurações de firewall/antivírus
4. Contatar suporte do Supabase se necessário