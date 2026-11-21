import Foundation

extension Calendar {
    /// Gregorian in the device's time zone.
    ///
    /// Shared identities (the day's Sheepshead Minute) and stored day keys use
    /// it instead of `.current`, so a Buddhist, Hebrew or Japanese system
    /// calendar cannot hand a player different questions from everyone else or
    /// orphan their saved results. Days still turn over at local midnight,
    /// and weeks start on the device's first weekday (Monday in most of
    /// Europe): a bare Gregorian calendar always starts them on Sunday.
    static var gregorianLocal: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.firstWeekday = Calendar.current.firstWeekday
        calendar.minimumDaysInFirstWeek = Calendar.current.minimumDaysInFirstWeek
        return calendar
    }
}
