//
//  ContentView.swift
//  PlantitApp
//
//  Created by Solly Boukman on 1/29/22.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import UIKit
import PDFKit



struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State var loggedIn = false
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    
    @State var  shouldShowImagePicker = false
    
    
     
    var body: some View {
        NavigationView {
            ScrollView {

                VStack(spacing: 16) {
                    Picker(selection: $isLoginMode, label: Text("Picker here")) {
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }.pickerStyle(SegmentedPickerStyle())

                    if !isLoginMode {
                        Button {
                            shouldShowImagePicker
                                .toggle()
                        } label: {
                            
                            VStack{
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 128, height: 128)
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                        .foregroundColor(Color(.label))
                                }
                                    
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64)
                                        .stroke(Color(.label), lineWidth: 3)
                            )
                            
                            
                            
                        }
                    }

                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                    }
                    .padding(12)
                    .background(Color.white)

                    Button {
                        handleAction()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Log In" : "Create Account")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }.background(Color.blue)

                    }
                    
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                    if loggedIn {
                        NavigationLink {
                            Guides()
                        } label: {
                            Text("Go to home screen")
                        }
                    }
                    
                }
                .padding()
                
                

            }
            .navigationTitle(isLoginMode ? "Log In" : "Create Account")
            .background(Color(.init(white: 0, alpha: 0.05))
                            .ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
    }
    
    @State var image: UIImage?

    private func handleAction() {
        if isLoginMode {
            //print("Should log into Firebase with existing credentials")
            loginUser()
        } else {
            createNewAccount()
           // print("Register a new account inside of Firebase Auth and then store image in Storage somehow....")
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            res, err in
            if let err = err {
                print("Failed to login user", err)
                self.loginStatusMessage = "Failed to login user: \(err)"
                return
            }
            print("Successfully Logged In as User: \(res?.user.uid ?? "")")
            self.loginStatusMessage = "Successfully Logged In as User: \(res?.user.uid ?? "")"
            
            self.didCompleteLoginProcess()
            loggedIn = true
        }
    }
    
    @State var loginStatusMessage = ""
    
    private func createNewAccount() {
        if self.image == nil {
            self.loginStatusMessage = "You must select an avatar image"
            return
        }
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) {
            result, err in
            if let err = err {
                print("Failed to create user", err)
                self.loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            print("Successfully Created User: \(result?.user.uid ?? "")")
            self.loginStatusMessage = "Successfully Created User: \(result?.user.uid ?? "")"
            
            persistImagetoStorage()
            
        }
        
    }
    
    private func persistImagetoStorage() {
   //     let filename = UUID().uuidString
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
            else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "Failed to push image to Storage: \(err)"
                return
            }
            
            ref.downloadURL { url, err in
                if let err = err {
                    self.loginStatusMessage = "Failed to retrieve downloadURL: \(err)"
                    return
                }
                
                self.loginStatusMessage = "Successfully stored image with url: \(url?.absoluteString ?? "")"
                
                guard let url = url else {
                    return
                }
                
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            return }
        let userData = ["email": self.email, "uuid": uid, "profileImageUrl": imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    print(err)
                    self.loginStatusMessage = "\(err)"
                    return
                }
                
                print("Success")
                self.didCompleteLoginProcess()
                self.loggedIn = true
            }
    }
}





struct Datum: Identifiable {
    
    var id: String { name }
    let name: String
    let States: [String]
    init(name: String, states: [String]) {
        self.name = name
        self.States = states
        
    }
   
}

struct PDFKitRepresentedView: UIViewRepresentable {
    let url: URL

    init(_ url: URL) {
        self.url = url
    }

    func makeUIView(context: UIViewRepresentableContext<PDFKitRepresentedView>) -> PDFKitRepresentedView.UIViewType {
        // Create a `PDFView` and set its `PDFDocument`.
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: self.url)
        return pdfView
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PDFKitRepresentedView>) {
        // Update the view.
    }
}


struct PDFKitView: View {
    var url: URL

    var body: some View {
        PDFKitRepresentedView(url)
    }
}


struct Guides: View {

    @State var showStates = false
    


    var body: some View {
        NavigationView {
            VStack {
                customGuideNavBar
                GuideStartView()
            }
            .navigationBarHidden(true)
        }
    }

private var customGuideNavBar: some View {
    
    HStack(spacing: 16) {
        

        
        Text("Plants")
            .font(.system(size: 24, weight: .bold))
            
        
        
    }

}
    
}

struct GuideStartView: View {
    
    @State var dataa = [Datum]()
    //makeDatum()
    
    
    var plants = ["squash": ["NJ", "NY"],
                         "strawberries": ["NH","NY", "PA", "WV"],
                         "sweetcorn": ["DE", "MD", "NY", "WV"],
                         "sweetpotatoes": ["NJ"],
                         "tobacco": ["WV"],
                         "tomatoes": ["MD", "NJ", "NY", "PA", "WV"],
                         "watermelons": ["DE", "MD"],
                         "Wheat": ["DE"],
                         "WineGrape": ["PA"],
                         "alfalfa": ["NJ", "VT", "WV"],
                         "apples": ["NJ", "NY", "WV"],
                         "arugula": ["NJ"],
                         "asparagus": ["NJ"],
                         "basil": ["NJ"],
                         "beans-dry": ["NY"],
                         "beans-lima": ["DE"],
                         "beans-snap": ["NY"],
                         "beets": ["NY"],
                         "blackberries": ["NY"],
                         "blueberries": ["ME", "NH", "NY", "RI"],
                         "cabbage": ["NY"],
                         "carrots": ["NJ", "NY"]]



    func makeDatum() {
        for (key, val) in plants {
            let d = Datum(name: key, states: val)
            dataa.append(d)
        }
        return
    }
    
    private var cusNavBar: some View {
        
        HStack(spacing: 16) {
            

            
            Text("Plants")
                .font(.system(size: 24, weight: .bold))
                
            
            
        }

    }
    
    @State var documentURL = ""
    


    
/*
                         "cherries": ["NY", "PA"],
                         "Corn": ["NJ", "VT"],
                         "cranberries": ["NJ"],
                         "cucumbers": ["MD"],
                         "cucumbers": ["MD", "NY"],
                         "eggplants": ["NJ"],
                         "gooseberries": ["NY"],
                         "grape": ["PA"],
                         "greenpeas": ["DE"],
                         "greenpeppers": ["DE"],
                         "kale": ["NJ"],
                         "lettuce": ["NY"],
                         "mushrooms": ["PA"],
                         "muskmelon": ["MD"],
                         "nectarines": ["PA"],
                         "onions": ["NY"],
                         "peaches": ["DE", "NJ", "PA", "WV", "NY"],
                         "peas": ["MD", "NY"],
                         "peppers": ["NJ", "NY"],
                         "potatoes": ["MD", "NY", "PA", "WV"],
                         "pumpkins": ["NJ", "NY", "PA"],
                         "raspberries": ["NH", "NY"],
                         "snapbeans": ["DE", "PA"],
                         "sod": ["RI"],
                         "soybean": ["DE"],
                         "spinach": ["DE", "NJ"],
                         "squash": ["DE", "MD"]]
*/
// var component = Array(plants.keys)

    
    
    var body: some View {
        
        
        
        ScrollView {
            let comp = Array(plants.keys) as [String]
            let vals = Array(plants.values) as [[String]]
            let combined = Array(zip(comp, vals))
            
            
            ForEach(comp.indices) { plant in
                VStack {
                    NavigationLink {
                        
                        Spacer()
                        ScrollView {
                            Text("States")
                                .font(.system(size: 24, weight: .bold))
                            
                            ForEach(combined[plant].1.indices) {ind in
                                VStack {
                                    
                                    NavigationLink {
                                        
                                        PDFKitView(url: Bundle.main.url(forResource: combined[plant].0 + "_" + combined[plant].1[ind], withExtension: "pdf")!)

                                        // the url can be a web url or a file url
                                        
                                                
                                        
                                        Text("here")
                                        
                                    } label: {
                                    
                                    ScrollView {
                                        Text(combined[plant].1[ind])
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    .navigationBarHidden(false)
                                    }
                                    
                                    
                                }
                                Divider()
                            }
                            
                        }.navigationTitle("Cultivation Guides")
                            
                            
                        
                        
                    
                    
                    } label: {
                        
                        Spacer()
                        Text(combined[plant].0)
                        .font(.system(size: 16, weight: .bold))
                                
                        Spacer()
                            
                        }
                        Divider()
                            .padding(.vertical, 8)
                    
                }.padding(.horizontal)
                
            }
        }.padding(.bottom, 50)
            .navigationTitle("Plants")
    }


}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {
            Guides()
        })
            .preferredColorScheme(.light)
    }
}
