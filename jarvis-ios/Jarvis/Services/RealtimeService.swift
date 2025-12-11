import Foundation
import AVFoundation

class RealtimeService: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var error: String?

    private var webSocketTask: URLSessionWebSocketTask?
    private var audioEngine: AVAudioEngine?  // For recording
    private var playbackAudioEngine: AVAudioEngine?  // For playback
    private var audioPlayer: AVAudioPlayerNode?
    private var audioFormat: AVAudioFormat?

    // OpenAI API Configuration
    private var apiKey: String
    private let model = "gpt-4o-realtime-preview-2024-12-17"
    private let wsURL = "wss://api.openai.com/v1/realtime"

    init(apiKey: String) {
        self.apiKey = apiKey
        super.init()
    }

    func updateAPIKey(_ newKey: String) {
        print("🔑 Updating API key: \(newKey.prefix(10))...\(newKey.suffix(4))")
        self.apiKey = newKey
    }

    // MARK: - WebSocket Connection

    func connect() {
        print("📱 connect() called")
        print("   isConnected: \(isConnected)")
        print("   apiKey empty: \(apiKey.isEmpty)")

        guard !isConnected else {
            print("⚠️  Already connected, skipping")
            return
        }

        guard !apiKey.isEmpty else {
            print("❌ API key is empty")
            DispatchQueue.main.async {
                self.error = "API key is empty. Tap the key icon to add one."
            }
            return
        }

        // Clear previous error
        DispatchQueue.main.async {
            self.error = nil
        }

        guard let url = URL(string: "\(wsURL)?model=\(model)") else {
            print("❌ Invalid URL")
            DispatchQueue.main.async {
                self.error = "Invalid WebSocket URL"
            }
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")
        request.timeoutInterval = 10

        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)

        webSocketTask = session.webSocketTask(with: request)

        print("🔌 Connecting to OpenAI Realtime API...")
        print("📍 URL: \(url.absoluteString)")
        print("🔑 API Key: \(apiKey.prefix(10))...\(apiKey.suffix(4))")
        print("📋 Headers: Authorization: Bearer ***")
        print("📋 Headers: OpenAI-Beta: realtime=v1")

        webSocketTask?.resume()

        receiveMessage()

        // Configure session after connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.isConnected {
                print("✅ Connection successful, configuring session...")
                self.configureSession()
            } else {
                print("❌ Connection timeout after 3 seconds")
                self.error = "Connection timeout. Check:\n• API key is valid\n• Internet connection\n• OpenAI service status"
            }
        }
    }

    func disconnect() {
        print("🔌 Disconnecting...")
        stopRecording()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        print("✅ Disconnected")
    }

    private func configureSession() {
        let sessionConfig: [String: Any] = [
            "type": "session.update",
            "session": [
                "modalities": ["text", "audio"],
                "instructions": "You are JARVIS, a helpful AI assistant. Be concise and conversational.",
                "voice": "alloy",
                "input_audio_format": "pcm16",
                "output_audio_format": "pcm16",
                "input_audio_transcription": [
                    "model": "whisper-1"
                ],
                "turn_detection": [
                    "type": "server_vad",
                    "threshold": 0.5,
                    "prefix_padding_ms": 300,
                    "silence_duration_ms": 500
                ]
            ]
        ]

        sendEvent(sessionConfig)
    }

    // MARK: - WebSocket Message Handling

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }

                // Continue receiving
                self?.receiveMessage()

            case .failure(let error):
                print("❌ WebSocket error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.error = "Connection failed: \(error.localizedDescription)"
                    self?.isConnected = false
                }
            }
        }
    }

    private func handleMessage(_ text: String) {
        print("📨 Received message: \(text.prefix(200))...")

        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            print("⚠️  Failed to parse message")
            return
        }

        print("📬 Event type: \(type)")

        DispatchQueue.main.async {
            switch type {
            case "session.created":
                self.isConnected = true
                self.error = nil
                print("✅ Session created - CONNECTED!")
                if let session = json["session"] as? [String: Any] {
                    print("   Session ID: \(session["id"] ?? "unknown")")
                    print("   Model: \(session["model"] ?? "unknown")")
                }

            case "session.updated":
                print("✅ Session configured")

            case "input_audio_buffer.speech_started":
                print("🎤 Speech detected")

            case "input_audio_buffer.speech_stopped":
                print("🛑 Speech stopped")

            case "conversation.item.input_audio_transcription.completed":
                if let transcript = json["transcript"] as? String {
                    self.transcribedText = transcript
                    print("📝 Transcription: \(transcript)")
                }

            case "response.audio.delta":
                if let delta = json["delta"] as? String {
                    print("🔊 Audio delta received (\(delta.count) chars)")
                    self.playAudioDelta(delta)
                }

            case "response.done":
                print("✅ Response completed")

            case "error":
                if let errorData = json["error"] as? [String: Any] {
                    let message = errorData["message"] as? String ?? "Unknown error"
                    let code = errorData["code"] as? String ?? "unknown"
                    let errorMsg = "API error (\(code)): \(message)"
                    print("❌ \(errorMsg)")
                    self.error = errorMsg
                    self.isConnected = false
                }

            default:
                print("📭 Received event: \(type)")
            }
        }
    }

    private func sendEvent(_ event: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: event),
              let jsonString = String(data: data, encoding: .utf8) else {
            return
        }

        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Send error: \(error)")
            }
        }
    }

    // MARK: - Audio Recording (24kHz PCM16)

    func startRecording() {
        print("🎤 startRecording() called")
        print("   isConnected: \(isConnected)")

        guard isConnected else {
            print("❌ Not connected, cannot record")
            DispatchQueue.main.async {
                self.error = "Not connected to OpenAI"
            }
            return
        }

        // Request microphone permission first
        AVAudioApplication.requestRecordPermission { granted in
            print("🎤 Microphone permission: \(granted)")
            if !granted {
                DispatchQueue.main.async {
                    self.error = "Microphone permission denied. Go to Settings → Privacy → Microphone"
                }
                return
            }

            // Permission granted, continue on main thread
            DispatchQueue.main.async {
                self.setupAndStartRecording()
            }
        }
    }

    private func setupAndStartRecording() {
        print("🎤 Setting up audio...")

        stopRecording()

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            print("✅ Audio session configured")
        } catch {
            print("❌ Audio session error: \(error)")
            self.error = "Audio setup failed: \(error.localizedDescription)"
            return
        }

        // Create audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            print("❌ Failed to create audio engine")
            self.error = "Failed to create audio engine"
            return
        }

        let inputNode = audioEngine.inputNode
        print("✅ Got input node")

        // Target format: 24kHz, PCM16, mono
        let targetSampleRate = 24000.0
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            print("❌ Failed to create target format")
            self.error = "Failed to create audio format"
            return
        }
        print("✅ Created target format: 24kHz PCM16 mono")

        // Input format from microphone
        let inputFormat = inputNode.outputFormat(forBus: 0)
        print("✅ Input format: \(inputFormat.sampleRate)Hz, \(inputFormat.channelCount) channels")

        // Create converter
        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            print("❌ Failed to create converter")
            self.error = "Failed to create audio converter"
            return
        }
        print("✅ Created audio converter")

        // Install tap
        do {
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
                self?.convertAndSendAudio(buffer: buffer, converter: converter, targetFormat: targetFormat)
            }
            print("✅ Installed audio tap")
        } catch {
            print("❌ Tap installation failed: \(error)")
            self.error = "Failed to install audio tap: \(error.localizedDescription)"
            return
        }

        // Start engine
        audioEngine.prepare()
        print("✅ Audio engine prepared")

        do {
            try audioEngine.start()
            print("✅ Audio engine started")
            isRecording = true
            print("🎤 Recording started successfully!")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
            self.error = "Failed to start recording: \(error.localizedDescription)"
            inputNode.removeTap(onBus: 0)
            self.audioEngine = nil
        }
    }

    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        isRecording = false

        if isConnected {
            // Commit audio buffer
            let commitEvent: [String: Any] = [
                "type": "input_audio_buffer.commit"
            ]
            sendEvent(commitEvent)

            // Request response
            let responseEvent: [String: Any] = [
                "type": "response.create"
            ]
            sendEvent(responseEvent)
        }

        print("🛑 Recording stopped")
    }

    private func convertAndSendAudio(buffer: AVAudioPCMBuffer, converter: AVAudioConverter, targetFormat: AVAudioFormat) {
        // Calculate output buffer size
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * targetFormat.sampleRate / buffer.format.sampleRate)

        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else {
            return
        }

        var error: NSError?
        converter.convert(to: convertedBuffer, error: &error) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        if let error = error {
            print("Conversion error: \(error)")
            return
        }

        // Convert to base64
        guard let channelData = convertedBuffer.int16ChannelData else { return }
        let channelDataPointer = channelData.pointee
        let data = Data(bytes: channelDataPointer, count: Int(convertedBuffer.frameLength) * 2) // 2 bytes per Int16
        let base64Audio = data.base64EncodedString()

        // Send to OpenAI
        let event: [String: Any] = [
            "type": "input_audio_buffer.append",
            "audio": base64Audio
        ]
        sendEvent(event)
    }

    // MARK: - Audio Playback

    private func playAudioDelta(_ base64Audio: String) {
        guard let audioData = Data(base64Encoded: base64Audio) else { return }

        // Initialize audio player if needed
        if audioPlayer == nil {
            setupAudioPlayer()
        }

        // Play PCM16 audio
        playPCM16Audio(audioData)
    }

    private func setupAudioPlayer() {
        print("🔊 Setting up audio player...")

        audioPlayer = AVAudioPlayerNode()
        playbackAudioEngine = AVAudioEngine()

        guard let audioPlayer = audioPlayer,
              let playbackEngine = playbackAudioEngine,
              let audioFormat = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: 24000.0,
                channels: 1,
                interleaved: false
              ) else {
            print("❌ Failed to create audio player or format")
            return
        }

        self.audioFormat = audioFormat

        // Attach player node to playback engine
        playbackEngine.attach(audioPlayer)
        playbackEngine.connect(audioPlayer, to: playbackEngine.mainMixerNode, format: audioFormat)

        do {
            try playbackEngine.start()
            audioPlayer.play()
            print("✅ Audio player started successfully")
        } catch {
            print("❌ Failed to start playback engine: \(error)")
        }
    }

    private func playPCM16Audio(_ data: Data) {
        guard let audioPlayer = audioPlayer,
              let audioFormat = audioFormat else { return }

        let frameCount = UInt32(data.count / 2) // 2 bytes per Int16 sample

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            return
        }

        buffer.frameLength = frameCount

        // Copy audio data to buffer
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            guard let source = bytes.baseAddress?.assumingMemoryBound(to: Int16.self),
                  let destination = buffer.int16ChannelData?.pointee else { return }
            destination.initialize(from: source, count: Int(frameCount))
        }

        audioPlayer.scheduleBuffer(buffer)
    }
}
