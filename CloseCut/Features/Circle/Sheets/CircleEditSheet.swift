//
//  CircleEditSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/05/26.
//

import SwiftUI

struct CircleEditSheet: View {
    let circle: CloseCircle
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: (_ name: String, _ description: String?) -> Void

    @State private var name: String
    @State private var description: String

    init(
        circle: CloseCircle,
        isSaving: Bool,
        onCancel: @escaping () -> Void,
        onSave: @escaping (_ name: String, _ description: String?) -> Void
    ) {
        self.circle = circle
        self.isSaving = isSaving
        self.onCancel = onCancel
        self.onSave = onSave

        _name = State(initialValue: circle.name)
        _description = State(initialValue: circle.description ?? "")
    }

    private var canSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
        isSaving == false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    Text("Edit Circle")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Update the name and description members see in this private Circle.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Circle name")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        TextField("Circle name", text: $name)
                            .font(.body)
                            .foregroundStyle(CloseCutColors.textPrimary)
                            .textInputAutocapitalization(.words)
                            .padding(14)
                            .background(CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description optional")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        TextField("What is this Circle for?", text: $description)
                            .font(.body)
                            .foregroundStyle(CloseCutColors.textPrimary)
                            .textInputAutocapitalization(.sentences)
                            .padding(14)
                            .background(CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    if isSaving {
                        HStack(spacing: 10) {
                            ProgressView()

                            Text("Saving changes…")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Edit Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, description)
                    }
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
