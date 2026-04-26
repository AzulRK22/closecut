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

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Text("CloseCut")
                        .font(.largeTitle)
                        .fontWeight(.semibold)

                    Text("A private emotional journal for movies and series.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    SecureField("Password", text: $password)
                        .textContentType(isCreatingAccount ? .newPassword : .password)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    Task {
                        await submit()
                    }
                } label: {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text(isCreatingAccount ? "Create Account" : "Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canSubmit || isSubmitting)

                Button {
                    isCreatingAccount.toggle()
                } label: {
                    Text(isCreatingAccount
                         ? "Already have an account? Sign in"
                         : "New here? Create an account")
                }
                .font(.footnote)

                if case .error(let message) = authService.authState {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel("Authentication error: \(message)")
                }

                Spacer()
            }
            .padding()
            .navigationTitle("")
        }
    }

    private var canSubmit: Bool {
        email.contains("@") && password.count >= 6
    }

    private func submit() async {
        isSubmitting = true

        if isCreatingAccount {
            await authService.signUp(email: email, password: password)
        } else {
            await authService.signIn(email: email, password: password)
        }

        isSubmitting = false
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthService())
}
