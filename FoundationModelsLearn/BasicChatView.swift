//
//  BasicChatView.swift
//  FoundationModelsLearn
//
//  Created by Rani Badri on 9/15/25.
//

import Foundation
import FoundationModels
import SwiftUI

struct BasicChatView: View {
    @State private var prompt: String = ""
    @State private var isGenerating: Bool = false
    @State private var response = ""
    @State private var session: LanguageModelSession?
    
    var body: some View {
        VStack {
            TextField("Ask me anything", text: $prompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Ask") {
                Task {
                    await generateResponse()
                }
            }
            .disabled(session?.isResponding == true)
            
            if isGenerating {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(height: 40)
            } else if !response.isEmpty {
                Text(response)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .task {
            await setupSession()
            session?.prewarm() // call when user interaction is likely within seconds.
        }
    }
    
    func setupSession() async {
        guard SystemLanguageModel.default.availability == .available else {
            return
        }
        let instructions =
        """
            You are a helpful writing assistant that helps users improve their content.
            Focus on clarity, tone, and structure.
            Provide specific suggestions for improvement.
            Keep responses concise and actionable
        """
        
//        """
//        You are a customer service representative for a fitness app.
//        Be helpful, encouraging, and focus on solving user problems.
//        Keep responses professional but friendly.
//        """
//        """
//            You suggest related topics. Examples:
//            User: "Making homemade bread"
//        
//            Assistant: 1. Sourdough starter basics 2. Bread flour types 3. Kneading techniques
//            User: "iOS development"
//        
//            Assistant: 1. SwiftUI fundamentals 2. App Store guidelines 3. Xcode debugging
//            Keep suggestions concise (3-7 words) and naturally related.
//        """
        
        session = LanguageModelSession(
            instructions: Instructions(instructions),
        )
    }
    
    private func generateResponse() async {
        guard let session = session else { return }
        
        isGenerating = true
        
        do {
            let topicOptions = GenerationOptions(temperature: 0.7, maximumResponseTokens: 400)
            let topKOptions = GenerationOptions(sampling: .random(top: 50, seed: nil), temperature: 0.7)
            
            let result = try await session.respond(to: prompt, options: topKOptions)
            response = result.content
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            response = "This conversation is too long. Please start a new session"
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            response = "I cannot respond to that request"
        } catch LanguageModelSession.GenerationError.assetsUnavailable{
            response = "Foundation Model is temporarily unavailable. Please try again"
        } catch LanguageModelSession.GenerationError.concurrentRequests {
            response = "Please wait for the current request to finish before starting a new one."
        } catch LanguageModelSession.GenerationError.rateLimited {
            response = "Too many requests. Please try again later"
        } catch LanguageModelSession.GenerationError.unsupportedLanguageOrLocale {
            response = "This language is not supported. Plese try English or another supported language"
        } catch LanguageModelSession.GenerationError.decodingFailure {
            response = "Unable to process the response. Please try again"
        } catch LanguageModelSession.GenerationError.unsupportedGuide {
            response = "Invalid generation parametere, Please check your request format"
        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            do {
                let explanationContent = try await Task.detached {
                    let explanation = try await refusal.explanation
                    return explanation.content
                }.value
                response = "The model declined to respond: \(explanationContent)"
            } catch {
                response = "The model declined to this request"
            }
        }
        catch {
            response = "Error: \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
}
    

