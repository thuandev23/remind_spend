import XCTest
@testable import Runner

final class BankRegexParserTests: XCTestCase {

    // MARK: - VCB

    func testVCB_debitDashFormat() {
        let result = BankRegexParser.parse(text: "GD: -50,000 VND tai ATM")
        XCTAssertEqual(result?.bankId, "vcb")
        XCTAssertEqual(result?.amountVnd, 50_000)
        XCTAssertEqual(result?.sign, "debit")
    }

    func testVCB_debitNoSpace() {
        let result = BankRegexParser.parse(text: "GD: -1,500,000VND")
        XCTAssertEqual(result?.bankId, "vcb")
        XCTAssertEqual(result?.amountVnd, 1_500_000)
    }

    func testVCB_debitKeyword() {
        let result = BankRegexParser.parse(text: "Debit: 200,000 VND")
        XCTAssertEqual(result?.bankId, "vcb")
        XCTAssertEqual(result?.amountVnd, 200_000)
        XCTAssertEqual(result?.sign, "debit")
    }

    func testVCB_balanceFormat() {
        let result = BankRegexParser.parse(text: "So du TK 1234: 5,000,000 VND")
        XCTAssertEqual(result?.bankId, "vcb")
        XCTAssertEqual(result?.amountVnd, 5_000_000)
    }

    // MARK: - MB Bank

    func testMB_chi() {
        let result = BankRegexParser.parse(text: "Bạn đã chi 150,000 đ cho đơn hàng")
        XCTAssertEqual(result?.bankId, "mb")
        XCTAssertEqual(result?.amountVnd, 150_000)
        XCTAssertEqual(result?.sign, "debit")
    }

    func testMB_giaoDich() {
        let result = BankRegexParser.parse(text: "giao dịch 300,000 đ thành công")
        XCTAssertEqual(result?.bankId, "mb")
        XCTAssertEqual(result?.amountVnd, 300_000)
    }

    func testMB_balance() {
        let result = BankRegexParser.parse(text: "Số dư: 2,000,000 đ")
        XCTAssertEqual(result?.bankId, "mb")
        XCTAssertEqual(result?.amountVnd, 2_000_000)
    }

    // MARK: - Techcombank

    func testTCB_gdDash() {
        let result = BankRegexParser.parse(text: "GD: -75,000VND")
        // VCB pattern also matches GD:- so VCB wins; this tests TCB-specific
        // "GD: -XVND" (no space before VND).
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.amountVnd, 75_000)
    }

    // MARK: - MoMo

    func testMoMo_chi() {
        let result = BankRegexParser.parse(text: "Bạn đã chi 50,000đ cho Grab")
        XCTAssertEqual(result?.bankId, "momo")
        XCTAssertEqual(result?.amountVnd, 50_000)
        XCTAssertEqual(result?.sign, "debit")
    }

    func testMoMo_thanhToan() {
        let result = BankRegexParser.parse(text: "thanh toán 120,000đ thành công")
        XCTAssertEqual(result?.bankId, "momo")
        XCTAssertEqual(result?.amountVnd, 120_000)
    }

    func testMoMo_gui() {
        let result = BankRegexParser.parse(text: "Bạn đã gửi 80,000đ tới Nguyen Van A")
        XCTAssertEqual(result?.bankId, "momo")
        XCTAssertEqual(result?.amountVnd, 80_000)
    }

    // MARK: - ZaloPay

    func testZaloPay_chi() {
        let result = BankRegexParser.parse(text: "chi 250,000 VND tại cửa hàng")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.amountVnd, 250_000)
        XCTAssertEqual(result?.sign, "debit")
    }

    // MARK: - No match

    func testNoMatch_returnNil() {
        XCTAssertNil(BankRegexParser.parse(text: "Xác nhận mã OTP của bạn là 123456"))
        XCTAssertNil(BankRegexParser.parse(text: ""))
    }

    // MARK: - Amount parsing

    func testCommaThousandSeparatorIsStripped() {
        let result = BankRegexParser.parse(text: "GD: -1,000,000 VND")
        XCTAssertEqual(result?.amountVnd, 1_000_000)
    }

    func testDotThousandSeparatorIsStripped() {
        // Vietnamese banks sometimes use dots as thousands separator in SMS.
        let result = BankRegexParser.parse(text: "GD: -1.000.000 VND")
        XCTAssertEqual(result?.amountVnd, 1_000_000)
    }

    func testAmountIsNeverNegative() {
        // The parsed amountVnd should be the absolute value extracted by the
        // capture group — the sign field carries the direction.
        let result = BankRegexParser.parse(text: "GD: -500,000 VND")
        XCTAssertGreaterThan(result?.amountVnd ?? -1, 0)
    }
}
