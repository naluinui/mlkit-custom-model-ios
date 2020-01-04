import Foundation
import FirebaseMLCommon
import FirebaseMLModelInterpreter

class TicTacToeInterpreter {
    
    var isRemoteModel = false
    
    private var interpreter: ModelInterpreter?
    private let inputOutputOptions = ModelInputOutputOptions()
    
    func prepare() {
        guard interpreter == nil else { return }
        
        // configure local model
        guard let modelPath = Bundle.main.path(forResource: "tictactoe", ofType: "tflite") else {
            print("model file not found")
            return
        }

        let localModel = CustomLocalModel(modelPath: modelPath)
        
        // configure remote model
        let remoteModel = CustomRemoteModel(name: "tictactoe")
        let downloadConditions = ModelDownloadConditions(allowsCellularAccess: true, allowsBackgroundDownloading: true)
        let downloadProgress = ModelManager.modelManager().download(remoteModel, conditions: downloadConditions)
        
        // create a model interpreter
        if ModelManager.modelManager().isModelDownloaded(remoteModel) {
          interpreter = ModelInterpreter.modelInterpreter(remoteModel: remoteModel)
          isRemoteModel = true
        } else {
          interpreter = ModelInterpreter.modelInterpreter(localModel: localModel)
        }
        
        try! inputOutputOptions.setInputFormat(index: 0, type: .float32, dimensions: [3,3])
        try! inputOutputOptions.setOutputFormat(index: 0, type: .float32, dimensions: [3,3])
    }
    
    func run(_ input: [[Float]], completion: @escaping ([[Float]]?) -> Void) {
        guard let interpreter = interpreter else {
            print("interpreter must be prepared before run")
            completion(nil)
            return
        }
        
        guard input.count == 3, input[0].count == 3, input[1].count == 3, input[2].count == 3 else {
            print("input is wrong dimension")
            completion(nil)
            return
        }
        
        let inputs = ModelInputs()
        try! inputs.addInput(input)

        interpreter.run(inputs: inputs, options: inputOutputOptions) { (outputs, error) in
            guard error == nil, let outputs = outputs else {
                print(error!.localizedDescription)
                completion(nil)
                return
            }
            
            guard let outputAny = try? outputs.output(index: 0),
                let outputValues = outputAny as? [[NSNumber]] else {
                    print("output shape is invalid (should be dim 2)")
                    completion(nil)
                    return
            }
            
            let result = outputValues.map { $0.map({ $0.floatValue }) }
            completion(result)
        }
    }
    
}
