//
//  EntryTitleAutocompleteCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct EntryTitleAutocompleteCard: View {
    @Binding var title: String
    @Binding var type: EntryType

    let selectedResult: TMDBMediaSearchResult?
    let existingPosterPath: String?
    let existingSubtitle: String?
    let existingMediaType: TMDBMediaType
    let suggestions: [TMDBMediaSearchResult]
    let isSearching: Bool
    let searchErrorMessage: String?
    let errors: [String]

    let onTitleChanged: () -> Void
    let onSubmitSearch: () -> Void
    let onSelectResult: (TMDBMediaSearchResult) -> Void
    let onClearSelection: () -> Void

    @FocusState private var isTitleFocused: Bool

    private var cleanedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasConnectedMetadata: Bool {
        selectedResult != nil || existingPosterPath != nil || existingSubtitle != nil
    }

    private var hasTitleError: Bool {
        errors.contains("Title is required.") ||
        errors.contains("Title must be \(EntryValidation.maxTitleLength) characters or less.")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            titleInput

            if let selectedResult {
                selectedMetadataCard(result: selectedResult)
            } else if hasConnectedMetadata {
                existingMetadataCard
            }

            if shouldShowSuggestions {
                suggestionsList
            }

            if shouldShowSearchError {
                searchErrorBanner
            }

            TypeSelector(selectedType: $type)
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(hasTitleError ? CloseCutColors.failed.opacity(0.7) : CloseCutColors.separator, lineWidth: hasTitleError ? 1 : 0.5)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: hasConnectedMetadata ? "checkmark.seal.fill" : "magnifyingglass")
                .font(.caption.weight(.semibold))
                .foregroundStyle(hasConnectedMetadata ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                .frame(width: 30, height: 30)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("What did you watch?")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var headerSubtitle: String {
        if selectedResult != nil {
            return "Connected to TMDB. You can still edit the display title."
        }

        if hasConnectedMetadata {
            return "This entry already has metadata connected."
        }

        return "Start typing to search TMDB. You can also save manually."
    }

    private var titleInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "textformat")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)

                TextField("Movie or series title", text: $title)
                    .focused($isTitleFocused)
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        guard cleanedTitle.count >= 2 else {
                            return
                        }

                        onSubmitSearch()
                    }
                    .onChange(of: title) { _, newValue in
                        if newValue.count > EntryValidation.maxTitleLength {
                            title = String(newValue.prefix(EntryValidation.maxTitleLength))
                        }

                        onTitleChanged()
                    }

                if isSearching {
                    ProgressView()
                        .scaleEffect(0.76)
                } else if cleanedTitle.isEmpty == false {
                    Button {
                        title = ""
                        onTitleChanged()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear title")
                }
            }
            .padding(14)
            .background(CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(hasTitleError ? CloseCutColors.failed : CloseCutColors.separator, lineWidth: 0.5)
            }

            HStack {
                if hasTitleError {
                    Text(titleErrorText)
                        .font(.caption2)
                        .foregroundStyle(CloseCutColors.failed)
                } else {
                    Text(cleanedTitle.count >= 2 && selectedResult == nil ? "Searching helps attach poster, year, overview, genres, and rating." : "Required")
                        .font(.caption2)
                        .foregroundStyle(CloseCutColors.textTertiary)
                }

                Spacer()

                Text("\(title.count)/\(EntryValidation.maxTitleLength)")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
        }
    }

    private var titleErrorText: String {
        if errors.contains("Title is required.") {
            return "Title is required"
        }

        return "Title is too long"
    }

    private var shouldShowSuggestions: Bool {
        selectedResult == nil &&
        suggestions.isEmpty == false &&
        cleanedTitle.count >= 2
    }

    private var shouldShowSearchError: Bool {
        selectedResult == nil &&
        searchErrorMessage != nil &&
        cleanedTitle.count >= 2
    }

    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Best matches")
                    .font(.caption2.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)

                Spacer()

                Text("Tap to connect")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
            }

            VStack(spacing: 10) {
                ForEach(suggestions.prefix(4)) { result in
                    suggestionRow(result)
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func suggestionRow(_ result: TMDBMediaSearchResult) -> some View {
        Button {
            onSelectResult(result)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                MediaPosterView(
                    posterPath: result.posterPath,
                    mediaType: result.mediaType,
                    width: 48,
                    height: 72,
                    cornerRadius: 11
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text(result.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(2)

                    Text(result.subtitle)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(1)

                    if let overview = cleanOptional(result.overview) {
                        Text(overview)
                            .font(.caption2)
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(CloseCutColors.accentLight)
            }
            .padding(12)
            .background(CloseCutColors.input.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Connect \(result.title), \(result.subtitle)")
    }

    private func selectedMetadataCard(result: TMDBMediaSearchResult) -> some View {
        HStack(alignment: .top, spacing: 12) {
            MediaPosterView(
                posterPath: result.posterPath,
                mediaType: result.mediaType,
                width: 58,
                height: 86,
                cornerRadius: 12
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("Connected to TMDB")
                    .font(.caption2.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(CloseCutColors.accentLight)
                    .textCase(.uppercase)

                Text(result.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)

                Text(result.subtitle)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(1)

                Text("This powers poster, overview, genres, and QuickPick signals.")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button {
                onClearSelection()
            } label: {
                Text("Clear")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(CloseCutColors.card)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(CloseCutColors.input.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CloseCutColors.accent.opacity(0.45), lineWidth: 0.7)
        }
    }

    private var existingMetadataCard: some View {
        HStack(alignment: .top, spacing: 12) {
            MediaPosterView(
                posterPath: existingPosterPath,
                mediaType: existingMediaType,
                width: 58,
                height: 86,
                cornerRadius: 12
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("Metadata connected")
                    .font(.caption2.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(CloseCutColors.accentLight)
                    .textCase(.uppercase)

                Text(cleanedTitle.isEmpty ? "Connected title" : cleanedTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)

                if let existingSubtitle {
                    Text(existingSubtitle)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(1)
                }

                Text("Edit the title for your display name. Metadata stays connected.")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var searchErrorBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 1)

            Text("TMDB search is unavailable right now. You can still save this manually.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
