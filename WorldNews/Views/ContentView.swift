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
    @Environment(\.colorScheme) private var systemColorScheme
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    
    var body: some View {
        TabView {
            NewsFeedView()
                .tabItem { Label("", systemImage: "newspaper") }
            
            PinListView()
                .tabItem { Label("", systemImage: "pin") }
            
            SettingView()
                .tabItem { Label("", systemImage: "gearshape") }
        }
        .preferredColorScheme(colorScheme)
    }
    
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum AppearanceMode: String, CaseIterable {
    case system = "시스템"
    case light = "라이트"
    case dark = "다크"
}
    

// MARK: - Preview
#Preview {
    ContentView()
}
