//
//  WrapSharePreviewView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/06/26.
//

import SwiftUI

struct WrapSharePreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let summary: WrapSummary

    @State private var options = WrapShareOptions.privacySafeDefault

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        header

                        WrapShareCardView(
                            summary: summary,
                            options: options
                        )
                        .padding(.top, 4)

                        privacyOptions

                        safetyNote

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Share Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share") {
                        // Export image viene en el siguiente paso.
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accent)
                    .disabled(true)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Customize what you share")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Your Wrap stays privacy-safe by default. Titles and posters are off unless you decide to include them.")
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var privacyOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Privacy controls")
                .font(.caption2.weight(.bold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.9)

            VStack(spacing: 0) {
                optionToggle(
                    title: "Watched count",
                    subtitle: "Show how many stories you watched.",
                    isOn: $options.includeWatchedCount
                )

                divider

                optionToggle(
                    title: "Movie / series split",
                    subtitle: "Show your movies and series count.",
                    isOn: $options.includeMediaSplit
                )

                divider

                optionToggle(
                    title: "Top genres",
                    subtitle: "Show your top genre signals.",
                    isOn: $options.includeTopGenres
                )

                divider

                optionToggle(
                    title: "Mood signal",
                    subtitle: "Show your strongest emotional signal.",
                    isOn: $options.includeMoodSignal
                )

                divider

                optionToggle(
                    title: "Top title",
                    subtitle: "Show the strongest memory from this Wrap.",
                    isOn: $options.includeTopTitle
                )

                divider

                optionToggle(
                    title: "Poster strip",
                    subtitle: "Show poster artwork from this period.",
                    isOn: $options.includePosterStrip
                )

                divider

                optionToggle(
                    title: "CloseCut branding",
                    subtitle: "Show a small CloseCut footer.",
                    isOn: $options.includeBranding
                )
            }
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
        }
    }

    private func optionToggle(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: CloseCutColors.accent))
        .padding(14)
    }

    private var divider: some View {
        Divider()
            .overlay(CloseCutColors.separator)
            .padding(.leading, 14)
    }

    private var safetyNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .padding(.top, 2)

            Text("Personal notes, quotes, Circle names, shared status, and takeaways are never included in this share card.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }
}
