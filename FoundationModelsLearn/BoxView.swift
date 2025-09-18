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

    private let speechRecognizer = SpeechRecognizer()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Request permissions on initialization
        speechRecognizer.requestPermissions()

        // Bind speech recognizer's isListening to our isListening
        speechRecognizer.$isListening
            .assign(to: \.isListening, on: self)
            .store(in: &cancellables)

        // Update message with transcript
        speechRecognizer.$transcript
            .sink { [weak self] transcript in
                if !transcript.isEmpty {
                    self?.message = transcript
                } else if self?.isListening == true {
                    self?.message = "Listening..."
                } else {
                    self?.message = ""
                }
            }
            .store(in: &cancellables)
    }

    func toggleListening() {
        if speechRecognizer.isAuthorized {
            if isListening {
                speechRecognizer.stopRecording()
            } else {
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
}

// MARK: - Chat Input Container
struct ChatInputContainer: View {
    @ObservedObject var viewModel: BoxViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            MessageTextField(message: $viewModel.message)
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
    
    var body: some View {
        TextField("Ask about BusinessName", text: $message)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.clear)
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
                PulsingMicrophoneButton(
                    isListening: viewModel.isListening,
                    action: viewModel.toggleListening
                )
                
                ActionButton(
                    systemName: "waveform",
                    action: viewModel.waveformButtonTapped
                )
            }
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
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) // Change this identifier for different languages
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
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
            }
        }
        
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }
    
    func startRecording() {
        // STEP 1: Clean up any previous recording session
        // Cancel any existing recognition task to avoid conflicts
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // STEP 2: Configure the audio session for recording
        // This tells iOS how we want to use the audio system
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // .record: We want to record audio
            // .measurement: High-quality recording mode for speech recognition
            // .duckOthers: Lower other app volumes while recording
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            
            // Activate the audio session (start using microphone)
            // .notifyOthersOnDeactivation: Tell other apps when we're done
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session configuration error: \(error)")
            return
        }
        
        // STEP 3: Create a speech recognition request
        // This object will receive audio data and convert it to text
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }
        
        // Enable live results - we get text updates as the user speaks
        // (not just at the end of recording)
        recognitionRequest.shouldReportPartialResults = true
        
        // STEP 4: Set up the audio engine to capture microphone input
        let inputNode = audioEngine.inputNode  // Device's microphone
        let recordingFormat = inputNode.outputFormat(forBus: 0)  // Audio format from mic
        
        // Install a "tap" on the audio input - this captures audio data
        // bufferSize: 1024 samples at a time (good balance of latency vs processing)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            // Every time we get audio data, send it to speech recognition
            recognitionRequest.append(buffer)
            
            // Calculate amplitude for wave animation
            let amplitude = self.calculateAmplitude(from: buffer)
            DispatchQueue.main.async {
                self.currentAmplitude = amplitude
            }
        }
        
        // STEP 5: Start the audio engine
        audioEngine.prepare()  // Get ready to record
        
        do {
            try audioEngine.start()  // Begin capturing microphone audio
            isListening = true       // Update UI state
        } catch {
            print("Audio engine start error: \(error)")
            return
        }
        
        // STEP 6: Start the speech recognition task
        // This processes the audio data and converts it to text
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            // This closure runs every time we get speech recognition results
            DispatchQueue.main.async {
                if let result = result {
                    // Update the transcript with the latest recognized text
                    // bestTranscription gives us the most confident result
                    self.transcript = result.bestTranscription.formattedString
                }
                
                // Stop recording if there's an error or speech recognition is complete
                if error != nil || result?.isFinal == true {
                    self.stopRecording()
                }
            }
        }
    }
    
    func stopRecording() {
        // STEP 1: Stop the audio engine
        // Stop capturing audio from the microphone
        audioEngine.stop()
        
        // Remove the "tap" we installed on the microphone input
        // This stops the flow of audio data to speech recognition
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // STEP 2: Clean up speech recognition
        // Tell the recognition request that no more audio is coming
        recognitionRequest?.endAudio()
        
        // Cancel the recognition task to stop processing
        recognitionTask?.cancel()
        
        // STEP 3: Clear our references to avoid memory leaks
        recognitionRequest = nil
        recognitionTask = nil
        
        // STEP 4: Update UI state
        isListening = false  // Hide "recording" indicator
        currentAmplitude = 0.0  // Reset amplitude for wave animation
        
        // STEP 5: Deactivate the audio session
        // This tells iOS we're done using the microphone
        // and allows other apps to use audio again
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Audio session deactivation error: \(error)")
        }
    }
    
    func clearTranscript() {
        transcript = ""
    }
    
    // Calculate amplitude from audio buffer for wave animation
    private func calculateAmplitude(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData?[0] else { return 0.0 }
        
        let frames = buffer.frameLength
        var sum: Float = 0.0
        
        // Calculate RMS (Root Mean Square) for amplitude
        for i in 0..<Int(frames) {
            let sample = channelData[i]
            sum += sample * sample
        }
        
        let rms = sqrt(sum / Float(frames))
        let amplitude = Double(rms) * 10 // Scale for better visualization
        
        return min(max(amplitude, 0.0), 1.0) // Clamp between 0 and 1
    }
}

// MARK: - Preview
#Preview {
    BoxView()
}
