//
//  QuickAddPreviewSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct QuickAddPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let result: TMDBMediaSearchResult
    @Binding var selectedSentiment: QuickSentiment?
    @Binding var selectedApproxDate: WatchedDateApprox
    let onAdd: () -> Void

    private var overviewText: String? {
        guard let overview = result.overview else {
            return nil
        }

        let cleaned = overview.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        hero

                        QuickAddSectionCard(
                            title: "Memory signal",
                            subtitle: "A quick feeling is enough for now."
                        ) {
                            QuickReactionChips(
                                selectedSentiment: $selectedSentiment
                            )
                        }

                        QuickAddSectionCard(
                            title: "Watched around",
                            subtitle: "No need to be exact."
                        ) {
                            RoughDateSelector(
                                selectedDate: $selectedApproxDate
                            )
                        }

                        Text("You can add takeaway, tags, and Circle sharing later.")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 112)
                }

                QuickAddPreviewAddBar(title: "Add to Personal") {
                    onAdd()
                    dismiss()
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                MediaPosterView(
                    posterPath: result.posterPath,
                    mediaType: result.mediaType,
                    width: 88,
                    height: 132,
                    cornerRadius: 16
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(result.mediaType == .tv ? "Series" : "Movie")
                        .font(.caption2.weight(.semibold))
                        .tracking(0.8)
                        .foregroundStyle(CloseCutColors.accentLight)
                        .textCase(.uppercase)

                    Text(result.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(result.subtitle)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(2)

                    if let rating = result.voteAverage, rating > 0 {
                        Text(String(format: "%.1f TMDB", rating))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())
                    }
                }

                Spacer(minLength: 0)
            }

            if let overviewText {
                Text(overviewText)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(4)
                    .lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }
}
