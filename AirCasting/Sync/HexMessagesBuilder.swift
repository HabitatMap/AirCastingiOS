//
//  HexMessagesBuilder.swift
//  AirCasting
//
//  Created by Lunar on 01/03/2021.
//

import Foundation

struct HexMessegasBuilder {
    
    private var BEGIN_MESSAGE_CODE = UInt8(0xfe)
    private var END_MESSAGE_CODE = UInt8(0xff)
    private var BLUETOOTH_STREAMING_METHOD = UInt8(0x01)
    private var WIFI_CODE = UInt8(0x02)
    private var CELLULAR_CODE = UInt8(0x03)
    private var UUID_CODE = UInt8(0x04)
    private var AUTH_TOKEN_CODE = UInt8(0x05)
    private var LAT_LNG_CODE = UInt8(0x06)
    private var CURRENT_TIME_CODE = UInt8(0x07)
    private var SYNC_CODE = UInt8(0x08)
    private var CLEAR_SDCARD_CODE = UInt8(0x0a)

    lazy var bluetoothConfigurationMessage: UInt8 = BEGIN_MESSAGE_CODE + BLUETOOTH_STREAMING_METHOD + END_MESSAGE_CODE
    lazy var cellularconfigurationCode: UInt8 = BEGIN_MESSAGE_CODE + CELLULAR_CODE + END_MESSAGE_CODE
    
    
    func buildMessage(messageString: String, configurationCode: String) {

    }
    
    func asciToHex(asciStr: String) -> String {
        var outputString = ""
        
        for character in asciStr {
            let asci = character.asciiValue
            let hex = String(format: "%02hhx", asci!)
            outputString.append(hex)
        }
        return outputString
    }
    
    func stringToByte(string: String, configurationCode: UInt8) -> Data {
        var message = Data()
        message.append(BEGIN_MESSAGE_CODE)
        message.append(configurationCode)

        var i = 0
        while (i < string.count) {
            let i1 = string.index(string.startIndex, offsetBy: i)
            let i2 = string.index(string.startIndex, offsetBy: i + 1)
            
            let first = Int(string[i1...i1], radix: 16)! << 4
            // let first = Character.digit(s[i], 16) shl 4)
            let second = Int(string[i2...i2], radix: 16)!
            //let second = Character.digit(s[i + 1], 16)
            let byte = UInt8(first + second)
            //let byte = (first + second).toByte()
            
            message.append(byte)
            
            i += 2
        }
        message.append(END_MESSAGE_CODE)
        return message
    }
}
