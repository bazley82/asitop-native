import WidgetKit
import AppIntents
import SwiftUI

@main
struct ASITOPWidgetBundle: WidgetBundle {
    var body: some Widget {
        ASITOPDesktopWidget()
        if #available(macOS 15.0, *) {
            ASITOPControl()
        }
    }
}

// MARK: - Desktop Widget
struct ASITOPDesktopWidget: Widget {
    let kind: String = "com.bazley82.asitop-native.DesktopWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DesktopWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("ASITOP Monitor")
        .description("View real-time Apple Silicon performance on your desktop.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DesktopWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.blue)
                Text("ASITOP")
                    .font(.headline)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                MetricRow(label: "CPU", value: "24%", color: .blue)
                MetricRow(label: "GPU", value: "15%", color: .purple)
                MetricRow(label: "RAM", value: "8.2GB", color: .orange)
            }
        }
        .padding()
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.caption).bold()
        }
    }
}

struct Provider: TimelineProvider {
    typealias Entry = SimpleEntry
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entries = [SimpleEntry(date: Date())]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

// MARK: - Control Center
@available(macOS 14.0, *)
struct ASITOPControl: ControlWidget {
    static let kind: String = "com.bazley82.asitop-native.control"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenASITOPIntent()) {
                Label("ASITOP", systemImage: "cpu")
            }
        }
        .displayName("ASITOP Dashboard")
        .description("Quickly open the ASITOP performance dashboard.")
    }
}

@available(macOS 14.0, *)
struct OpenASITOPIntent: AppIntent, ControlConfigurationIntent {
    static var title: LocalizedStringResource = "Open ASITOP"
    static var isDiscoverable: Bool = true
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
