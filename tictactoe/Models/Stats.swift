//
//  Stats.swift
//  tictactoe
//
//  Created by Rishi Jansari on 27/08/2026.
//

import Foundation

@Observable
class Stats: Codable {
    var wins: Int = 0 { didSet { save() } }
    var losses: Int = 0 { didSet { save() } }
    var draws: Int = 0 { didSet { save() } }
    
    private enum CodingKeys: String, CodingKey {
        case wins, losses, draws
    }
    
    init(wins: Int = 0, losses: Int = 0, draws: Int = 0) {
        self.wins = wins
        self.losses = losses
        self.draws = draws
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.wins = try container.decode(Int.self, forKey: .wins)
        self.losses = try container.decode(Int.self, forKey: .losses)
        self.draws = try container.decode(Int.self, forKey: .draws)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(wins, forKey: .wins)
        try container.encode(losses, forKey: .losses)
        try container.encode(draws, forKey: .draws)
    }
    
    static func load() -> Stats {
        if let data = UserDefaults.standard.data(forKey: "stats"),
           let decoded = try? JSONDecoder().decode(Stats.self, from: data) {
            return decoded
        }
        return Stats()
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "stats")
        }
    }
}
