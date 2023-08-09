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
                            pswCount = await askPwned(hash: getSha1(for: psw))
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
    
    func askPwned(hash: String) async -> Int {
        let prefix = String(hash.prefix(5))
        let sufix = String(hash.dropFirst(5))
        
        if let url = URL(string: "https://api.pwnedpasswords.com/range/\(prefix)") {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let theResponse = String(data: data, encoding: .utf8)!.lowercased()
                if let range = theResponse.range(of: "(\(sufix):\\d+)", options: .regularExpression) {
                    let result = String(theResponse[range])
                    let count = String(result.split(separator: ":").last ?? "0")
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


/*
 
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
                             await checkPsw()
                         }
                     }
                 }
             Text(msg).bold().foregroundStyle(pswCount > 0 ? .red : .green)
         }
         .padding()
     }
     
     func checkPsw() async {
         let hash = getSha1(for: psw)
         let prefix = String(hash.prefix(5))
         let sufix = String(hash.dropFirst(5))
         
         let results = await askPwned(prefix)
         
         if let value = results[sufix] {
             pswCount = value
         } else {
             pswCount = 0
         }
         
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
     
     func getSha1(for str: String) -> String {
         Insecure.SHA1.hash(data: str.data(using: .utf8)!)
             .map{ String(format: "%02x", $0) }.joined()
     }

     func askPwned(_ hashPrefix: String) async -> [String:Int] {
         if let url = URL(string: "https://api.pwnedpasswords.com/range/\(hashPrefix)") {
             do {
                 let (data, _) = try await URLSession.shared.data(from: url)
                 let theResponse = String(data: data, encoding: .utf8)!
                 let lines: [String] = theResponse.components(separatedBy: "\n")

                 var results: [String:Int] = [:]
                 for line in lines {
                     let compo = line.components(separatedBy: ":")
                     if let first = compo.first?.trimmingCharacters(in: .whitespacesAndNewlines),
                        let last = compo.last?.trimmingCharacters(in: .whitespacesAndNewlines),
                        let val = Int(last) {
                         results[first.lowercased()] = val
                     }
                 }
                 return results
             } catch {
                 print(error)
             }
         }
         return [:]
     }
     
 }

 */
