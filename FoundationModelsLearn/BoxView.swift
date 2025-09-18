//
//  BoxView.swift
//  FoundationModelsLearn
//
//  Created by Rani Badri on 9/17/25.
//

import Foundation
import SwiftUI
import Combine

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
    
    func toggleListening() {
        isListening.toggle()
        if isListening {
            message = "Listening..."
        } else {
            message = ""
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

// MARK: - Preview
#Preview {
    BoxView()
}
