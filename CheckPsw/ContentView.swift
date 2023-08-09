//
//  ContentView.swift
//  CheckSec
//
//

import SwiftUI
import Foundation
import CryptoKit



struct ContentView: View {
    @State var psw = ""
    @State var pswCount = 0
    @State var msg = ""

    var body: some View {
        VStack (spacing: 30) {
            TextField("enter password", text: $psw).border(.red)
                .onSubmit {
                    pswCount = 0
                    msg = ""
                    if !psw.isEmpty {
                        Task {
                            pswCount = await askPwned(psw)
                            if pswCount > 0 {
                                msg = """
                    Oh no — pwned!
                                
                    This password has been seen \(pswCount) times before
                    This password has previously appeared in a data breach and should never be used. If you've ever used it anywhere before, change it!
                    """
                            } else {
                                msg = """
                    Good news — no pwnage found!
                    
                    This password wasn't found in any of the Pwned Passwords loaded into Have I Been Pwned. That doesn't necessarily mean it's a good password, merely that it's not indexed on this site. If you're not already using a password manager, go and download 1Password and change all your passwords to be strong and unique.
                    """
                            }
                        }
                    }
                }
            Text(msg).bold().foregroundStyle(pswCount > 0 ? .red : .green)
        }
        .padding()
    }
    
    func getSha1(for str: String) -> String {
        Insecure.SHA1.hash(data: str.data(using: .utf8)!).map{ String(format: "%02x", $0) }.joined()
    }
    
    func askPwned(_ psw: String) async -> Int {
        let hash = getSha1(for: psw)
        let prefix = hash.prefix(5)
        let sufix = hash.dropFirst(5)
        
        if let url = URL(string: "https://api.pwnedpasswords.com/range/\(prefix)") {
            do {
                var request = URLRequest(url: url)
                request.addValue("true", forHTTPHeaderField: "Add-Padding")
                let (data, _) = try await URLSession.shared.data(for: request)
                let theResponse = String(data: data, encoding: .utf8)!.lowercased()
                if let range = theResponse.range(of: "(\(sufix):\\d+)", options: .regularExpression) {
                    let count = theResponse[range].split(separator: ":").last ?? "0"
                    return if Int(count) != nil { Int(count)! } else { 0 }
                }
            } catch {
                print(error)
            }
        }
        return 0
    }
    
}

#Preview {
    ContentView()
}
