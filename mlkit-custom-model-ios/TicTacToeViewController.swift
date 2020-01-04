import UIKit

class TicTacToeViewController: UIViewController {
    
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet var nextMoveButton: UIButton!
    
    var boardState: [[Mark]] = [[.empty, .empty, .empty],
                                [.empty, .empty, .empty],
                                [.empty, .empty, .empty]]
    var nextMove: Mark = .cross
    
    let interpreter = TicTacToeInterpreter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        interpreter.prepare()

        for i in 0..<buttons.count {
            let state = boardState[i/3][i%3]
            buttons[i].setImage(state.image, for: .normal)
        }
    }
    
    @IBAction func buttonPressed(_ button: UIButton) {
        let i = button.tag - 1
        let state = boardState[i/3][i%3]
        switch state {
        case .empty:
            boardState[i/3][i%3] = .nought
            button.setImage(Mark.nought.image, for: .normal)
        case .nought:
            boardState[i/3][i%3] = .cross
            button.setImage(Mark.cross.image, for: .normal)
        case .cross:
            boardState[i/3][i%3] = .empty
            button.setImage(Mark.empty.image, for: .normal)
        }
        
        updateBestMoves()
    }
    
    @IBAction func toggleNextMove(_ button: UIButton) {
        if nextMove == .cross {
            nextMove = .nought
        } else {
            nextMove = .cross
        }
        nextMoveButton.setImage(nextMove.image, for: .normal)
        
        updateBestMoves()
    }
    
    func updateBestMoves() {
        let modelInput = boardState.map { row in row.map { $0.value(nextMove: nextMove) } }
        interpreter.run(modelInput) { output in
            guard let output = output else {
                return
            }
            print(output)
            self.updateButtons(bestMoves: output)
        }
    }
    
    func updateButtons(bestMoves: [[Float]]) {
        let heatmap = bestMoves.map { row in row.map { $0.color } }
        for i in 0..<buttons.count {
            buttons[i].backgroundColor = heatmap[i/3][i%3]
            buttons[i].setTitle(String(format: "%.2f", bestMoves[i/3][i%3]), for: .normal)
        }
    }
}

enum Mark {
    case empty
    case nought
    case cross
    
    var image: UIImage? {
        switch self {
        case .empty:
            return nil
        case .nought:
            return UIImage(named: "nought")
        case .cross:
            return UIImage(named: "cross")
        }
    }
    
    func value(nextMove: Mark) -> Float {
        if nextMove == self {
            return 1.0
        }
        if self == .empty {
            return 0.0
        }
        return -1.0
    }
}

extension Float {
    var color: UIColor {
        let value = 1 - CGFloat(max(0, min(10, Int(self * 10)))) / 10
        return UIColor(white: value, alpha: 1.0)
    }
}
