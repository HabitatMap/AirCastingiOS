import SwiftUI
import Resolver

struct ExternalGraphView<StatsViewModelType>: View where StatsViewModelType: StatisticsContainerViewModelable {
    let session: ExternalSessionEntity
    let thresholds: ABMeasurementsViewThreshold
    @Binding var selectedStream: MeasurementStreamEntity?
    @StateObject var statsContainerViewModel: StatsViewModelType
    let graphStatsDataSource: GraphStatsDataSource
    
    var body: some View {
        VStack(alignment: .trailing) {
            ExternalSessionHeader(session: session, thresholds: thresholds, selectedStream: $selectedStream, isCollapsed: .constant(false), expandingAction: nil)
                .padding([.bottom, .leading, .trailing])
            if isProceeding(session: session) {
                if let threshold = thresholds.value.threshold(for: selectedStream?.sensorName ?? "") {
                    let formatter = Resolver.resolve(ThresholdFormatter.self, args: threshold)
                    if let selectedStream = selectedStream {
                        ZStack(alignment: .topLeading) {
                            ExternalGraph(stream: selectedStream,
                                          thresholds: threshold,
                                          isAutozoomEnabled: false)
                            .onDateRangeChange { [weak graphStatsDataSource, weak statsContainerViewModel] range in
                                graphStatsDataSource?.dateRange = range
                                statsContainerViewModel?.adjustForNewData()
                            }
                            StatisticsContainerView(statsContainerViewModel: statsContainerViewModel,
                                                    threshold: threshold)
                        }
                        NavigationLink(destination: ThresholdsSettingsView(thresholdValues: formatter.formattedBinding(),
                                                                           initialThresholds: selectedStream.thresholds,
                                                                           threshold: threshold)) {
                            EditButtonView()
                                .padding([.horizontal, .top])
                        }
                    }
                    ThresholdsSliderView(threshold: threshold)
                        .padding()
                    // Fixes labels covered by tabbar
                        .padding(.bottom)
                }
            }
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.aircastingBackground.ignoresSafeArea())
    }
    
    func isProceeding(session: ExternalSessionEntity) -> Bool {
        return session.allStreams.allSatisfy({ stream in
            !(stream.allMeasurements?.isEmpty ?? true)
        })
    }
}
