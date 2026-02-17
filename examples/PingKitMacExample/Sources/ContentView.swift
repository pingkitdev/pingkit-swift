import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SetupTab()
                .tabItem {
                    Label("Setup", systemImage: "gearshape")
                }

            ModalTab()
                .tabItem {
                    Label("Modal", systemImage: "rectangle.portrait.on.rectangle.portrait")
                }

            HeadlessTab()
                .tabItem {
                    Label("Headless", systemImage: "terminal")
                }
        }
        .padding()
    }
}
