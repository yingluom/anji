import SwiftUI
import AnkiClients
import AnkiSync

/// Login form for AnkiWeb / custom sync server.
struct LoginSheet: View {
    @Binding var isPresented: Bool
    let onSuccess: () -> Void

    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("AnkiWeb Email", text: $username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        Task { await login() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().frame(maxWidth: .infinity)
                            } else {
                                Text("Sign In").frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .disabled(username.isEmpty || password.isEmpty || isLoading)
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    private func login() async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await SyncClient.login(username: username, password: password)
            isPresented = false
            onSuccess()
        } catch {
            errorMessage = "Login failed. Check your email and password."
        }
        isLoading = false
    }
}
