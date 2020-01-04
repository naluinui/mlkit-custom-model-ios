import UIKit
import FirebaseMLCommon
import FirebaseMLModelInterpreter

class SumViewController: UIViewController {
    
    @IBOutlet var inputLabel: UILabel!
    @IBOutlet var outputLabel: UILabel!
    
    let interpreter = SumInterpreter()

    override func viewDidLoad() {
        super.viewDidLoad()

        interpreter.prepare()
    }
    
    @IBAction func refresh() {
        let input = [0,1,2].compactMap({ _ in Float.random(in: 1.0 ..< 10.0) })
        inputLabel.text = input.map({ String(format: "%.2f", $0) }).joined(separator: "  ")
        
        interpreter.run(input) { output in
            if let output = output {
                self.outputLabel.text = String(format: "%.2f", output)
            } else {
                self.outputLabel.text = "Error"
            }
        }
    }
    
}
