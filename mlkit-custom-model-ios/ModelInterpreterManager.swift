//
//  ModelInterpreterManager.swift
//  mlkit-custom-model-ios
//
//  Created by Somjintana Korbut on 28/6/2562 BE.
//  Copyright © 2562 Nui.swift. All rights reserved.
//

import Foundation
import FirebaseMLCommon
import FirebaseMLModelInterpreter

class ModelInterpreterManager {
    
    public typealias DetectPoseCompletion = ([BodyPoint?]?, Error?) -> Void
    
    public var modelConfigurations: ModelConfigurations!
    
    private var modelOptions: ModelOptions!
    private let modelInputOutputOptions = ModelInputOutputOptions()
    private var modelInterpreter: ModelInterpreter?
    
    init(configuration: ModelConfigurations) {
        self.modelConfigurations = configuration
        setupModel()
    }
    
    // MARK: Set up model
    
    func setupModel() {
        
        var remoteModel: RemoteModel? = nil
        var localModel: LocalModel? = nil
        
        // Setup remote model
        
        if let remoteModelName = modelConfigurations.remoteModelName {
            
            let initialConditions = ModelDownloadConditions(
                allowsCellularAccess: true,
                allowsBackgroundDownloading: true
            )
            let updateConditions = ModelDownloadConditions(
                allowsCellularAccess: false,
                allowsBackgroundDownloading: true
            )
            remoteModel = RemoteModel(
                name: remoteModelName,
                allowsModelUpdates: true,
                initialConditions: initialConditions,
                updateConditions: updateConditions
            )
            
            ModelManager.modelManager().register(remoteModel!)
        }
        
        // Setup local model
        
        if let localModelFilePath = Bundle.main.path(forResource: modelConfigurations.localModelName, ofType: modelConfigurations.modelExtension) {
            localModel = LocalModel(name: modelConfigurations.localModelName, path: localModelFilePath)
            ModelManager.modelManager().register(localModel!)
        }
        
        modelOptions = ModelOptions(remoteModelName: remoteModel?.name, localModelName: localModel?.name)
        
    }
    
    // MARK: Load model
    
    func loadModel() -> Bool {
        do {
            modelInterpreter = ModelInterpreter.modelInterpreter(options: modelOptions)
            try modelInputOutputOptions.setInputFormat(
                index: modelConfigurations!.inputOutputIndex,
                type: modelConfigurations!.elementType,
                dimensions: modelConfigurations!.inputDimensions
            )
            try modelInputOutputOptions.setOutputFormat(
                index: modelConfigurations!.inputOutputIndex,
                type: modelConfigurations!.elementType,
                dimensions: modelConfigurations!.outputDimensions
            )
        } catch let error {
            print("Failed to load the model with error: \(error.localizedDescription)")
            return false
        }
        return true
    }
    
    // MARK: Detect & Process output
    
    func detect(in imageData: Data?, completion: @escaping DetectPoseCompletion) {
        
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
            self.process(outputs, completion: completion)
        }
    }
    
    func process(_ outputs: ModelOutputs, completion: @escaping DetectPoseCompletion) {
        
        let bodyPoints = outputs.toBodyPoints()
        
        if bodyPoints.count == 0 {
            completion(nil, ModelInterpreterError.invalidResults)
            return
        }
        
        completion(bodyPoints, nil)
        
    }

}

public enum ModelInterpreterError: Error {
    case invalidImageData
    case invalidResults
    case invalidModelDataType
}

// MARK: - Fileprivate

/// Safely dispatches the given block on the main queue. If the current thread is `main`, the block
/// is executed synchronously; otherwise, the block is executed asynchronously on the main thread.
fileprivate func safeDispatchOnMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread { block(); return }
    DispatchQueue.main.async { block() }
}
