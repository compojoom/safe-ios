//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 04.01.22.
//

import Foundation
import Solidity
import XCTest

class ContractFunctionEncodingTests: XCTestCase {
    func testEncodeStaticParams() {
        let value = Sol.ContractFunction<Sol.EmptyTuple>(
            selector: Sol.Bytes4(storage: Data([0xcd, 0xcd, 0x77, 0xc0])),
            parameters: Sol.Tuple(elements: [Sol.UInt32(69), Sol.Bool(storage: true)]))
        let expected = Data([
            // 0xcdcd77c0
            0xcd, 0xcd, 0x77, 0xc0,
            // 0000000000000000000000000000000000000000000000000000000000000045
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x45,
            // 0000000000000000000000000000000000000000000000000000000000000001
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
        ])
        let data = value.encode()
        XCTAssertEqual(Array(data), Array(expected))
    }

    func testDecodeStaticParams() throws {
        let data = Data([
            // 0xcdcd77c0
            0xcd, 0xcd, 0x77, 0xc0,
            // 0000000000000000000000000000000000000000000000000000000000000045
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x45,
            // 0000000000000000000000000000000000000000000000000000000000000001
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
        ])
        var value = Sol.ContractFunction<Sol.EmptyTuple>(
            selector: Sol.Bytes4(),
            parameters: Sol.Tuple(elements: [Sol.UInt32(), Sol.Bool()])
        )
        var offset = 0
        try value.decode(from: data, offset: &offset)
        continueAfterFailure = false
        XCTAssertEqual(value.selector.storage.map(\.magnitude), [0xcd, 0xcd, 0x77, 0xc0])
        XCTAssertEqual(value.parameters.elements.count, 2)
        XCTAssertEqual(value.parameters.elements[0] as? Sol.UInt32, 69)
        XCTAssertEqual(value.parameters.elements[1] as? Sol.Bool, .init(storage: true))
        XCTAssertEqual(offset, 68)
    }

    func testEncodeTransferFrom() {
        let value = ERC20.transferFrom(
            from: Sol.Address(storage: Sol.UInt160(0xaa)),
            to: Sol.Address(storage: Sol.UInt160(0xbb)),
            value: Sol.UInt256(0x1234)
        )
        let expected = Data([
            // 0x23b872dd
            0x23, 0xb8, 0x72, 0xdd,
            // 0xaa
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xaa,
            // 0xbb
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xbb,
            // 0x1234
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x12, 0x34,
        ])
        let data = value.encode()
        XCTAssertEqual(Array(data), Array(expected))
    }

    func testDecodeTransferFrom() throws {
        let data = Data([
            // 0x23b872dd
            0x23, 0xb8, 0x72, 0xdd,
            // 0xaa
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xaa,
            // 0xbb
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xbb,
            // 0x1234
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x12, 0x34,
        ])
        var value = ERC20.transferFrom()
        var offset = 0
        try value.decode(from: data, offset: &offset)
        continueAfterFailure = false
        XCTAssertEqual(value.from, Sol.Address(storage: Sol.UInt160(0xaa)))
        XCTAssertEqual(value.to, Sol.Address(storage: Sol.UInt160(0xbb)))
        XCTAssertEqual(value.value, Sol.UInt256(0x1234))
        XCTAssertEqual(offset, 100)
    }

    func testDecodeTransferFromReturns() throws {
        let data = Data([
            // 0x01 (true)
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
        ])
        var value = ERC20.transferFrom.Returns()
        var offset = 0
        try value.decode(from: data, offset: &offset)
        continueAfterFailure = false
        XCTAssertEqual(value.success, .init(storage: true))
        XCTAssertEqual(offset, 32)

    }
}
