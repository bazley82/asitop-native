import WidgetKit
import AppIntents
import SwiftUI

@main
@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
struct OpenASITOPIntent: AppIntent, ControlConfigurationIntent {
    static var title: LocalizedStringResource = "Open ASITOP"
    static var isDiscoverable: Bool = true
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // AppIntents with openAppWhenRun = true will automatically launch the main app
        return .result()
    }
}
