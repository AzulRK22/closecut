//
//  JoinCircleSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import SwiftUI

struct JoinCircleSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var inviteCode: String
    let preview: CirclePreview?
    let isPreviewing: Bool
    let isJoining: Bool
    let onPreview: () -> Void
    let onJoin: () -> Void
    let onCancel: () -> Void
    let onInviteCodeChanged: (_ normalizedInviteCode: String) -> Void

    @FocusState private var isCodeFocused: Bool

    private var cleanedInviteCode: String {
        inviteCode.normalizedInviteCode
    }

    private var canPreview: Bool {
        cleanedInviteCode.isEmpty == false &&
        isPreviewing == false &&
        isJoining == false
    }

    private var canJoin: Bool {
        preview != nil &&
        preview?.isAlreadyMember == false &&
        isPreviewing == false &&
        isJoining == false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

                        inviteCodeSection

                        if isPreviewing {
                            loadingCard(
                                message: "Finding Circle…"
                            )
                        }

                        if let preview {
                            CirclePreviewCard(preview: preview)
                        }

                        if isJoining {
                            loadingCard(
                                message: "Joining Circle…"
                            )
                        }

                        actionButton

                        privacyCard

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Join Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .disabled(isJoining || isPreviewing)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isCodeFocused = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                SwiftUI.Circle()
                    .fill(CloseCutColors.accent.opacity(0.18))
                    .frame(width: 52, height: 52)

                Image(systemName: "ticket.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Join a trusted Circle.")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Paste an invite code, preview the space, then decide if you want to join.")
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var inviteCodeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Invite code")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Codes are shared by Circle members. You will preview before joining.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Image(systemName: "number")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)

                TextField("PASTE CODE", text: $inviteCode)
                    .focused($isCodeFocused)
                    .font(.title3.monospaced().weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        guard canPreview else {
                            return
                        }

                        onPreview()
                    }
                    .onChange(of: inviteCode) { _, newValue in
                        let normalized = newValue.normalizedInviteCode

                        if normalized != newValue {
                            inviteCode = normalized
                        }

                        onInviteCodeChanged(normalized)
                    }

                if cleanedInviteCode.isEmpty == false {
                    Button {
                        inviteCode = ""
                        onInviteCodeChanged("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear invite code")
                }
            }
            .padding(14)
            .background(CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "eye.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .padding(.top, 1)

                Text("Previewing does not join the Circle or share anything from your Personal library.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var actionButton: some View {
        Button {
            if let preview {
                if preview.isAlreadyMember {
                    onCancel()
                    dismiss()
                } else {
                    onJoin()
                }
            } else {
                onPreview()
            }
        } label: {
            HStack(spacing: 8) {
                if isPreviewing || isJoining {
                    ProgressView()
                        .scaleEffect(0.85)
                }

                Text(actionTitle)
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(actionIsEnabled ? .white : CloseCutColors.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(actionIsEnabled ? CloseCutColors.accent : CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(actionIsEnabled == false)
    }

    private var actionTitle: String {
        if isPreviewing {
            return "Finding Circle…"
        }

        if isJoining {
            return "Joining Circle…"
        }

        if let preview {
            return preview.isAlreadyMember ? "Done" : "Join Circle"
        }

        return "Preview Circle"
    }

    private var actionIsEnabled: Bool {
        if preview != nil {
            return preview?.isAlreadyMember == true || canJoin
        }

        return canPreview
    }

    private var privacyCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "eye.slash.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 28, height: 28)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Joining is not sharing")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("A Circle only sees entries intentionally shared with it. Your Personal library stays private.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

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

    private func loadingCard(
        message: String
    ) -> some View {
        HStack(spacing: 10) {
            ProgressView()

            Text(message)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
