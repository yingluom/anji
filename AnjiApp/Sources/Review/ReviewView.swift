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
                    Button { session.undo() } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(!session.canUndo)
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
            // Card type indicator
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(session.currentCardType.color)
                        .frame(width: 8, height: 8)
                    Text(session.currentCardType.label)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(session.currentCardType.color)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(session.currentCardType.color.opacity(0.12))
                )
                Spacer()
            }
            .padding(.top, 8)
            .padding(.bottom, 4)

            ScrollView {
                CardWebView(
                    html: session.showingAnswer ? session.answerHTML : session.questionHTML,
                    templateCSS: session.templateCSS
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if session.showingAnswer {
                ratingButtons
            } else {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { session.revealAnswer() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("review.show_answer")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                    }
                    .background(
                        ZStack {
                            // Base glass layer
                            Capsule()
                                .fill(.ultraThinMaterial)
                            
                            // Gradient overlay
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            anjiAccent.opacity(0.25),
                                            anjiAccent.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            // Inner highlight
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.5),
                                            .white.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                            
                            // Outer border
                            Capsule()
                                .stroke(anjiAccent.opacity(0.4), lineWidth: 1.5)
                        }
                        .shadow(
                            color: anjiAccent.opacity(0.25),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    )
                    .foregroundStyle(anjiAccent)
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.vertical, 16)
            }
        }
    }

    // MARK: - Rating Buttons

    private var ratingButtons: some View {
        HStack(spacing: Spacing.sm) {
            ratingButton(.again, color: .anjiAgain)
            ratingButton(.hard,  color: .anjiHard)
            ratingButton(.good,  color: .anjiGood)
            ratingButton(.easy,  color: .anjiEasy)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private struct RatingButton: View {
        let rating: Rating
        let color: Color
        let interval: String
        let action: () -> Void

        @State private var isPressed = false

        var body: some View {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    action()
                }
            } label: {
                VStack(spacing: 2) {
                    Text(interval)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(rating.label)
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 4)
            }
            .background(
                ZStack {
                    // Base glass layer
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    
                    // Gradient overlay for depth
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.15),
                                    color.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Inner highlight
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.4),
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                    
                    // Outer border with color
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(isPressed ? 0.5 : 0.25), lineWidth: isPressed ? 2 : 1)
                }
                .shadow(
                    color: color.opacity(isPressed ? 0.3 : 0.15),
                    radius: isPressed ? 12 : 6,
                    x: 0,
                    y: isPressed ? 6 : 2
                )
            )
            .foregroundStyle(color)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isPressed)
            .buttonStyle(RatingButtonStyle(isPressed: $isPressed))
        }
    }

    private struct RatingButtonStyle: ButtonStyle {
        @Binding var isPressed: Bool

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .onChange(of: configuration.isPressed) { _, newValue in
                    isPressed = newValue
                }
        }
    }

    private func ratingButton(_ rating: Rating, color: Color) -> some View {
        RatingButton(
            rating: rating,
            color: color,
            interval: session.nextIntervals[rating] ?? "",
            action: { session.answer(rating: rating) }
        )
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
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

            Spacer()
            Button("common.done") { onDismiss() }
                .buttonStyle(AnjiPrimaryButton())
                .padding()
        }
    }
}
