//
//  CameraViewController.swift
//  mlkit-custom-model-ios
//
//  Created by Somjintana Korbut on 28/6/2562 BE.
//  Copyright © 2562 Nui.swift. All rights reserved.
//

import UIKit
import CoreMedia

class CameraViewController: UIViewController {
    
    private lazy var modelConfigurations = PoseEstimationModelConfigurations()
    private lazy var manager = ModelInterpreterManager(configuration: modelConfigurations)
    
    private var isInferencing = false
    private var videoCapture: VideoCapture!
    private let measure = PerformanceMeasure()
    
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var jointView: JointView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setUpCamera()
        measure.delegate = self
    }
    
    func detect(image: UIImage) {
        
        // Load model
        
        if !manager.loadModel() {
            updateStatus(with: "Failed to load the model.")
        }
        
        // Convert image to data
        
        let size = CGSize(width: modelConfigurations.dimensionImageWidth.intValue, height: modelConfigurations.dimensionImageHeight.intValue)
        let data = image.scaledData(with: size, byteCount: Int(size.width) * Int(size.height) * modelConfigurations.dimensionComponents.intValue * modelConfigurations.dimensionBatchSize.intValue, isQuantized: modelConfigurations.elementType == .uInt8)
        
        // Detect pose
        manager.detect(in: data) { (bodyPoints, error) in
            
            self.measure.label(with: "endInference")
            
            if let error = error {
                self.updateStatus(with: error.localizedDescription)
                self.measure.stop()
                return
            }
            
            guard let bodyPoints = bodyPoints else {
                return
            }
            print("output: \(String(describing: bodyPoints))")
            
            self.jointView.bodyPoints = bodyPoints
            self.measure.stop()
            self.isInferencing = false
        }
    }

}

// MARK: - View supporter

extension CameraViewController {
    
    func setupView() {
        updateStatus(with: nil)
    }
    
    func updateStatus(with text: String?) {
        let setText = {
            self.statusLabel.text = text
        }
        if Thread.isMainThread { setText(); return }
        DispatchQueue.main.async { setText() }
    }
    
    // MARK: Video
    
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 30
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
extension CameraViewController: VideoCaptureDelegate {
    
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        
        // check if the captured image from camera is contained on pixelBuffer
        if !isInferencing, let pixelBuffer = pixelBuffer, let uiImage = UIImage(pixelBuffer: pixelBuffer) {
            
            // start of measure
            self.measure.start()
            
            // predict
            self.detect(image: uiImage)
        }
        
    }
}

extension CameraViewController: PerformanceMeasureDelegate {
    
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
        updateStatus(with: "inference: \(Int(inferenceTime*1000.0)) mm execution: \(Int(executionTime*1000.0)) mm fps: \(fps)")

    }
    
}
