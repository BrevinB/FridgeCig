import SwiftUI
import UIKit

/// The reply thread on a feed post, with a composer pinned to the bottom.
struct CommentsSheet: View {
    let activity: ActivityItem

    @EnvironmentObject private var commentService: CommentService
    @EnvironmentObject private var identityService: IdentityService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var draft = ""
    @State private var commentToDelete: ActivityComment?
    @FocusState private var isComposerFocused: Bool

    private var comments: [ActivityComment] {
        commentService.comments(for: activity.id)
    }

    private var canPost: Bool {
        ActivityComment.sanitize(draft) != nil
            && !commentService.isPosting
            && identityService.currentProfile != nil
    }

    private var remainingCharacters: Int {
        ActivityComment.maxLength - draft.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                postSummary

                Divider()

                if commentService.isLoading(activity.id) && comments.isEmpty {
                    loadingState
                } else if comments.isEmpty {
                    emptyState
                } else {
                    commentList
                }

                Divider()

                composer
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await commentService.loadThread(for: activity.id)
            }
            .refreshable {
                await commentService.loadThread(for: activity.id, force: true)
            }
            .alert(
                "Delete Comment?",
                isPresented: Binding(
                    get: { commentToDelete != nil },
                    set: { if !$0 { commentToDelete = nil } }
                ),
                presenting: commentToDelete
            ) { comment in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task { await commentService.delete(comment) }
                }
            } message: { _ in
                Text("This can't be undone.")
            }
        }
        .presentationDetents([.large])
    }

    private var titleText: String {
        let count = commentService.count(for: activity.id)
        return count > 0 ? "\(count) Comment\(count == 1 ? "" : "s")" : "Comments"
    }

    // MARK: - Post Summary

    private var postSummary: some View {
        HStack(spacing: 12) {
            AvatarView(
                displayName: activity.displayName,
                profilePhotoID: activity.profilePhotoID,
                profileEmoji: activity.profileEmoji,
                size: 36
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.dietCokeCharcoal)
                    .lineLimit(1)

                if let subtitle = activity.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.dietCokeDarkSilver)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(activity.formattedTime)
                .font(.caption2)
                .foregroundColor(.dietCokeDarkSilver)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.dietCokeCardBackground)
    }

    // MARK: - States

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(.dietCokeRed)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.dietCokeSilver)

            Text("No comments yet")
                .font(.headline)
                .foregroundColor(.dietCokeCharcoal)

            Text("Be the first to say something.")
                .font(.subheadline)
                .foregroundColor(.dietCokeDarkSilver)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var commentList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(comments) { comment in
                        CommentRow(
                            comment: comment,
                            isAuthorOfPost: comment.authorID == activity.userID,
                            canDelete: commentService.canDelete(comment)
                        ) {
                            commentToDelete = comment
                        }
                        .id(comment.id)
                    }
                }
                .padding(16)
            }
            .onChange(of: comments.count) { _, _ in
                guard let last = comments.last else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Composer

    private var composer: some View {
        VStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 10) {
                AvatarView(
                    displayName: identityService.currentProfile?.displayName ?? "You",
                    profilePhotoID: identityService.currentProfile?.profilePhotoID,
                    profileEmoji: identityService.currentProfile?.profileEmoji,
                    size: 32
                )

                TextField("Add a comment…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($isComposerFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(colorScheme == .dark ? Color(white: 0.16) : Color(.systemGray6))
                    )
                    .onChange(of: draft) { _, newValue in
                        if newValue.count > ActivityComment.maxLength {
                            draft = String(newValue.prefix(ActivityComment.maxLength))
                        }
                    }

                Button {
                    post()
                } label: {
                    if commentService.isPosting {
                        ProgressView()
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(canPost ? Color.dietCokeRed : Color.dietCokeSilver)
                    }
                }
                .disabled(!canPost)
                .accessibilityLabel("Post comment")
            }

            if remainingCharacters <= 40 {
                Text("\(remainingCharacters) characters left")
                    .font(.caption2)
                    .foregroundColor(remainingCharacters <= 0 ? .dietCokeRed : .dietCokeDarkSilver)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.dietCokeCardBackground)
    }

    private func post() {
        guard let profile = identityService.currentProfile else { return }
        let text = draft
        draft = ""
        HapticManager.lightImpact()

        Task {
            let posted = await commentService.post(text: text, on: activity, author: profile)
            if posted == nil {
                // Give the text back so nothing is silently lost.
                draft = text
                HapticManager.error()
            }
        }
    }
}

// MARK: - Comment Row

private struct CommentRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let comment: ActivityComment
    let isAuthorOfPost: Bool
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AvatarView(
                displayName: comment.authorName,
                profilePhotoID: comment.authorPhotoID,
                profileEmoji: comment.authorEmoji,
                size: 34
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.authorName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.dietCokeCharcoal)

                    if isAuthorOfPost {
                        Text("AUTHOR")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.dietCokeRed)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(Color.dietCokeRed.opacity(0.12))
                            )
                    }

                    Text(comment.formattedTime)
                        .font(.caption2)
                        .foregroundColor(.dietCokeDarkSilver)

                    Spacer()
                }

                Text(comment.text)
                    .font(.subheadline)
                    .foregroundColor(.dietCokeCharcoal)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark ? Color(white: 0.13) : Color.white)
            )
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = comment.text
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

            if canDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Latest Comment Preview

/// A one-line teaser of the newest reply, so a conversation is visible from the
/// feed instead of hidden behind a tap.
struct LatestCommentPreview: View {
    let activity: ActivityItem

    @EnvironmentObject private var commentService: CommentService
    @State private var showingComments = false

    private var latest: ActivityComment? {
        commentService.latestComment(for: activity.id)
    }

    private var olderCount: Int {
        max(0, commentService.count(for: activity.id) - 1)
    }

    var body: some View {
        if let latest {
            Button {
                showingComments = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    if olderCount > 0 {
                        Text("View \(olderCount) more comment\(olderCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.dietCokeDarkSilver)
                    }

                    (Text(latest.authorName).fontWeight(.semibold)
                        + Text(" ")
                        + Text(latest.text))
                        .font(.caption)
                        .foregroundColor(.dietCokeCharcoal)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingComments) {
                CommentsSheet(activity: activity)
            }
        }
    }
}

// MARK: - Comment Button

/// The feed-row entry point into a thread.
struct CommentButton: View {
    let activity: ActivityItem

    @EnvironmentObject private var commentService: CommentService
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingComments = false

    private var count: Int {
        commentService.count(for: activity.id)
    }

    var body: some View {
        Button {
            showingComments = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: count > 0 ? "bubble.left.fill" : "bubble.left")
                    .font(.system(size: 14))

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .semibold))
                        .contentTransition(.numericText())
                }
            }
            .foregroundColor(.dietCokeDarkSilver)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? Color(white: 0.18) : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(count > 0 ? "\(count) comments" : "Add a comment")
        .sheet(isPresented: $showingComments) {
            CommentsSheet(activity: activity)
        }
    }
}

#if DEBUG
#Preview {
    CommentsSheet(activity: PreviewSamples.sampleActivity())
        .withPreviewEnvironment()
}
#endif
