// Created by Lunar on 26/05/2021.
//

//import SwiftUI
//
//struct ChartCreator: View {
//    
//    let session: SessionEntity
//    @ObservedObject var stream: MeasurementStreamEntity
//    @ObservedObject var thresholds: SensorThreshold
//    
//    var body: some View {
//        drawPollutionChart()
//    }
//    
//    func drawPollutionChart() -> some View {
//        let entries =  ChartEntriesCreator(session: session, stream: stream).generateEntries()
//        return ChartView(entries: entries, thresholds: thresholds)
//            .frame(height: 200)
////            .background(Color.random)
//    }
//}

//struct ChartCreator_Previews: PreviewProvider {
//    static var previews: some View {
//        ChartCreator(stream: .mock)
//    }
//}
