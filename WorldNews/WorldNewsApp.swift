//
//  WorldNewsApp.swift
//  WorldNews
//
//  Created by 조준희 on 2/9/26.
//

import SwiftUI
import SwiftData

@main
struct WorldNewsApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Schema([]), configurations: [ModelConfiguration(schema: Schema([]), isStoredInMemoryOnly: false)])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
