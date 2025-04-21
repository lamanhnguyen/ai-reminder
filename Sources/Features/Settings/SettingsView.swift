import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("Permissions")) {
                Toggle("Notifications", isOn: $viewModel.isNotificationsEnabled)
                    .disabled(viewModel.isLoading)
                    .onChange(of: viewModel.isNotificationsEnabled) { isEnabled in
                        if isEnabled {
                            Task {
                                await viewModel.requestNotificationPermission()
                            }
                        }
                    }
                
                Toggle("Speech Recognition", isOn: $viewModel.isSpeechRecognitionEnabled)
                    .disabled(viewModel.isLoading)
                    .onChange(of: viewModel.isSpeechRecognitionEnabled) { isEnabled in
                        if isEnabled {
                            Task {
                                await viewModel.requestSpeechRecognitionPermission()
                            }
                        }
                    }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil), actions: {
            Button("OK") {
                viewModel.clearError()
            }
        }, message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        })
        .navigationTitle("Settings")
    }
} 