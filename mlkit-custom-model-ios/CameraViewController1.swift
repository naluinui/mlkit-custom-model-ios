//
//  CameraViewController.swift
//  mlkit-custom-model-ios
//
//  Created by Somjintana Korbut on 25/6/2562 BE.
//  Copyright © 2562 Nui.swift. All rights reserved.
//

import UIKit
import CoreMedia
import FirebaseMLCommon
import FirebaseMLModelInterpreter

class CameraViewController1: UIViewController {
    
    private var isInferencing = false
    
    private lazy var manager = ModelInterpreterManager()
    
    private var isRemoteModelDownloaded: Bool {
        return UserDefaults.standard.bool(forKey: Constants.isRemoteModelDownloadedUserDefaultsKey)
    }
    private var isLocalModelLoaded = false
    
    // MARK - Performance Measurement Property
    private let 👨‍🔧 = 📏()
    
    // MARK: - AV Property
    var videoCapture: VideoCapture!
    
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var jointView: JointView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLocalModel()
        setUpCamera()
        👨‍🔧.delegate = self
    }
    
    // MARK: Model
    
    private func setUpRemoteModel() {
        let modelName = Constants.modelInfo.name
        if !manager.setUpRemoteModel(name: modelName) {
//            showResultView(with: "\(resultView.text ?? "")\nFailed to set up the `\(modelName)` " +
//                "remote model.")
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(remoteModelDownloadDidSucceed(_:)),
            name: .firebaseMLModelDownloadDidSucceed,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(remoteModelDownloadDidFail(_:)),
            name: .firebaseMLModelDownloadDidFail,
            object: nil
        )
    }
    
    private func setUpLocalModel() {
        let modelName = Constants.modelInfo.name
        if !manager.setUpLocalModel(name: modelName, filename: modelName, type: Constants.modelInfo.extension) {
            showResultView(with: "Failed to set up the local model.")
        }
    }
    
    private func downloadRemoteModel() {
        let name = Constants.modelInfo.name
        let modelManager = ModelManager.modelManager()
        guard let remoteModel = modelManager.remoteModel(withName: name) else {
//            showResultView(with: "Failed to download remote model with name: \(name) because the model " +
//                "was not registered with the Model Manager.")
            return
        }
        modelManager.download(remoteModel)
    }
    
    private func loadLocalModel() {
        if !manager.loadLocalModel(isQuantizedModel: Constants.elementType == .uInt8, inputOutputIndex: Constants.inputOutputIndex, inputDimensions: Constants.inputDimensions, outputDimensions: Constants.outputDimensions) {
            showResultView(with: "Failed to load the local model.")
            return
        }
        isLocalModelLoaded = true
    }
    
    private func loadRemoteModel() {
        if !manager.loadRemoteModel(isQuantizedModel: Constants.elementType == .uInt8, inputOutputIndex: Constants.inputOutputIndex, inputDimensions: Constants.inputDimensions, outputDimensions: Constants.outputDimensions) {
            showResultView(with: "Failed to load the remote model.")
        }
    }
    
    func detect(image: UIImage?) {
        isInferencing = true
        guard let image = image else {
            showResultView(with: "Image cannot be nil")
            return
        }
        
        // Load model
        //        if isRemoteModelDownloaded {
        //            showResultView(with: "Loading the remote model...\n")
        //            loadRemoteModel()
        //        } else {
//        showResultView(with: "Loading the local model...\n")
        loadLocalModel()
        //        }
        
        // Convert image to data
        let data = manager.scaledImageData(from: image, with: Constants.imageSize, componentCount: Constants.componentCount, elementType: Constants.elementType, batchSize: Constants.batchSize)
        
        // TODO: Detect pose
        manager.detectObjects(in: data) { (bodyPoints, error) in
            
            self.👨‍🔧.🏷(with: "endInference")
            
            if let error = error {
                self.showResultView(with: error.localizedDescription)
                self.👨‍🔧.🎬🤚()
                return
            }
            
            var inferenceMessageString = "Inference results using "
            if self.isRemoteModelDownloaded {
                inferenceMessageString += "remote model:\n"
            } else {
                inferenceMessageString += "local model:\n"
            }
            
            guard let bodyPoints = bodyPoints else {
                return
            }
            print("output: \(String(describing: bodyPoints))")
            
            self.jointView.bodyPoints = bodyPoints
            self.👨‍🔧.🎬🤚()
            self.isInferencing = false
        }
    }
    
    // MARK: Notifications
    
    @objc
    private func remoteModelDownloadDidSucceed(_ notification: Notification) {
        let notificationHandler = {
            self.showResultView(with: nil)
            guard let userInfo = notification.userInfo,
                let remoteModel =
                userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue] as? RemoteModel
                else {
                    self.showResultView(with: "firebaseMLModelDownloadDidSucceed notification posted without a " +
                        "RemoteModel instance.")
                    return
            }
            UserDefaults.standard.set(true, forKey: Constants.isRemoteModelDownloadedUserDefaultsKey)
//            self.detectButton.isEnabled = true
            self.showResultView(with: "Successfully downloaded the remote model with name: " + "\(remoteModel.name). The model is ready for detection.")
        }
        if Thread.isMainThread { notificationHandler(); return }
        DispatchQueue.main.async { notificationHandler() }
    }
    
    @objc
    private func remoteModelDownloadDidFail(_ notification: Notification) {
        let notificationHandler = {
            self.showResultView(with: nil)
//            self.detectButton.isEnabled = true
            guard let userInfo = notification.userInfo,
                let remoteModel =
                userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue] as? RemoteModel,
                let error = userInfo[ModelDownloadUserInfoKey.error.rawValue] as? NSError
                else {
                    self.showResultView(with: "firebaseMLModelDownloadDidFail notification posted without a " +
                        "RemoteModel instance or error.")
                    return
            }
            self.showResultView(with: "Failed to download the remote model with name: " +
                "\(remoteModel.name), error: \(error).")
        }
        if Thread.isMainThread { notificationHandler(); return }
        DispatchQueue.main.async { notificationHandler() }
    }
    
    // MARK: - SetUp Video
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 10
        videoCapture.setUp(sessionPreset: .vga640x480) { success in
            
            if success {
                // add preview view on the layer
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // start video preview when setup is done
                self.videoCapture.start()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
    
}

// MARK: - VideoCaptureDelegate
extension CameraViewController1: VideoCaptureDelegate {
    
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        
        // the captured image from camera is contained on pixelBuffer
        if !isInferencing, let pixelBuffer = pixelBuffer,
            let uiImage = UIImage(pixelBuffer: pixelBuffer) {
            
            // start of measure
            self.👨‍🔧.🎬👏()
            
            // predict!
            self.detect(image: uiImage)
        }
    }
}

// MARK: - View support

extension CameraViewController1 {
    
    func setupView() {
        hideResultView()
    }
    
    func showResultView(with text: String? = nil) {
        let setText = {
            self.statusLabel.text = text
        }
        if Thread.isMainThread { setText(); return }
        DispatchQueue.main.async { setText() }
    }
    
    func hideResultView() {
        let setText = {
            self.statusLabel.text = nil
        }
        if Thread.isMainThread { setText(); return }
        DispatchQueue.main.async { setText() }
    }
    
    /// Returns a string representation of the detection results.
    private func detectionResultsString(fromResults results: [(label: String, confidence: Float)]?) -> String {
        guard let results = results else { return "failedToDetectObjectsMessage" }
        return results.reduce("") { (resultString, result) -> String in
            let (label, confidence) = result
            return resultString + "\(label): \(String(describing: confidence))\n"
        }
    }
    
}

// MARK: - 📏(Performance Measurement) Delegate
extension CameraViewController1: 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
        print(executionTime, fps)
        showResultView(with: "inference: \(Int(inferenceTime*1000.0)) mm execution: \(Int(executionTime*1000.0)) mm fps: \(fps)")
    }
}
