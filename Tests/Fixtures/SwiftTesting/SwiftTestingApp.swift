//
//  SwiftTestingApp.swift
//  Harmonize
//
//  Created by Lucas Cavalcante on 5/15/25.
//

import Combine

class SwiftTestingApp {
    let viewModel = SwiftTestingAppViewModel()
}

private class SwiftTestingAppViewModel : ObservableObject {
    @Published var isPresented: Bool = false
    
    func onAppear() {
        isPresented = true
    }
    
    func onDisappear() {
        isPresented = false
    }
}
