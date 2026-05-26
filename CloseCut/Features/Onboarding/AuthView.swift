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
    @State private var isPasswordVisible = false

    @FocusState private var focusedField: AuthField?

    private enum AuthField {
        case email
        case password
    }

    private var cleanedEmail: String {
        email.trimmed.lowercased()
    }

    private var isEmailValid: Bool {
        cleanedEmail.contains("@") &&
        cleanedEmail.contains(".") &&
        cleanedEmail.count >= 5
    }

    private var isPasswordValid: Bool {
        password.count >= 6
    }

    private var canSubmit: Bool {
        isEmailValid &&
        isPasswordValid &&
        isSubmitting == false
    }

    private var titleText: String {
        isCreatingAccount
            ? "Create your private taste library"
            : "Welcome back"
    }

    private var subtitleText: String {
        isCreatingAccount
            ? "Build a private record of what you watch, what stayed with you, and what your taste says about you."
            : "Continue your private Timeline, QuickPick, and trusted Circles."
    }

    private var primaryButtonTitle: String {
        if isSubmitting {
            return isCreatingAccount ? "Creating account…" : "Signing in…"
        }

        return isCreatingAccount ? "Create account" : "Sign in"
    }

    private var passwordHintText: String {
        if password.isEmpty {
            return "Use at least 6 characters."
        }

        if isPasswordValid == false {
            return "Password is too short."
        }

        return isCreatingAccount ? "Looks good." : "Password ready."
    }

    private var emailHintText: String {
        if cleanedEmail.isEmpty {
            return "Use the email connected to your CloseCut account."
        }

        if isEmailValid == false {
            return "Enter a valid email address."
        }

        return "Email ready."
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Spacer(minLength: 34)

                        brandHeader

                        valueSignals

                        authForm

                        primaryButton

                        modeToggleButton

                        if case .error(let message) = authService.authState {
                            errorBanner(message)
                        }

                        privacyNote

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, CloseCutSpacing.xxl)
                    .padding(.vertical, CloseCutSpacing.xl)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .onChange(of: isCreatingAccount) { _, _ in
            password = ""
            focusedField = .email
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
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("CloseCut. \(titleText). \(subtitleText)")
    }

    private var valueSignals: some View {
        HStack(spacing: 8) {
            signalPill(
                icon: "lock.fill",
                text: "Private"
            )

            signalPill(
                icon: "sparkles",
                text: "QuickPick"
            )

            signalPill(
                icon: "person.2.fill",
                text: "Circles"
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var authForm: some View {
        VStack(spacing: 14) {
            inputGroup(
                label: "Email",
                hint: emailHintText,
                isValid: cleanedEmail.isEmpty ? nil : isEmailValid
            ) {
                TextField("you@example.com", text: $email)
                    .focused($focusedField, equals: .email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .password
                    }
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textPrimary)
            }

            inputGroup(
                label: "Password",
                hint: passwordHintText,
                isValid: password.isEmpty ? nil : isPasswordValid
            ) {
                HStack(spacing: 10) {
                    Group {
                        if isPasswordVisible {
                            TextField("Minimum 6 characters", text: $password)
                        } else {
                            SecureField("Minimum 6 characters", text: $password)
                        }
                    }
                    .focused($focusedField, equals: .password)
                    .textContentType(isCreatingAccount ? .newPassword : .password)
                    .submitLabel(.go)
                    .onSubmit {
                        Task {
                            await submit()
                        }
                    }
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textPrimary)

                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                }
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

    private func inputGroup<Content: View>(
        label: String,
        hint: String,
        isValid: Bool?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .tracking(0.8)

                Spacer()

                if let isValid {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isValid ? CloseCutColors.synced : CloseCutColors.pending)
                        .accessibilityHidden(true)
                }
            }

            content()
                .padding(14)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(inputBorderColor(isValid: isValid), lineWidth: 0.6)
                }

            Text(hint)
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
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
                        .tint(.white)
                }

                Text(primaryButtonTitle)
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

            VStack(alignment: .leading, spacing: 3) {
                Text("Couldn’t continue")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

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

    private func signalPill(
        icon: String,
        text: String
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }

    private func inputBorderColor(isValid: Bool?) -> Color {
        guard let isValid else {
            return CloseCutColors.separator
        }

        return isValid ? CloseCutColors.separator : CloseCutColors.pending.opacity(0.7)
    }

    private func submit() async {
        guard canSubmit else {
            return
        }

        focusedField = nil
        isSubmitting = true

        defer {
            isSubmitting = false
        }

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
