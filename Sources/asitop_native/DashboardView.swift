import SwiftUI

struct DashboardView: View {
    @ObservedObject var collector: DataCollector
    
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HeaderView(name: "Apple Silicon")
                Spacer()
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing)
            }
            
            if !collector.hasPermission {
                PermissionRequestView(collector: collector)
                    .padding(.bottom)
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    MetricSection(title: "Processor Utilization") {
                        UsageGauge(label: "E-CPU", value: collector.metrics.cpu.eClusterActive, 
                                   text: String(format: "%.0f%% @ %.0f MHz", collector.metrics.cpu.eClusterActive, collector.metrics.cpu.eClusterFreq), color: .green)
                        UsageGauge(label: "P-CPU", value: collector.metrics.cpu.pClusterActive, 
                                   text: String(format: "%.0f%% @ %.0f MHz", collector.metrics.cpu.pClusterActive, collector.metrics.cpu.pClusterFreq), color: .blue)
                        UsageGauge(label: "GPU", value: collector.metrics.gpu.active, 
                                   text: String(format: "%.0f%% @ %.0f MHz", collector.metrics.gpu.active, collector.metrics.gpu.freq), color: .purple)
                    }
                    
                    MetricSection(title: "Memory") {
                        let ramUsedPct = 100.0 - collector.metrics.ram.freePercent
                        UsageGauge(label: "RAM", value: ramUsedPct, 
                                   text: String(format: "%.0f%% (%.1f/%.0f GB)", ramUsedPct, collector.metrics.ram.usedGB, collector.metrics.ram.totalGB),
                                   color: .orange)
                    }
                    
                    MetricSection(title: "Power") {
                        VStack(spacing: 8) {
                            HStack {
                                PowerVal(label: "CPU", value: collector.metrics.cpu.cpuPower)
                                Divider()
                                PowerVal(label: "GPU", value: collector.metrics.cpu.gpuPower)
                                Divider()
                                PowerVal(label: "ANE", value: collector.metrics.cpu.anePower)
                            }
                            Divider()
                            HStack {
                                Text("Total Power").font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.2f W", collector.metrics.cpu.packagePower)).font(.headline).monospacedDigit()
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 350, height: 500)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .sheet(isPresented: $showingSettings) {
            SettingsView(collector: collector)
                .overlay(alignment: .topTrailing) {
                    Button(action: { showingSettings = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
        }
    }
}

struct MetricSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundColor(.secondary)
            content
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct UsageGauge: View {
    let label: String
    let value: Double
    var text: String? = nil
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.subheadline).bold()
                Spacer()
                Text(text ?? String(format: "%.0f%%", value)).font(.caption).monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(width: geo.size.width * CGFloat(value / 100.0))
                }
            }
            .frame(height: 8)
        }
    }
}

struct PowerVal: View {
    let label: String
    let value: Double
    
    var body: some View {
        VStack {
            Text(label).font(.caption2).foregroundColor(.secondary)
            Text(String(format: "%.1fW", value)).font(.system(.body, design: .monospaced))
        }
        .frame(maxWidth: .infinity)
    }
}

struct HeaderView: View {
    let name: String
    var body: some View {
        HStack {
            Image(systemName: "cpu").font(.title2)
            Text("ASITOP Native").font(.headline)
            Spacer()
            Text(name).font(.caption).padding(4).background(Color.blue).cornerRadius(4)
        }
        .padding()
    }
}

struct PermissionRequestView: View {
    @ObservedObject var collector: DataCollector
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield").font(.largeTitle).foregroundColor(.orange)
            Text("Metrics Locked").font(.headline)
            Text("Apple Silicon metrics require administrator permission to run securely.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: { collector.runSetup() }) {
                Text("Unlock Metrics")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
