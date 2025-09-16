//
//  StructuredView.swift
//  FoundationModelsLearn
//
//  Created by Rani Badri on 9/15/25.
//

import SwiftUI
import FoundationModels
import Playgrounds

struct StructuredView: View {
    @State private var prompt: String = ""
    @State private var session: LanguageModelSession?
    @State private var book: BookRecommendation?
    @State private var isGenerating = false
    
    var body: some View {
        VStack {
            HStack {
                TextField("Ask anything", text: $prompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 40)
                
                Button(action: {
                    Task {
                        do {
                            try await getBookName()
                        } catch  {
                            print("error: (\(error))")
                        }
                    }
                },label: {
                    Text("Ask")
                        .padding()
                })
                .disabled(session?.isResponding == true )
            }
        
            if isGenerating {
                ProgressView()
                    .scaleEffect(1.4)
            } else {
                if let book = book  {
                    Text(" Book: \(book.title)\n Author: \(book.author)\n Difficulty: \(book.difficulty)\n Availability: \(book.availability) \n Pros: \(book.pros)\n Rating: \(book.rating)")
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func getBookName() async throws {
        isGenerating = true
        let session = LanguageModelSession()
        let book = try await session.respond(
            to: "Recommend a book on Programming",
            generating: BookRecommendation.self
        )
        self.book = book.content
        isGenerating = false
    }
}

@Generable
struct BookRecommendation {
    @Guide(description: "The Book Title")
    let title: String
    
    @Guide(description: "Author Name")
    let author: String
    
    @Guide(description: "Brief Description")
    let description: String
    
    @Guide(description: "Book Difficulty level, /^(Beginner|Intermediate|Advanced)$/")
    let difficulty: String
    
    @Guide(description: "Availability (if specified)")
    let availability: String?
    
    @Guide(description: "2-5 Pro about the book")
    let pros: [String]
    
    @Guide(description: "Rating from 1 to 5 stars", .range(1...5))
    let rating: Int
}



@Generable
struct RecipeDetails {
    @Guide(description: "A clear recipe name, maximum 60 characters")
    let name: String
    
    @Guide(description: "Cooking time in minutes, between 5 and 240")
    let cookingTime: String
    
    @Guide(description: "Step by Step cooking instructions")
    let instructions: String
    
    @Guide(description: "The cuisine type this recipe belongs to")
    let cuisine: CuisineType
}

@Generable
enum CuisineType {
    case italian
    case mexican
    case asian
    case mediterranean
    case indian
}

#Playground {
    let session = LanguageModelSession()
    let recipe = try await session.respond(
        to: "Chapathi Dal Curry",
        generating: RecipeDetails.self
    )
}
