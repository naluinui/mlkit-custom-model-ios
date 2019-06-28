//
//  Data.swift
//  mlkit-custom-model-ios
//
//  Created by Somjintana Korbut on 22/6/2562 BE.
//  Copyright © 2562 Nui.swift. All rights reserved.
//

import Foundation

extension Data {
    /// Creates a new buffer by copying the buffer pointer of the given array.
    ///
    /// - Warning: The given array's element type `T` must be trivial in that it can be copied bit
    ///     for bit with no indirection or reference-counting operations; otherwise, reinterpreting
    ///     data from the resulting buffer has undefined behavior.
    /// - Parameter array: An array with elements of type `T`.
    init<T>(copyingBufferOf array: [T]) {
        self = array.withUnsafeBufferPointer(Data.init)
    }
}
