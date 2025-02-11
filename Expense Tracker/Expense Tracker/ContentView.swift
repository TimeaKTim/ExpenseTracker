//
//  ContentView.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 10.02.2025.
//

import SwiftUI

struct ContentView: View {
    /// Intro Visibility Status
    @AppStorage("isFirstTime") private var isFirstTime: Bool = true
    /// Active Tab
    @State private var activeTab: Tab = .recents
    var body: some View {
        TabView(selection: $activeTab){
            Recents()
                .tag(Tab.recents)
                .tabItem {Tab.recents.tabContent}
            
            Search()
                .tag(Tab.search)
                .tabItem {Tab.search.tabContent}
            
            Graphs()
                .tag(Tab.charts)
                .tabItem {Tab.charts.tabContent}
            
            Settings()
                .tag(Tab.settings)
                .tabItem {Tab.settings.tabContent}
        }
        .tint(appTint)
        .sheet(isPresented: $isFirstTime, content: {
            IntroScreen()
                .interactiveDismissDisabled()
        })
    }
}

#Preview {
    ContentView()
}
