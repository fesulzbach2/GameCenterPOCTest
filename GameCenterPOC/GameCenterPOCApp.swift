//
//  GameCenterPOCApp.swift
//  GameCenterPOC
//
//  Created by Fernando Sulzbach on 02/09/25.
//

import SwiftUI

@main
struct GameCenterPOCApp: App {
    @StateObject private var gameCenter = GameCenterHelper()
    
    var body: some Scene {
        WindowGroup {
            MessagesView(gameCenter: gameCenter)
        }
    }
}
