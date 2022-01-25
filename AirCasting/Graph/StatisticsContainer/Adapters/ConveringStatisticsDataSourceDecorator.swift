// Created by Lunar on 25/01/2022.
//

import Combine

class ConveringStatisticsDataSourceDecorator<D: MeasurementsStatisticsDataSource>: MeasurementsStatisticsDataSource, ObservableObject {
    let dataSource: D
    var stream: MeasurementStreamEntity?
    private let settings: UserSettings
    private var cancellables: [AnyCancellable] = []
    
    init(dataSource: D, stream: MeasurementStreamEntity?, settings: UserSettings) {
        self.dataSource = dataSource
        self.stream = stream
        self.settings = settings
    }
    
    var onForceReload: (() -> Void)? {
        set { dataSource.onForceReload = newValue }
        get { dataSource.onForceReload }
    }
    
    var visibleMeasurements: [MeasurementStatistics.Measurement] { dataSource.visibleMeasurements.map(convert) }
    var allMeasurements: [MeasurementStatistics.Measurement] { dataSource.allMeasurements.map(convert) }
    
    private func setupHooks() {
        settings.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
            self?.onForceReload?()
        }.store(in: &cancellables)
    }
    
    private func convert(_ measurement: MeasurementStatistics.Measurement) -> MeasurementStatistics.Measurement {
        guard settings.convertToCelsius, (stream?.isTemperature ?? false) else { return measurement }
        let convertedValue = TemperatureConverter.calculateCelsius(fahrenheit: measurement.value)
        return .init(measurementTime: measurement.measurementTime, value: convertedValue)
    }
}
