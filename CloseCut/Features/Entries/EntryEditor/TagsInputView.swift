//
//  TagsInputView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

struct TagsInputView: View {
    @Binding var tags: [String]
    @State private var draftTag = ""
    @State private var helperMessage: String?

    private let maxTags = EntryValidation.maxTags
    private let maxTagLength = EntryValidation.maxTagLength

    private var canAddMoreTags: Bool {
        tags.count < maxTags
    }

    private var normalizedTags: [String] {
        EntryValidation.normalizedTags(tags)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if normalizedTags.isEmpty == false {
                tagList
            }

            inputField

            HStack {
                Text("\(normalizedTags.count)/\(maxTags) tags")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Spacer()

                if let helperMessage {
                    Text(helperMessage)
                        .font(.caption2)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(1)
                }
            }
        }
        .onAppear {
            tags = normalizedTags
        }
    }

    private var tagList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(normalizedTags, id: \.self) { tag in
                    tagChip(tag)
                }
            }
        }
        .accessibilityLabel("Tags \(normalizedTags.joined(separator: ", "))")
    }

    private func tagChip(_ tag: String) -> some View {
        HStack(spacing: 6) {
            Text("#\(tag)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)

            Button {
                remove(tag)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
            .accessibilityLabel("Remove tag \(tag)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }

    private var inputField: some View {
        TextField(canAddMoreTags ? "+ Add a tag" : "Tag limit reached", text: $draftTag)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .onSubmit {
                addDraftTag()
            }
            .onChange(of: draftTag) { _, newValue in
                if newValue.contains(",") {
                    addDraftTag()
                } else if newValue.count > maxTagLength + 4 {
                    draftTag = String(newValue.prefix(maxTagLength + 4))
                }
            }
            .font(.body)
            .foregroundStyle(CloseCutColors.textPrimary)
            .padding(.vertical, 10)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(CloseCutColors.separator)
                    .frame(height: 0.5)
            }
            .disabled(canAddMoreTags == false)
    }

    private func addDraftTag() {
        let cleaned = EntryValidation.normalizeTag(draftTag)

        defer {
            draftTag = ""
        }

        guard cleaned.isEmpty == false else {
            helperMessage = nil
            return
        }

        guard canAddMoreTags else {
            helperMessage = "Limit reached"
            return
        }

        guard cleaned.count <= maxTagLength else {
            helperMessage = "Too long"
            return
        }

        guard normalizedTags.contains(cleaned) == false else {
            helperMessage = "Already added"
            return
        }

        tags = EntryValidation.normalizedTags(tags + [cleaned])
        helperMessage = "Added"
    }

    private func remove(_ tag: String) {
        tags = normalizedTags.filter { $0 != tag }
        helperMessage = "Removed"
    }
}
