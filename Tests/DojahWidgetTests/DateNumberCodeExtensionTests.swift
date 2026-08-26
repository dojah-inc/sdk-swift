import CoreLocation
import XCTest
@testable import DojahWidget

final class DateNumberCodeExtensionTests: XCTestCase {
    private var calendar: Calendar { Calendar.current }

    func testDaySuffix() {
        func date(day: Int) -> Date {
            calendar.date(from: DateComponents(year: 2024, month: 1, day: day))!
        }
        XCTAssertEqual(date(day: 1).daySuffix, "st")
        XCTAssertEqual(date(day: 21).daySuffix, "st")
        XCTAssertEqual(date(day: 31).daySuffix, "st")
        XCTAssertEqual(date(day: 2).daySuffix, "nd")
        XCTAssertEqual(date(day: 22).daySuffix, "nd")
        XCTAssertEqual(date(day: 3).daySuffix, "rd")
        XCTAssertEqual(date(day: 4).daySuffix, "th")
        XCTAssertEqual(date(day: 11).daySuffix, "th")
        XCTAssertEqual(date(day: 23).daySuffix, "th")
    }

    func testCurrentComponentAndFormatting() {
        let date = calendar.date(from: DateComponents(year: 2024, month: 5, day: 9, hour: 15, minute: 4, second: 7))!
        XCTAssertEqual(date.current(.year), 2024)
        XCTAssertEqual(date.current(.month), 5)
        XCTAssertEqual(date.current(.day), 9)
        XCTAssertEqual(date.toString(format: "yyyy-MM-dd", timezone: TimeZone(secondsFromGMT: 0)), "2024-05-09")
        XCTAssertEqual(date.string(format: "dd MMM yyyy"), date.toString(format: "dd MMM yyyy"))
        XCTAssertFalse(date.timeOnlyString().isEmpty)
        XCTAssertFalse(date.dateAndTimetoString().isEmpty)
        XCTAssertFalse(date.appendAsString().isEmpty)
    }

    func testStartEndOfMonthAndNavigation() {
        let date = calendar.date(from: DateComponents(year: 2024, month: 2, day: 15))!
        XCTAssertEqual(calendar.component(.day, from: date.startOfMonth), 1)
        XCTAssertEqual(calendar.component(.month, from: date.endOfMonth), 2)
        XCTAssertEqual(calendar.component(.day, from: date.endOfMonth), 29)
        XCTAssertEqual(calendar.component(.day, from: date.nextDate()), 16)
        XCTAssertEqual(calendar.component(.day, from: date.previousDate()), 14)
    }

    func testAddRemoveDateComponents() {
        let date = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 10, minute: 0))!
        XCTAssertEqual(calendar.component(.month, from: date.addMonths(2)), 3)
        XCTAssertEqual(calendar.component(.minute, from: date.addMinutes(15)), 15)
        XCTAssertEqual(calendar.component(.hour, from: date.addHours(2)), 12)
        XCTAssertEqual(calendar.component(.day, from: date.addDays(5)), 20)
        XCTAssertEqual(calendar.component(.year, from: date.plus(1, component: .year)), 2025)
        XCTAssertEqual(calendar.component(.month, from: date.removeMonths(numberOfMonths: 1)), 12)
        XCTAssertEqual(calendar.component(.year, from: date.removeYears(numberOfYears: 1)), 2023)
    }

    func testHumanReadableDayString() {
        let sunday = calendar.date(from: DateComponents(year: 2024, month: 1, day: 7))!
        XCTAssertEqual(sunday.getHumanReadableDayString(), "Sunday")
        let wednesday = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10))!
        XCTAssertEqual(wednesday.getHumanReadableDayString(), "Wednesday")
    }

    func testTimeAgoAndTimeBetween() {
        let now = Date()
        XCTAssertEqual(now.time(since: now), "Just now")
        XCTAssertTrue(now.addingTimeInterval(120).time(since: now).contains("ago"))
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2024, month: 1, day: 11))!
        XCTAssertEqual(start.timeBetween(endDate: end, timeComponent: .day), 10)
        XCTAssertEqual(start.timeBetween(endDate: end, timeComponent: .year), 0)
        XCTAssertEqual(start.timeBetween(endDate: end, timeComponent: .era), 0)
    }

    func testIntOfAndStringToDate() {
        XCTAssertEqual(1.of("day"), "1 day")
        XCTAssertEqual(2.of("day"), "2 days")
        XCTAssertNotNil("01 Jan 2024 10:00 AM".toDate())
        XCTAssertNil("not-a-date".toDate())
        XCTAssertFalse("2024-03-09T12:30:00Z".displayDate(format: "yyyy").isEmpty)
        XCTAssertTrue("01-12-1990".isValidDate())
        XCTAssertFalse("1990-12-01".isValidDate())
        XCTAssertFalse(currentDate().timeIntervalSinceNow > 2)
    }

    func testNumericHelpers() {
        XCTAssertEqual(10.double, 10.0)
        XCTAssertEqual(10.float, 10.0)
        XCTAssertEqual(10.int, 10)
        XCTAssertEqual(0.orNil, "Nil")
        XCTAssertEqual(4.orNil, "4")
        XCTAssertEqual(0.orEmpty, "")
        XCTAssertEqual(4.orEmpty, "4")
        XCTAssertEqual(5.string, "5")
        XCTAssertEqual(2.inKobo, 200)
        XCTAssertEqual(200.inNaira, 2)
        XCTAssertEqual(12.percent, "12%")
        XCTAssertEqual(50.percentage, 0.5)
        XCTAssertEqual(1000.currencyFormatted(), "1,000")
        XCTAssertEqual(1000.currencyFormatted(symbol: "₦"), "₦1,000")
        XCTAssertEqual(10.5.string(fractionDigits: 2), "10.50")
        XCTAssertTrue(3.lessThan(4))
        XCTAssertTrue(3.lessThanOrEquals(3))
        XCTAssertTrue(4.greaterThan(3))
        XCTAssertTrue(4.greaterThanOrEquals(4))
        XCTAssertTrue(5.equals(5))
        XCTAssertTrue(5.notEquals(6))
        XCTAssertEqual(CGFloat(3).double, 3.0)
    }

    func testCollectionOptionalSetAndDictionaryHelpers() {
        XCTAssertEqual(Set([1, 2]).toArray.sorted(), [1, 2])
        XCTAssertEqual(Array("123456").chunk(n: 2).map { String($0) }, ["12", "34", "56"])
        XCTAssertEqual(Array("12345").chunk(n: 2).map { String($0) }, ["12", "34", "5"])
        XCTAssertTrue([1, 2].isNotEmpty)
        XCTAssertTrue([1, 2].countEquals(2))
        XCTAssertTrue([1].countNotEqual(to: 2))
        XCTAssertTrue([1, 2, 3].countGreaterThan(2))
        XCTAssertTrue([1, 2].countGreaterThanOrEquals(2))
        XCTAssertTrue([1].countLessThan(2))
        XCTAssertTrue([1, 2].countLessThanOrEquals(2))
        XCTAssertTrue([1, 2].doesNotContain(3))

        let optionalInt: Int? = nil
        XCTAssertTrue(optionalInt.isNil)
        XCTAssertFalse(optionalInt.isNotNil)
        XCTAssertEqual(optionalInt.orZero, 0)
        XCTAssertEqual((5 as Int?).orZero, 5)

        let optionalDouble: Double? = nil
        XCTAssertEqual(optionalDouble.orZero, 0)

        let optionalString: String? = nil
        XCTAssertEqual(optionalString.orEmpty, "")
        XCTAssertEqual(("hi" as String?).orEmpty, "hi")
        XCTAssertEqual(("" as String?).orEmpty, "")

        XCTAssertEqual(["a", "b", "a", "c"].distinctBy { $0 }, ["a", "b", "c"])

        var merged = ["a": 1]
        XCTAssertEqual(merged.merge(["b": 2]), ["a": 1, "b": 2])
        XCTAssertTrue(["a": 1].containKey("a"))
        XCTAssertFalse(["a": 1].containKey("z"))
        XCTAssertEqual(["a": 1] + ["b": 2], ["a": 1, "b": 2])
        XCTAssertEqual(NSObject.className, "NSObject")
    }

    func testWithFunctionAndRandomString() {
        let value = with(3) { _ in }
        XCTAssertEqual(value, 3)
        XCTAssertEqual(randomString(length: 8).count, 8)
        XCTAssertEqual(randomString(length: 0), "")
        let generated = randomString(length: 20)
        XCTAssertTrue(generated.allSatisfy { "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".contains($0) })
    }

    func testCLLocationCoordinateHelpers() {
        let coordinate = CLLocationCoordinate2D(latitude: 6.5, longitude: 3.3)
        XCTAssertEqual(coordinate.location.coordinate.latitude, 6.5, accuracy: 0.0001)
        XCTAssertTrue(coordinate.latLngString.contains("6.5"))
        XCTAssertEqual(coordinate.location.latLngString, coordinate.latLngString)
    }
}
