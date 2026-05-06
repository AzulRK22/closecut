//
//  BattleOptionSelectorSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.

import SwiftUI

struct BattleOptionSelectorSheet: View {
    let entries: [Entry]
    let initialSelection: Set<String>
    let onCancel: () -> Void
    let onConfirm: ([Entry]) -> Void

    @State private var selectedEntryIds: Set<String> = []

    private var sortedEntries: [Entry] {
        entries.sorted { first, second in
            first.watchedAt > second.watchedAt
        }
    }

    private var selectedEntries: [Entry] {
        sortedEntries.filter { selectedEntryIds.contains($0.id) }
    }

    private var canConfirm: Bool {
        selectedEntryIds.count >= 2
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(sortedEntries) { entry in
                                optionRow(entry)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }

                    footer
                }
            }
            .navigationTitle("Choose options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onConfirm(selectedEntries)
                    }
                    .disabled(canConfirm == false)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            selectedEntryIds = initialSelection
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pick at least two memories from your Timeline.")
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(selectedEntryIds.count) selected")
                .font(.caption.weight(.semibold))
                .foregroundStyle(canConfirm ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Button {
                onConfirm(selectedEntries)
            } label: {
                Text(canConfirm ? "Use selected options" : "Select at least 2")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(canConfirm ? .white : CloseCutColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(canConfirm ? CloseCutColors.accent : CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(canConfirm == false)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(CloseCutColors.backgroundPrimary)
    }

    private func optionRow(_ entry: Entry) -> some View {
        let isSelected = selectedEntryIds.contains(entry.id)

        return Button {
            toggle(entry)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(2)

                    Text(subtitle(for: entry))
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(14)
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? CloseCutColors.accentLight : CloseCutColors.separator, lineWidth: isSelected ? 1 : 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    private func subtitle(for entry: Entry) -> String {
        var parts: [String] = []

        if let releaseYear = entry.releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(entry.type.displayName)

        if entry.sourceType == .quickAdd {
            parts.append("Quick Add")
        }

        if entry.visibility == .circle {
            parts.append("Shared")
        }

        return parts.joined(separator: " • ")
    }

    private func toggle(_ entry: Entry) {
        if selectedEntryIds.contains(entry.id) {
            selectedEntryIds.remove(entry.id)
        } else {
            selectedEntryIds.insert(entry.id)
        }
    }
}
