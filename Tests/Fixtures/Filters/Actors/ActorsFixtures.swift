//
//  ActorsFixtures.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2026. All Rights Reserved.
//

import Foundation

protocol Service: Sendable {}

actor AccountService: Service {
    private var balance: Int = 0

    init(balance: Int) {
        self.balance = balance
    }

    func deposit(_ amount: Int) {
        balance += amount
    }
}

actor SessionCache {
    private var entries: [String: String] = [:]

    func store(_ value: String, for key: String) {
        entries[key] = value
    }

    actor Metrics {
        func record() {}
    }
}

distributed actor RemoteService {
    distributed func fetch() {}
}

final class Container {
    actor Inner {
        func work() {}
    }
}
