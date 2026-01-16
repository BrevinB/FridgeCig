import SwiftUI

struct SetupProfileView: View {
    @EnvironmentObject var identityService: IdentityService
    @State private var displayName = ""
    @State private var isCreating = false
    @State private var showError = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.dietCokeRed.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.dietCokeRed)
            }

            // Title
            VStack(spacing: 8) {
                Text("Join the Leaderboard")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.dietCokeCharcoal)

                Text("Compete with friends and see who drinks the most DC")
                    .font(.subheadline)
                    .foregroundColor(.dietCokeDarkSilver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Name input
            VStack(alignment: .leading, spacing: 12) {
                Text("What should we call you?")
                    .font(.headline)
                    .foregroundColor(.dietCokeCharcoal)

                TextField("Display Name", text: $displayName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.dietCokeCardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.dietCokeSilver.opacity(0.3), lineWidth: 1)
                    )
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if canContinue {
                            createProfile()
                        }
                    }

                Text("This is how you'll appear on the leaderboard")
                    .font(.caption)
                    .foregroundColor(.dietCokeDarkSilver)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            Button {
                createProfile()
            } label: {
                HStack {
                    if isCreating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Get Started")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.dietCokePrimary)
            .disabled(!canContinue || isCreating)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(identityService.error?.localizedDescription ?? "Something went wrong")
        }
        .onAppear {
            isNameFocused = true
        }
    }

    private var canContinue: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func createProfile() {
        guard canContinue else { return }

        isCreating = true
        Task {
            do {
                try await identityService.createIdentity(displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines))
            } catch {
                showError = true
            }
            isCreating = false
        }
    }
}

#Preview {
    SetupProfileView()
        .environmentObject(IdentityService(cloudKitManager: CloudKitManager()))
}
