//
//  CreateSessionView.swift
//  AirCasting
//
//  Created by Lunar on 05/02/2021.
//

import SwiftUI
import AirCastingStyling
import Resolver

struct ChooseSessionTypeView: View {
    @EnvironmentObject private var tabSelection: TabBarSelection
    @EnvironmentObject private var emptyDashboardButtonTapped: EmptyDashboardButtonTapped
    @EnvironmentObject private var finishAndSyncButtonTapped: FinishAndSyncButtonTapped
    @StateObject var viewModel: ChooseSessionTypeViewModel
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel
    
    var shouldGoToChooseSessionScreen: Bool {
        (tabSelection.selection == .createSession && emptyDashboardButtonTapped.mobileWasTapped) ? true : false
    }
    var shouldGoToSyncScreen: Bool {
        (tabSelection.selection == .createSession && finishAndSyncButtonTapped.finishAndSyncButtonWasTapped) ? true : false
    }
    
    init(sessionContext: CreateSessionContext) {
        self._viewModel = .init(wrappedValue: .init(sessionContext: sessionContext))
    }
    
    var body: some View {
        if #available(iOS 15, *) {
            NavigationView {
                mainContent
                    .fullScreenCover(isPresented: .init(get: {
                        viewModel.isPowerABLinkActive
                    }, set: { new in
                        viewModel.setPowerABLink(using: new)
                    })) {
                        CreatingSessionFlowRootView {
                            PowerABView(creatingSessionFlowContinues: .init(get: {
                                viewModel.isPowerABLinkActive
                            }, set: { new in
                                viewModel.setPowerABLink(using: new)
                            }))
                        }
                    }
                
                    .fullScreenCover(isPresented: .init(get: {
                        viewModel.isTurnLocationOnLinkActive
                    }, set: { new in
                        viewModel.setLocationLink(using: new)
                    })) {
                        CreatingSessionFlowRootView {
                            TurnOnLocationView(creatingSessionFlowContinues: .init(get: {
                                viewModel.isTurnLocationOnLinkActive
                            }, set: { new in
                                viewModel.setLocationLink(using: new)
                            }),
                                               viewModel: TurnOnLocationViewModel(sessionContext: viewModel.passSessionContext,
                                                                                  isSDClearProcess: false))
                        }
                    }
                
                    .fullScreenCover(isPresented: .init(get: {
                        viewModel.isTurnBluetoothOnLinkActive
                    }, set: { new in
                        viewModel.setBluetoothLink(using: new)
                    })) {
                        CreatingSessionFlowRootView {
                            TurnOnBluetoothView(creatingSessionFlowContinues: .init(get: {
                                viewModel.isTurnBluetoothOnLinkActive
                            }, set: { new in
                                viewModel.setBluetoothLink(using: new)
                            }),
                                                sdSyncContinues: .constant(false))
                        }
                    }
                
                    .fullScreenCover(isPresented: .init(get: {
                        viewModel.isMobileLinkActive
                    }, set: { new in
                        viewModel.setMobileLink(using: new)
                    })) {
                        CreatingSessionFlowRootView {
                            SelectDeviceView(creatingSessionFlowContinues: .init(get: {
                                viewModel.isMobileLinkActive
                            }, set: { new in
                                viewModel.setMobileLink(using: new)
                            }),
                                             sdSyncContinues: .constant(false))
                        }
                    }
                
                    .fullScreenCover(isPresented: .init(get: {
                        viewModel.startSync
                    }, set: { new in
                        viewModel.setStartSync(using: new)
                    })) {
                        CreatingSessionFlowRootView {
                            SDSyncRootView(creatingSessionFlowContinues: .init(get: {
                                viewModel.startSync
                            }, set: { new in
                                viewModel.setStartSync(using: new)
                            }))
                        }
                    }
                    .onAppear { defineNextMove() }
                    .onChange(of: tabSelection.selection, perform: { _ in defineNextMove() })
            }
            .environmentObject(viewModel.passSessionContext)
        } else {
            NavigationView {
                mainContent
                    .background(
                        Group {
                            EmptyView()
                                .fullScreenCover(isPresented: .init(get: {
                                    viewModel.isPowerABLinkActive
                                }, set: { new in
                                    viewModel.setPowerABLink(using: new)
                                })) {
                                    CreatingSessionFlowRootView {
                                        PowerABView(creatingSessionFlowContinues: .init(get: {
                                            viewModel.isPowerABLinkActive
                                        }, set: { new in
                                            viewModel.setPowerABLink(using: new)
                                        }))
                                    }
                                }
                            EmptyView()
                                .fullScreenCover(isPresented: .init(get: {
                                    viewModel.isTurnLocationOnLinkActive
                                }, set: { new in
                                    viewModel.setLocationLink(using: new)
                                })) {
                                    CreatingSessionFlowRootView {
                                        TurnOnLocationView(creatingSessionFlowContinues: .init(get: {
                                            viewModel.isTurnLocationOnLinkActive
                                        }, set: { new in
                                            viewModel.setLocationLink(using: new)
                                        }),
                                                           viewModel: TurnOnLocationViewModel(sessionContext: viewModel.passSessionContext,
                                                                                              isSDClearProcess: false))
                                    }
                                }
                            EmptyView()
                                .fullScreenCover(isPresented: .init(get: {
                                    viewModel.isTurnBluetoothOnLinkActive
                                }, set: { new in
                                    viewModel.setBluetoothLink(using: new)
                                })) {
                                    CreatingSessionFlowRootView {
                                        TurnOnBluetoothView(creatingSessionFlowContinues: .init(get: {
                                            viewModel.isTurnBluetoothOnLinkActive
                                        }, set: { new in
                                            viewModel.setBluetoothLink(using: new)
                                        }),
                                                            sdSyncContinues: .constant(false))
                                    }
                                }
                            EmptyView()
                                .fullScreenCover(isPresented: .init(get: {
                                    viewModel.isMobileLinkActive
                                }, set: { new in
                                    viewModel.setMobileLink(using: new)
                                })) {
                                    CreatingSessionFlowRootView {
                                        SelectDeviceView(creatingSessionFlowContinues: .init(get: {
                                            viewModel.isMobileLinkActive
                                        }, set: { new in
                                            viewModel.setMobileLink(using: new)
                                        }),
                                                         sdSyncContinues: .constant(false))
                                    }
                                }
                            EmptyView()
                                .fullScreenCover(isPresented: .init(get: {
                                    viewModel.startSync
                                }, set: { new in
                                    viewModel.setStartSync(using: new)
                                })) {
                                    CreatingSessionFlowRootView {
                                        SDSyncRootView(creatingSessionFlowContinues: .init(get: {
                                            viewModel.startSync
                                        }, set: { new in
                                            viewModel.setStartSync(using: new)
                                        }))
                                    }
                                }
                                .onAppear { defineNextMove() }
                                .onChange(of: tabSelection.selection, perform: { _ in defineNextMove() })
                        }
                    )
            }
            .environmentObject(viewModel.passSessionContext)
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 50) {
            VStack(alignment: .leading, spacing: 10) {
                titleLabel
                messageLabel
            }
            .background(Color.white)
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    recordNewLabel
                    Spacer()
                    moreInfo
                }
                HStack {
                    fixedSessionButton
                    Spacer()
                    mobileSessionButton
                }
                Spacer()
                if featureFlagsViewModel.enabledFeatures.contains(.sdCardSync) {
                    orLabel
                    sdSyncButton
                }
                Spacer()
            }
            .padding([.bottom, .vertical])
            .padding(.horizontal, 30)
            .background(
                Color.aircastingBackground.opacity(0.25)
                    .ignoresSafeArea()
            )
            .alert(item: $viewModel.alert, content: { $0.makeAlert() })
        }
    }
}

// MARK: - Private View Functions
private extension ChooseSessionTypeView {
    func defineNextMove() {
        shouldGoToChooseSessionScreen ? (viewModel.handleMobileSessionState()) : (viewModel.isMobileLinkActive = false)
        viewModel.setStartSync(using: shouldGoToSyncScreen)
    }
}

// MARK: - Private View Components
private extension ChooseSessionTypeView {
    var titleLabel: some View {
        Text(Strings.ChooseSessionTypeView.title)
            .font(Fonts.boldTitle1)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.ChooseSessionTypeView.message)
            .font(Fonts.regularHeading1)
            .foregroundColor(.aircastingGray)
    }
    
    var recordNewLabel: some View {
        Text(Strings.ChooseSessionTypeView.recordNew)
            .font(Fonts.boldHeading3)
            .foregroundColor(.aircastingDarkGray)
    }
    
    var orLabel: some View {
        Text(Strings.ChooseSessionTypeView.orLabel)
            .font(Fonts.boldHeading3)
            .foregroundColor(.aircastingDarkGray)
    }
    
    var moreInfoLabel: some View {
        Text(Strings.ChooseSessionTypeView.moreInfo)
            .font(Fonts.regularHeading3)
            .foregroundColor(.accentColor)
    }
    
    var moreInfo: some View {
        Button(action: {
            viewModel.infoButtonTapped()
        }, label: {
            moreInfoLabel
        })
            .sheet(isPresented: .init(get: {
                viewModel.isInfoPresented
            }, set: { new in
                viewModel.setInfoPresented(using: new)
            }), content: {
                MoreInfoPopupView()
            })
    }
    
    var fixedSessionButton: some View {
        Button(action: {
            viewModel.fixedSessionButtonTapped()
        }) {
            fixedSessionLabel
        }
    }
    
    var mobileSessionButton: some View {
        Button(action: {
            viewModel.mobileSessionButtonTapped()
        }) {
            mobileSessionLabel
        }
    }
    
    var sdSyncButton: some View {
        Button(action: {
            viewModel.syncButtonTapped()
        }) {
            syncButtonLabel
        }
    }
    
    var fixedSessionLabel: some View {
        chooseSessionButton(title: Strings.ChooseSessionTypeView.fixedLabel_1,
                            description: Strings.ChooseSessionTypeView.fixedLabel_2)
    }
    
    var mobileSessionLabel: some View {
        chooseSessionButton(title: Strings.ChooseSessionTypeView.mobileLabel_1,
                            description: Strings.ChooseSessionTypeView.mobileLabel_2)
    }
    
    var syncButtonLabel: some View {
        chooseSessionButton(title: Strings.ChooseSessionTypeView.syncTitle,
                            description: Strings.ChooseSessionTypeView.syncDescription)
    }
}

extension View {
    func chooseSessionButton(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Fonts.boldHeading1)
                .foregroundColor(.accentColor)
            Text(description)
                .font(Fonts.muliHeading3)
                .foregroundColor(.aircastingGray)
        }
        .multilineTextAlignment(.leading)
        .padding(15)
        .frame(minWidth: (UIScreen.main.bounds.width / 2.5) < 147 ? (UIScreen.main.bounds.width / 2.5) : 147,
               maxWidth: 147,
               minHeight: (UIScreen.main.bounds.height) / 4.5 < 145 ? (UIScreen.main.bounds.height) : 145,
               maxHeight: 145,
               alignment: .leading)
        .background(Color.white)
        .shadow(color: Color.shadow, radius: 9, x: 0, y: 1)
    }
}
