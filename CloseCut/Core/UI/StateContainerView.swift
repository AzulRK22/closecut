//
//  StateContainerView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

enum ViewState<Value> {
    case loading
    case empty
    case success(Value)
    case error(String)
}

struct StateContainerView<Content: View>: View {
    let title: String
    let message: String
    let state: ViewState<Bool>
    let retry: (() -> Void)?
    let content: () -> Content

    var body: some View {
        switch state {
        case .loading:
            VStack(spacing: 16) {
                ProgressView()
                Text("Loading")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            EmptyStateView(
                title: title,
                message: message,
                systemImage: "film"
            )

        case .success:
            content()

        case .error(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("Something went wrong")
                    .font(.headline)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let retry {
                    Button("Retry") {
                        retry()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
