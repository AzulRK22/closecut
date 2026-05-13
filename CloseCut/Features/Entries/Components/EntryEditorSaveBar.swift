//
//  EntryEditorSaveBar.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct EntryEditorSaveBar: View {
    let canSave: Bool
    let isSaving: Bool
    let buttonTitle: String
    let contextText: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Divider()
                .overlay(CloseCutColors.separator)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(canSave ? "Ready to save" : "Almost there")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text(contextText)
                        .font(.caption2)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(2)
                }

                Spacer()

                Button {
                    action()
                } label: {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                        }

                        Text(buttonTitle)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(canSave ? CloseCutColors.accent : CloseCutColors.inactive)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(canSave == false || isSaving)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }
}
