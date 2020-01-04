import Foundation
import FirebaseMLCommon
import FirebaseMLModelInterpreter

class SumInterpreter {
    
    var interpreter: ModelInterpreter?
    let inputOutputOptions = ModelInputOutputOptions()
    
    func prepare() {
        guard interpreter == nil else { return }
        
        guard let modelPath = Bundle.main.path(forResource: "sum", ofType: "tflite") else {
            print("model file not found")
            return
        }
        let localModel = CustomLocalModel(modelPath: modelPath)
        interpreter = ModelInterpreter.modelInterpreter(localModel: localModel)
        
        try! inputOutputOptions.setInputFormat(index: 0, type: .float32, dimensions: [3])
        try! inputOutputOptions.setOutputFormat(index: 0, type: .float32, dimensions: [1])
    }
    
    func run(_ input: [Float], completion: @escaping (Float?) -> Void) {
        guard let interpreter = interpreter else {
            print("interpreter must be prepared before run")
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
                let outputValues = outputAny as? [NSNumber], outputValues.count == 1 else {
                    print("output shape is invalid (should be dim 1, length 1)")
                    completion(nil)
                    return
            }
            
            let result = outputValues[0].floatValue
            completion(result)
            print("result is \(result)")
        }
    }
    
}
