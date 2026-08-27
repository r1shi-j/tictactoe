//
//  Difficulty.swift
//  tictactoe
//
//  Created by Rishi Jansari on 26/08/2026.
//

import Foundation

enum Difficulty: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}
