import SwiftUI
import ServiceManagement
import WidgetKit

struct SettingsView: View {
    @ObservedObject var collector: DataCollector
    @Binding var isPresented: Bool
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMenuBar") private var showMenuBar = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Settings")
                .font(.title).bold()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionView(title: "GENERAL") {
                        Toggle("Launch at Login (Perpetual)", isOn: $launchAtLogin)
                            .onChange(of: launchAtLogin) { newValue in
                                toggleLaunchAtLogin(enabled: newValue)
                            }
                    }
                    
                    SectionView(title: "VISIBILITY") {
                        Toggle("Show in Menu Bar", isOn: $showMenuBar)
                    }
                    
                    SectionView(title: "CONTROL CENTER & DESKTOP") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Widgets and Control Center entries are managed by macOS. Use the 'Edit' buttons in those areas to find ASITOP.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Refresh Widgets") {
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        }
                    }
                    
                    SectionView(title: "PERMISSIONS") {
                        HStack {
                            Image(systemName: collector.hasPermission ? "checkmark.circle.fill" : "lock.circle.fill")
                                .foregroundColor(collector.hasPermission ? .green : .orange)
                            VStack(alignment: .leading) {
                                Text(collector.hasPermission ? "Perpetual Access: ON" : "Access: Locked")
                                    .font(.headline)
                                Text(collector.hasPermission ? "No password needed anymore." : "Click to setup permanent access.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if !collector.hasPermission {
                                Button("Setup") {
                                    collector.runSetup()
                                }
                            }
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Done") {
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(25)
        .frame(width: 450, height: 500)
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

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).bold().foregroundColor(.secondary)
            content
            Divider()
        }
    }
}
