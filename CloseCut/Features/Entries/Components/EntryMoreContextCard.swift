//
//  EntryMoreContextCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct EntryMoreContextCard: View {
    @Binding var keyMoment: String
    @Binding var intensity: Int
    @Binding var tags: [String]
    @Binding var watchContext: WatchContext
    @Binding var cinemaAudio: Int?
    @Binding var cinemaScreen: Int?
    @Binding var cinemaComfort: Int?

    @FocusState.Binding var focusedField: EntryEditorFocusField?

    @State private var isExpanded = false

    private var hasAddedContext: Bool {
        keyMoment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ||
        tags.isEmpty == false ||
        intensity != 3 ||
        watchContext != .home ||
        cinemaAudio != nil ||
        cinemaScreen != nil ||
        cinemaComfort != nil
    }

    private var keyMomentBorderColor: Color {
        keyMoment.count > EntryValidation.maxQuoteLength
            ? CloseCutColors.failed
            : CloseCutColors.separator
    }

    var body: some View {
        EntryEditorSectionCard(
            title: "More context",
            subtitle: summaryText,
            systemImage: "slider.horizontal.3"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                toggleButton

                if isExpanded {
                    expandedContent
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .onAppear {
            isExpanded = hasAddedContext
        }
    }

    private var summaryText: String {
        if hasAddedContext {
            return "Signals added for richer memory, rewatch logic, and QuickPick."
        }

        return "Optional signals for tags, intensity, context, and cinema details."
    }

    private var toggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                Text(isExpanded ? "Hide details" : "Add more context")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Spacer()

                if hasAddedContext && isExpanded == false {
                    Text("Added")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(CloseCutColors.card)
                        .clipShape(Capsule())
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
            .padding(12)
            .background(CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? "Hide more context" : "Add more context")
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            keyMomentSection

            intensitySection

            tagsSection

            contextSection

            if watchContext == .cinema {
                CinemaExperienceFields(
                    audio: $cinemaAudio,
                    screen: $cinemaScreen,
                    comfort: $cinemaComfort
                )
                .animation(.easeInOut(duration: 0.2), value: watchContext)
            }
        }
    }

    private var keyMomentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Moment")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textSecondary)

            TextField("A line, scene, or detail that stayed with you…", text: $keyMoment, axis: .vertical)
                .focused($focusedField, equals: .keyMoment)
                .font(.body)
                .foregroundStyle(CloseCutColors.textPrimary)
                .lineLimit(1...3)
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(keyMomentBorderColor)
                        .frame(height: 0.5)
                }
                .onChange(of: keyMoment) { _, newValue in
                    if newValue.count > EntryValidation.maxQuoteLength {
                        keyMoment = String(newValue.prefix(EntryValidation.maxQuoteLength))
                    }
                }

            Text("\(keyMoment.count)/\(EntryValidation.maxQuoteLength)")
                .font(.caption2)
                .foregroundStyle(
                    keyMoment.count > EntryValidation.maxQuoteLength
                    ? CloseCutColors.failed
                    : CloseCutColors.textTertiary
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Intensity")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textSecondary)

            IntensitySelector(value: $intensity)
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textSecondary)

            TagsInputView(tags: $tags)
        }
    }

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Where did you watch it?")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textSecondary)

            ContextSelector(selectedContext: $watchContext)
        }
    }
}
