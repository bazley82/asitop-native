import SwiftUI
import ServiceManagement
import WidgetKit

struct SettingsView: View {
    @ObservedObject var collector: DataCollector
    @Binding var isPresented: Bool
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMenuBar") private var showMenuBar = true
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.system(size: 24, weight: .bold))
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(25)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        LiquidSection(title: "AUTORUN") {
                            Toggle(isOn: $launchAtLogin) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Launch at Login")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Start ASITOP automatically on boot.")
                                        .font(.system(size: 11)).opacity(0.6)
                                }
                            }
                            .onChange(of: launchAtLogin) { newValue in
                                toggleLaunchAtLogin(enabled: newValue)
                            }
                        }
                        
                        LiquidSection(title: "INTERFACE") {
                            Toggle(isOn: $showMenuBar) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Menu Bar Icon")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Show current usage in the menu bar at all times.")
                                        .font(.system(size: 11)).opacity(0.6)
                                }
                            }
                        }
                        
                        LiquidSection(title: "SYSTEM INTEGRATION") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Add ASITOP to your Desktop or Control Center using the system's edit mode.")
                                    .font(.system(size: 11))
                                    .opacity(0.6)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Button(action: { WidgetCenter.shared.reloadAllTimelines() }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise.circle.fill")
                                        Text("Refresh System Widgets")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            }
                        }
                        
                        LiquidSection(title: "SECURITY") {
                            HStack(spacing: 15) {
                                Circle()
                                    .fill(collector.hasPermission ? .green.opacity(0.2) : .orange.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        Image(systemName: collector.hasPermission ? "checkmark.shield.fill" : "lock.shield.fill")
                                            .foregroundColor(collector.hasPermission ? .green : .orange)
                                    }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(collector.hasPermission ? "Perpetual Access Enabled" : "Administrative Access Required")
                                        .font(.system(size: 14, weight: .bold))
                                    Text(collector.hasPermission ? "App can monitor hardware without passwords." : "Authorize once to monitor forever.")
                                        .font(.system(size: 11))
                                        .opacity(0.6)
                                }
                                
                                Spacer()
                                
                                if !collector.hasPermission {
                                    Button("Setup") {
                                        collector.runSetup()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 30)
                }
                
                Divider().opacity(0.1)
                
                HStack {
                    Text("v1.2.6 - Build with Google Antigravity").font(.system(size: 9, weight: .bold)).opacity(0.3)
                    Spacer()
                    Button("Close") {
                        isPresented = false
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(25)
            }
        }
        .frame(width: 440, height: 600)
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
