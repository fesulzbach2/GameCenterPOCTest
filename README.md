# Game Center POC - Sistema de Convites

Este projeto demonstra como implementar um sistema de convites funcional usando Game Center no iOS.

## Funcionalidades Implementadas

- ✅ Autenticação automática no Game Center
- ✅ Recebimento de convites quando o app está em background
- ✅ Processamento automático de convites quando o app é aberto
- ✅ Tela de matchmaking automática ao aceitar convites
- ✅ Sistema de mensagens em tempo real durante partidas

## Como Testar os Convites

### 1. Configuração Inicial
- Certifique-se de que o Game Center está ativado no dispositivo
- Faça login com uma conta válida do Game Center
- Execute o app em dois dispositivos diferentes (ou simulador + dispositivo)

### 2. Teste de Convite
1. **Dispositivo A (Host):**
   - Abra o app
   - Clique em "Encontrar Match"
   - Aguarde a tela de matchmaking

2. **Dispositivo B (Convidado):**
   - Feche o app completamente (swipe up e force close)
   - Aceite o convite que aparecer na notificação
   - O app deve abrir automaticamente e ir para a tela de matchmaking

### 3. Cenários de Teste

#### Cenário 1: App em Background
- App está rodando em background
- Recebe convite
- Usuário aceita convite
- App volta ao primeiro plano e processa convite automaticamente

#### Cenário 2: App Fechado
- App está completamente fechado
- Usuário recebe convite
- Aceita convite
- App abre e processa convite automaticamente

#### Cenário 3: App Ativo
- App está rodando e ativo
- Recebe convite
- Processa convite imediatamente

## Estrutura do Código

### GameCenterHelper.swift
- Gerencia autenticação e convites
- Implementa `GKLocalPlayerListener` para receber convites
- Observa mudanças no estado do app
- Processa convites pendentes automaticamente

### GameCenterPOCApp.swift
- Cria instância única do `GameCenterHelper`
- Garante persistência do estado entre aberturas do app

### MessagesView.swift
- Interface do usuário
- Recebe instância do `GameCenterHelper`
- Verifica convites pendentes ao aparecer

## Logs de Debug

O app inclui logs detalhados para facilitar o debug:

- 📩 Convite recebido
- ⏳ Convite armazenado
- 📩 Processando convite pendente
- ✅ Match encontrado
- ❌ Erros e falhas

## Troubleshooting

### Convite não é processado
1. Verifique se o Game Center está ativado
2. Confirme se o usuário está autenticado
3. Verifique os logs no console
4. Teste em dispositivo físico (simulador pode ter limitações)

### App não abre com convite
1. Verifique se o app tem as permissões corretas
2. Confirme se o bundle ID está correto
3. Teste em dispositivo físico

## Requisitos

- iOS 14.0+
- Xcode 13.0+
- Conta válida do Game Center
- Dispositivo físico para testes completos (recomendado)
