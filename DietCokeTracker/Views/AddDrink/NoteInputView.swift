import SwiftUI

struct NoteInputView: View {
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note (Optional)")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)

            TextField("Add a note...", text: $note)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.dietCokeCardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.dietCokeSilver.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

#if DEBUG
private struct NoteInputPreviewWrapper: View {
    @State private var note = ""
    var body: some View { NoteInputView(note: $note).padding() }
}

#Preview { NoteInputPreviewWrapper() }
#endif
