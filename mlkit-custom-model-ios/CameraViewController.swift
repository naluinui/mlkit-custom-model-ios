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
    
    var videoCapture: VideoCapture!
    
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var jointView: JointView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setUpCamera()
    }
    
    func detect(image: UIImage) {
        
        // Load model
        
        if !manager.loadModel() {
            updateStatus(with: "Failed to load the model.")
        } else {
            updateStatus(with: "Model loaded")
        }
        
        // Convert imge to data
        
        let size = CGSize(width: modelConfigurations.dimensionImageWidth.intValue, height: modelConfigurations.dimensionImageHeight.intValue)
        let data = image.scaledData(with: size, byteCount: Int(size.width) * Int(size.height) * modelConfigurations.dimensionComponents.intValue * modelConfigurations.dimensionBatchSize.intValue, isQuantized: modelConfigurations.elementType == .uInt8)
        
        // TODO: detect pose
        manager.detect(in: data) { (bodyPoint, error) in
            
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
extension CameraViewController: VideoCaptureDelegate {
    
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        
        // TODO: check if the captured image from camera is contained on pixelBuffer
        
        // TODO: start of measure
            
        // TODO: predict
        
    }
}
