//
//  BodyProviding.swift
//  Harmonize
//
//  Copyright (c) Perry Street Software 2024. All Rights Reserved.
//

/// A protocol that represents declarations capable of providing a body.
public protocol BodyProviding {
    /// The body of the declaration, if any.
    var body: Body? { get }
}
