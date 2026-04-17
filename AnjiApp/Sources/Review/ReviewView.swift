import SwiftUI
import AnkiKit

struct ReviewView: View {
    let deckId: Int64
    let onDismiss: () -> Void

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
                    Text("\(session.stats.reviewed) reviewed")
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
                    Button("Done") { onDismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { session.undo() } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(!session.canUndo)
                }
            }
        }
        .task { session.start() }
    }

    // MARK: - Card Area

    private var cardArea: some View {
        VStack(spacing: 0) {
            CardWebView(html: session.showingAnswer ? session.answerHTML : session.questionHTML)
                .frame(maxHeight: .infinity)

            if session.showingAnswer {
                ratingButtons
            } else {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { session.revealAnswer() }
                } label: {
                    Text("Show Answer")
                        .anjiFont(.bodyBold)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.anjiAccent)
                .padding()
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

    private func ratingButton(_ rating: Rating, color: Color) -> some View {
        Button { session.answer(rating: rating) } label: {
            VStack(spacing: 4) {
                Text(session.nextIntervals[rating] ?? "")
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(rating.label)
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .foregroundStyle(color)
        .buttonStyle(.plain)
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(Color.anjiAccent.gradient)
                .symbolEffect(.bounce, value: session.isFinished)

            Text("Well Done!")
                .anjiFont(.largeTitle)
                .foregroundStyle(Color.anjiPrimary)

            VStack(spacing: Spacing.xs) {
                Text("\(session.stats.reviewed) cards reviewed")
                if session.stats.reviewed > 0 {
                    Text("Accuracy: \(Int(session.stats.accuracy * 100))%")
                }
            }
            .anjiFont(.body)
            .foregroundStyle(Color.anjiSecondary)

            Spacer()
            Button("Done") { onDismiss() }
                .buttonStyle(AnjiPrimaryButton())
                .padding()
        }
    }
}
