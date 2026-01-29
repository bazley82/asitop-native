import SwiftUI
import ServiceManagement

@main
struct asitop_nativeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var collector = DataCollector.shared
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    var body: some Scene {
        MenuBarExtra {
            DashboardView(collector: collector)
            
            Divider()
            
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    toggleLaunchAtLogin(enabled: newValue)
                }
            
            Button("About ASITOP") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.orderFrontStandardAboutPanel(nil)
            }
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "cpu")
                Text(String(format: "%.0f%%", collector.metrics.cpu.pClusterActive))
            }
        }
        .menuBarExtraStyle(.window)
    }
    
    private func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DataCollector.shared.start()
    }
}
