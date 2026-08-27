//
//  tictactoeApp.swift
//  tictactoe
//
//  Created by Rishi Jansari on 25/08/2026.
//

import SwiftUI

@main
struct tictactoeApp: App {
    @State private var stats = Stats.load()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(stats)
        }
    }
}

// add winning line
// add animations
