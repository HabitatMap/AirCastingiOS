// Created by Lunar on 17/08/2022.
//

import Resolver
import Foundation

class MicrophoneManualCalibrationViewModel: ObservableObject {
    @Published var text: String {
        didSet { okButtonEnabled = (Double(text) != nil) }
    }
    @Published var okButtonEnabled: Bool = true
    
    private var writer: MicrophoneCalibrationValueWritable
    private let reader: MicrophoneCalibraionValueProvider
    private let exitRoute: () -> Void
    
    init(exitRoute: @escaping () -> Void) {
        self.reader = Resolver.resolve()
        self.writer = Resolver.resolve()
        self.text = "\(Int(abs(reader.zeroLevelAdjustment)))"
        self.exitRoute = exitRoute
    }
    
    func okTapped() {
        guard let doubleValue = Double(text) else { return }
        Log.info("Setting new mic adjustment level: \(doubleValue)")
        writer.zeroLevelAdjustment = doubleValue
        exitRoute()
    }
    
    func cancelTapped() {
        exitRoute()
    }
}
