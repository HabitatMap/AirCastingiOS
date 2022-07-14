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
            userSettings.twentyFourHour ? Self.pollutionChartDateFormatter24 : Self.pollutionChartDateFormatter12
        }
        
        var utcDateIntervalFormatter: DateIntervalFormatter {
            userSettings.twentyFourHour ? Self.utcDateIntervalFormatter24 : Self.utcDateIntervalFormatter12
        }
        
        static let pollutionChartDateFormatter24: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "HH:mm"
            df.timeZone = TimeZone(abbreviation: "UTC")
            return df
        }()
        
        static let pollutionChartDateFormatter12: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "h:mm a"
            df.timeZone = TimeZone(abbreviation: "UTC")
            return df
        }()
        
        static let utcDateIntervalFormatter24: DateIntervalFormatter = {
            let df = DateIntervalFormatter()
            df.dateTemplate = "MM/dd/yy HH:mm"
            df.timeZone = TimeZone(abbreviation: "UTC")
            df.locale = Locale(identifier: "en_US_POSIX")
            return df
        }()
        
        static let utcDateIntervalFormatter12: DateIntervalFormatter = {
            let df = DateIntervalFormatter()
            df.dateTemplate = "MM/dd/yy h:mm a"
            df.timeZone = TimeZone(abbreviation: "UTC")
            df.locale = Locale(identifier: "en_US_POSIX")
            return df
        }()
    }
    
    struct TimeAxisRenderer {
        @InjectedObject private var userSettings: UserSettings
        static let shared = TimeAxisRenderer()
        
        private init() { }
        
        var shortUTCDateFormatter: DateFormatter {
            userSettings.twentyFourHour ? Self.shortUTCDateFormatter24 : Self.shortUTCDateFormatter12
        }
        
        static let shortUTCDateFormatter12: DateFormatter = {
            let df = DateFormatter()
            df.timeZone =  TimeZone.init(abbreviation: "UTC")
            df.locale = Locale(identifier: "en_US")
            df.dateFormat = "h:mm a"
            return df
        }()
        
        static let shortUTCDateFormatter24: DateFormatter = {
            let df = DateFormatter()
            df.timeZone =  TimeZone.init(abbreviation: "UTC")
            df.locale = Locale(identifier: "en_US")
            df.dateFormat = "HH:mm"
            return df
        }()
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


