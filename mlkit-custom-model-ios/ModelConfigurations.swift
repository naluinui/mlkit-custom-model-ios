//
//  ModelConfigurations.swift
//  PoseEstimation-MLKit
//
//  Created by GwakDoyoung on 23/01/2019.
//  Copyright © 2019 tucan9389. All rights reserved.
//

import Foundation
import FirebaseMLModelInterpreter

protocol ModelConfigurations {
    
    var localModelName: String { get }
    var modelExtension: String { get }
    
    var remoteModelName: String? { get }
    
    var dimensionBatchSize: NSNumber { get }
    var dimensionImageWidth: NSNumber { get }
    var dimensionImageHeight: NSNumber { get }
    var dimensionComponents: NSNumber { get }
    
    var outputDimensionWidth: NSNumber { get }
    var outputDimensionHeight: NSNumber { get }
    var outputDimensionDepth: NSNumber { get }
    
    var inputOutputIndex: UInt { get }
    var elementType: ModelElementType { get }
    
    var inputDimensions: [NSNumber] { get }
    var outputDimensions: [NSNumber] { get }
    
}

// PoseEstimationForMobile tflite model configuration
// input: [1,192,192,3]
// output: [1,48,48,14]
public struct PoseEstimationModelConfigurations: ModelConfigurations {

    let localModelName = "cpm-model"
    let modelExtension = "tflite"

    let remoteModelName: String? = nil

    var dimensionBatchSize: NSNumber = 1
    var dimensionImageWidth: NSNumber = 192
    var dimensionImageHeight: NSNumber = 192
    var dimensionComponents: NSNumber = 3

    var outputDimensionWidth: NSNumber = 96
    var outputDimensionHeight: NSNumber = 96
    var outputDimensionDepth: NSNumber = 14
    
    var inputOutputIndex: UInt = 0
    var elementType = ModelElementType.float32
    
    var inputDimensions: [NSNumber] {
        return [dimensionBatchSize, dimensionImageWidth, dimensionImageHeight, dimensionComponents]
    }
    
    var outputDimensions: [NSNumber] {
        return [1, outputDimensionWidth, outputDimensionHeight, outputDimensionDepth]
    }
    
}
