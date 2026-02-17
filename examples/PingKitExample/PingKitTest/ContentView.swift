import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                SetupView()
            }
            .tabItem {
                Label("Setup", systemImage: "gearshape")
            }

            NavigationStack {
                ModalTestView()
            }
            .tabItem {
                Label("Modal", systemImage: "rectangle.portrait.bottomhalf.inset.filled")
            }

            NavigationStack {
                HeadlessTestView()
            }
            .tabItem {
                Label("Headless", systemImage: "terminal")
            }

            NavigationStack {
                TestRunnerView()
            }
            .tabItem {
                Label("Tests", systemImage: "checklist")
            }
        }
    }
}

#Preview {
    ContentView()
}
