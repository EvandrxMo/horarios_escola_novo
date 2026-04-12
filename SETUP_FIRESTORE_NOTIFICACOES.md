# 📲 Sistema de Notificações Remoto (Firebase + Firestore)

## Overview

O app agora suporta **notificações remotas em ambas as plataformas**:
- **Android**: Usa FCM (Firebase Cloud Messaging) - push verdadeiro
- **iOS** (sem Apple Developer Program): Usa Firestore listener - pull em tempo real

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────┐
│   Admin envia notificação                   │
│   → Firestore collection 'remote_banners'   │
└──────────────────┬──────────────────────────┘
                   │
        ┌──────────┴──────────┐
        ↓                     ↓
    [Android]             [iOS]
    FCM Push          Firestore Listener
    (sempre)           (quando app aberto)
        │                     │
        └──────────┬──────────┘
                   ↓
    RemoteMessagingService
    (gerencia banners)
                   ↓
         Home Screen (exibe)
         Modal + Banner card
```

## 📋 Estrutura Firestore

Collection: `remote_banners`

```
remote_banners/
├─ doc_1
│  ├─ "titulo": "Nova programação"
│  ├─ "corpo": "Confira a aula de amanhã"
│  ├─ "imageUrl": "https://..." (opcional)
│  ├─ "timestamp": 2026-04-11T14:30:00Z
│  ├─ "vista": false
│  └─ "deviceId": "abc123" (opcional, para targeting)
│
├─ doc_2
│  └─ ...
```

### Campo por Campo

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `titulo` | String | ✅ | Título do banner |
| `corpo` | String | ✅ | Texto do banner |
| `imageUrl` | String | ❌ | URL da imagem (48x48, PNG/JPG) |
| `timestamp` | Timestamp | ✅ | Quando foi criado |
| `vista` | Boolean | ✅ | Se já foi vista (default: `false`) |
| `deviceId` | String | ❌ | ID do device (para targeting futuro) |

## 🚀 Como Enviar Notificações

### 1️⃣ Via Firebase Console (Manual)

1. Abra [Firebase Console](https://console.firebase.google.com)
2. Vá para **Cloud Firestore** → `yasmin-f5265` project
3. Crie collection: `remote_banners` (se não existir)
4. Clique em **Adicionar documento**
5. Preencha:
   ```
   titulo:    "Nova aula"
   corpo:     "Aula de português às 14h"
   imageUrl:  "https://exemple.com/logo.png"  (opcional)
   timestamp: (deixar auto-generated ou clock time)
   vista:     false
   ```
6. **Salvar**

**Visualmente no app:**
```
┌──────────────────────────────────┐
│ [🖼️] Nova aula               ✕  │
│       Aula de português às 14h   │
└──────────────────────────────────┘
```

O banner aparecerá:
- **Android**: Notificação + banner em primeiro plano (ambos)
- **iOS**: Banner em primeiro plano quando app abrir

**💡 Dica sobre imagem:**
- Deve ser URL pública (não funciona com localhost)
- Tamanho recomendado: 48x48 px (para não ficar distorcida)
- Formatos: PNG, JPG, WebP
- Se não há imagem, usa ícone padrão (📢)

### 2️⃣ Via código (Backend)

Se tiver um backend/API, pode fazer assim:

```python
# Python example
from firebase_admin import firestore, initialize_app

db = firestore.client()

db.collection('remote_banners').add({
    'titulo': 'Reunião importante',
    'corpo': 'Não esqueça da reunião às 15h',
    'imageUrl': 'https://exemple.com/meeting-icon.png',  # opcional
    'timestamp': firestore.SERVER_TIMESTAMP,
    'vista': False,
})
```

```javascript
// JavaScript/Node.js example
const admin = require('firebase-admin');

const db = admin.firestore();

db.collection('remote_banners').add({
  titulo: 'Novo aviso',
  corpo: 'Leia o comunicado importante',
  imageUrl: 'https://exemple.com/warning-icon.png',  // opcional
  timestamp: admin.firestore.FieldValue.serverTimestamp(),
  vista: false,
});
```

### 3️⃣ Via Admin Panel (No futuro)

Quando implementarmos um painel de admin, será possível enviar via UI.

## 📱 Comportamento no App

### Android
```
Notificação enviada
       ↓
FCM recebe
       ↓
[App aberto?]
  ├─ SIM: Notificação do sistema + Banner modal + Banner card
  └─ NÃO: Notificação do sistema (banner ao abrir)
       ↓
App abre
  └─ Mostra banner em primeiro plano (modal + card)
```

### iOS (sem APNs)
```
Notificação enviada para Firestore
       ↓
Listener ativo no Firestore
       ↓
[App aberto?]
  ├─ SIM: Banner modal + Band card IMEDIATAMENTE
  └─ NÃO: Nenhuma notificação (sem APNs)
       ↓
Usuário abre app (manualmente)
  └─ Carrega banner pendente (se houver)
```

## 🔑 Chaves importante no código

### RemoteMessagingService
- `initialize()`: Inicia FCM + listener Firestore (iOS only)
- `inAppBannerNotifier`: ValueNotifier que dispara quando novo banner chega
- `loadPendingBanner()`: Carrega banner salvo em `SharedPreferences`
- `dismissPendingBanner()`: Remove banner

### Home Screen (lib/pages/home_tela.dart)
- `_carregarBannerRemotoPendente()`: Carrega ao init
- `_onRemoteBannerChanged()`: Listener para mudanças
- `_mostrarBannerEmPrimeiroPlanoSeNecessario()`: Modal dialog

## 🧪 Teste Rápido

1. Abra o app em Android/iOS
2. Abra Firebase Console → Firestore
3. Crie um novo documento em `remote_banners`:
   ```
   titulo: "Teste"
   corpo:  "Funcionou!"
   timestamp: (server)
   vista: false
   ```
4. Veja o banner aparecer NO APP em tempo real! 🎉

## ⚙️ Configuração Técnica

### Dependências
```yaml
firebase_core: ^3.15.2
firebase_messaging: ^15.2.10
cloud_firestore: ^5.1.0
flutter_local_notifications: ^19.0.0
shared_preferences: ^2.5.4
```

### Regras Firestore (Security)

Para produção, configure as regras em Firestore:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Apenas app pode ler remote_banners
    match /remote_banners/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Apenas via backend/admin
    }
  }
}
```

## 🐛 Troubleshooting

| Problema | Solução |
|----------|---------|
| Banner não aparece no iOS | Verifique se app está aberto. Sem APNs, não há notificação em background. |
| Listener não se conecta | Verifique regras Firestore e autenticação Firebase (anonymous deve estar ativa). |
| Banner aparece 2x | Normal se chegar por FCM e Firestore simultaneamente. Será deduplicado se tiver mesmo ID. |
| "Access Denied" no Firestore | Configure autenticação Anonymous em Firebase Console → Authentication. |

## 📝 Próximas Melhorias

- [ ] Targeting por `deviceId` (enviar para devices específicos)
- [ ] Categorias de notificações (horários, avisos, etc)
- [ ] Admin panel para UIgráfica de envio
- [ ] Agendamento de notificações
- [ ] Analytics (quantas viram, quantas clicaram)
- [ ] Suporte a links/deep linking no banner

## 🔗 Referências

- [Firebase Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Cloud Firestore Docs](https://firebase.google.com/docs/firestore)
- [Flutter Firebase Plugin](https://pub.dev/packages/firebase_messaging)
