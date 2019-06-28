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
    private var bodyPoints: [BodyPoint?] = [] {
        didSet {
            self.jointView?.bodyPoints = bodyPoints
            self.tableView.reloadData()
        }
    }
    private var videoCapture: VideoCapture!
    
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var jointView: JointView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        setUpCamera()
        
        // Load model
        
        if !manager.loadModel() {
            updateStatus(with: "Failed to load the model.")
        } else {
            updateStatus(with: "Model loaded.")
        }
    }
    
    func detect(image: UIImage) {
        
        self.isInferencing = true
        
        // Convert image to data
        
        let size = CGSize(width: modelConfigurations.dimensionImageWidth.intValue, height: modelConfigurations.dimensionImageHeight.intValue)
        let data = image.scaledData(with: size, byteCount: Int(size.width) * Int(size.height) * modelConfigurations.dimensionComponents.intValue * modelConfigurations.dimensionBatchSize.intValue, isQuantized: modelConfigurations.elementType == .uInt8)
        
        // Detect pose
        manager.detect(in: data) { (bodyPoints, error) in
            
            if let error = error {
                self.updateStatus(with: error.localizedDescription)
                return
            }
            
            guard let bodyPoints = bodyPoints else {
                return
            }
            print("output: \(String(describing: bodyPoints))")
            
            self.bodyPoints = bodyPoints
            self.isInferencing = false
        }
    }

}

// MARK: - VideoCaptureDelegate
extension CameraViewController: VideoCaptureDelegate {
    
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        
        // check if the captured image from camera is contained on pixelBuffer
        if !isInferencing, let pixelBuffer = pixelBuffer, let uiImage = UIImage(pixelBuffer: pixelBuffer) {
            
            // predict
            self.detect(image: uiImage)
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

extension CameraViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bodyPoints.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell", for: indexPath)
        if let bodyPoint = bodyPoints[indexPath.row] {
            cell.textLabel?.text = bodyPoint.getLabel(index: indexPath.row)
            let pointText: String = "\(String(format: "%.3f", bodyPoint.maxPoint.x)), \(String(format: "%.3f", bodyPoint.maxPoint.y))"
             cell.detailTextLabel?.text = "(\(pointText)), [\(String(format: "%.3f", bodyPoint.maxConfidence))]"
        }
        
        return cell
    }
}
