//
//  BoxView.swift
//  FoundationModelsLearn
//
//  Created by Rani Badri on 9/17/25.
//

import Foundation
import SwiftUI
import Combine
import Speech
import AVFoundation

// MARK: - Main Container View
struct BoxView: View {
    @StateObject private var viewModel = BoxViewModel()

    var body: some View {
        VStack {
            Spacer()
            
            ChatInputContainer(viewModel: viewModel)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
        }
        .preferredColorScheme(.light)
    }
}

// MARK: - View Model
class BoxViewModel: ObservableObject {
    @Published var message: String = ""
    @Published var isListening: Bool = false
    @Published var showProgress: Bool = false
    @Published var wordCount: Int = 0
    @Published var showSendButton: Bool = false

    private let speechRecognizer = SpeechRecognizer()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Request permissions on initialization
        speechRecognizer.requestPermissions()

        // Bind speech recognizer's isListening to our isListening
        speechRecognizer.$isListening
            .sink { [weak self] listening in
                self?.isListening = listening
                self?.showProgress = listening
                
                if !listening {
                    // When listening stops, check if we have meaningful content
                    self?.checkAndShowSendButton()
                } else {
                    // Hide send button when starting to listen
                    self?.showSendButton = false
                }
            }
            .store(in: &cancellables)

        // Update message with transcript
        speechRecognizer.$transcript
            .sink { [weak self] transcript in
                guard let self = self else { return }

                if !transcript.isEmpty {
                    let words = transcript.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                    self.wordCount = words.count

                    if self.wordCount >= 4 {
                        // We have enough words, update the message
                        self.message = transcript
                        self.showProgress = false
                        
                        // If not currently listening, show send button
                        if !self.isListening {
                            self.showSendButton = true
                        }
                    } else if self.isListening {
                        self.message = "Listening..."
                    }
                } else {
                    // Empty transcript
                    if self.isListening {
                        self.message = "Listening..."
                        self.wordCount = 0
                    } else {
                        // Not listening and no transcript
                        self.message = ""
                        self.wordCount = 0
                        self.showSendButton = false
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkAndShowSendButton() {
        // Check if we should show send button when listening stops
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            let hasValidMessage = !self.message.isEmpty &&
                                 self.message != "Listening..." &&
                                 self.wordCount >= 4
            
            self.showSendButton = hasValidMessage
        }
    }

    func toggleListening() {
        if speechRecognizer.isAuthorized {
            if isListening {
                speechRecognizer.stopRecording()
            } else {
                // Clear previous state when starting new recording
                speechRecognizer.clearTranscript()
                showSendButton = false
                speechRecognizer.startRecording()
            }
        } else {
            speechRecognizer.requestPermissions()
        }
    }

    func addButtonTapped() {
        // Handle add action
    }

    func waveformButtonTapped() {
        // Handle waveform action
    }

    func sendMessage() {
        // Handle sending the message
        print("Sending message: \(message)")
        // Reset after sending
        message = ""
        showSendButton = false
        wordCount = 0
        speechRecognizer.clearTranscript()
    }
}

// MARK: - Chat Input Container
struct ChatInputContainer: View {
    @ObservedObject var viewModel: BoxViewModel

    var body: some View {
        VStack(spacing: 12) {
            MessageTextField(
                message: $viewModel.message,
                showProgress: viewModel.showProgress
            )
            ActionButtonsRow(viewModel: viewModel)
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(GradientBorder())
    }
}

// MARK: - Message Text Field
struct MessageTextField: View {
    @Binding var message: String
    let showProgress: Bool

    var body: some View {
        HStack {
            if showProgress {
                ListeningProgressView()
                    .transition(.opacity)
                Spacer()
            } else {
                TextField("Ask anything", text: $message, axis: .vertical)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.clear)
        .animation(.easeInOut(duration: 0.3), value: showProgress)
    }
}

// MARK: - Action Buttons Row
struct ActionButtonsRow: View {
    @ObservedObject var viewModel: BoxViewModel
    
    var body: some View {
        HStack {
            ActionButton(
                systemName: "plus",
                action: viewModel.addButtonTapped
            )
            
            Spacer()
            
            HStack(spacing: 16) {
                if viewModel.showSendButton {
                    SendButton(action: viewModel.sendMessage)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    PulsingMicrophoneButton(
                        isListening: viewModel.isListening,
                        action: viewModel.toggleListening
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                ActionButton(
                    systemName: "waveform",
                    action: viewModel.waveformButtonTapped
                )
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.showSendButton)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Reusable Action Button
struct ActionButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Pulsing Microphone Button
struct PulsingMicrophoneButton: View {
    let isListening: Bool
    let action: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.7
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isListening {
                    PulsingCircles(
                        pulseScale: pulseScale,
                        pulseOpacity: pulseOpacity
                    )
                } else {
                    MicrophoneIcon()
                }
            }
            .frame(width: 44, height: 44)
        }
        .onAppear {
            startPulseIfNeeded()
        }
        .onChange(of: isListening) { newValue in
            if newValue {
                startPulseAnimation()
            } else {
                stopPulseAnimation()
            }
        }
    }
    
    private func startPulseIfNeeded() {
        if isListening {
            startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.3
            pulseOpacity = 0.3
        }
    }
    
    private func stopPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            pulseScale = 1.0
            pulseOpacity = 0.7
        }
    }
}

// MARK: - Pulsing Circles Component
struct PulsingCircles: View {
    let pulseScale: CGFloat
    let pulseOpacity: Double
    
    private let circleConfigs = [
        CircleConfig(size: 44, lineWidth: 2, color: .blue, scaleMultiplier: 1.2, opacityMultiplier: 0.3),
        CircleConfig(size: 36, lineWidth: 2, color: .white, scaleMultiplier: 1.3, opacityMultiplier: 0.2),
        CircleConfig(size: 28, lineWidth: 3, color: .blue, scaleMultiplier: 1.4, opacityMultiplier: 0.4),
        CircleConfig(size: 20, lineWidth: 3, color: .white, scaleMultiplier: 1.5, opacityMultiplier: 0.3)
    ]
    
    var body: some View {
        ZStack {
            // Outer circles (stroked)
            ForEach(Array(circleConfigs.enumerated()), id: \.offset) { index, config in
                Circle()
                    .stroke(config.color.opacity(0.7), lineWidth: config.lineWidth)
                    .frame(width: config.size, height: config.size)
                    .scaleEffect(pulseScale * config.scaleMultiplier)
                    .opacity(pulseOpacity * config.opacityMultiplier)
            }
            
            // Inner filled circle
            Circle()
                .fill(Color.blue.opacity(0.7))
                .frame(width: 18, height: 18)
                .scaleEffect(pulseScale * 1.6)
                .opacity(pulseOpacity * 0.5)
            
            // Center indicator
            CenterIndicator()
        }
    }
}

// MARK: - Circle Configuration
struct CircleConfig {
    let size: CGFloat
    let lineWidth: CGFloat
    let color: Color
    let scaleMultiplier: CGFloat
    let opacityMultiplier: Double
}

// MARK: - Center Indicator
struct CenterIndicator: View {
    var body: some View {
        Rectangle()
            .fill(Color.black)
            .frame(width: 6, height: 6)
            .cornerRadius(1)
    }
}

// MARK: - Microphone Icon
struct MicrophoneIcon: View {
    var body: some View {
        Image(systemName: "mic")
            .font(.title2)
            .foregroundColor(.gray)
    }
}

// MARK: - Send Button
struct SendButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "paperplane")
                .font(.title2)
                .foregroundColor(.blue)
                .rotationEffect(.degrees(45))
                .frame(width: 44, height: 44)
                .background(Color.white)
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue,
                                    Color.cyan,
                                    Color.green
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                )
        }
    }
}

// MARK: - Listening Progress View
struct ListeningProgressView: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))

            Text("Listening...")
                .foregroundColor(.blue)
                .font(.body)
        }
    }
}

// MARK: - Gradient Border
struct GradientBorder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 32)
            .strokeBorder(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue,
                        Color.cyan,
                        Color.green
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
    }
}

@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isListening = false
    @Published var currentAmplitude: Double = 0.0
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    init() {
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    var isAuthorized: Bool {
        return authorizationStatus == .authorized &&
               AVAudioSession.sharedInstance().recordPermission == .granted
    }
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }
    
    func startRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session configuration error: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
            
            let amplitude = self.calculateAmplitude(from: buffer)
            DispatchQueue.main.async {
                self.currentAmplitude = amplitude
            }
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            print("Audio engine start error: \(error)")
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self.transcript = result.bestTranscription.formattedString
                }
                
                if error != nil || result?.isFinal == true {
                    self.stopRecording()
                }
            }
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        isListening = false
        currentAmplitude = 0.0
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Audio session deactivation error: \(error)")
        }
    }
    
    func clearTranscript() {
        transcript = ""
    }
    
    private func calculateAmplitude(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData?[0] else { return 0.0 }
        
        let frames = buffer.frameLength
        var sum: Float = 0.0
        
        for i in 0..<Int(frames) {
            let sample = channelData[i]
            sum += sample * sample
        }
        
        let rms = sqrt(sum / Float(frames))
        let amplitude = Double(rms) * 10
        
        return min(max(amplitude, 0.0), 1.0)
    }
}

// MARK: - Preview
#Preview {
    BoxView()
}
