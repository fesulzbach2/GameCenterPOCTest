//
//  ContentView.swift
//  GameCenterPOC
//
//  Created by Fernando Sulzbach on 02/09/25.
//

import SwiftUI
import GameKit

struct ContentView: View {
    @StateObject var gameCenter = GameCenterHelper()
    
    var body: some View {
        VStack(spacing: 20) {
            if gameCenter.isAuthenticated {
                Text("✅ Autenticado como \(GKLocalPlayer.local.displayName)")
                Button("Encontrar Partida") {
                    gameCenter.startMatchmaking()
                }
                Button("Enviar Mensagem") {
                    gameCenter.sendMessage("Oi, pessoal! 😎")
                }
            } else {
                Text("⏳ Autenticando no Game Center...")
            }
        }
        .padding()
    }
}


#Preview {
    ContentView()
}
