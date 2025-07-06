//
//  ConversationDivider.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/4/25.
//


import SwiftUI

struct ConversationDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 1)
            .edgesIgnoringSafeArea(.vertical)
    }
}
