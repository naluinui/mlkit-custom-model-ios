import Foundation
import FirebaseMLCommon
import FirebaseMLModelInterpreter

class YamnetInterpreter {
    
    var numOfSamples = 15600
    var minConfidence: Float = 0.1
    
    private var interpreter: ModelInterpreter?
    private let inputOutputOptions = ModelInputOutputOptions()
    private let labels = Labels()
    
    func prepare() {
        guard interpreter == nil else { return }
        
        // configure local model
        guard let modelPath = Bundle.main.path(forResource: "yamnet", ofType: "tflite") else {
            print("model file not found")
            return
        }

        let localModel = CustomLocalModel(modelPath: modelPath)
        
        interpreter = ModelInterpreter.modelInterpreter(localModel: localModel)
        
        try! inputOutputOptions.setInputFormat(index: 0, type: .float32, dimensions: [1,NSNumber(value: numOfSamples)])
        try! inputOutputOptions.setOutputFormat(index: 0, type: .float32, dimensions: [1,521])
        try! inputOutputOptions.setOutputFormat(index: 1, type: .float32, dimensions: [96,64])
    }
    
    func run(_ input: [Float], completion: @escaping ([Score]?) -> Void) {
        guard let interpreter = interpreter else {
            print("interpreter must be prepared before run")
            completion(nil)
            return
        }
        
        guard input.count == numOfSamples else {
            print("input has wrong number of samples")
            completion(nil)
            return
        }
        
        let inputs = ModelInputs()
        try! inputs.addInput([input])

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
            
            let results = outputValues[0].map { $0.floatValue }
            
            let scores = results.indices
                .filter({ results[$0] > self.minConfidence })
                .sorted(by: { results[$0] > results[$1] })
                .map({ Score(index: $0, value: results[$0], label: self.labels.get(index: $0) ?? "") })
            
            completion(scores)
        }
    }
    
}

struct Score {
    let index: Int
    let value: Float
    let label: String
}
