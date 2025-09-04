import SwiftUI
import GameKit

struct MessagesView: View {
    @ObservedObject var gameCenter: GameCenterHelper
    @State private var typedMessage = ""
    
    var body: some View {
        VStack {
            // Área de matchmaking / status
            HStack {
                if gameCenter.isAuthenticated {
                    Text("Autenticado! Top: \(GKLocalPlayer.local.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    Spacer()
                    Button("Encontrar Match") {
                        gameCenter.startMatchmaking()
                    }
                } else {
                    Text("Autenticando no Game Center...")
                        .foregroundColor(.orange)
                }
            }
            .padding()
            
            Divider()
            
            // Chat / mensagens
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(gameCenter.messages.indices, id: \.self) { i in
                            Text(gameCenter.messages[i])
                                .padding(8)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                                .id(i)
                        }
                    }
                    .padding()
                }
                .onChange(of: gameCenter.messages.count) { _ in
                    // Scroll automático para a última mensagem
                    if let last = gameCenter.messages.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
            
            HStack {
                TextField("Digite sua mensagem...", text: $typedMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Enviar") {
                    guard !typedMessage.isEmpty else { return }
                    gameCenter.sendMessage(typedMessage)
                    typedMessage = ""
                }
            }
            .padding()
        }
        .onAppear {
            // Verificar se há convites pendentes quando a view aparecer
            gameCenter.processPendingInvite()
        }
    }
}
