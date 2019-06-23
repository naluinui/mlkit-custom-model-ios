//
//  UIImage+TFLite.swift
//  mlkit-custom-model-ios
//
//  Created by Somjintana Korbut on 22/6/2562 BE.
//  Copyright © 2562 Nui.swift. All rights reserved.
//

import UIKit
import Accelerate

extension UIImage {
    
    func asGreyValues() -> [UInt8]? {
        
        var width = 0
        var height = 0
        var pixelValues: [UInt8]?
        if let imageRef = self.cgImage {
            width = imageRef.width
            height = imageRef.height
            let bitsPerComponent = imageRef.bitsPerComponent
            let totalBytes = height * width
            
            let colorSpace = CGColorSpaceCreateDeviceGray()
            var intensities = [UInt8](repeating: 0, count: totalBytes)
            
            let contextRef = CGContext(data: &intensities, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: width, space: colorSpace, bitmapInfo: 0)
            contextRef?.draw(imageRef, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))
            
            pixelValues = intensities
        }
        
        return pixelValues
    }
    
    /// Returns the data representation of the image after scaling to the given `size` and removing
    /// the alpha component.
    ///
    /// - Parameters
    ///   - size: Size to scale the image to (i.e. image size used while training the model).
    ///   - byteCount: The expected byte count for the scaled image data calculated using the values
    ///       that the model was trained on: `imageWidth * imageHeight * componentsCount * batchSize`.
    ///   - isQuantized: Whether the model is quantized (i.e. fixed point values rather than floating
    ///       point values).
    /// - Returns: The scaled image as data or `nil` if the image could not be scaled.
    public func scaledData(with size: CGSize, byteCount: Int, isQuantized: Bool) -> Data? {
        guard let cgImage = self.cgImage, cgImage.width > 0, cgImage.height > 0 else { return nil }
        guard let imageData = imageData(from: cgImage, with: size) else { return nil }
        var scaledBytes = [UInt8](repeating: 0, count: byteCount)
        var index = 0
        for component in imageData.enumerated() {
            let offset = component.offset
            if offset > index { break }
            let isAlphaComponent =
                (offset % Constant.alphaComponent.baseOffset) == Constant.alphaComponent.moduloRemainder
            guard !isAlphaComponent else { continue }
            scaledBytes[index] = component.element
            index += 1
        }
        if isQuantized { return Data(bytes: scaledBytes) }
        let scaledFloats = scaledBytes.map { Float32($0) / Constant.maxRGBValue }
        print(scaledFloats[...10])
        return Data(copyingBufferOf: scaledFloats)
    }
    
    /// Returns the image data for the given CGImage based on the given `size`.
    private func imageData(from cgImage: CGImage, with size: CGSize) -> Data? {
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        )
        let width = Int(size.width)
        let scaledBytesPerRow = (cgImage.bytesPerRow / cgImage.width) * width
        guard let context = CGContext(
            data: nil,
            width: width,
            height: Int(size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: scaledBytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue)
            else {
                return nil
        }
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        return context.makeImage()?.dataProvider?.data as Data?
    }
}

// MARK: - Constants

private enum Constant {
    static let jpegCompressionQuality: CGFloat = 0.8
    static let alphaComponent = (baseOffset: 4, moduloRemainder: 3)
    static let maxRGBValue: Float32 = 255.0
}
