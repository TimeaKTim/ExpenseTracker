//
//  PlaceListView.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 29.04.2025.
//

import SwiftUI
import MapKit

struct PlaceListView: View {
    let landmarks: [Landmark]
    var onTap: () -> ()
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Tap here to show full addresses")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.leading)
            }
            .frame(width: UIScreen.main.bounds.size.width, height: 60)
            .background(Color.gray)
            .gesture(TapGesture().onEnded(self.onTap))
            
            List {
                ForEach(self.landmarks, id: \.id) { landmark in
                    VStack(alignment: .leading) {
                        Text(landmark.name)
                            .fontWeight(.bold)
                        Text(landmark.title)
                    }
                }
            }
        }
        .cornerRadius(10)
    }
}
