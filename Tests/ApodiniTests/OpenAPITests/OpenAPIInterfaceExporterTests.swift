//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
@testable import Apodini
@testable import ApodiniOpenAPI
@testable import ApodiniREST
@_implementationOnly import Yams
import OpenAPIKit
import XCTApodiniNetworking


final class OpenAPIInterfaceExporterTests: ApodiniTests {
    struct SomeComp: Handler {
        func handle() -> String {
            "Test"
        }
    }

    func testInterfaceExporterDefaultServing() throws {
        struct TestWebService: WebService {
            var content: some Component {
                SomeComp()
            }

            var configuration: Configuration {
                REST {
                    OpenAPI()
                }
            }
        }

        try TestWebService().start(app: app)

        try app.testable().test(.GET, "\(OpenAPI.ConfigurationDefaults.outputEndpoint)") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertNoThrow(try res.bodyStorage.getFullBodyData(decodedAs: OpenAPI.Document.self, using: JSONDecoder()))
        }
        
        let headers = HTTPHeaders {
            $0[.contentType] = .html
        }
        
        try app.testable().test(.GET, "/\(OpenAPI.ConfigurationDefaults.swaggerUiEndpoint)", headers: headers) { res in
            XCTAssertEqual(res.status, .ok)
            guard let htmlFile = Bundle.apodiniOpenAPIResources.path(forResource: "swagger-ui", ofType: "html"),
                  var html = try? String(contentsOfFile: htmlFile)
            else {
                throw HTTPAbortError(status: .internalServerError)
            }
            html = html.replacingOccurrences(of: "{{OPEN_API_ENDPOINT_URL}}", with: "/\(OpenAPI.ConfigurationDefaults.outputEndpoint)")
            XCTAssertEqual(res.bodyStorage.readNewDataAsString(), html)
        }
    }

    func testInterfaceExporterConfiguredServing() throws {
        let configuredOutputEndpoint = "/oas"
        let configuredSwaggerUiEndpoint = "/oas-ui"
        
        struct TestWebService: WebService {
            var content: some Component {
                SomeComp()
            }

            var configuration: Configuration {
                REST(encoder: JSONEncoder(), decoder: JSONDecoder()) {
                    OpenAPI(outputFormat: .yaml,
                            outputEndpoint: "/oas",
                            swaggerUiEndpoint: "/oas-ui")
                }
            }
        }

        try TestWebService().start(app: app)

        try app.testable().test(.GET, configuredOutputEndpoint) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertThrowsError(try res.bodyStorage.getFullBodyData(decodedAs: OpenAPI.Document.self, using: JSONDecoder()))
        }

        let headers = HTTPHeaders {
            $0[.contentType] = .html
        }

        try app.testable().test(.GET, configuredSwaggerUiEndpoint, headers: headers) { res in
            XCTAssertEqual(res.status, .ok)
            guard let htmlFile = Bundle.apodiniOpenAPIResources.path(forResource: "swagger-ui", ofType: "html"),
                  var html = try? String(contentsOfFile: htmlFile)
                else {
                return XCTFail("Missing Swagger-UI HTML resource.")
            }
            html = html.replacingOccurrences(of: "{{OPEN_API_ENDPOINT_URL}}", with: configuredOutputEndpoint)
            XCTAssertEqual(res.bodyStorage.readNewDataAsString(), html)
        }
    }
}
