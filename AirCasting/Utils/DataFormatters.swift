// Created by Lunar on 30/09/2021.
//

import Foundation

enum DateFormatters {
    
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
    
    enum SessionCartView {
        static let pollutionChartDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "HH:mm"
            df.timeZone = TimeZone(abbreviation: "UTC")
            return df
        }()
        
        static let utcDateIntervalFormatter: DateIntervalFormatter = {
            let df = DateIntervalFormatter()
            df.dateTemplate = "MM/dd/yy HH:mm"
            df.timeZone = TimeZone(abbreviation: "UTC")
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
    
    enum TimeAxisRenderer {
        static let shortUTCDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.timeZone =  TimeZone.init(abbreviation: "UTC")
            df.locale = Locale(identifier: "en_US")
            df.dateFormat = "HH:mm"
            return df
        }()
    }
    
    enum DateExtension {
        static let milisecondsDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "SSS"
            return df
        }()
        
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
            dateFormatter.dateFormat = "MM/dd/yyy'T'HH:mm:ss"
            return dateFormatter
        }()
    }
}


