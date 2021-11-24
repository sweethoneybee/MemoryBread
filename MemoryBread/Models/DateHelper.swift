//
//  DateHelper.swift
//  MemoryBread
//
//  Created by 정성훈 on 2021/11/12.
//

import Foundation
import Then
import UIKit

extension Locale {
    var localeFromIdentifier: Locale {
        switch languageCode {
        case "en": return Locale(identifier: "en")
        case "ko": return Locale(identifier: "ko-KR")
        default: return Locale(identifier: "en")
        }
    }
}

final class DateHelper {
    private let todayDateFormatter = DateFormatter().then {
        $0.dateStyle = .medium
        $0.timeStyle = .short
        $0.locale = Locale.current.localeFromIdentifier
        $0.setLocalizedDateFormatFromTemplate("hm")
    }
    
    private let lastWeekDateFormatter = DateFormatter().then {
        $0.dateStyle = .medium
        $0.timeStyle = .short
        $0.locale = Locale.current.localeFromIdentifier
        $0.setLocalizedDateFormatFromTemplate("EEEE")
    }
    
    private let normalDateFormatter = DateFormatter().then {
        $0.dateStyle = .medium
        $0.timeStyle = .short
        $0.locale = Locale.current.localeFromIdentifier
        $0.setLocalizedDateFormatFromTemplate("yyyy M d")
    }
    
    func string(from date: Date) -> String {
        let calendar = Calendar.current
        let lastWeekDay = calendar.date(byAdding: .day, value: -7, to: date)
        
        if calendar.isDateInToday(date) {
            return todayDateFormatter.string(from: date)
        } else if let lastWeekDay = lastWeekDay,
                  calendar.compare(date, to: lastWeekDay, toGranularity: .day) != .orderedAscending{
            return lastWeekDateFormatter.string(from: date)
        } else {
            return normalDateFormatter.string(from: date)
        }
    }
}
