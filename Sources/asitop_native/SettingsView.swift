import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var collector: DataCollector
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMenuBar") private var showMenuBar = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title2).bold()
            
            Section(header: Text("GENERAL").font(.caption).foregroundColor(.secondary)) {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        toggleLaunchAtLogin(enabled: newValue)
                    }
            }
            
            Section(header: Text("VISIBILITY").font(.caption).foregroundColor(.secondary)) {
                Toggle("Show in Menu Bar", isOn: $showMenuBar)
            }
            
            Section(header: Text("PERMISSIONS").font(.caption).foregroundColor(.secondary)) {
                HStack {
                    Image(systemName: collector.hasPermission ? "checkmark.circle.fill" : "lock.circle.fill")
                        .foregroundColor(collector.hasPermission ? .green : .orange)
                    VStack(alignment: .leading) {
                        Text(collector.hasPermission ? "Metrics Unlocked" : "Metrics Locked")
                            .font(.headline)
                        Text(collector.hasPermission ? "Perpetual access granted." : "One-time setup required for perpetual access.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if !collector.hasPermission {
                        Button("Unlock Now") {
                            collector.runSetup()
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Done") {
                    // Close logic handled by parent
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 400)
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
