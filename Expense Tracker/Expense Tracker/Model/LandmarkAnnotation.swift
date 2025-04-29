//
//  LandmarkAnnotation.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 29.04.2025.
//

import MapKit
import UIKit

final class LandmarkAnnotation: NSObject, MKAnnotation {
    let title: String?
    let coordinate: CLLocationCoordinate2D

    init(landmark: Landmark) {
        self.title = landmark.name
        self.coordinate = landmark.coordinate
    }
}
