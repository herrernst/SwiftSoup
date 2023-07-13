//
//  Element+AttributedText.swift
//  
//
//  Created by herrernst on 13.07.23.
//

import Foundation
import os.log

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
fileprivate let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Element+AttributedText")

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Element {
    struct RangeAttributes {
        let range: ClosedRange<Int>
        let attributes: AttributeContainer
    }
    
    class AttributedTextNodeVisitor: textNodeVisitor {
        struct VisitorContext {
            let tagName: String
            let depth: Int
            let currentStringOffset: Int
            var attributes: AttributeContainer?
        }
        var visitorStack: [VisitorContext] = []
        class Counter {
            var count = 0
            func next() -> Int {
                count += 1
                return count
            }
        }
        var identityCounter = Counter()
        // TODO: change to inout like accum
        public var rangesAttributes: [RangeAttributes] = []
        
        public override func head(_ node: Node, _ depth: Int) {
            logger.debug("enter nodename: \(node.nodeName())")
            var visitorContext = VisitorContext(tagName: node.nodeName(), depth: depth, currentStringOffset: accum.xlength)
            super.head(node, depth)
            if let element = (node as? Element) {
                logger.debug("node is also element: \(element._tag.getName())")
                var attributes = AttributeContainer()
                // FIXME: overwrites
//                if element.isBlock() {
//                    attributes.inlinePresentationIntent = .blockHTML
//                } else {
//                    attributes.inlinePresentationIntent = .inlineHTML
//                }
                if node.nodeName() == "b" {
                    attributes.inlinePresentationIntent = .stronglyEmphasized
                }
                if node.nodeName() == "i" {
                    attributes.inlinePresentationIntent = .emphasized
                }
                if node.nodeName() == "p" {
                    attributes.presentationIntent = PresentationIntent.init(.paragraph, identity: identityCounter.next())
                }
                if node.nodeName() == "ul" {
                    attributes.presentationIntent = PresentationIntent.init(.unorderedList, identity: identityCounter.next())
                }
                if node.nodeName() == "ol" {
                    attributes.presentationIntent = PresentationIntent.init(.orderedList, identity: identityCounter.next())
                }
                if node.nodeName() == "h1" {
                    attributes.presentationIntent = PresentationIntent.init(.header(level: 1), identity: identityCounter.next())
                }
                if node.nodeName() == "li" {
                    // TODO: count list items
                    attributes.presentationIntent = PresentationIntent.init(.listItem(ordinal: 1), identity: identityCounter.next(), parent: visitorStack.last?.attributes?.presentationIntent)
                }
                visitorContext.attributes = attributes
            }
            visitorStack.append(visitorContext)
        }
        
        public override func tail(_ node: Node, _ depth: Int) {
            logger.debug("leave nodename: \(node.nodeName())")
            let popped = visitorStack.popLast()!
            assert(popped.tagName == node.nodeName())
            super.tail(node, depth)
            // nodeName can also be #text and #document
            if let element = (node as? Element) {
                logger.debug("node is also element: \(element._tag.getName())")
                if let attributes = popped.attributes {
                    let end = accum.xlength
                    let range = popped.currentStringOffset...end
                    let rangeAttributes = RangeAttributes(range: range, attributes: attributes)
                    rangesAttributes.append(rangeAttributes)
                }
            }

        }
    }
    public func attributedText(trimAndNormaliseWhitespace: Bool = true) throws -> AttributedString {
        let accum: StringBuilder = StringBuilder()
        // see: https://forums.swift.org/t/presentationintents-on-attributedstring-containers/61952
        let attributedTextNodeVisitor = AttributedTextNodeVisitor(accum, trimAndNormaliseWhitespace: trimAndNormaliseWhitespace)
        let nodeTraversor = NodeTraversor(attributedTextNodeVisitor)
        try nodeTraversor.traverse(self)
        let text = accum.toString()
        var attributedText = AttributedString(text)
        attributedTextNodeVisitor.rangesAttributes.forEach { rangeAttributes in
            // TODO: will this work with wide chars, e. g. CJK scripts?
            let startIndex = String.Index(utf16Offset: rangeAttributes.range.lowerBound, in: text)
            let endIndex = String.Index(utf16Offset: rangeAttributes.range.upperBound, in: text)
            if let attributedStartIndex = AttributedString.Index(startIndex, within: attributedText),
               let attributedEndIndex = AttributedString.Index(endIndex, within: attributedText) {
                logger.debug("\(rangeAttributes.range): \(rangeAttributes.attributes)")
                let attributedStringRange = attributedStartIndex..<attributedEndIndex
                attributedText[attributedStringRange].mergeAttributes(rangeAttributes.attributes)
            } else {
                logger.debug("cannot set attributes")
            }
        }
        return attributedText
    }
}
