//
//  RootAppView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI
import Firebase

struct RootAppView: View {
    
    let persistenceController = PersistenceController.shared
    @ObservedObject var bluetoothManager = BluetoothManager()
    @AppStorage(UserDefaults.AUTH_TOKEN_KEY) var authToken: String?
    var isLoggedIn: Bool { authToken != nil }
    @Environment(\.managedObjectContext) var context
    
    /////
    @State private var sink: Any?
    var mesurmentStreamTimer = Timer.publish(every: 60.0,
                                             on: .current,
                                             in: .common).autoconnect()
    
    ////
    
    var body: some View {
        if isLoggedIn {
            mainAppView
        } else {
            NavigationView {
                SignInView()
            }
        }
    }
    
    var mainAppView: some View {
        MainTabBarView()
            .onAppear {
                if FirebaseApp.app() == nil {
                    FirebaseApp.configure()
                }
                
                
                
                let uuid = UUID(uuidString: "fcb242f0-fdba-4c9b-943e-51adff1aebac")!
                let syncDate = Date().addingTimeInterval(-8000)
                sink = FixedSession
                    .getFixedMeasurement(uuid: uuid,
                                         lastSync: syncDate)
                    .sink { (completion) in
                        switch completion {
                        case .finished:
                            print("sucess")
                        case .failure(let error):
                            print("ERROR: \(error)")
                        }
                    } receiveValue: { (fixedMeasurementOutput) in
                        
                        let session = Session(context: context)
                        let dateFormatter = ISO8601DateFormatter()
                        session.uuid = fixedMeasurementOutput.uuid
                        session.type = SessionType.from(string: fixedMeasurementOutput.type)?.rawValue ?? -1
                        
                        session.name = fixedMeasurementOutput.title
                        session.tags  = fixedMeasurementOutput.tag_list
                        session.startTime  = dateFormatter.date(from: fixedMeasurementOutput.start_time)
                        session.endTime  = dateFormatter.date(from: fixedMeasurementOutput.end_time)
                        session.version = Int16(fixedMeasurementOutput.version)
                        
                        for (_, streamOutput) in fixedMeasurementOutput.streams {
                            let stream = MeasurementStream(context: context)
                            stream.sensorName = streamOutput.sensor_name
                            stream.sensorPackageName = streamOutput.sensor_package_name
                            stream.measurementType = streamOutput.measurement_type
                            stream.measurementShortType = streamOutput.measurement_short_type
                            stream.unitName = streamOutput.unit_name
                            stream.unitSymbol = streamOutput.unit_symbol
                            stream.thresholdVeryLow = Int32(streamOutput.threshold_very_low)
                            stream.thresholdLow = Int32(streamOutput.threshold_low)
                            stream.thresholdMedium = Int32(streamOutput.threshold_medium)
                            stream.thresholdHigh = Int32(streamOutput.threshold_high)
                            stream.thresholdVeryHigh = Int32(streamOutput.threshold_very_high)
                            stream.gotDeleted = streamOutput.deleted ?? false
                            
                            //                            // Save starting thresholds
                            //                            let thresholds = SensorThreshold(context: context)
                            //                            thresholds.sensorName = streamOutput.sensor_name
                            //                            thresholds.thresholdVeryLow = Int32(streamOutput.threshold_very_low)
                            //                            thresholds.thresholdLow = Int32(streamOutput.threshold_low)
                            //                            thresholds.thresholdMedium = Int32(streamOutput.threshold_medium)
                            //                            thresholds.thresholdHigh = Int32(streamOutput.threshold_high)
                            //                            thresholds.thresholdVeryHigh = Int32(streamOutput.threshold_very_high)
                            
                            for measurement in streamOutput.measurements {
                                let newMeasaurement = Measurement(context: context)
                                newMeasaurement.value = Double(measurement.measured_value)
                                newMeasaurement.latitude = Double(measurement.latitude)
                                newMeasaurement.longitude = Double(measurement.longitude)
                                newMeasaurement.time = dateFormatter.date(from: measurement.time)
                            }
                            session.addToMeasurementStreams(stream)
                        }
                        
                        
                        
                        print("Output: \(fixedMeasurementOutput)")
                    }
            }
            .environmentObject(bluetoothManager)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
}

struct RootAppView_Previews: PreviewProvider {
    static var previews: some View {
        RootAppView()
    }
}
