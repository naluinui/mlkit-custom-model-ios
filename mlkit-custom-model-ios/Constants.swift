//
//  Constants.swift
//  mlkitdemo
//
//  Created by Somjintana Korbut on 21/6/2562 BE.
//  Copyright © 2562 rfcx. All rights reserved.
//

import Foundation

struct Constants {
    
    static let images = [
        ImageDisplay(file: "000000151859.jpg", name: "Jumping"),
        ImageDisplay(file: "000000206278.jpg", name: "Skating"),
        ImageDisplay(file: "000000430193.jpg", name: "Skiing"),
        ImageDisplay(file: "000000414047.jpg", name: "Running")
    ]
    
}

struct ImageDisplay {
    let file: String
    let name: String
}
