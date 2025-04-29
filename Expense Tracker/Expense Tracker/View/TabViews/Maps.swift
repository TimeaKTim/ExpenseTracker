//
//  Maps.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 29.04.2025.
//

import SwiftUI
import MapKit

struct Maps: View {
    @ObservedObject var locationManager = LocationManager()
    @State private var landmarks: [Landmark] = []
    @State private var tapped: Bool = false

    private func getNearbyLandmarks() {
        guard let location = locationManager.location else { return }
        
        let query = "ATM"
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response = response {
                self.landmarks = response.mapItems.map {
                    Landmark(placemark: $0.placemark)
                }
            }
        }
    }
    
    func calculateOffset() -> CGFloat {
        if self.landmarks.count > 0 && !self.tapped {
            return UIScreen.main.bounds.size.height - UIScreen.main.bounds.size.height/4
        } else if self.tapped {
            return 100
        } else {
            return UIScreen.main.bounds.size.height
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            MapView(landmarks: landmarks)
                .onAppear {
                    self.getNearbyLandmarks()
            }
            
            PlaceListView(landmarks: self.landmarks) {
                self.tapped.toggle()
            }
            .animation(.spring(), value: tapped)
            .offset(y: calculateOffset())
        }
    }
}

#Preview {
    Maps()
}
