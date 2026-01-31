import SwiftUI

/// Reusable error state view for displaying errors with retry option
struct ErrorStateView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?

    init(
        title: String = "Something went wrong",
        message: String = "Please try again later.",
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let retryAction {
                Button {
                    retryAction()
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.dietCokeRed)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
}

/// Compact inline error message for use within forms/lists
struct InlineErrorMessage: View {
    let message: String
    let dismissAction: (() -> Void)?

    init(_ message: String, dismissAction: (() -> Void)? = nil) {
        self.message = message
        self.dismissAction = dismissAction
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)

            Spacer()

            if let dismissAction {
                Button {
                    dismissAction()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Toast-style error message that appears at top/bottom of screen
struct ErrorToast: View {
    let message: String
    @Binding var isShowing: Bool

    var body: some View {
        if isShowing {
            VStack {
                Spacer()

                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        withAnimation {
                            isShowing = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                .background(Color.red.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                // Auto-dismiss after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
    }
}

/// Modifier to easily add error toast to any view
struct ErrorToastModifier: ViewModifier {
    @Binding var error: String?

    func body(content: Content) -> some View {
        ZStack {
            content

            if let errorMessage = error {
                ErrorToast(
                    message: errorMessage,
                    isShowing: Binding(
                        get: { error != nil },
                        set: { if !$0 { error = nil } }
                    )
                )
            }
        }
        .animation(.spring(response: 0.3), value: error)
    }
}

extension View {
    func errorToast(_ error: Binding<String?>) -> some View {
        modifier(ErrorToastModifier(error: error))
    }
}

#Preview {
    VStack(spacing: 40) {
        ErrorStateView(
            title: "Failed to load",
            message: "Check your internet connection and try again."
        ) {
            print("Retry tapped")
        }

        InlineErrorMessage("Failed to save changes")

        Spacer()
    }
    .padding()
}
