//
//  ContentView.swift
//  tictactoe
//
//  Created by Rishi Jansari on 25/08/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedMode: GameMode?
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var isShowingStats = false
    @Environment(Stats.self) private var stats
    @Namespace private var animationNamespace
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.green.mix(with: .purple, by: 0.3).opacity(0.20).ignoresSafeArea()
                VStack {
                    Text("Tic Tac Toe")
                        .font(.system(.largeTitle, design: .default, weight: .heavy))
                        .fontWidth(.expanded)
                    
                    VStack(spacing: 10) {
                        Button {
                            selectedMode = .onePlayer(difficulty: selectedDifficulty)
                        } label: {
                            HStack {
                                Text("1 Player:")
                                
                                Menu {
                                    Picker(selection: $selectedDifficulty) {
                                        ForEach(Difficulty.allCases) {
                                            Text($0.rawValue)
                                                .tag($0)
                                        }
                                    } label: {}
                                } label: {
                                    Text(selectedDifficulty.rawValue)
                                        .underline()
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(Color.red.opacity(0.65))
                            .font(.system(.largeTitle, design: .default, weight: .heavy))
                            .fontWidth(.expanded)
                        }
                        .buttonStyle(.plain)
                        .matchedTransitionSource(id: "onePlayerCard", in: animationNamespace)
                        
                        Button {
                            selectedMode = .twoPlayer
                        } label: {
                            HStack {
                                Text("2 Players")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(Color.blue.opacity(0.4))
                            .font(.system(.largeTitle, design: .default, weight: .heavy))
                            .fontWidth(.expanded)
                        }
                        .buttonStyle(.plain)
                        .matchedTransitionSource(id: "twoPlayerCard", in: animationNamespace)
                        
                        Button {
                            withAnimation(.linear) {
                                isShowingStats.toggle()
                            }
                        } label: {
                            HStack {
                                VStack(spacing: 10) {
                                    Text("Stats")
                                    
                                    if isShowingStats {
                                        VStack {
                                            Text("Wins: \(stats.wins)")
                                            Text("Losses: \(stats.losses)")
                                            Text("Draws: \(stats.draws)")
                                        }
                                        .font(.system(.title3, design: .default, weight: .bold))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: isShowingStats ? 150 : 60)
                            .background(Color.teal.opacity(0.5))
                            .font(.system(.title2, design: .default, weight: .black))
                            .fontWidth(.expanded)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationDestination(item: $selectedMode) { mode in
                #if os(iOS)
                GameView(mode: mode)
                    .navigationTransition(.zoom(sourceID: transitionID(for: mode), in: animationNamespace))
                #else
                GameView(mode: mode)
                #endif
            }
        }
    }
    
    private func transitionID(for mode: GameMode) -> String {
        switch mode {
            case .onePlayer: "onePlayerCard"
            case .twoPlayer: "twoPlayerCard"
        }
    }
}

#Preview {
    ContentView()
        .environment(Stats.load())
}
