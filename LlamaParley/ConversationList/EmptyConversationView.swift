//
//  EmptyConversationView.swift
//  LlamaParley
//
//  Created by Nash Erickson on 7/4/25.
//


import SwiftUI

struct EmptyConversationView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.yellow)
            Text("No conversations yet")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Tap 'New Chat' to get started.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}
