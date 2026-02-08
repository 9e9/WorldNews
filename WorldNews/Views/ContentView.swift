//
//  ContentView.swift
//  WorldNews
//
//  Created by 조준희 on 2/9/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            NewsFeedView()
                .tabItem { Label("", systemImage: "newspaper") }
            
            PinListView()
                .tabItem { Label("", systemImage: "pin") }
            
            SettingView()
                .tabItem { Label("", systemImage: "gearshape") }
        }
    }
}

// Preview
#Preview {
    ContentView()
}
