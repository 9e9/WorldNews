//
//  PinListView.swift
//  WorldNews
//
//  Created by 조준희 on 2/9/26.
//

import SwiftUI

struct PinListView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("즐겨찾기한 기사가 없습니다.")
                    
            }
            .navigationTitle("즐겨찾기")
            .navigationBarTitleDisplayMode(.automatic)
        }
    }
}

// MARK: - Preview
#Preview {
    PinListView()
}
