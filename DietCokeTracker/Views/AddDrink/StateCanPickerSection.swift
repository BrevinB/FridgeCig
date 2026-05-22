import SwiftUI

struct StateCanPickerSection: View {
    @Binding var selectedCode: String?
    @EnvironmentObject var stateCanStore: StateCanStore
    @Environment(\.colorScheme) private var colorScheme

    private var selectedCan: StateCan? {
        selectedCode.flatMap { StateCan.byCode[$0] }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flag.checkered")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeRed)
                Text("WHICH STATE CAN?")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.dietCokeDarkSilver)
                Spacer()
            }

            Menu {
                Button("None") { selectedCode = nil }
                Divider()
                ForEach(StateCan.all) { can in
                    Button {
                        selectedCode = can.code
                    } label: {
                        if stateCanStore.isCollected(can.code) {
                            Label("\(can.name) — already collected", systemImage: "checkmark.seal.fill")
                        } else {
                            Text(can.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    if let can = selectedCan {
                        Image(systemName: can.icon)
                            .font(.title3)
                            .foregroundColor(.dietCokeRed)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(can.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.dietCokeCharcoal)
                            Text(can.symbol)
                                .font(.caption)
                                .foregroundColor(.dietCokeDarkSilver)
                        }
                    } else {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.title3)
                            .foregroundColor(.dietCokeDarkSilver)
                        Text("Pick a state")
                            .font(.subheadline)
                            .foregroundColor(.dietCokeDarkSilver)
                    }

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.dietCokeDarkSilver)
                }
                .padding(14)
                .background(Color.dietCokeCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }
}

#if DEBUG
private struct StateCanPickerPreviewWrapper: View {
    @State private var code: String?
    init(code: String? = nil) {
        _code = State(initialValue: code)
    }
    var body: some View {
        StateCanPickerSection(selectedCode: $code).padding()
    }
}

#Preview("None selected") {
    StateCanPickerPreviewWrapper().withPreviewEnvironment()
}

#Preview("State selected") {
    StateCanPickerPreviewWrapper(code: "CA").withPreviewEnvironment()
}
#endif
