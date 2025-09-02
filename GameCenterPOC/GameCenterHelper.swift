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
    var match: GKMatch?
    
    override init() {
        super.init()
        authenticatePlayer()
    }
    
    // 1. Autenticar jogador no Game Center
    private func authenticatePlayer() {
        GKLocalPlayer.local.authenticateHandler = { vc, error in
            if let vc = vc {
                // Mostra tela de login do Game Center
                UIApplication.shared.currentRootViewController?.present(vc, animated: true)
            } else if GKLocalPlayer.local.isAuthenticated {
                print("✅ Jogador autenticado: \(GKLocalPlayer.local.displayName)")
                self.isAuthenticated = true
            } else {
                print("❌ Falha ao autenticar: \(String(describing: error))")
            }
        }
    }
    
    // 2. Criar matchmaking
    func startMatchmaking(minPlayers: Int = 2, maxPlayers: Int = 4) {
        let request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        
        let vc = GKMatchmakerViewController(matchRequest: request)!
        vc.matchmakerDelegate = self
        
        UIApplication.shared.currentRootViewController?.present(vc, animated: true)
    }
    
    // 3. Enviar mensagem para todos os jogadores
    func sendMessage(_ text: String) {
        guard let match = match else { return }
        if let data = text.data(using: .utf8) {
            do {
                try match.sendData(toAllPlayers: data, with: .reliable)
                print("📤 Enviado: \(text)")
            } catch {
                print("Erro ao enviar: \(error)")
            }
        }
    }
}

// MARK: - Delegates
extension GameCenterHelper: GKMatchmakerViewControllerDelegate, GKMatchDelegate {
    
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController,
                                  didFailWithError error: Error) {
        viewController.dismiss(animated: true)
        print("Erro no matchmaking: \(error.localizedDescription)")
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController,
                                  didFind match: GKMatch) {
        viewController.dismiss(animated: true)
        self.match = match
        match.delegate = self
        print("✅ Match encontrado com \(match.players.count) jogadores")
        
        // Teste: mandar mensagem de boas-vindas
        sendMessage("Olá, galera!")
    }
    
    // Receber mensagens
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        if let text = String(data: data, encoding: .utf8) {
            print("📥 Recebido de \(player.displayName): \(text)")
        }
    }
}
