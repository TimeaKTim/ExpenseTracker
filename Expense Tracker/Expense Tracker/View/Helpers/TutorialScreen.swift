//
//  TutorialScreen.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 12.06.2025.
//

import SwiftUI

struct TutorialScreen: View {
    @AppStorage("isFirstTime") private var isFirstTime: Bool = true
    @State private var currentPage: Int = 0

    let tutorialPages: [TutorialPage] = [
        .init(image: "emptyWelcome", title: "Track Your Finances", description: "Tap the plus icon to add new expenses or income. You can also change the date by tapping it."),
        
        .init(image: "addNew", title: "Add Transactions", description: "Quickly record your expenses or income with customizable details."),
        
        .init(image: "searchKauf", title: "Smart Search & Filters", description: "Easily find transactions by title, or use filters to narrow your results."),
        
        .init(image: "map", title: "Find Nearby ATMs", description: "Use the built-in map to locate the closest ATMs around you."),
        
        .init(image: "monthly", title: "Monthly Overview", description: "Stay on top of your spending and income with a clear monthly summary."),
        
        .init(image: "cat", title: "Category Insights", description: "Visualize your spending habits with detailed category breakdowns.")
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            TabView(selection: $currentPage) {
                ForEach(tutorialPages.indices, id: \.self) { index in
                    VStack(spacing: 20) {
                        Image(tutorialPages[index].image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                        
                        Text(tutorialPages[index].title)
                            .font(.title)
                            .bold()
                        
                        Text(tutorialPages[index].description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .animation(.easeInOut, value: currentPage)
            .frame(height: 450)
            
            Button(action: {
                if currentPage < tutorialPages.count - 1 {
                    currentPage += 1
                } else {
                    isFirstTime = false
                }
            }) {
                Text(currentPage == tutorialPages.count - 1 ? "Get Started" : "Continue")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(appTint.gradient, in: .rect(cornerRadius: 12))
                    .padding(.horizontal)
            }
        }
    }
}


#Preview {
    TutorialScreen()
}
