//
//  ContentView.swift
//  FoundationModelsLearn
//
//  Created by Rani Badri on 9/15/25.
//

import SwiftUI
import FoundationModels
import Playgrounds

struct ContentView: View {
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(height: 40)
            } else {
                EmptyView()
            }
        }
        .padding()
        .onAppear {
            supportedLanguages()
            
            Task {
                await generateMultiLanguageExamples()
            }
           
        }
    }
    
    private func supportedLanguages() {
        let model = SystemLanguageModel.default
        let supportedLanguages = model.supportedLanguages
        
        for language in supportedLanguages {
            let lang = language.languageCode?.identifier ?? "unknown"
            let region = language.region?.identifier ?? "--"
            print("-- \(lang) \(region) --")
        }
    }
    
    private func generateMultiLanguageExamples() async {
        let session = LanguageModelSession(model: SystemLanguageModel.default)
        let prompts: [LanguagePromopt] = [
            .init(name: "English", text: "What is the capital of France? Please provide a brief answer"),
            .init(name: "Spanish", text: "¿Cuál es la capital de España? Por favor, proporciona una respuesta breve.")
        ]
        
        for prompt in prompts {
            do {
                let response = try await session.respond(to: prompt.text)
                print("\(prompt.name): \(response.rawContent)")
            } catch {
                print("\(prompt.name): Error \(error.localizedDescription)")
            }
        }
    }
}

struct LanguagePromopt {
    let name: String
    let text: String
}



#Playground {
    let session = LanguageModelSession()
    
    // Your Foundation Models code can go here
    // For example:
    
    let prompt = "What's a good recipe for chocolate chip cookies?"
    
    do {
        let response = try await session.respond(to: prompt)
        print(response.content)
        
        let travelResponse = try await session.respond(to: "Generate a title for a travel blog")
        print(travelResponse.content)
    } catch {
        print("Error: \(error)")
    }
}
