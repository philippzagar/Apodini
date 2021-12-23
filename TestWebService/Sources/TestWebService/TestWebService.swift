//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniREST
import ApodiniOpenAPI
import ApodiniWebSocket
import ApodiniMigration
import ApodiniObserve
import ApodiniObserveOpenTelemetry
import ArgumentParser
import Tracing


@main
struct TestWebService: Apodini.WebService {
    let greeterRelationship = Relationship(name: "greeter")

    @Argument(help: "Endpoint to expose OpenAPI specification")
    var openApiEndpoint: String = "oas"
    
    var content: some Component {
        // Hello World! 👋
        Text("Hello World! 👋")
            .response(EmojiTransformer(emojis: "🎉"))

        // Bigger Subsystems:
        AuctionComponent()
        GreetComponent(greeterRelationship: greeterRelationship)
        RandomComponent(greeterRelationship: greeterRelationship)
        SwiftComponent()
        UserComponent(greeterRelationship: greeterRelationship)
        WeatherComponent()
    }
    
    var configuration: Configuration {
        REST {
            OpenAPI(
                outputFormat: .json,
                outputEndpoint: openApiEndpoint,
                swaggerUiEndpoint: openApiEndpoint + "-ui",
                title: "The great TestWebService - presented by Apodini"
            )
        }
        
        WebSocket()
        
        Migrator()
        
        // Tracing configuration for an OpenTelemetry backend with default configuration options
        TracingConfiguration(
            .defaultOpenTelemetry(serviceName: "TestWebService")
        )
    }
}
