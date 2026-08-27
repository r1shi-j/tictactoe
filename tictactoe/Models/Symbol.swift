//
//  Symbol.swift
//  tictactoe
//
//  Created by Rishi Jansari on 26/08/2026.
//

import Foundation

enum Symbol: String {
    case cross = "Cross"
    case circle = "Circle"
    
    var length: CGFloat {
        switch self {
            case .cross: 60
            case .circle: 65
        }
    }
    
    mutating func swap() {
        self = self == .cross ? .circle : .cross
    }
    
    func swapped() -> Symbol {
        self == Symbol.cross ? Symbol.circle : Symbol.cross
    }
}
