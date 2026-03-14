
import Foundation

struct BillingPeriod {
    static func current(startDay: Int, referenceDate: Date = .now) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let day   = calendar.component(.day,   from: referenceDate)
        let month = calendar.component(.month, from: referenceDate)
        let year  = calendar.component(.year,  from: referenceDate)

        if day >= startDay {
            // Billing started this month
            let start = date(year: year, month: month, day: startDay)
            let end   = date(year: year, month: month + 1, day: startDay - 1)
            return (start, end)
        } else {
            // Billing started last month
            let start = date(year: year, month: month - 1, day: startDay)
            let end   = date(year: year, month: month, day: startDay - 1)
            return (start, end)
        }
    }

    private static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year  = year
        components.month = month
        components.day   = day
        // Calendar automatically handles month overflow (e.g. month 13 → next year)
        return Calendar.current.date(from: components)!
    }

    static func formatted(_ period: (start: Date, end: Date)) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        fmt.locale = Locale(identifier: "fr_CA")
        return "\(fmt.string(from: period.start)) → \(fmt.string(from: period.end))"
    }
}
