import SwiftUI

struct ContentView: View {
    @StateObject private var realtimeService = RealtimeService(
        apiKey: UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    )
    @State private var messages: [Message] = []
    @State private var showAPIKeyInput = false
    @State private var apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with settings
                HStack {
                    Spacer()
                    Button(action: {
                        showAPIKeyInput = true
                    }) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                            .padding()
                    }
                }

                // Conversation Area
                if messages.isEmpty {
                    emptyStateView
                } else {
                    conversationView
                }

                Spacer()

                // Connection status
                if !realtimeService.isConnected && !apiKey.isEmpty {
                    Text("Connecting...")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.yellow.opacity(0.7))
                        .padding(.bottom, 8)
                }

                if let error = realtimeService.error {
                    Text(error)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.red.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                // Voice Button
                voiceButton
                    .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showAPIKeyInput) {
            APIKeyInputView(apiKey: $apiKey, onSave: {
                saveAPIKey()
                reconnect()
            })
        }
        .onAppear {
            if !apiKey.isEmpty {
                realtimeService.connect()
            }
        }
        .onChange(of: realtimeService.transcribedText) { newValue in
            if !newValue.isEmpty && (messages.last?.text != newValue) {
                // Add or update user message
                if let lastMessage = messages.last, lastMessage.isUser {
                    messages[messages.count - 1] = Message(text: newValue, isUser: true)
                } else {
                    messages.append(Message(text: newValue, isUser: true))
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            // Animated pulse circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .overlay(
                    Circle()
                        .stroke(
                            realtimeService.isConnected ? Color.green.opacity(0.5) : Color.blue.opacity(0.5),
                            lineWidth: 2
                        )
                        .frame(width: 150, height: 150)
                )

            Text("JARVIS")
                .font(.system(size: 32, weight: .thin))
                .foregroundColor(.white.opacity(0.9))
                .tracking(8)

            if apiKey.isEmpty {
                Button(action: {
                    showAPIKeyInput = true
                }) {
                    Text("Configure API Key")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(20)
                }
                .padding(.top, 8)
            } else {
                Text(realtimeService.isConnected ? "Connected - Tap to speak" : "Connecting...")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 8)
            }

            Spacer()
        }
    }

    private var conversationView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 120)
            }
            .onChange(of: messages.count) { _ in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var voiceButton: some View {
        Button(action: {
            toggleRecording()
        }) {
            ZStack {
                // Outer glow when recording
                if realtimeService.isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                }

                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: realtimeService.isRecording ?
                                [Color.red, Color.red.opacity(0.8)] :
                                realtimeService.isConnected ?
                                [Color.blue, Color.blue.opacity(0.8)] :
                                [Color.gray, Color.gray.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: realtimeService.isRecording ? .red.opacity(0.5) : .blue.opacity(0.5),
                        radius: 20
                    )

                // Icon
                Image(systemName: realtimeService.isRecording ? "stop.fill" : "waveform")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(realtimeService.isRecording ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: realtimeService.isRecording)
        .disabled(!realtimeService.isConnected)
    }

    private func toggleRecording() {
        if realtimeService.isRecording {
            realtimeService.stopRecording()
        } else {
            realtimeService.startRecording()
        }
    }

    private func saveAPIKey() {
        UserDefaults.standard.set(apiKey, forKey: "openai_api_key")
    }

    private func reconnect() {
        realtimeService.disconnect()
        realtimeService.updateAPIKey(apiKey)

        // Wait a moment before reconnecting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.realtimeService.connect()
        }
    }
}

struct Message: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
    var isLoading: Bool = false
    let timestamp = Date()
}

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if message.isLoading {
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white.opacity(0.6))
                                .frame(width: 8, height: 8)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: message.isLoading
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                    )
                } else {
                    Text(message.text)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    message.isUser ?
                                        Color.blue.opacity(0.3) :
                                        Color.white.opacity(0.1)
                                )
                        )

                    Text(message.timestamp, style: .time)
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 4)
                }
            }

            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct APIKeyInputView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var apiKey: String
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("OpenAI API Key")
                        .font(.system(size: 24, weight: .thin))
                        .foregroundColor(.white)
                        .padding(.top, 40)

                    Text("Enter your OpenAI API key to enable voice conversations")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    SecureField("sk-...", text: $apiKey)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                        .padding(.top, 20)

                    Button(action: {
                        onSave()
                        dismiss()
                    }) {
                        Text("Save")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                    .disabled(apiKey.isEmpty)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
