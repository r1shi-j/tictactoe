//
//  GameView.swift
//  tictactoe
//
//  Created by Rishi Jansari on 26/08/2026.
//

import SwiftUI

struct GameView: View {
    @State private var gameBoard: [[Tile]] = GameView.setupGameBoard()
    @State private var whoMoves: Symbol = .cross
    @State private var whoStarts: Side
    @State private var endState: EndState?
    @State private var isObserving = false
    let mode: GameMode
    @Environment(Stats.self) private var stats
    
    init(mode: GameMode) {
        self.mode = mode
        
        if mode == .twoPlayer {
            _whoStarts = State(initialValue: .human)
        } else {
            _whoStarts = State(initialValue: Side.allCases.randomElement()!)
        }
    }
    
    private var isHumanMove: Bool {
        if mode == .twoPlayer { return true }
        
        switch whoStarts {
            case .human:
                return whoMoves == .cross
            case .computer:
                return whoMoves != .cross
        }
    }
    
    private let winnableIndexPairs = [
        [(0,0), (1,0), (2,0)],
        [(0,1), (1,1), (2,1)],
        [(0,2), (1,2), (2,2)],
        [(0,0), (0,1), (0,2)],
        [(1,0), (1,1), (1,2)],
        [(2,0), (2,1), (2,2)],
        [(0,0), (1,1), (2,2)],
        [(0,2), (1,1), (2,0)]
    ]
    
    private let cornerIndexPairs = [
        (0,0), (0,2), (2,0), (2,2)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                mode.viewBackground.ignoresSafeArea()
                VStack {
                    grid()
                        .overlay {
                            if endState == nil && !isObserving {
                                Text("\(mode == .twoPlayer ? whoMoves.rawValue : (isHumanMove ? "Human" : "Computer")) move")
                                    .font(.system(.largeTitle, design: .serif, weight: .heavy))
                                    .offset(y: -210)
                            }
                        }
                }
            }
            .task(id: !isHumanMove) {
                guard !isHumanMove else { return }
                
                try? await Task.sleep(for: .milliseconds(500))
                
                computerMove()
                if checkForWin() { return }
                if checkForDraw() { return }
                whoMoves.swap()
            }
//            .onAppear {
//                guard mode != .twoPlayer else { return }
//                if whoStarts == .computer {
////                    withAnimation {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
//                        
//                            computerMove()
//                            whoMoves.swap()
//                        }
////                    }
//                }
//            }
            .allowsHitTesting(!isObserving && isHumanMove)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .title) {
                    Text(mode.viewTitle)
                        .fontWidth(.expanded)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset", systemImage: "arrow.trianglehead.counterclockwise") {
//                        withAnimation {
                            isObserving = false
                            resetGame()
//                        }
                    }
                }
            }
            .alert(endState == .draw ? "Draw" : "\(mode == .twoPlayer ? whoMoves.rawValue : (isHumanMove ? "Human" : "Computer")) won", item: $endState) { _ in
                Button("Observe", role: .close) {
//                    withAnimation {
                        isObserving = true
//                    }
                }
                Button("New Game", role: .confirm) {
//                    withAnimation {
                        resetGame()
//                    }
                }
            }
        }
    }
    
    private func grid() -> some View {
        Grid(alignment: .center, horizontalSpacing: 20, verticalSpacing: 20) {
            ForEach(0..<3) { row in
                GridRow(alignment: .center) {
                    ForEach(0..<3) { col in
                        ZStack {
                            Rectangle()
                                .frame(width: 100, height: 100)
                                .foregroundStyle(mode.gridForeground)
                            if let symbol = gameBoard[row][col].symbol {
                                Image(symbol.rawValue.lowercased())
                                    .resizable()
                                    .frame(width: symbol.length, height: symbol.length)
                                    .foregroundStyle(mode.iconForeground)
                                    .transition(.scale(scale: 0.9))
                            }
                        }
                        .onTapGesture {
                            // check if already occupied
                            guard gameBoard[row][col].symbol == nil else { return }
//                            withAnimation {
                                gameBoard[row][col].symbol = whoMoves // place move
                                if checkForWin() { return } // check for win
                                if checkForDraw() { return } // check for draw
                                whoMoves.swap() // game not ended so swap move
//                            }
                            
                            // if computer then go
//                            guard mode != .twoPlayer else { return }
////                            withAnimation {
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
//                                
//                                    computerMove()
//                                    if checkForWin() { return }
//                                    if checkForDraw() { return }
//                                    whoMoves.swap()
//                                }
//                            }
                        }
                    }
                }
            }
        }
        .background(mode.gridBackground)
    }
    
    private static func setupGameBoard() -> [[Tile]] {
        var tempGameBoard: [[Tile]] = []
        for i in 0..<3 {
            tempGameBoard.append([])
            for j in 0..<3 {
                tempGameBoard[i].append(Tile(id: "\(i)-\(j)"))
            }
        }
        return tempGameBoard
    }
    
    private func resetGame() {
        gameBoard = GameView.setupGameBoard()
        whoMoves = .cross
        whoStarts = Side.allCases.randomElement()!
        
//        guard mode != .twoPlayer else { return }
//        if whoStarts == .computer {
////            withAnimation {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
//                
//                    computerMove()
//                    whoMoves.swap()
//                }
////            }
//        }
    }
    
    private func computerMove() {
        func easy() {
            // completely random move
            var randomI = Int.random(in: 0..<3)
            var randomJ = Int.random(in: 0..<3)
            while gameBoard[randomI][randomJ].symbol != nil {
                randomI = Int.random(in: 0..<3)
                randomJ = Int.random(in: 0..<3)
            }
            gameBoard[randomI][randomJ].symbol = whoMoves
        }
        
        func twoOutOfThree(indexPairs: [(Int, Int)]) -> Bool {
            // checking if any win route of 2/3 already complete, then finish off
            if gameBoard[indexPairs[0].0][indexPairs[0].1].symbol == nil,
               gameBoard[indexPairs[1].0][indexPairs[1].1].symbol == whoMoves,
               gameBoard[indexPairs[2].0][indexPairs[2].1].symbol == whoMoves {
                gameBoard[indexPairs[0].0][indexPairs[0].1].symbol = whoMoves
                return true
            }
            
            if gameBoard[indexPairs[0].0][indexPairs[0].1].symbol == whoMoves,
               gameBoard[indexPairs[1].0][indexPairs[1].1].symbol == nil,
               gameBoard[indexPairs[2].0][indexPairs[2].1].symbol == whoMoves {
                gameBoard[indexPairs[1].0][indexPairs[1].1].symbol = whoMoves
                return true
            }
            
            if gameBoard[indexPairs[0].0][indexPairs[0].1].symbol == whoMoves,
               gameBoard[indexPairs[1].0][indexPairs[1].1].symbol == whoMoves,
               gameBoard[indexPairs[2].0][indexPairs[2].1].symbol == nil {
                gameBoard[indexPairs[2].0][indexPairs[2].1].symbol = whoMoves
                return true
            }
            
            // if no winning for us then see if can block
            // checking if any win route for enemy of 2/3 already complete, then block them
            if gameBoard[indexPairs[0].0][indexPairs[0].1].symbol == nil,
               gameBoard[indexPairs[1].0][indexPairs[1].1].symbol == whoMoves.swapped(),
               gameBoard[indexPairs[2].0][indexPairs[2].1].symbol == whoMoves.swapped() {
                gameBoard[indexPairs[0].0][indexPairs[0].1].symbol = whoMoves
                return true
            }
            
            if gameBoard[indexPairs[0].0][indexPairs[0].1].symbol == whoMoves.swapped(),
               gameBoard[indexPairs[1].0][indexPairs[1].1].symbol == nil,
               gameBoard[indexPairs[2].0][indexPairs[2].1].symbol == whoMoves.swapped() {
                gameBoard[indexPairs[1].0][indexPairs[1].1].symbol = whoMoves
                return true
            }
            
            if gameBoard[indexPairs[0].0][indexPairs[0].1].symbol == whoMoves.swapped(),
               gameBoard[indexPairs[1].0][indexPairs[1].1].symbol == whoMoves.swapped(),
               gameBoard[indexPairs[2].0][indexPairs[2].1].symbol == nil {
                gameBoard[indexPairs[2].0][indexPairs[2].1].symbol = whoMoves
                return true
            }
            
            return false
        }
        
        func medium() {
            // checking for any 2/3 in a row (no diagonals)
            for indexPairs in winnableIndexPairs.dropLast(2).shuffled() {
                if twoOutOfThree(indexPairs: indexPairs) { return }
            }
            
            // no strategic moves so pick a random tile
            easy()
        }
        
        func hard() {
            // checking for any 2/3 in a row
            for indexPairs in winnableIndexPairs.shuffled() {
                if twoOutOfThree(indexPairs: indexPairs) { return }
            }
            
            // checking corner tiles
            for indexPair in cornerIndexPairs.shuffled() {
                if gameBoard[indexPair.0][indexPair.1].symbol == nil {
                    gameBoard[indexPair.0][indexPair.1].symbol = whoMoves
                    return
                }
            }
            
            // checking middle tile
            if gameBoard[1][1].symbol == nil {
                gameBoard[1][1].symbol = whoMoves
                return
            }
            
            // no strategic moves so pick a random tile
            easy()
        }
        
        if mode == .onePlayer(difficulty: .easy) {
            easy()
        } else if mode == .onePlayer(difficulty: .medium) {
            medium()
        } else if mode == .onePlayer(difficulty: .hard) {
            hard()
        }
    }
    
    private func checkForWin() -> Bool {
        for indexPairs in winnableIndexPairs {
            var symbols: [Tile] = []
            for indexPair in indexPairs {
                symbols.append(gameBoard[indexPair.0][indexPair.1])
            }
            let symbolsM = symbols.compactMap(\.symbol)
            if symbolsM.count == 3, Set(symbolsM).count == 1 {
                endState = .win(whoMoves)
                if mode != .twoPlayer {
                    if isHumanMove {
                        stats.wins += 1
                    } else {
                        stats.losses += 1
                    }
                }
                // TODO: draw winning line
                return true
            }
        }
        return false
    }
    
    private func checkForDraw() -> Bool {
        let allValues = gameBoard.flatMap({ $0 }).compactMap(\.symbol)
        if allValues.count == 9 {
            endState = .draw
            stats.draws += 1
            return true
        }
        return false
    }
}

//#Preview {
//    GameView(mode: .onePlayer(difficulty: .easy))
//}
