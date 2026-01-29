import SwiftUI
import ServiceManagement

@main
struct asitop_nativeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var collector = DataCollector.shared
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMenuBar") private var showMenuBar = true
    
    var body: some Scene {
        Window("ASITOP Dashboard", id: "main") {
            DashboardView(collector: collector)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        MenuBarExtra(isInserted: $showMenuBar) {
            Button("Open Dashboard") {
                openDashboard()
            }
            
            Divider()
            
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    toggleLaunchAtLogin(enabled: newValue)
                }
            
            Button("Settings...") {
                openSettings()
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
    
    private func openDashboard() {
        NSApp.activate(ignoringOtherApps: true)
        // This is a simple way to bring the window to front if it exists
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    private func openSettings() {
        // Implementation for opening a settings window or showing it in the main view
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
