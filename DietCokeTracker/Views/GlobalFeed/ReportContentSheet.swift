import SwiftUI

struct ReportContentSheet: View {
    @EnvironmentObject var activityService: ActivityFeedService
    @EnvironmentObject var identityService: IdentityService
    @EnvironmentObject var globalFeedService: GlobalFeedService
    @Environment(\.dismiss) private var dismiss

    let activityID: String
    let reportedUserID: String
    var onReported: (() -> Void)?

    @State private var selectedReason: ContentReport.ReportReason = .inappropriate
    @State private var details: String = ""
    @State private var isSubmitting = false
    @State private var hasSubmitted = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ContentReport.ReportReason.allCases, id: \.self) { reason in
                        Button {
                            selectedReason = reason
                        } label: {
                            HStack {
                                Text(reason.displayName)
                                    .foregroundColor(.dietCokeCharcoal)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.dietCokeRed)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Reason")
                }

                Section {
                    TextField("Additional details (optional)", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Details")
                }

                if hasSubmitted {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Thank you. We'll review this report. This post has been hidden from your feed.")
                                .font(.subheadline)
                                .foregroundColor(.dietCokeDarkSilver)
                        }
                    }
                }
            }
            .navigationTitle("Report Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        Task {
                            await submitReport()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSubmitting || hasSubmitted)
                }
            }
        }
    }

    private func submitReport() async {
        guard let reporterUserID = identityService.currentIdentity?.userIDString else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        await activityService.submitReport(
            activityID: activityID,
            reportedUserID: reportedUserID,
            reporterUserID: reporterUserID,
            reason: selectedReason,
            details: details.isEmpty ? nil : details
        )

        // Hide the reported item from the local feed
        globalFeedService.items.removeAll { $0.id.uuidString == activityID }
        onReported?()

        hasSubmitted = true

        // Auto-dismiss after brief delay
        try? await Task.sleep(for: .seconds(1.5))
        dismiss()
    }
}
