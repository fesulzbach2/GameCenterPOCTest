import SwiftUI
import GameKit

// MARK: - Helper para pegar rootViewController
extension UIApplication {
    var currentRootViewController: UIViewController? {
        return self.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}

// MARK: - Game Center Helper
class GameCenterHelper: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var messages: [String] = []
    var match: GKMatch?
    private var pendingInvite: GKInvite?
    private var pendingPlayersToInvite: [GKPlayer]?
    
    override init() {
        super.init()
        authenticatePlayer()
    }
    
    // Autenticação
    private func authenticatePlayer() {
        GKLocalPlayer.local.authenticateHandler = { vc, error in
            if let vc = vc {
                // Apresenta a tela de login do Game Center
                UIApplication.shared.currentRootViewController?.present(vc, animated: true)
            } else if GKLocalPlayer.local.isAuthenticated {
                print("✅ Jogador autenticado: \(GKLocalPlayer.local.displayName)")
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                }
                
                // Registrar para ouvir convites
                GKLocalPlayer.local.register(self)
                
                // NÃO processar convites automaticamente ao abrir o app
                // Apenas limpar qualquer convite pendente
                self.clearPendingInvites()
                
            } else {
                print("❌ Falha ao autenticar: \(String(describing: error))")
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    // Limpar convites pendentes sem processá-los
    private func clearPendingInvites() {
        // Isso previne que convites antigos sejam processados ao abrir o app
        pendingInvite = nil
        pendingPlayersToInvite = nil
    }
    
    // Processar convite pendente (chamado apenas quando necessário)
    func processPendingInvite() {
        if let invite = pendingInvite {
            pendingInvite = nil
            acceptInvite(invite)
        } else if let players = pendingPlayersToInvite {
            pendingPlayersToInvite = nil
            acceptMatchRequest(with: players)
        }
    }
    
    // Aceitar convite
    private func acceptInvite(_ invite: GKInvite) {
        print("📩 Processando convite de \(invite.sender.displayName)")
        
        if let vc = GKMatchmakerViewController(invite: invite) {
            vc.matchmakerDelegate = self
            UIApplication.shared.currentRootViewController?.present(vc, animated: true)
        }
    }
    
    // Aceitar solicitação de partida
    private func acceptMatchRequest(with players: [GKPlayer]) {
        print("📩 Processando solicitação de partida para \(players.count) jogadores")
        
        let request = GKMatchRequest()
        request.recipients = players
        request.minPlayers = 2
        request.maxPlayers = 4
        
        if let vc = GKMatchmakerViewController(matchRequest: request) {
            vc.matchmakerDelegate = self
            UIApplication.shared.currentRootViewController?.present(vc, animated: true)
        }
    }
    
    // Matchmaking manual (botão Iniciar Partida)
    func startMatchmaking(minPlayers: Int = 2, maxPlayers: Int = 4) {
        guard isAuthenticated else {
            print("⚠️ Usuário não está autenticado")
            return
        }
        
        let request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        
        if let vc = GKMatchmakerViewController(matchRequest: request) {
            vc.matchmakerDelegate = self
            UIApplication.shared.currentRootViewController?.present(vc, animated: true)
        }
    }
    
    // Enviar mensagem
    func sendMessage(_ text: String) {
        guard let match = match else {
            print("⚠️ Nenhuma partida ativa")
            return
        }
        
        if let data = text.data(using: .utf8) {
            do {
                try match.sendData(toAllPlayers: data, with: .reliable)
                print("📤 Enviado: \(text)")
                DispatchQueue.main.async {
                    self.messages.append("Você: \(text)")
                }
            } catch {
                print("❌ Erro ao enviar mensagem: \(error)")
            }
        }
    }
}

// MARK: - Delegates
extension GameCenterHelper: GKMatchmakerViewControllerDelegate, GKMatchDelegate {
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true)
        print("❌ Matchmaking cancelado")
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController,
                                  didFailWithError error: Error) {
        viewController.dismiss(animated: true)
        print("❌ Erro no matchmaking: \(error.localizedDescription)")
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController,
                                  didFind match: GKMatch) {
        viewController.dismiss(animated: true)
        self.match = match
        match.delegate = self
        print("✅ Match encontrado com \(match.players.count) jogadores")
        
        // Limpar mensagens antigas e enviar mensagem de boas-vindas
        DispatchQueue.main.async {
            self.messages.removeAll()
        }
        sendMessage("Olá, galera!")
    }
    
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        if let text = String(data: data, encoding: .utf8) {
            print("📥 Recebido de \(player.displayName): \(text)")
            DispatchQueue.main.async {
                self.messages.append("\(player.displayName): \(text)")
            }
        }
    }
    
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        switch state {
        case .connected:
            print("✅ \(player.displayName) conectado")
        case .disconnected:
            print("❌ \(player.displayName) desconectado")
        @unknown default:
            print("⚠️ Estado desconhecido para \(player.displayName)")
        }
    }
}

// MARK: - Listener de convites
extension GameCenterHelper: GKLocalPlayerListener {
    // Quando um convite é aceito pelo usuário FORA do app
    func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        print("📩 Convite recebido de \(invite.sender.displayName)")
        
        // IMPORTANTE: Verificar se o app está em primeiro plano
        // Se o app foi aberto através de um convite, processar
        // Se o app já estava aberto, armazenar para processar depois
        
        if UIApplication.shared.applicationState == .active {
            // App já estava ativo - armazenar convite e deixar o usuário decidir
            pendingInvite = invite
            
            // Você pode notificar o usuário aqui se quiser
            // Por exemplo, mostrar um alerta ou banner
            print("⏳ Convite armazenado. Use processPendingInvite() para aceitar.")
            
            // OU processar imediatamente se preferir
            // acceptInvite(invite)
        } else {
            // App foi aberto através do convite - processar imediatamente
            acceptInvite(invite)
        }
    }
    
    // Recebimento de solicitação de partida
    func player(_ player: GKPlayer, didRequestMatchWithRecipients recipientPlayers: [GKPlayer]) {
        print("📩 Solicitação de partida recebida para \(recipientPlayers.count) jogadores")
        
        if UIApplication.shared.applicationState == .active {
            // App já estava ativo - armazenar para processar depois
            pendingPlayersToInvite = recipientPlayers
            print("⏳ Solicitação armazenada. Use processPendingInvite() para aceitar.")
        } else {
            // App foi aberto através da solicitação - processar imediatamente
            acceptMatchRequest(with: recipientPlayers)
        }
    }
}
