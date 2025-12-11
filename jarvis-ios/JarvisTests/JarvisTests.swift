import XCTest
@testable import Jarvis

final class JarvisTests: XCTestCase {
    func testItemCreation() {
        let item = Item(title: "Test Item", itemDescription: "Test Description")
        XCTAssertEqual(item.title, "Test Item")
        XCTAssertEqual(item.itemDescription, "Test Description")
        XCTAssertNotNil(item.timestamp)
    }

    func testItemWithoutDescription() {
        let item = Item(title: "Test Item")
        XCTAssertEqual(item.title, "Test Item")
        XCTAssertNil(item.itemDescription)
    }

    func testUserCreation() {
        let date = Date()
        let user = User(
            name: "Test User",
            email: "test@example.com",
            bio: "Test bio",
            memberSince: date
        )

        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.bio, "Test bio")
        XCTAssertEqual(user.memberSince, date)
    }

    func testUserStatsInitialization() {
        let stats = UserStats(
            totalItems: 10,
            itemsThisWeek: 3,
            itemsThisMonth: 7
        )

        XCTAssertEqual(stats.totalItems, 10)
        XCTAssertEqual(stats.itemsThisWeek, 3)
        XCTAssertEqual(stats.itemsThisMonth, 7)
    }
}
