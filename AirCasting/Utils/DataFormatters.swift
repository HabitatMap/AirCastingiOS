// Created by Lunar on 30/09/2021.
//

import Foundation

enum DateFormatters {
    
    enum SessionDownloadService {
        static let decoderDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.timeZone = TimeZone.init(abbreviation: "UTC")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            return df
        }()
    }
    
    enum SessionUploadService {
        static let encoderDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.timeZone = TimeZone.init(abbreviation: "UTC")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            return df
        }()
    }
    
    enum CreateSessionAPIService {
        static let encoderDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            return df
        }()
    }
    
    enum AirBeam3Configurator {
        static let usLocaleFullDateDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            df.locale = Locale(identifier: "en_US_POSIX")
            return df
        }()
    }
    
    enum SessionCartView {
        static let pollutionChartDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "HH:mm"
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
        
        static let mobileActiveDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "HH:mm"
            df.timeZone = TimeZone.init(abbreviation: "UTC")
            df.locale = Locale(identifier: "en_US")
            return df
        }()
    }
    
    enum TimeAxisRenderer {
        static let shortUSLocaleDateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.timeStyle = .short
            df.locale = Locale(identifier: "en_US")
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
}


