//
//  Attribute.swift
//  Harmonize
//
//  Copyright 2024 Perry Street Software Inc.

//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at

//  http://www.apache.org/licenses/LICENSE-2.0

//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import SwiftSyntax

/// A struct that represents an attribute in a Swift declaration.
public struct Attribute: DeclarationDecoration, SyntaxNodeProviding {
    /// The syntax node representing the attribute in the abstract syntax tree (AST).
    public let node: AttributeSyntax
    
    /// The name of the attribute as a `String`.
    ///
    /// This property extracts and returns the name of the attribute. For example, in `@Published`,
    /// the `name` is `"Published"`.
    public var name: String {
        node.attributeName.trimmedDescription
    }
    
    /// The annotation associated with the attribute, if any.
    ///
    /// This property checks if the attribute name corresponds to a known `Annotation` and returns it if found.
    /// If there is no matching annotation, this property returns `nil`.
    public var annotation: Annotation? {
        return Annotation.from(name: name)
    }
    
    /// The arguments provided to the attribute, if any.
    ///
    /// This property extracts the arguments from the attribute syntax node. For example, in the attribute
    /// `@available(iOS 10.0, *)`, the `arguments` would represent `iOS 10.0, *`. If there are no arguments,
    /// this property returns an empty array.
    public var arguments: [Argument] {
        Argument.arguments(from: node.arguments)
    }
    
    public var description: String {
        node.trimmedDescription
    }
    
    internal init(node: AttributeSyntax) {
        self.node = node
    }
    
    internal init?(node: AttributeSyntax?) {
        guard let node = node else { return nil }
        self.node = node
    }
}

// MARK: - Annotation, Argument
public extension Attribute {
    enum Annotation: String, Equatable {
        // declaration-site attributes
        case attached = "attached"
        case available = "available"
        case backDeployed = "backDeployed"
        case discardableResult = "discardableResult"
        case dynamicCallable = "dynamicCallable"
        case dynamicMemberLookup = "dynamicMemberLookup"
        case freestanding = "freestanding"
        case frozen = "frozen"
        case gkInspectable = "GKInspectable"
        case inlinable = "inlinable"
        case main = "main"
        case nonobjc = "nonobjc"
        case nsApplicationMain = "NSApplicationMain"
        case nsCopying = "NSCopying"
        case nsManaged = "NSManaged"
        case objc = "objc"
        case objcMembers = "objcMembers"
        case preconcurrency = "preconcurrency"
        case propertyWrapper = "propertyWrapper"
        case resultBuilder = "resultBuilder"
        case requiresStoredPropertyInits = "requires_stored_property_inits"
        case testable = "testable"
        case uiApplicationMain = "UIApplicationMain"
        case unchecked = "unchecked"
        case usableFromInline = "usableFromInline"
        case warnUnqualifiedAccess = "warn_unqualified_access"
        
        // type-site attributes
        case autoclosure = "autoclosure"
        case convention = "convention"
        case escaping = "escaping"
        case sendable = "Sendable"
        
        // property wrappers from Combine/SwiftUI.
        case appStorage = "AppStorage"
        case binding = "Binding"
        case environment = "Environment"
        case environmentObject = "EnvironmentObject"
        case fetchRequest = "FetchRequest"
        case focusedBinding = "FocusedBinding"
        case focusState = "FocusState"
        case gestureState = "GestureState"
        case observedObject = "ObservedObject"
        case observable = "Observable"
        case sceneStorage = "SceneStorage"
        case state = "State"
        case stateObject = "StateObject"
        case published = "Published"
        
        public static func from(name: String) -> Self? {
            let unsupportedAttributes = ["inline", "rethrows"]
            
            if name.hasPrefix("_") || unsupportedAttributes.contains(name) {
                return nil
            }
            
            return Self(rawValue: name)
        }
    }
    
    struct Argument: Equatable, Hashable {
        /// The argument label.
        public let label: String?

        /// The argument value.
        public let value: String

        internal static func arguments(from args: AttributeSyntax.Arguments?) -> [Argument] {
            guard let args else { return [] }
            
            return switch args {
            case .argumentList(let values):
                values.map {
                    let expressionAsString = if let literalExpression = $0.expression.as(StringLiteralExprSyntax.self) {
                        literalExpression.segments.trimmedDescription
                    } else {
                        $0.expression.trimmedDescription
                    }
                    
                    return Argument(label: $0.label?.text, value: expressionAsString)
                }
            case .token(let value):
                [Argument(label: nil, value: value.text)]
            case .string(let value):
                [Argument(label: nil, value: value.trimmedDescription)]
            case .availability(let values):
                values.compactMap { availability(from: $0.argument) }
            case .specializeArguments(let values):
                values.map { Argument(label: nil, value: $0.trimmedDescription) }
            case .objCName(let values):
                values.map { Argument(label: nil, value: $0.trimmedDescription) }
            case .implementsArguments(let value):
                [Argument(label: nil, value: value.type.trimmedDescription)]
            case .differentiableArguments(let value):
                [value.arguments?.arguments.trimmedDescription].compactMap {
                    $0
                }.map { Argument(label: nil, value: $0) }
            case .derivativeRegistrationArguments(let value):
                [Argument(label: nil, value: value.trimmedDescription)]
            case .backDeployedArguments(let value):
                [Argument(label: value.beforeLabel.text, value: value.platforms.map { $0.platformVersion.description}.joined(separator: ","))]
            case .conventionArguments(let value):
                [Argument(label: nil, value: value.conventionLabel.text)]
            case .conventionWitnessMethodArguments(let value):
                [Argument(label: nil, value: value.protocolName.text)]
            case .opaqueReturnTypeOfAttributeArguments(let value):
                [Argument(label: nil, value: value.mangledName.trimmedDescription)]
            case .exposeAttributeArguments(let value):
                [Argument(label: nil, value: value.trimmedDescription)]
            case .originallyDefinedInArguments(let value):
                [Argument(label: nil, value: value.trimmedDescription)]
            case .underscorePrivateAttributeArguments(let value):
                [Argument(label: nil, value: value.sourceFileLabel.text)]
            case .dynamicReplacementArguments(let value):
                [Argument(label: nil, value: value.declName.trimmedDescription)]
            case .unavailableFromAsyncArguments(_):
                []
            case .effectsArguments(let values):
                values.map { Argument(label: nil, value: $0.text) }
            case .documentationArguments(let values):
                values.map { Argument(label: nil, value: $0.label.text) }
            }
        }
        
        private static func availability(from arg: AvailabilityArgumentSyntax.Argument) -> Argument {
            return switch arg {
            case .token(let token):
                Argument(label: nil, value: token.text)
            case .availabilityVersionRestriction(let versionRestriction):
                if let version = versionRestriction.version {
                    Argument(label: versionRestriction.platform.text, value: version.trimmedDescription)
                } else {
                    Argument(label: nil, value: versionRestriction.platform.text)
                }
            case .availabilityLabeledArgument(let labeledArgument):
                availabilityLabeledArgument(from: labeledArgument)
            }
        }
        
        private static func availabilityLabeledArgument(from arg: AvailabilityLabeledArgumentSyntax) -> Argument {
            let value: String? = switch arg.value {
            case .string(let literalStringExpression):
                literalStringExpression.segments.trimmedDescription
            case .version(let versionTuple):
                versionTuple.trimmedDescription
            }
            
            return if let value = value {
                Argument(label: arg.label.text, value: value)
            } else {
                Argument(label: nil, value: arg.label.text)
            }
        }
    }
}

// MARK: - Attributes Factory

extension Attribute {
    static func attributes(from node: AttributeListSyntax) -> [Self] {
        node.compactMap {
            return switch $0 {
            case .attribute(let attributeNode):
                Attribute(node: attributeNode)
            default:
                nil
            }
        }
    }
}
