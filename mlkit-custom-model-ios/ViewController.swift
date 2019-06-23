//
//  ViewController.swift
//  mlkit-custom-model-ios
//
//  Created by Somjintana Korbut on 23/6/2562 BE.
//  Copyright © 2562 Nui.swift. All rights reserved.
//

import UIKit
import FirebaseMLCommon
import FirebaseMLModelInterpreter

class ViewController: UIViewController {
    
    private lazy var manager = ModelInterpreterManager()
    
    private var isRemoteModelDownloaded: Bool {
        return UserDefaults.standard.bool(forKey: Constants.isRemoteModelDownloadedUserDefaultsKey)
    }
    private var isLocalModelLoaded = false
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var resultView: UITextView!
    @IBOutlet weak var downloadProgressView: UIProgressView!
    @IBOutlet weak var detectButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setUpLocalModel()
        setUpRemoteModel()
        downloadRemoteModel()
    }
    
    // MARK: IBAction
    
    @IBAction func detectButtonDidTouch(_ sender: UIButton) {
        
        guard let image = imageView.image else {
            showResultView(with: "Image cannot be nil")
            return
        }
        
        // Load model
        if isRemoteModelDownloaded {
            showResultView(with: "Loading the remote model...\n")
            loadRemoteModel()
        } else {
            showResultView(with: "Loading the local model...\n")
            loadLocalModel()
        }
        
        // Convert image to data
        let data = manager.scaledImageData(from: image, with: Constants.imageSize, componentCount: Constants.componentCount, elementType: Constants.elementType, batchSize: Constants.batchSize)
        
        // TODO: Detect pose
        /*
        manager.detectObjects(in: data, topResultsCount: Constants.topResultsCount) { (result, error) in
            
            if let error = error {
                self.showResultView(with: error.localizedDescription)
                return
            }
            
            var inferenceMessageString = "Inference results using "
            if self.isRemoteModelDownloaded {
                inferenceMessageString += "remote model:\n"
            } else {
                inferenceMessageString += "local model:\n"
            }
            
            self.showResultView(with: inferenceMessageString + self.detectionResultsString(fromResults: result))
        }
        */
    }
    
    // MARK: Model
    
    private func setUpRemoteModel() {
        let modelName = Constants.modelInfo.name
        if !manager.setUpRemoteModel(name: modelName) {
            showResultView(with: "\(resultView.text ?? "")\nFailed to set up the `\(modelName)` " +
                "remote model.")
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
            showResultView(with: "\(resultView.text ?? "")\nFailed to set up the local model.")
        }
    }
    
    private func downloadRemoteModel() {
        let name = Constants.modelInfo.name
        let modelManager = ModelManager.modelManager()
        guard let remoteModel = modelManager.remoteModel(withName: name) else {
            showResultView(with: "Failed to download remote model with name: \(name) because the model " +
                "was not registered with the Model Manager.")
            return
        }
        downloadProgressView.observedProgress = modelManager.download(remoteModel)
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
            self.detectButton.isEnabled = true
            self.showResultView(with: "Successfully downloaded the remote model with name: " + "\(remoteModel.name). The model is ready for detection.")
        }
        if Thread.isMainThread { notificationHandler(); return }
        DispatchQueue.main.async { notificationHandler() }
    }
    
    @objc
    private func remoteModelDownloadDidFail(_ notification: Notification) {
        let notificationHandler = {
            self.showResultView(with: nil)
            self.detectButton.isEnabled = true
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

}

// MARK: - View support

extension ViewController {
    
    func setupView() {
        hideResultView()
        imageView.image = UIImage(named: Constants.images[0].file)
    }
    
    func showResultView(with text: String? = nil) {
        resultView.text = text
        resultView.isHidden = false
    }
    
    func hideResultView() {
        resultView.text = nil
        resultView.isHidden = true
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

// MARK: Picker view

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Constants.images.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Constants.images[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        hideResultView()
        let imageDisplay = Constants.images[row]
        imageView.image = UIImage(named: imageDisplay.file)
    }
}


