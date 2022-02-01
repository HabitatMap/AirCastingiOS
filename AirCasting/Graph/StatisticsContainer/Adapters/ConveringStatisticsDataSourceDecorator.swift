// Created by Lunar on 25/01/2022.
//

import Combine
import Resolver

class ConveringStatisticsDataSourceDecorator<D: MeasurementsStatisticsDataSource>: MeasurementsStatisticsDataSource, ObservableObject {
    let dataSource: D
    var stream: MeasurementStreamEntity?
    @Injected private var settings: UserSettings
    private var cancellables: [AnyCancellable] = []
    
    init(dataSource: D, stream: MeasurementStreamEntity?) {
        self.dataSource = dataSource
        self.stream = stream
        setupHooks()
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
