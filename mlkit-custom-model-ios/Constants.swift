//
//  Constants.swift
//  mlkitdemo
//
//  Created by Somjintana Korbut on 21/6/2562 BE.
//  Copyright © 2562 rfcx. All rights reserved.
//

import UIKit
import FirebaseMLModelInterpreter

struct Constants {
    
    public static let labelsInfo = (name: "labels", extension: "txt", count: 2)
    public static let modelInfo = (name: "cpm-model", extension: "tflite")
    public static let componentCount: Int = 3
    public static let batchSize: Int = 1
    public static let imageSize = CGSize(width: 192, height: 192)
    public static let elementType = ModelElementType.float32
    public static let inputOutputIndex: UInt = 0
    public static let inputDimensions = [
        NSNumber(value: batchSize),
        NSNumber(value: Int(imageSize.height)),
        NSNumber(value: Int(imageSize.width)),
        NSNumber(value: componentCount),
    ]
    public static let outputDimensions = [
        NSNumber(value: batchSize),
        NSNumber(value: 96),
        NSNumber(value: 96),
        NSNumber(value: 14)
    ]
    
    public static let images = [
        ImageDisplay(file: "000000151859.jpg", name: "Jumping"),
        ImageDisplay(file: "000000206278.jpg", name: "Skating"),
        ImageDisplay(file: "000000430193.jpg", name: "Skiing"),
        ImageDisplay(file: "000000414047.jpg", name: "Running")
    ]
    
    
    public static let isRemoteModelDownloadedUserDefaultsKey = "isRemoteModelDownloaded"
    
}

struct ImageDisplay {
    let file: String
    let name: String
}
