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
    /// ex) 13시 56분
    private let todayDateFormatter = DateFormatter().then {
        $0.dateStyle = .medium
        $0.timeStyle = .short
        $0.locale = Locale.current.localeFromIdentifier
        $0.setLocalizedDateFormatFromTemplate("hm")
    }
    
    /// 현재 시각을 기준으로 당일을 제외한 7일 이내; ex) 수요일
    private let lastWeekDateFormatter = DateFormatter().then {
        $0.dateStyle = .medium
        $0.timeStyle = .short
        $0.locale = Locale.current.localeFromIdentifier
        $0.setLocalizedDateFormatFromTemplate("EEEE")
    }
    
    /// 현재 시각을 기준으로 7일 이후; ex) 2021.11.18
    private let normalDateFormatter = DateFormatter().then {
        $0.dateStyle = .medium
        $0.timeStyle = .short
        $0.locale = Locale.current.localeFromIdentifier
        $0.setLocalizedDateFormatFromTemplate("yyyy M d")
    }
    
    func string(from date: Date) -> String {
        let calendar = Calendar.current
        let lastWeekDay = calendar.date(byAdding: .day, value: -7, to: Date.now)
        
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
