//
//  ViewController.swift
//  mlkit-custom-model-ios
//
//  Created by Somjintana Korbut on 23/6/2562 BE.
//  Copyright © 2562 Nui.swift. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var resultView: UITextView!
    @IBOutlet weak var downloadProgressView: UIProgressView!
    @IBOutlet weak var detectButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

}

// MARK: - View support

extension ViewController {
    
    func setupView() {
        hideResultView()
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


