// Created by Lunar on 30/09/2021.
//

import Foundation
import Resolver

enum DateFormatters {
    
    struct SessionCardView {
        @InjectedObject private var userSettings: UserSettings
        static let shared = SessionCardView()
        
        private init() { }
        
        var pollutionChartDateFormatter: DateFormatter {
            let df = DateFormatter()
            if userSettings.twentyFourHour { df.dateFormat = "HH:mm" } else { df.dateFormat = "h:mm a" }
            df.timeZone = TimeZone(abbreviation: "UTC")
            return df
        }
        
        var utcDateIntervalFormatter: DateIntervalFormatter {
            let df = DateIntervalFormatter()
            if userSettings.twentyFourHour {
                df.dateTemplate = "MM/dd/yy HH:mm"
            } else {
                df.dateTemplate = "MM/dd/yy h:mm a"
            }
            df.timeZone = TimeZone(abbreviation: "UTC")
            df.locale = Locale(identifier: "en_US_POSIX")
            return df
        }
    }
    
    struct TimeAxisRenderer {
        @InjectedObject private var userSettings: UserSettings
        static let shared = TimeAxisRenderer()
        
        var shortUTCDateFormatter: DateFormatter {
            let df = DateFormatter()
            df.timeZone =  TimeZone.init(abbreviation: "UTC")
            df.locale = Locale(identifier: "en_US")
            if userSettings.twentyFourHour { df.dateFormat = "HH:mm" } else { df.dateFormat = "h:mm a" }
            return df
        }
    }
    
    enum SessionDownloadService {
        static let decoderDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.timeZone = TimeZone(abbreviation: "UTC")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            return df
        }()
    }
    
    enum SessionUploadService {
        static let encoderDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.timeZone = TimeZone(abbreviation: "UTC")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            return df
        }()
    }
    
    enum CreateSessionAPIService {
        static let encoderDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.timeZone = TimeZone(abbreviation: "UTC")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            return df
        }()
    }
    
    enum AirBeam3Configurator {
        static let usLocaleFullDateDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.timeZone = TimeZone(abbreviation: "UTC")
            df.dateFormat = "dd/MM/yy-HH:mm:ss"
            df.locale = Locale(identifier: "en_US_POSIX")
            return df
        }()
    }
    
    enum GraphView {
        static let usLocalTimeDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "HH:mm"
            df.locale = Locale(identifier: "en_US")
            return df
        }()
        
        static let UTCDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "HH:mm"
            df.locale = Locale(identifier: "en_US")
            df.timeZone = TimeZone(abbreviation: "UTC")
            return df
        }()
    }
    
    enum DateExtension {
        static let currentTimeZoneDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.timeZone = TimeZone.current
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return df
        }()
        
        static let utcTimeZoneDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.timeZone = TimeZone.init(abbreviation: "UTC")
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return df
        }()
    }
    
    enum SDCardSync {
        static let fileParserFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "MM/dd/yyyy'T'HH:mm:ss"
            return dateFormatter
        }()
    }
    
    enum Debug {
        static let logsFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return df
        }()
    }
    
    enum SearchAndFollow {
        static let timeFormatter: DateFormatter = {
            let df = DateFormatter()
            df.timeZone =  TimeZone.init(abbreviation: "UTC")
            df.locale = Locale(identifier: "en_US")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            return df
        }()
    }
}


