//
//  PinListView.swift
//  WorldNews
//
//  Created by 조준희 on 2/9/26.
//

import SwiftUI

struct PinListView: View {
    var body: some View {
        VStack {
            HStack {
                Text("핀 목록")
                    .font(.largeTitle)
                    .padding(.leading)
                    .bold()
                Spacer()
            }
            .navigationTitle("핀 고정")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview
#Preview {
    PinListView()
}
