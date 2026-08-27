//
//  GameMode.swift
//  tictactoe
//
//  Created by Rishi Jansari on 26/08/2026.
//

import SwiftUI

enum GameMode: Hashable {
    case onePlayer(difficulty: Difficulty)
    case twoPlayer
    
    var viewTitle: String {
        switch self {
            case .onePlayer(let difficulty): "One Player: \(difficulty.rawValue)"
            case .twoPlayer: "Two Player"
        }
    }
    
    var primaryColor: Color {
        switch self {
            case .onePlayer: .pink.mix(with: .teal, by: 0.5)
            case .twoPlayer: .blue.mix(with: .purple, by: 0.3)
        }
    }
    
    var iconForeground: Color {
        .black.mix(with: primaryColor, by: 0.6)
    }
    
    var gridForeground: Color {
        .black.mix(with: .white, by: 0.9).mix(with: primaryColor, by: 0.3)
    }
    
    var gridBackground: Color {
        .black.mix(with: .white, by: 0.5).mix(with: primaryColor, by: 0.6)
    }
    
    var viewBackground: Color {
        primaryColor.opacity(0.20)
    }
}
