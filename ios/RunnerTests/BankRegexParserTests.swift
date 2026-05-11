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
        XCTAssertEqual(result?.sign, "debit")
    }

    func testVCB_debitKeyword() {
        let result = BankRegexParser.parse(text: "Debit: 200,000 VND NGUYEN VAN A")
        XCTAssertEqual(result?.bankId, "vcb")
        XCTAssertEqual(result?.amountVnd, 200_000)
        XCTAssertEqual(result?.sign, "debit")
    }

    func testVCB_creditPlusFormat() {
        let result = BankRegexParser.parse(text: "GD: +250,000 VND tu NGUYEN VAN A. So du: 5,250,000 VND")
        XCTAssertEqual(result?.bankId, "vcb")
        XCTAssertEqual(result?.amountVnd, 250_000)
        XCTAssertEqual(result?.sign, "credit")
    }

    func testVCB_creditKeyword() {
        let result = BankRegexParser.parse(text: "Credit: 500,000 VND from NGUYEN VAN A")
        XCTAssertEqual(result?.bankId, "vcb")
        XCTAssertEqual(result?.amountVnd, 500_000)
        XCTAssertEqual(result?.sign, "credit")
    }

    func testVCB_balanceOnlyDoesNotParse() {
        // Balance-only notifications have no GD:/Credit/Debit keyword — should not match
        let result = BankRegexParser.parse(text: "So du TK 1234: 5,000,000 VND")
        // No VCB-specific pattern matches. ACB broad pattern is removed from iOS rules.
        XCTAssertNil(result)
    }

    // MARK: - MB Bank

    func testMB_chiDebit() {
        let result = BankRegexParser.parse(text: "TK 0123456789 chi 150,000đ luc 14:30")
        XCTAssertEqual(result?.bankId, "mb")
        XCTAssertEqual(result?.amountVnd, 150_000)
        XCTAssertEqual(result?.sign, "debit")
    }

    func testMB_giaoDichDebit() {
        let result = BankRegexParser.parse(text: "giao dịch 300,000đ thanh cong")
        XCTAssertEqual(result?.bankId, "mb")
        XCTAssertEqual(result?.amountVnd, 300_000)
        XCTAssertEqual(result?.sign, "debit")
    }

    func testMB_nhanCredit() {
        let result = BankRegexParser.parse(text: "TK 0123456789 nhận 250,000đ tu NGUYEN VAN A")
        XCTAssertEqual(result?.bankId, "mb")
        XCTAssertEqual(result?.amountVnd, 250_000)
        XCTAssertEqual(result?.sign, "credit")
    }

    func testMB_congCredit() {
        let result = BankRegexParser.parse(text: "TK 0123456789 cộng 100,000đ tu NGUYEN VAN A")
        XCTAssertEqual(result?.bankId, "mb")
        XCTAssertEqual(result?.amountVnd, 100_000)
        XCTAssertEqual(result?.sign, "credit")
    }

    func testMB_balanceOnlyDoesNotParse() {
        // "Số dư:" alone without chi/nhận/cộng → removed from rules
        let result = BankRegexParser.parse(text: "Số dư: 2,000,000 đ")
        XCTAssertNil(result)
    }

    // MARK: - Techcombank

    func testTCB_gdDebit() {
        // VCB debit pattern matches "GD: -XVND" first — that's expected on iOS
        // since there's no package-name filter. Amount must be correct.
        let result = BankRegexParser.parse(text: "GD: -75,000VND tai POS XYZ")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.amountVnd, 75_000)
        XCTAssertEqual(result?.sign, "debit")
    }

    func testTCB_gdCredit() {
        let result = BankRegexParser.parse(text: "GD: +75,000VND tu NGUYEN VAN A")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.amountVnd, 75_000)
        XCTAssertEqual(result?.sign, "credit")
    }

    // MARK: - BIDV

    func testBIDV_giamDebit() {
        let result = BankRegexParser.parse(text: "TK 01234 giam 250,000VND. So du: 5,000,000VND")
        XCTAssertEqual(result?.bankId, "bidv")
        XCTAssertEqual(result?.amountVnd, 250_000)
        XCTAssertEqual(result?.sign, "debit")
    }

    func testBIDV_tangCredit() {
        let result = BankRegexParser.parse(text: "TK 01234 tang 250,000VND. So du: 5,250,000VND")
        XCTAssertEqual(result?.bankId, "bidv")
        XCTAssertEqual(result?.amountVnd, 250_000)
        XCTAssertEqual(result?.sign, "credit")
    }

    func testBIDV_nhanCredit() {
        let result = BankRegexParser.parse(text: "TK 01234 nhan 500,000VND tu NGUYEN VAN A")
        XCTAssertEqual(result?.bankId, "bidv")
        XCTAssertEqual(result?.amountVnd, 500_000)
        XCTAssertEqual(result?.sign, "credit")
    }

    // MARK: - Vietinbank

    func testVTB_giamDebitDotSeparator() {
        let result = BankRegexParser.parse(text: "TK 0123456789 Giam 250.000 VND. SD 5.000.000 VND")
        XCTAssertEqual(result?.bankId, "vtb")
        XCTAssertEqual(result?.amountVnd, 250_000)
        XCTAssertEqual(result?.sign, "debit")
    }

    func testVTB_tangCreditDotSeparator() {
        let result = BankRegexParser.parse(text: "TK 0123456789 Tang 250.000 VND. SD 5.250.000 VND")
        XCTAssertEqual(result?.bankId, "vtb")
        XCTAssertEqual(result?.amountVnd, 250_000)
        XCTAssertEqual(result?.sign, "credit")
    }

    // MARK: - MoMo

    func testMoMo_chiDebit() {
        let result = BankRegexParser.parse(text: "Bạn đã chi 50,000đ cho Grab")
        XCTAssertEqual(result?.bankId, "momo")
        XCTAssertEqual(result?.amountVnd, 50_000)
        XCTAssertEqual(result?.sign, "debit")
    }

    func testMoMo_thanhToanDebit() {
        let result = BankRegexParser.parse(text: "thanh toán 120,000đ thành công")
        XCTAssertEqual(result?.bankId, "momo")
        XCTAssertEqual(result?.amountVnd, 120_000)
        XCTAssertEqual(result?.sign, "debit")
    }

    func testMoMo_nhanCredit() {
        let result = BankRegexParser.parse(text: "Bạn nhận 80,000đ từ Nguyen Van A")
        XCTAssertEqual(result?.bankId, "momo")
        XCTAssertEqual(result?.amountVnd, 80_000)
        XCTAssertEqual(result?.sign, "credit")
    }

    func testMoMo_hoanTienCredit() {
        let result = BankRegexParser.parse(text: "hoàn tiền 30,000đ đơn hàng #ABC123")
        XCTAssertEqual(result?.bankId, "momo")
        XCTAssertEqual(result?.amountVnd, 30_000)
        XCTAssertEqual(result?.sign, "credit")
    }

    // MARK: - ZaloPay

    func testZaloPay_chiDebit() {
        let result = BankRegexParser.parse(text: "chi 250,000 VND tại cửa hàng")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.amountVnd, 250_000)
        XCTAssertEqual(result?.sign, "debit")
    }

    func testZaloPay_nhanCredit() {
        // "nhận ... VND" also matches MoMo credit (which comes before ZaloPay in rules).
        // On iOS there's no package-name filter — Shortcuts handles bank discrimination.
        // We verify the sign and amount are correct regardless of which rule matches first.
        let result = BankRegexParser.parse(text: "nhận 100,000 VND từ NGUYEN VAN A")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.amountVnd, 100_000)
        XCTAssertEqual(result?.sign, "credit")
    }

    // MARK: - No match

    func testNoMatch_otp() {
        XCTAssertNil(BankRegexParser.parse(text: "Xác nhận mã OTP của bạn là 123456"))
    }

    func testNoMatch_empty() {
        XCTAssertNil(BankRegexParser.parse(text: ""))
    }

    // MARK: - Amount parsing

    func testCommaThousandSeparatorIsStripped() {
        let result = BankRegexParser.parse(text: "GD: -1,000,000 VND")
        XCTAssertEqual(result?.amountVnd, 1_000_000)
    }

    func testDotThousandSeparatorIsStripped() {
        let result = BankRegexParser.parse(text: "Giam 1.000.000 VND")
        XCTAssertEqual(result?.amountVnd, 1_000_000)
    }

    func testAmountIsPositive() {
        // amountVnd is always the absolute value; sign field carries the direction
        let result = BankRegexParser.parse(text: "GD: -500,000 VND")
        XCTAssertGreaterThan(result?.amountVnd ?? -1, 0)
    }
}
