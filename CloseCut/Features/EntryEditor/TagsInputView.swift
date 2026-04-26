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

    private let maxTags = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 6) {
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundStyle(CloseCutColors.accentLight)

                                Button {
                                    remove(tag)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                        .foregroundStyle(CloseCutColors.textTertiary)
                                }
                                .accessibilityLabel("Remove tag \(tag)")
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            TextField("+ Add a tag", text: $draftTag)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit {
                    addDraftTag()
                }
                .onChange(of: draftTag) { _, newValue in
                    if newValue.contains(",") {
                        addDraftTag()
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
                .disabled(tags.count >= maxTags)

            Text("\(tags.count)/\(maxTags) tags")
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textTertiary)
        }
    }

    private func addDraftTag() {
        let cleaned = draftTag
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard cleaned.isEmpty == false else {
            draftTag = ""
            return
        }

        guard tags.count < maxTags else {
            draftTag = ""
            return
        }

        guard tags.contains(cleaned) == false else {
            draftTag = ""
            return
        }

        tags.append(cleaned)
        draftTag = ""
    }

    private func remove(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}
