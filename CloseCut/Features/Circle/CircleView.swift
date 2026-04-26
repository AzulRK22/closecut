//
//  CircleView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

struct CircleView: View {
    let user: AuthUser
    let profile: UserProfile

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                EmptyStateView(
                    title: "Your circle is empty",
                    message: "Invite friends with your personal code.",
                    systemImage: "person.2.circle",
                    actionTitle: "Invite friends",
                    action: {}
                )
            }
            .navigationTitle("Circle")
        }
    }
}
