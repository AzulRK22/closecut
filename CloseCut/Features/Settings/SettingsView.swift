//
//  SettingsView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authService: AuthService

    let user: AuthUser
    let profile: UserProfile

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                List {
                    Section("Profile") {
                        HStack {
                            SwiftUI.Circle()
                                .fill(CloseCutColors.accent)
                                .frame(width: 56, height: 56)
                                .overlay {
                                    Text(profile.displayName.prefix(2).uppercased())
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }

                            VStack(alignment: .leading) {
                                Text(profile.displayName)
                                    .font(.headline)

                                Text(profile.email ?? user.id)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section("Privacy") {
                        Text("Your entries are private by default. Only entries you choose to share are visible to your circle.")
                            .font(.subheadline)
                    }

                    Section("Account") {
                        Button("Sign Out") {
                            authService.signOut()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }
}
