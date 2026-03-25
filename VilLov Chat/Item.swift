//
//  Item.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
