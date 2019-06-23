//
//  ModelInterpreterManager.swift
//  mlkit-custom-model-ios
//
//  Created by Somjintana Korbut on 23/6/2562 BE.
//  Copyright © 2562 Nui.swift. All rights reserved.
//

import UIKit
import FirebaseMLCommon
import FirebaseMLModelInterpreter

public enum ModelInterpreterError: Error {
    case invalidImageData
    case invalidResults
    case invalidModelDataType
}

public class ModelInterpreterManager {
    
    public typealias DetectObjectsCompletion = ([(label: String, confidence: Float)]?, Error?) -> Void
    
    private let modelInputOutputOptions = ModelInputOutputOptions()
    private var remoteModelOptions: ModelOptions?
    private var localModelOptions: ModelOptions?
    private var modelInterpreter: ModelInterpreter?
    private var modelElementType: ModelElementType = .float32
    private var labels = [String]()
    
    public func setUpRemoteModel(name: String) -> Bool {
        let initialConditions = ModelDownloadConditions(
            allowsCellularAccess: true,
            allowsBackgroundDownloading: true
        )
        let updateConditions = ModelDownloadConditions(
            allowsCellularAccess: false,
            allowsBackgroundDownloading: true
        )
        let remoteModel = RemoteModel(
            name: name,
            allowsModelUpdates: true,
            initialConditions: initialConditions,
            updateConditions: updateConditions
        )
        
        ModelManager.modelManager().register(remoteModel)
        
        remoteModelOptions = ModelOptions(remoteModelName: name, localModelName: nil)
        return true
    }
    
    public func setUpLocalModel(name: String, filename: String, type: String, bundle: Bundle = .main) -> Bool {
        guard let localModelFilePath = bundle.path(
            forResource: filename,
            ofType: type)
            else {
                print("Failed to get the local model file path.")
                return false
        }
        let localModel = LocalModel(name: name, path: localModelFilePath)
        ModelManager.modelManager().register(localModel)
        localModelOptions = ModelOptions(remoteModelName: nil, localModelName: name)
        return true
    }
    
    public func loadRemoteModel(
        isQuantizedModel: Bool,
        inputOutputIndex: UInt,
        inputDimensions: [NSNumber],
        outputDimensions: [NSNumber]
        ) -> Bool {
        guard let remoteModelOptions = remoteModelOptions else {
            print("Failed to load the remote model because the options are nil.")
            return false
        }
        return loadModel(
            options: remoteModelOptions,
            isQuantizedModel: isQuantizedModel,
            inputOutputIndex: inputOutputIndex,
            inputDimensions: inputDimensions,
            outputDimensions: outputDimensions
        )
    }
    
    public func loadLocalModel(
        isQuantizedModel: Bool,
        inputOutputIndex: UInt,
        inputDimensions: [NSNumber],
        outputDimensions: [NSNumber]
        ) -> Bool {
        guard let localModelOptions = localModelOptions else {
            print("Failed to load the local model because the options are nil.")
            return false
        }
        return loadModel(
            options: localModelOptions,
            isQuantizedModel: isQuantizedModel,
            inputOutputIndex: inputOutputIndex,
            inputDimensions: inputDimensions,
            outputDimensions: outputDimensions
        )
    }
    
    func loadModel(
        options: ModelOptions,
        isQuantizedModel: Bool,
        inputOutputIndex: UInt,
        inputDimensions: [NSNumber],
        outputDimensions: [NSNumber],
        bundle: Bundle = .main
        ) -> Bool {
        do {
//            guard let labelsPath = bundle.path(
//                forResource: "labels",
//                ofType: "txt")
//                else {
//                    print("Failed to get the labels file path.")
//                    return false
//            }
//            let contents = try String(contentsOfFile: labelsPath, encoding: .utf8)
//            labels = contents.components(separatedBy: CharacterSet.newlines)
            modelInterpreter = ModelInterpreter.modelInterpreter(options: options)
            try modelInputOutputOptions.setInputFormat(
                index: inputOutputIndex,
                type: ModelElementType.float32,
                dimensions: inputDimensions
            )
            try modelInputOutputOptions.setOutputFormat(
                index: inputOutputIndex,
                type: ModelElementType.float32,
                dimensions: outputDimensions
            )
        } catch let error {
            print("Failed to load the model with error: \(error.localizedDescription)")
            return false
        }
        return true
    }
    
    public func detectObjects(
        in imageData: Data?,
        topResultsCount: Int,
        completion: @escaping DetectObjectsCompletion
        ) {
        guard let imageData = imageData else {
            safeDispatchOnMain {
                completion(nil, ModelInterpreterError.invalidImageData)
            }
            return
        }
        let inputs = ModelInputs()
        do {
            try inputs.addInput(imageData)
        } catch let error {
            print("Failed to add the image data input with error: \(error.localizedDescription)")
            safeDispatchOnMain {
                completion(nil, error)
            }
            return
        }
        modelInterpreter?.run(inputs: inputs, options: modelInputOutputOptions) { (outputs, error) in
            guard error == nil, let outputs = outputs else {
                completion(nil, error)
                return
            }
            self.process(outputs, topResultsCount: topResultsCount, completion: completion)
        }
    }
    
    private func process(
        _ outputs: ModelOutputs,
        topResultsCount: Int,
        completion: @escaping DetectObjectsCompletion
        ) {
        
        let output: [[NSNumber]]?
        do {
            // Get the output for the first batch, since the default batch size is 1.
            output = try outputs.output(index: 0) as? [[NSNumber]]
        } catch let error {
            print("Failed to process detection outputs with error: \(error.localizedDescription)")
            completion(nil, error)
            return
        }
        
        guard let firstOutput = output?.first else {
            print("Failed to get the results array from output.")
            completion(nil, ModelInterpreterError.invalidResults)
            return
        }
        
        print(firstOutput.first!.floatValue)
        
        let confidences: [Float]
        switch modelElementType {
        case .uInt8:
            confidences = firstOutput.map { quantizedValue in
                Softmax.scale * Float(quantizedValue.intValue - Softmax.zeroPoint)
            }
        case .float32:
            confidences = firstOutput.map { $0.floatValue }
        default:
            completion(nil, ModelInterpreterError.invalidModelDataType)
            return
        }
        
        print("output: \(String(describing: output))")
        
        // Create a zipped array of tuples [(labelIndex: Int, confidence: Float)].
        let zippedResults = zip(labels.indices, confidences)
        
        // Sort the zipped results by confidence value in descending order.
        let sortedResults = zippedResults.sorted { $0.1 > $1.1 }.prefix(topResultsCount)
        
        // Create an array of tuples with the results as [(label: String, confidence: Float)].
        let results = sortedResults.isEmpty ? nil : sortedResults.map { (labels[$0], $1) }
        completion(results, nil)
    }
    
    public func scaledImageData(
        from image: UIImage,
        with size: CGSize,
        componentCount: Int,
        elementType: ModelElementType,
        batchSize: Int
        ) -> Data? {
        guard let scaledImageData = image.scaledData(
            with: size,
            byteCount: Int(size.width) * Int(size.height) * componentCount * batchSize,
            isQuantized: (elementType == .uInt8))
            else {
                print("Failed to get scaled image data with size: \(size).")
                return nil
        }
        return scaledImageData
    }
}

// MARK: - Internal

/// Default quantization parameters for Softmax. The Softmax function is normally implemented as the
/// final layer, just before the output layer, of a neural-network based classifier.
///
/// Quantized values can be mapped to float values using the following conversion:
///   `realValue = scale * (quantizedValue - zeroPoint)`.
enum Softmax {
    static let zeroPoint: Int = 0
    static var scale: Float { return Float(1.0 / (maxUInt8QuantizedValue + normalizerValue)) }
    
    // MARK: - Private
    
    private static let maxUInt8QuantizedValue = 255.0
    private static let normalizerValue = 1.0
}

// MARK: - Fileprivate

/// Safely dispatches the given block on the main queue. If the current thread is `main`, the block
/// is executed synchronously; otherwise, the block is executed asynchronously on the main thread.
fileprivate func safeDispatchOnMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread { block(); return }
    DispatchQueue.main.async { block() }
}
