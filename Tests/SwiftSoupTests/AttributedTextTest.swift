//
//  AttributedTextTest.swift
//  
//
//  Created by herrernst on 05.07.23.
//

import XCTest
import SwiftSoup

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
final class AttributedTextTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }


    func testAttr() throws {
        
        let html = "<p>Parsed HTML <b>into</b> <i>a</i> doc.</p>"
        let doc = try SwiftSoup.parse(html)
        let body = doc.body()!
        let text = try body.text()
        XCTAssertEqual(text, "Parsed HTML into a doc.")
        let attributedText: AttributedString = try body.attributedText()
        print("runs: \(attributedText.runs.count)")
        print("\(attributedText)")
        XCTAssertEqual(String(attributedText.characters), "Parsed HTML into a doc.")
    }


}
