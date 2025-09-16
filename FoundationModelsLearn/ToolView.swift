//
//  ToolView.swift
//  FoundationModelsLearn
//
//  Created by Rani Badri on 9/15/25.
//

import Foundation
import FoundationModels
import Playgrounds
import SwiftUI

struct ToolView: View {
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
                    do {
                        response = try await calculateTip() ?? ""
                    } catch {
                        response = "Error:\(error.localizedDescription)"
                    }
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
        .padding(.horizontal)
    }
    
    private func calculateTip() async throws -> String? {
        let instructions = """
            You are a helpful tip calculator assistant. When asked to calculate tips, 
            Use the TipCalculatorTool for performing tip calculations.
        """
        session = LanguageModelSession(tools: [TipCalculatorTool()], instructions: instructions)
        let response = try await session?.respond(to: prompt)
        return response?.content
    }
}


struct TipCalculatorTool: Tool {
    let name = "Calculate Tip"
    let description = "Calculates tip amount and total bill based on bill amount and tip percentage, with optional bill"
    
    @Generable
    struct Arguments {
        @Guide(description: "The bill amount before tip in dollars")
        let billAmount: Double
        
        @Guide(description: "The tip percentage as a whole number( e.g., 18 for 18%)", .range(0...30))
        let tipPercentage: Int
        
        @Guide(description: "Number of people to split the bill between")
        let numberOfPeople: Int?
    }
    
    func call(arguments: Arguments) async throws -> String {
        let tipAmount = arguments.billAmount * Double(arguments.tipPercentage) / 100.0
        let totalBill = arguments.billAmount + tipAmount
        
        let perPersonAmount = arguments.numberOfPeople.map { totalBill / Double($0) }
        
        let result = TipCalculation(
            billAmount: arguments.billAmount,
            tipPercentage: arguments.tipPercentage,
            tipAmount: tipAmount,
            totalBill: totalBill,
            perPersonAmount: perPersonAmount
        )
        
        return result.summary
    }
}

@Generable
struct TipCalculation {
    let billAmount: Double
    let tipPercentage: Int
    let tipAmount: Double
    let totalBill: Double
    let perPersonAmount: Double?
    
    var summary: String {
        var result = "Bill: $\(String(format: "%.2f", billAmount))\n"
        
        result += "Tip (\(tipPercentage)%): $\(String(format: "%.2f", tipAmount))\n"
        
        result += "Total: $\(String(format: "%.2f", totalBill))"
        
        if let perPersonAmount = perPersonAmount {
            result += "\nPer person: $\(String(format: "%.2f", perPersonAmount))"
        }
        
        return result
    }
}

#Playground {
    let instructions = "Calculate the tip based on the amount provided"
    
    let prompt = "Enter the total bill amount: $500"
    
    let session = LanguageModelSession(tools: [TipCalculatorTool()], instructions: instructions)
    
    let response = try await session.respond(to: prompt)
    print(response.content)
}
