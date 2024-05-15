//
//  ContentView.swift
//  DATABASE
//
//  Created by 张一麟 on 2024/5/15.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.white]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Image(systemName: "server.rack")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                        .padding(.top, 50)
                    
                    Text("Welcome to SQL Command Executor")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text("Easily execute SQL commands and view the results.")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    NavigationLink(destination: CommandInputView()) {
                        Text("Go to Command Input")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal)
                    
                    NavigationLink(destination: ResultsView()) {
                        Text("Go to Results")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("SQL Command Executor", displayMode: .inline)
        }
    }
}

struct CommandInputView: View {
    @EnvironmentObject var viewModel: CommandViewModel
    @State private var navigateToResults = false

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                NavigationLink(destination: ResultsView(), isActive: $navigateToResults) { EmptyView() }
                
                Text("Enter your SQL commands:")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                // 多行输入框
                TextEditor(text: $viewModel.command)
                    .frame(height: 150)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                
                // 执行按钮
                Button(action: {
                    viewModel.executeCommands {
                        withAnimation {
                            navigateToResults = true
                        }
                    }
                }) {
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
                if viewModel.isLoading {
                    ProgressView("Executing...")
                        .padding()
                }
                
                Spacer()
            }
            .navigationBarTitle("Command Input", displayMode: .inline)
            .padding()
        }
    }
}

struct ResultsView: View {
    @EnvironmentObject var viewModel: CommandViewModel

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            List {
                ForEach(viewModel.queries.indices, id: \.self) { queryIndex in
                    NavigationLink(destination: QueryResultView(queryIndex: queryIndex)) {
                        Text(viewModel.queries[queryIndex].command)
                            .font(.headline)
                            .padding()
                    }
                }
            }
            .navigationBarTitle("Results", displayMode: .inline)
        }
    }
}

struct QueryResultView: View {
    @EnvironmentObject var viewModel: CommandViewModel
    let queryIndex: Int

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Command: \(viewModel.queries[queryIndex].command)")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    if viewModel.parsedResults[queryIndex].isTable {
                        TableView(tables: viewModel.parsedResults[queryIndex].data)
                    } else {
                        NonTableView(nonTableData: viewModel.parsedResults[queryIndex].data.flatMap { $0 })
                    }
                }
                .padding(.horizontal)
            }
            .navigationBarTitle("Query Result", displayMode: .inline)
        }
    }
}

struct TableView: View {
    let tables: [[String]]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(tables.indices, id: \.self) { rowIndex in
                HStack {
                    ForEach(tables[rowIndex].indices, id: \.self) { columnIndex in
                        Text(tables[rowIndex][columnIndex])
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(rowIndex == 0 ? Color.blue.opacity(0.7) : Color.white)
                            .foregroundColor(rowIndex == 0 ? .white : .black)
                            .border(Color.gray, width: 0.5)
                    }
                }
            }
        }
        .padding(.bottom, 20)
    }
}

struct NonTableView: View {
    let nonTableData: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(nonTableData, id: \.self) { item in
                Text(item)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(5)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    .padding(.bottom, 2)
            }
        }
    }
}

class CommandViewModel: ObservableObject {
    @Published var command: String = ""
    @Published var queries: [(command: String, result: String)] = []  // 存储查询及其结果
    @Published var parsedResults: [ParsedResult] = []  // 存储解析后的多个表格和非表格数据
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func executeCommands(completion: @escaping () -> Void) {
        let commands = command.split(separator: "\n").map { String($0) }
        queries = []
        parsedResults = []
        
        for cmd in commands {
            queries.append((command: cmd, result: ""))
            parsedResults.append(ParsedResult(isTable: false, data: []))
        }

        let group = DispatchGroup()
        
        for (index, cmd) in commands.enumerated() {
            group.enter()
            executeCommand(cmd, index: index) {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    private func executeCommand(_ command: String, index: Int, completion: @escaping () -> Void) {
        guard let url = URL(string: "http://localhost:3000/execute") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["command": command]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer {
                completion()
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
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
            
            if let responseString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    // 更新查询的结果
                    self.queries[index].result = responseString
                    
                    let results = responseString.components(separatedBy: "\n\n")
                    var parsedResult: ParsedResult
                    
                    if results.contains(where: { $0.contains("|") }) {
                        parsedResult = ParsedResult(isTable: true, data: results.flatMap { $0.contains("|") ? self.parseResponse($0) : [[]] })
                    } else {
                        parsedResult = ParsedResult(isTable: false, data: results.map { [$0] })
                    }
                    
                    self.parsedResults[index] = parsedResult
                    self.errorMessage = nil
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Unable to decode response"
                }
            }
        }.resume()
    }
    
    private func parseResponse(_ response: String) -> [[String]] {
        var result: [[String]] = []
        let rows = response.split(separator: "\n")
        for row in rows {
            let trimmedRow = row.trimmingCharacters(in: .whitespaces)
            let columns = trimmedRow.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            result.append(columns)
        }
        return result
    }
}

struct ParsedResult {
    var isTable: Bool
    var data: [[String]]
}


