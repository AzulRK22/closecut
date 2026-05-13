//
//  AuthView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var isCreatingAccount = false
    @State private var isSubmitting = false

    private var cleanedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        cleanedEmail.contains("@") &&
        cleanedEmail.contains(".") &&
        password.count >= 6 &&
        isSubmitting == false
    }

    private var titleText: String {
        isCreatingAccount ? "Create your private taste library" : "Welcome back"
    }

    private var subtitleText: String {
        isCreatingAccount
        ? "Add what you watched, remember what stayed with you, and get better picks from your own history."
        : "Continue your private library, QuickPick, and trusted Circles."
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        Spacer(minLength: 44)

                        brandHeader

                        authForm

                        primaryButton

                        modeToggleButton

                        if case .error(let message) = authService.authState {
                            errorBanner(message)
                        }

                        privacyNote

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .onChange(of: isCreatingAccount) { _, _ in
            password = ""
        }
    }

    private var brandHeader: some View {
        VStack(spacing: 18) {
            CloseCutLogoMark(size: 86)

            VStack(spacing: 8) {
                Text("CloseCut")
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(titleText)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var authForm: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                TextField("you@example.com", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .padding(14)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                SecureField("Minimum 6 characters", text: $password)
                    .textContentType(isCreatingAccount ? .newPassword : .password)
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .padding(14)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var primaryButton: some View {
        Button {
            Task {
                await submit()
            }
        } label: {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView()
                        .scaleEffect(0.9)
                }

                Text(isSubmitting ? "Working…" : isCreatingAccount ? "Create account" : "Sign in")
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(canSubmit ? .white : CloseCutColors.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(canSubmit ? CloseCutColors.accent : CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(canSubmit == false)
        .accessibilityLabel(isCreatingAccount ? "Create account" : "Sign in")
    }

    private var modeToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCreatingAccount.toggle()
            }
        } label: {
            Text(isCreatingAccount
                 ? "Already have an account? Sign in"
                 : "New here? Create an account")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.failed)
                .padding(.top, 2)

            Text(message)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.failedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Authentication error: \(message)")
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text("Private by default. Your Personal Timeline stays yours unless you choose to share with a Circle.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }

    private func submit() async {
        guard canSubmit else {
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        if isCreatingAccount {
            await authService.signUp(
                email: cleanedEmail,
                password: password
            )
        } else {
            await authService.signIn(
                email: cleanedEmail,
                password: password
            )
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthService())
}
