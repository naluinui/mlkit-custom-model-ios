//
//  ModelOutputs+Heatmap.swift
//  mlkit-custom-model-ios
//
//  Created by Ant on 23/06/2019.
//  Copyright © 2019 Nui.swift. All rights reserved.
//

import CoreGraphics
import FirebaseMLModelInterpreter

public struct BodyPoint {
    let maxPoint: CGPoint
    let maxConfidence: Double
}
// 1,96,96,14

extension ModelOutputs {
    func toBodyPoints() -> [BodyPoint?] {
        guard let outputAny = try? output(index: 0),
            let outputArray = outputAny as? [[[[NSNumber]]]],
            let outputBatch = outputArray.first else {
            print("output shape is invalid (should be dim 4)")
            return []
        }
        
        let heatmapWidth = outputBatch.count
        let heatmapHeight = outputBatch.first?.count ?? 0
        let keypointCount = outputBatch.first?.first?.count ?? 0
        
        guard heatmapWidth == 96, heatmapHeight == 96, keypointCount == 14 else {
            print("output shape is invalid (expected 1,96,96,14)")
            return []
        }
        
        var keypoints = (0..<keypointCount).map { _ -> BodyPoint? in
            return nil
        }
        
        for k in 0..<keypointCount {
            for j in 0..<heatmapHeight {
                for i in 0..<heatmapWidth {
                    let confidence = outputBatch[j][i][k].doubleValue
                    if (keypoints[k]?.maxConfidence ?? 0) < confidence {
                        keypoints[k] = BodyPoint(maxPoint: CGPoint(x: CGFloat(i), y: CGFloat(j)), maxConfidence: confidence)
                    }
                }
            }
        }
        
        // transpose to (1.0, 1.0)
        keypoints = keypoints.map { keypoint -> BodyPoint? in
            if let kp = keypoint {
                return BodyPoint(maxPoint: CGPoint(x: (kp.maxPoint.x+0.5)/CGFloat(heatmapWidth),
                                                   y: (kp.maxPoint.y+0.5)/CGFloat(heatmapHeight)),
                                 maxConfidence: kp.maxConfidence)
            } else {
                return nil
            }
        }
        
        return keypoints
    }
}
