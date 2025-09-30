//
//  FunctionCallsSample.swift
//
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

class FunctionCallsSample {
    class TestFactory {
        var value: Int?
        
        func withValue(_ value: Int) -> TestFactory {
            self.value = value
            return self
        }
    }
    
    class Something {
        func onTap() {}
    }
    
    func spec() {
        beforeEach {
            setUp()
            TestFactory().withValue(1)
        }

        given("something") {
            var foo: Int = 0

            then("there is something that will happen") {
                // ...
            }

            when("it happens") {
                beforeEach {
                    setUp()
                    something.onTap()
                }
                
                then("I see it finally happens") {
                    // ...
                }
            }
        }
    }
    
    private func beforeEach(_ body: () -> Void) {
        // ...
    }
    
    private func given(_ that: String, body: () -> Void) {
        // ...
    }
    
    private func when(_ that: String, body: () -> Void) {
        // ...
    }
    
    private func then(_ that: String, body: () -> Void) {
        // ...
    }
    
    private func setUp() {}
}
