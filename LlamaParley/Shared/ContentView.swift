import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            GeometricBackground()
            Text("Hello from LlamaParley!")
                .foregroundColor(.white)
                .font(.system(.largeTitle, design: .serif).bold())
                .padding()
        }
    }
}

#Preview {
    ContentView()
}
