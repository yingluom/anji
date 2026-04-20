import SwiftUI
import AnkiKit
import Sharing

struct ReviewView: View {
    let deckId: Int64
    let onDismiss: () -> Void
    @Environment(\.anjiAccent) private var anjiAccent
    @Shared(.liveActivityEnabled) private var liveActivityEnabled

    @State private var session: ReviewSession

    init(deckId: Int64, onDismiss: @escaping () -> Void) {
        self.deckId = deckId
        self.onDismiss = onDismiss
        _session = State(initialValue: ReviewSession(deckId: deckId))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                HStack(spacing: Spacing.md) {
                    CountBadgesView(counts: session.remainingCounts)
                    Spacer()
                    Text("review.cards_reviewed(\(session.stats.reviewed))")
                        .anjiFont(.callout)
                        .foregroundStyle(Color.anjiSecondary)
                }
                .padding(.horizontal)
                .padding(.vertical, Spacing.sm)

                if session.isFinished {
                    completionView
                } else {
                    cardArea
                }
            }
            .background(Color.anjiBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.done") { onDismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            // Replay audio for current card
                            NotificationCenter.default.post(name: .init("AnjiReplayAudio"), object: nil)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                        }
                        .disabled(session.isFinished)

                        Button { session.undo() } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .disabled(!session.canUndo)
                    }
                }
            }
        }
        .task {
            session.start()
            startLiveActivity()
        }
        .onChange(of: session.questionHTML) { _, _ in
            updateLiveActivity()
        }
        .onChange(of: session.showingAnswer) { _, _ in
            updateLiveActivity()
        }
        .onChange(of: session.remainingCounts) { _, _ in
            updateLiveActivity()
        }
        .onDisappear {
            endLiveActivity()
        }
    }

    // MARK: - Live Activity

    private func startLiveActivity() {
        guard liveActivityEnabled,
              #available(iOS 16.1, *) else { return }

        // Get deck name from somewhere - for now use a placeholder
        // In a real implementation, you'd get the deck name from the session or deck client
        let deckName = "Study Session"

        LiveActivityManager.shared.startActivity(
            deckName: deckName,
            cardFront: cleanHTML(session.questionHTML),
            counts: session.remainingCounts,
            totalReviewed: session.stats.reviewed
        )
    }

    private func updateLiveActivity() {
        guard liveActivityEnabled,
              #available(iOS 16.1, *) else { return }

        LiveActivityManager.shared.updateActivity(
            cardFront: cleanHTML(session.questionHTML),
            cardBack: cleanHTML(session.answerHTML),
            showingAnswer: session.showingAnswer,
            counts: session.remainingCounts,
            totalReviewed: session.stats.reviewed
        )
    }

    private func endLiveActivity() {
        guard #available(iOS 16.1, *) else { return }
        LiveActivityManager.shared.endActivity()
    }

    private func cleanHTML(_ html: String) -> String {
        // Remove HTML tags and decode entities for Live Activity display
        var text = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Card Area

    private var cardArea: some View {
        VStack(spacing: 0) {
            CardWebView(
                html: session.showingAnswer ? session.answerHTML : session.questionHTML,
                templateCSS: session.templateCSS
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if session.showingAnswer {
                ratingButtons
            } else {
                showAnswerButton
            }
        }
    }

    // MARK: - Show Answer

    private var showAnswerButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { session.revealAnswer() }
        } label: {
            Text("review.show_answer")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(Color.accentColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Rating Buttons (Anki iOS style)

    private var ratingButtons: some View {
        HStack(spacing: 8) {
            ratingButton(.again, color: .anjiAgain)
            ratingButton(.hard,  color: .anjiHard)
            ratingButton(.good,  color: .anjiGood)
            ratingButton(.easy,  color: .anjiEasy)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func ratingButton(_ rating: Rating, color: Color) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                session.answer(rating: rating)
            }
        } label: {
            VStack(spacing: 2) {
                Text(session.nextIntervals[rating] ?? "")
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(rating.label)
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
        )
        .buttonStyle(.plain)
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            if let error = session.lastError, session.stats.reviewed == 0 {
                // Show error state when session failed before any cards were reviewed
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.anjiWarning)

                Text("review.session_error")
                    .anjiFont(.title)
                    .foregroundStyle(Color.anjiPrimary)

                Text(error)
                    .anjiFont(.callout)
                    .foregroundStyle(Color.anjiSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 56))
                    .foregroundStyle(anjiAccent.gradient)
                    .symbolEffect(.bounce, value: session.isFinished)

                Text("review.well_done")
                    .anjiFont(.largeTitle)
                    .foregroundStyle(Color.anjiPrimary)

                VStack(spacing: Spacing.xs) {
                    Text("review.cards_completed(\(session.stats.reviewed))")
                    if session.stats.reviewed > 0 {
                        Text("review.accuracy(\(Int(session.stats.accuracy * 100)))")
                    }
                }
                .anjiFont(.body)
                .foregroundStyle(Color.anjiSecondary)
            }

            Spacer()
            Button("common.done") { onDismiss() }
                .buttonStyle(AnjiPrimaryButton())
                .padding()
        }
    }
}
