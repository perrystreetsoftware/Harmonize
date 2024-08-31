import Foundation
import Harmonize
import XCTest

final class FunctionsTests: XCTestCase {
    private var harmonize: Harmonize {
        HarmonizeUtils().appendingPath("Fixtures/Functions").harmonize()
    }
    
    func testAssertCanParseTopLevelFunctionsOnly() throws {
        let functions = harmonize.functions(includeNested: false)
        let functionNames = functions.map { $0.name }
        
        XCTAssertEqual(functions.count, 14)
        XCTAssertEqual(
            functionNames, 
            [
                "noArgLabelsFunction",
                "argLabelsFunction",
                "customArgLabelsFunction",
                "mixedLabeledArgsFunction",
                "variadic",
                "noLabelVariadic",
                "noLabelAtAll",
                "withReturnClause",
                "withGenericVariance",
                "withWhereClause",
                "withParametersInitializers",
                "withParametersAttributes",
                "fetchAllTheThings",
                "privateFunc"
            ]
        )
    }
    
    func testAssertCanParseFunctionsIncludingMemberFunctions() throws {
        let functions = harmonize.functions(includeNested: true)
        let functionNames = functions.map { $0.name }
        
        XCTAssertEqual(functions.count, 15)
        XCTAssertEqual(
            functionNames,
            [
                "nestedFunction",
                "noArgLabelsFunction",
                "argLabelsFunction",
                "customArgLabelsFunction",
                "mixedLabeledArgsFunction",
                "variadic",
                "noLabelVariadic",
                "noLabelAtAll",
                "withReturnClause",
                "withGenericVariance",
                "withWhereClause",
                "withParametersInitializers",
                "withParametersAttributes",
                "fetchAllTheThings",
                "privateFunc"
            ]
        )
    }
    
    func testAssertCanParseFunctionReturnClauses() throws {
        let functions = harmonize.functions()
        let returnClauses = functions.map { $0.returnClause }
        
        XCTAssertEqual(
            returnClauses,
            [
                .type("String"),
                .absent,
                .absent,
                .absent,
                .absent,
                .absent,
                .absent,
                .absent,
                .type("String"),
                .type("R"),
                .type("Int"),
                .type("Int"),
                .type("Int"),
                .type("Int"),
                .absent
            ]
        )
    }
    
    func testAssertCanParseFunctionParametersWithNoArgLabels() throws {
        let function = funcByName("noArgLabelsFunction")
        let parameters = function.parameters
        let labels = parameters.map { $0.label }
        XCTAssertEqual(labels, ["", ""])
    }
    
    func testAssertCanParseFunctionParametersWithArgLabels() throws {
        let function = funcByName("argLabelsFunction")
        let parameters = function.parameters
        let labels = parameters.map { $0.label }
        XCTAssertEqual(labels, ["p1", "p2"])
    }
    
    func testAssertCanParseFunctionParametersWithCustomArgLabels() throws {
        let function = funcByName("customArgLabelsFunction")
        let parameters = function.parameters
        
        let labels = parameters.map { $0.label }
        let names = parameters.map { $0.name }
        
        XCTAssertEqual(labels, ["param1", "param2"])
        XCTAssertEqual(names, ["p1", "param2"])
    }
    
    func testAssertCanParseFunctionParametersWithMixedArgLabels() throws {
        let function = funcByName("mixedLabeledArgsFunction")
        let parameters = function.parameters
        
        let labels = parameters.map { $0.label }
        let names = parameters.map { $0.name }
        
        XCTAssertEqual(labels, ["p1", ""])
        XCTAssertEqual(names, ["p1", "p2"])
    }
    
    func testAssertCanParseVariadicFunctionParameters() throws {
        let variadicArg = funcByName("variadic").parameters.first!
        let noLabelVariadicArg = funcByName("noLabelVariadic").parameters.first!
        
        XCTAssertEqual(variadicArg.name, "args")
        XCTAssertEqual(variadicArg.label, "args")
        XCTAssertEqual(variadicArg.typeAnnotation, "String...")
        XCTAssertEqual(noLabelVariadicArg.label, "")
    }
    
    func testAssertCanParseFunctionParametersWithNoNameAndLabels() throws {
        let unnamedParam = funcByName("noLabelAtAll").parameters.first!
        XCTAssertEqual(unnamedParam.name, "_")
        XCTAssertEqual(unnamedParam.label, "")
        XCTAssertEqual(unnamedParam.typeAnnotation, "String")
    }
    
    func testAssertCanParseFunctionParametersWithReturnClause() throws {
        let returnClause = funcByName("withReturnClause").returnClause
        XCTAssertEqual(returnClause, .type("String"))
    }
    
    func testAssertCanParseFunctionParametersWithGenericClause() throws {
        let genericClause = funcByName("withGenericVariance").genericClause
        XCTAssertEqual(genericClause, "<T, R>")
    }
    
    func testAssertCanParseFunctionParametersWithWhereClause() throws {
        let whereClause = funcByName("withWhereClause").whereClause
        XCTAssertEqual(whereClause, "where T: Sendable")

    }
    
    func testAssertCanParseFunctionParametersWithInitializer() throws {
        let param = funcByName("withParametersInitializers").parameters.first!
        XCTAssertEqual(param.defaultValue, "Value")
    }
    
    func testAssertCanParseFunctionParametersWithAttributes() throws {
        let attributedParam = funcByName("withParametersAttributes").parameters.first!
        XCTAssertEqual(attributedParam.attributes, [.type(attribute: .autoclosure)])
    }
    
    func testAssertCanParseFunctionModifiers() throws {
        let asyncfunc = funcByName("fetchAllTheThings")
        let privateFunc = funcByName("privateFunc")
        
        XCTAssertEqual(asyncfunc.modifiers, [.public])
        XCTAssertEqual(privateFunc.modifiers, [.private])
    }
    
    func testAssertCanParseFunctionBody() throws {
        let functionBody = funcByName("withReturnClause").body
        let body = """
        let cal = "cal"
        noLabelAtAll(cal)
        return "return"
        """
        XCTAssertEqual(functionBody, body)
    }
    
    private func funcByName(_ name: String, includeNested: Bool = true) -> SwiftFunction {
        harmonize.functions(includeNested: includeNested).first {
            $0.name == name
        }!
    }
}