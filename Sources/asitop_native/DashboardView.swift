import SwiftUI

struct DashboardView: View {
    @ObservedObject var collector: DataCollector
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            // Liquid Mesh Gradient Background
            MeshGradientBackground()
                .ignoresSafeArea()
            
            // Glass Surface
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "cpu")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.linearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("ASITOP NATIVE")
                            .font(.system(size: 14, weight: .black))
                            .tracking(2)
                        Text("Apple Silicon Performance")
                            .font(.system(size: 10, weight: .medium))
                            .opacity(0.6)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingSettings.toggle() }) {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                if !collector.hasPermission {
                    PermissionRequestView(collector: collector)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // CPU Section
                        LiquidSection(title: "PROCESSOR") {
                            HStack(spacing: 15) {
                                GlassGauge(label: "E-CORES", value: collector.metrics.cpu.eClusterActive, color: .green)
                                GlassGauge(label: "P-CORES", value: collector.metrics.cpu.pClusterActive, color: .blue)
                                GlassGauge(label: "GPU", value: collector.metrics.gpu.active, color: .purple)
                            }
                        }
                        
                        // Memory Section
                        LiquidSection(title: "MEMORY") {
                            let ramUsedPct = 100.0 - collector.metrics.ram.freePercent
                            CircularGlassGauge(label: "RAM USAGE", value: ramUsedPct, 
                                               detail: String(format: "%.1f/%.0f GB", collector.metrics.ram.usedGB, collector.metrics.ram.totalGB),
                                               color: .orange)
                        }
                        
                        // Power Section
                        LiquidSection(title: "ENERGY") {
                            HStack {
                                PowerDisplay(label: "CPU", value: collector.metrics.cpu.cpuPower, color: .blue)
                                Spacer()
                                PowerDisplay(label: "GPU", value: collector.metrics.cpu.gpuPower, color: .purple)
                                Spacer()
                                PowerDisplay(label: "ANE", value: collector.metrics.cpu.anePower, color: .green)
                            }
                            
                            Divider().opacity(0.1)
                            
                            HStack {
                                Text("PACKAGE TOTAL").font(.system(size: 10, weight: .bold)).opacity(0.5)
                                Spacer()
                                Text(String(format: "%.2f W", collector.metrics.cpu.packagePower))
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .frame(width: 380, height: 550)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .sheet(isPresented: $showingSettings) {
            SettingsView(collector: collector, isPresented: $showingSettings)
        }
    }
}

// MARK: - Components

struct MeshGradientBackground: View {
    @State private var animate = false
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = CGFloat(Date().timeIntervalSinceReferenceDate)
            
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
                
                let colors: [Color] = [.blue, .purple, .indigo, .cyan]
                for i in 0..<colors.count {
                    let offset = CGFloat(i) * 2.0
                    let x = size.width * (0.5 + 0.3 * sin(phase * 0.5 + offset))
                    let y = size.height * (0.5 + 0.3 * cos(phase * 0.4 + offset))
                    
                    context.fill(
                        Path(circleCenteredAt: CGPoint(x: x, y: y), radius: 300),
                        with: .radialGradient(
                            Gradient(colors: [colors[i].opacity(0.3), .clear]),
                            center: CGPoint(x: x, y: y),
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
                }
            }
            .blur(radius: 60)
        }
    }
}

extension Path {
    init(circleCenteredAt center: CGPoint, radius: CGFloat) {
        self.init(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }
}

struct LiquidSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .tracking(1)
                .opacity(0.4)
            
            content
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                }
        }
    }
}

struct GlassGauge: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                // Track
                Capsule()
                    .fill(.white.opacity(0.1))
                    .frame(width: 8, height: 80)
                
                // Fill
                Capsule()
                    .fill(color.gradient)
                    .frame(width: 8, height: 80 * CGFloat(value / 100.0))
                    .shadow(color: color.opacity(0.5), radius: 5)
            }
            
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .opacity(0.6)
            
            Text(String(format: "%.0f%%", value))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
        }
        .frame(maxWidth: .infinity)
    }
}

struct CircularGlassGauge: View {
    let label: String
    let value: Double
    let detail: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: value / 100.0)
                    .stroke(color.gradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.3), radius: 5)
                
                Text(String(format: "%.0f%%", value))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
            }
            .frame(width: 80, height: 80)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .opacity(0.6)
            }
            
            Spacer()
        }
    }
}

struct PowerDisplay: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .opacity(0.4)
            Text(String(format: "%.1fW", value))
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(color.gradient)
        }
    }
}

struct PermissionRequestView: View {
    @ObservedObject var collector: DataCollector
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(.orange.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.orange)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Unlock Metrics")
                    .font(.system(size: 14, weight: .bold))
                Text("Allow perpetual hardware access")
                    .font(.system(size: 11))
                    .opacity(0.6)
            }
            
            Spacer()
            
            Button("Setup") {
                collector.runSetup()
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            .controlSize(.small)
        }
        .padding(15)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
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
