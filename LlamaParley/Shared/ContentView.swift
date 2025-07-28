import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            GeometricBackground()
            Text("Lets Redefine Tomorrows Dialouge !")
                .foregroundColor(.white)
                .font(.system(.largeTitle, design: .serif).bold())
                .padding()
        }
    }
}

#Preview {
    ContentView()
}
