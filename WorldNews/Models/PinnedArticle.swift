//
//  PinnedArticle.swift
//  WorldNews
//
//  Created by 조준희 on 2/9/26.
//

import Foundation
import SwiftData

@Model
final class PinnedArticle {
    @Attribute(.unique) var id: String
    var displayTitle: String
    var displayDescription: String
    var displayDate: String
    var link: String
    var pinnedAt: Date
    
    init(id: String, displayTitle: String, displayDescription: String, displayDate: String, link: String) {
        self.id = id
        self.displayTitle = displayTitle
        self.displayDescription = displayDescription
        self.displayDate = displayDate
        self.link = link
        self.pinnedAt = Date()
    }
}
