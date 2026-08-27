//
//  GameView.swift
//  tictactoe
//
//  Created by Rishi Jansari on 26/08/2026.
//

import SwiftUI

struct GameView: View {
    @State private var gameBoard: [[Tile]] = GameView.setupGameBoard()
    @State private var whoStarts: Side
    @State private var whoMoves: Symbol = .cross
    @State private var turnTrigger = UUID()
    @State private var endState: EndState?
    @State private var isObserving = false
    @State private var isWaitingForAlert = false
    @State private var winningLine: [(Int, Int)]? = nil
    @State private var lineProgress: CGFloat = 0.0
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
    
    private let tileSize: CGFloat = 100
    private let tileSpacing: CGFloat = 20
    
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
                        .allowsHitTesting(endState == nil && !isObserving && isHumanMove && !isWaitingForAlert)
                        .overlay {
                            if endState == nil && !isObserving {
                                Text("\(mode == .twoPlayer ? whoMoves.rawValue : (isHumanMove ? "Your" : "Computer")) move")
                                    .font(.system(.largeTitle, design: .serif, weight: .heavy))
                                    .offset(y: -210)
                                    .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: endState == nil && !isObserving)
                }
            }
            .task(id: turnTrigger) {
                guard !isHumanMove, endState == nil && !isObserving && !isWaitingForAlert else { return }
                
                try? await Task.sleep(for: .milliseconds(500)) // wait 0.5s
                computerMove() // place move
                if checkForWin() || checkForDraw() { return } // check for win or draw
                whoMoves.swap() // game not ended so swap move
                turnTrigger = UUID() // reset computer move trigger
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .title) {
                    Text(mode.viewTitle)
                        .fontWidth(.expanded)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset", systemImage: "arrow.trianglehead.counterclockwise") {
                        resetGame()
                    }
                    .disabled(isWaitingForAlert)
                }
            }
            .alert(endState == .draw ? "Draw" : "\(mode == .twoPlayer ? whoMoves.rawValue : (isHumanMove ? "Human" : "Computer")) won", item: $endState) { _ in
                Button("Observe", role: .close) {
                    isWaitingForAlert = false
                    isObserving = true
                }
                Button("New Game", role: .confirm) {
                    resetGame()
                }
            }
        }
    }
    
    private func grid() -> some View {
        Grid(alignment: .center, horizontalSpacing: tileSpacing, verticalSpacing: tileSpacing) {
            ForEach(0..<3) { row in
                GridRow(alignment: .center) {
                    ForEach(0..<3) { col in
                        ZStack {
                            Rectangle()
                                .frame(width: tileSize, height: tileSize)
                                .foregroundStyle(mode.gridForeground)
                            if let symbol = gameBoard[row][col].symbol {
                                Image(symbol.rawValue.lowercased())
                                    .resizable()
                                    .frame(width: symbol.length, height: symbol.length)
                                    .foregroundStyle(mode.iconForeground)
                            }
                        }
                        .onTapGesture {
                            // check if already occupied
                            guard gameBoard[row][col].symbol == nil else { return }
                            gameBoard[row][col].symbol = whoMoves // place move
                            if checkForWin() || checkForDraw() { return } // check for win or draw
                            whoMoves.swap() // game not ended so swap move
                            turnTrigger = UUID() // reset computer move trigger
                        }
                    }
                }
            }
        }
        .background(mode.gridBackground)
        .overlay {
            winningLineOverlay()
        }
    }
    
    private func winningLineOverlay() -> some View {
        GeometryReader { _ in
            if let line = winningLine, let endpoints = lineBoundaryPoints(for: line) {
                Path { path in
                    path.move(to: endpoints.start)
                    path.addLine(to: endpoints.end)
                }
                .trim(from: 0, to: lineProgress)
                .stroke(mode.primaryColor.gradient, style: StrokeStyle(lineWidth: 12, lineCap: .square))
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        lineProgress = 1.0
                    }
                }
            }
        }
    }
    
    private func lineBoundaryPoints(for line: [(Int, Int)]) -> (start: CGPoint, end: CGPoint)? {
        guard let first = line.first, let last = line.last else { return nil }
        
        let totalSize: CGFloat = 3*tileSize + 2*tileSpacing
        let inset: CGFloat = 10
        
        if first.0 == last.0 {
            let y = (CGFloat(first.0) * (tileSize+tileSpacing)) + (tileSize/2)
            return (CGPoint(x: inset, y: y), CGPoint(x: totalSize - inset, y: y))
        }
        
        if first.1 == last.1 {
            let x = (CGFloat(first.1) * (tileSize+tileSpacing)) + (tileSize/2)
            return (CGPoint(x: x, y: inset), CGPoint(x: x, y: totalSize - inset))
        }
        
        if first == (0, 0) && last == (2, 2) {
            return (CGPoint(x: inset, y: inset), CGPoint(x: totalSize - inset, y: totalSize - inset))
        }
        
        if first == (0, 2) && last == (2, 0) {
            return (CGPoint(x: totalSize - inset, y: inset), CGPoint(x: inset, y: totalSize - inset))
        }
        
        return nil
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
        withAnimation(.easeInOut(duration: 0.1)) { lineProgress = 0 }
        gameBoard = GameView.setupGameBoard()
        whoStarts = (mode == .twoPlayer) ? .human : Side.allCases.randomElement()!
        whoMoves = .cross
        turnTrigger = UUID()
        endState = nil
        isObserving = false
        isWaitingForAlert = false
        winningLine = nil
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
            // if opponent in corner then we choose opposite if empty
            for indexPair in cornerIndexPairs.shuffled() {
                if gameBoard[indexPair.0][indexPair.1].symbol == whoMoves.swapped() {
                    let newIndexPair = ((indexPair.0 == 0 ? 2 : 0), (indexPair.1 == 0 ? 2 : 0))
                    if gameBoard[newIndexPair.0][newIndexPair.1].symbol == nil {
                        gameBoard[newIndexPair.0][newIndexPair.1].symbol = whoMoves
                        return
                    }
                }
            }
            
            // if opposite corner not available then choose any other corner
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
            
            // should not run
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
                winningLine = indexPairs
                
                isWaitingForAlert = true
                Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    
                    endState = .win(whoMoves)
                    if mode != .twoPlayer {
                        if isHumanMove {
                            stats.wins += 1
                        } else {
                            stats.losses += 1
                        }
                    }
                }
                return true
            }
        }
        return false
    }
    
    private func checkForDraw() -> Bool {
        let allValues = gameBoard.flatMap({ $0 }).compactMap(\.symbol)
        if allValues.count == 9 {
            isWaitingForAlert = true
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                
                endState = .draw
                stats.draws += 1
            }
            return true
        }
        return false
    }
}

//#Preview {
//    GameView(mode: .onePlayer(difficulty: .easy))
//}
