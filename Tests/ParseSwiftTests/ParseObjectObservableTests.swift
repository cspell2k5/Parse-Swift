//
//  ParseObjectObservableTests.swift
//  ParseSwift
//
//  Created by Craig Spell on 2/10/26.
//
import XCTest
import SwiftUI
@testable import ParseSwift

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
@MainActor
final class ParseObjectObservableTests: XCTestCase {
    
    struct MockObject: ParseObject {
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?
        
        var title: String?
        
        @MainActor
        static var object: ParseObjectObservable<MockObject> {
            MockObject(title: "Test").asObservable
        }
    }
    
    func testAsObservableExtension() {
        let observable = MockObject.object
        XCTAssertEqual(observable.title, "Test")
        observable.title = "New Title"
        XCTAssertEqual(observable.title, "New Title")
    }
    
    func testPointerConversion() throws {
        let objWithId = MockObject.object
        objWithId.objectId = "abc123"

        let pointer = try XCTUnwrap(objWithId.toPointer())
        XCTAssertEqual(pointer.objectId, "abc123")
    }
    
    func testObservationTriggeredOnPropertyChange() {
        let observable = MockObject.object

        let expectation = self.expectation(description: "Observation should trigger")
        
            // Tracking must access the property to register the dependency
        withObservationTracking {
            _ = observable.title
        } onChange: {
            expectation.fulfill()
        }

        observable.title = "Updated"
        
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(observable.title, "Updated")
    }
        
        /// Tests that the internal value updates correctly (Mocking the concept of a fetch)
    func testInternalValueUpdatesOnManualAssignment() async {
        let object = MockObject(title: "Old")
        let observable = object.asObservable
        
        let updatedObject = MockObject(title: "New")
        
            // This simulates what happens inside fetch/save methods
        let expectation = self.expectation(description: "UI should update when internal value changes")
        
        withObservationTracking {
            _ = observable.title
        } onChange: {
            expectation.fulfill()
        }
        
            // In code, this happens after 'try await value.fetch()'
        observable.title = updatedObject.title
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(observable.title, "New")
    }
    
    func testPointerConversionWithoutObjectIdThrows() {
        // Given an object without an objectId, pointer conversion should be nil or should fail
        let objNoId = MockObject(title: "NoId").asObservable
        XCTAssertThrowsError(try objNoId.toPointer())
        XCTAssertNil(try? objNoId.toPointer())
    }
}


