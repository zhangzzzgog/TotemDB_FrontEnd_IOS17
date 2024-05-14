//
//  ContentView.swift
//  DATABASE
//
//  Created by 张一麟 on 2024/5/14.
//

import SwiftUI

struct ContentView: View {
    @State private var command: String = ""
    @State private var result: String = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                // 背景颜色
                Color(.systemGray6)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // 标题
                    Text("SQL Command Executor")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // 输入框
                    TextField("Enter SQL Command", text: $command)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                    
                    // 执行按钮
                    Button(action: executeCommand) {
                        Text("Execute")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal)
                    
                    // 活动指示器
                    if isLoading {
                        ProgressView("Executing...")
                            .padding()
                    }
                    
                    // 结果显示
                    Text("Result:")
                        .font(.headline)
                        .padding(.top)
                    
                    ScrollView {
                        Text(result)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: 300) // 限制结果显示区的最大高度
                    
                    // 错误消息
                    if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .navigationBarTitle("Database Interface", displayMode: .inline)
                .padding()
            }
        }
    }
    
    func executeCommand() {
        guard let url = URL(string: "http://localhost:3000/execute") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["command": command]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        isLoading = true
        errorMessage = nil
        result = ""
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
            }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                }
                return
            }
            
            if let result = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.result = result
                    self.errorMessage = nil
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Unable to decode response"
                }
            }
        }.resume()
    }
}
