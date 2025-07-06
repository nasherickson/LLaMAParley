import SwiftUI

struct GeometricBackground: View {
    var body: some View {
        ZStack {
            Color.red.opacity(0.2) // TEMP debug, remove later
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#000741"),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ForEach(0..<156) { i in
                let angle = Angle(degrees: Double(i) * 1)
                RoundedRectangle(cornerRadius: 69)
                    .stroke(Color(hex: "#003153").opacity(0.24), lineWidth: 15)
                    .rotationEffect(angle)
                    .scaleEffect(0.9)
            }
            
            ForEach(0..<159) { i in
                let angle = Angle(degrees: Double(i) * 3)
                RoundedRectangle(cornerRadius: 69)
                    .stroke(Color(hex: "#7B1113").opacity(0.1), lineWidth: 20)
                    .rotationEffect(angle)
                    .scaleEffect(0.7)
            }
        }
    }

}
