//
//  HexMessagesBuilder.swift
//  AirCasting
//
//  Created by Lunar on 01/03/2021.
//

import Foundation

struct HexMessagesBuilder {
    
    struct TimeZoneHelper {
        func getTimezoneOffsetInHours() -> Int {
            let calendar = Calendar.current
            let timeZone = calendar.timeZone
            var offset = timeZone.secondsFromGMT()
            // We need to send *standard* offset, ignoring DST because AirBeam is calculating DST anyway
            if timeZone.isDaylightSavingTime() {
                offset -= Int(timeZone.daylightSavingTimeOffset())
            }
            let hoursOffset = Int(offset / 3600)
            return hoursOffset
        }
    }
    
    private var BEGIN_MESSAGE_CODE = UInt8(0xfe)
    private var END_MESSAGE_CODE = UInt8(0xff)
    private var BLUETOOTH_STREAMING_METHOD = UInt8(0x01)
    private var WIFI_CODE = UInt8(0x02)
    private var CELLULAR_CODE = UInt8(0x03)
    private var UUID_CODE = UInt8(0x04)
    private var AUTH_TOKEN_CODE = UInt8(0x05)
    private var LAT_LNG_CODE = UInt8(0x06)
    private var CURRENT_TIME_CODE = UInt8(0x08)
    private var SYNC_CODE = UInt8(0x09)
    private var CLEAR_SDCARD_CODE = UInt8(0x0a)

    var bluetoothConfigurationMessage: Data {
        Data([BEGIN_MESSAGE_CODE, BLUETOOTH_STREAMING_METHOD, END_MESSAGE_CODE])
    }
    var cellularconfigurationCode: Data {
        Data([BEGIN_MESSAGE_CODE, CELLULAR_CODE, END_MESSAGE_CODE])
    }
    
    var downloadFromSDCardModeRequest: Data {
        Data([BEGIN_MESSAGE_CODE, SYNC_CODE, END_MESSAGE_CODE])
    }
    
    var clearSDCardModeRequest: Data {
        Data([BEGIN_MESSAGE_CODE, CLEAR_SDCARD_CODE, END_MESSAGE_CODE])
    }
    
    func uuidMessage(uuid: SessionUUID) -> Data {
        return buildMessage(messageString: uuid.rawValue, configurationCode: UUID_CODE)
    }
    
    func authTokenMessage(authToken: String) -> Data? {
        let rawAuthToken = "\(authToken)"
        guard let encodedCredentials = rawAuthToken.data(using: .utf8)?.base64EncodedString() else {
            return nil
        }
        return buildMessage(messageString: encodedCredentials, configurationCode: AUTH_TOKEN_CODE)
    }
    
    func locationMessage(lat: Double, lng: Double) -> Data {
        let latLngString = "\(lng),\(lat)"
        // although You can think it is not right - it is: first lng then lat PLEASE
        return buildMessage(messageString: latLngString, configurationCode: LAT_LNG_CODE)
    }
    
    func currentTimeMessage(date: String) -> Data {
        return buildMessage(messageString: date, configurationCode: CURRENT_TIME_CODE)
    }
    
    func wifiConfigurationMessage(wifiSSID: String, wifiPassword: String) -> Data {
        let GMTOffset = TimeZoneHelper().getTimezoneOffsetInHours()
        let rawWifiConfigStr = wifiSSID + "," + wifiPassword + "," + "\(GMTOffset)"
        return buildMessage(messageString: rawWifiConfigStr, configurationCode: WIFI_CODE)
    }
    
    func buildMessage(messageString: String, configurationCode: UInt8) -> Data {
        let hexString = asciToHex(asciStr: messageString)
        let messageList = HexToByte(string: hexString, configurationCode: configurationCode)
        return messageList
    }
    
    func asciToHex(asciStr: String) -> String {
        var outputString = ""
        var hex = ""
        
        for character in asciStr {
            if let asci = character.asciiValue {
                hex = String(format: "%02hhx", asci)
            } else {
                let data = Data(character.utf8)
                hex = data.map{ String(format:"%02hhx", $0) }.joined()
            }
            outputString.append(hex)
        }
        return outputString
    }
    
    func HexToByte(string: String, configurationCode: UInt8) -> Data {
        var message = Data()
        message.append(BEGIN_MESSAGE_CODE)
        message.append(configurationCode)

        var i = 0
        while (i < string.count) {
            let i1 = string.index(string.startIndex, offsetBy: i)
            let i2 = string.index(string.startIndex, offsetBy: i + 1)
            
            let first = Int(string[i1...i1], radix: 16)! << 4
            let second = Int(string[i2...i2], radix: 16)!

            let byte = UInt8(first + second)
            
            message.append(byte)
            
            i += 2
        }
        message.append(END_MESSAGE_CODE)
        return message
    }
}
