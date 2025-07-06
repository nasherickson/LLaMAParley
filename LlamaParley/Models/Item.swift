//
//  Item.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/2/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID
    var name: String
    var createdAt: Date
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        
    }
}
