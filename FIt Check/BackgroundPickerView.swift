import SwiftUI

struct BackgroundPickerView: View {
    @AppStorage("selectedBackground") private var selectedBackground: String = CameraBackgroundStyle
        .none
        .rawValue

    var body: some View {
        Picker(
            "Background",
            selection: $selectedBackground
        ) {
            ForEach(CameraBackgroundStyle.allCases) { style in
                HStack {
                    if let color = style.color {
                        Circle()
                            .fill(Color(color))
                            .frame(width: 12, height: 12)
                    } else if style == .blur {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                    } else {
                        Image(systemName: "circle.slash")
                            .font(.caption2)
                    }
                    Text(style.rawValue)
                }
                .tag(style.rawValue)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .padding(6)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(8)
    }
}
