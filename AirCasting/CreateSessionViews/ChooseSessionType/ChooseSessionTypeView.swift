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
    @EnvironmentObject private var exploreSessionsButton: ExploreSessionsButton
    @StateObject var viewModel: ChooseSessionTypeViewModel
    @State private var buttonHeight = CGFloat.zero
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel
    
    var shouldShowSDSyncButton: Bool {
        featureFlagsViewModel.enabledFeatures.contains(.sdCardSync)
    }
    
    var shouldShowFollowSessionButton: Bool {
        featureFlagsViewModel.enabledFeatures.contains(.searchAndFollow)
    }
    
    var shouldGoToChooseSessionScreen: Bool {
        (tabSelection.selection == .createSession && emptyDashboardButtonTapped.mobileWasTapped) ? true : false
    }
    var shouldGoToSyncScreen: Bool {
        (tabSelection.selection == .createSession && finishAndSyncButtonTapped.finishAndSyncButtonWasTapped) ? true : false
    }
    
    var shouldGotToSearchScreen: Bool {
        (tabSelection.selection == .createSession && exploreSessionsButton.exploreSessionsButtonTapped) ? true : false
    }
    
    init(sessionContext: CreateSessionContext) {
        self._viewModel = .init(wrappedValue: .init(sessionContext: sessionContext))
    }
    
    var body: some View {
        if #available(iOS 15, *) {
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
                    viewModel.isSearchAndFollowLinkActive
                }, set: { new in
                    viewModel.setSearchAndFollow(using: new)
                })) {
                    CreatingSessionFlowRootView {
                        SearchView(isSearchAndFollowLinkActive: .init(get: {
                            viewModel.isSearchAndFollowLinkActive
                        }, set: { new in
                            viewModel.setSearchAndFollow(using: new)
                        }))
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
                .environmentObject(viewModel.passSessionContext)
        } else {
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
                        EmptyView()
                            .fullScreenCover(isPresented: .init(get: {
                                viewModel.isSearchAndFollowLinkActive
                            }, set: { new in
                                viewModel.setSearchAndFollow(using: new)
                            })) {
                                CreatingSessionFlowRootView {
                                    SearchView(isSearchAndFollowLinkActive: .init(get: {
                                        viewModel.isSearchAndFollowLinkActive
                                    }, set: { new in
                                        viewModel.setSearchAndFollow(using: new)
                                    }))
                                }
                            }
                    }
                )
                .onAppear { defineNextMove() }
                .onChange(of: tabSelection.selection, perform: { _ in defineNextMove() })
                .environmentObject(viewModel.passSessionContext)
        }
    }
    
    private var mainContent: some View {
        GeometryReader { geometry in
            // Minimum height is based on the iPhone SE (1st gen) screen size
            // which is currently the smallest supported screen size.
            let minimalRequiredHeight = 499.0
            let height = geometry.frame(in: .local).height
            let additionalSpace = max(height - minimalRequiredHeight, 0)
            let spacerHeight = min(additionalSpace / 2.0, 60)
            
            VStack() {
                Spacer().frame(height: spacerHeight)
                VStack(alignment: .leading, spacing: 10) {
                    titleLabel
                    messageLabel
                }
                .padding(.horizontal)
                Spacer().frame(height: spacerHeight)
                VStack(alignment: .leading, spacing: 15) {
                    let horizontalSpacerRatio = 17.0
                    HStack {
                        recordNewLabel
                        Spacer()
                        moreInfo
                    }
                    HStack {
                        fixedSessionButton
                        Spacer(minLength: geometry.size.width / horizontalSpacerRatio)
                        mobileSessionButton
                    }
                    let leftoverSpace = (additionalSpace - (spacerHeight * 2))
                    let innerSpacerHeight = min(leftoverSpace / 2, 25.0)
                    Spacer().frame(height: innerSpacerHeight)
                    if featureFlagsViewModel.enabledFeatures.contains(.sdCardSync) || featureFlagsViewModel.enabledFeatures.contains(.searchAndFollow) {
                        orLabel
                    }
                    HStack {
                        switch (shouldShowSDSyncButton, shouldShowFollowSessionButton) {
                        case (false, true):
                            shouldShowFollowSessionButton ? AnyView(followSessionButton) : AnyView(Color.clear)
                            Spacer(minLength: geometry.size.width / horizontalSpacerRatio)
                            shouldShowSDSyncButton ? AnyView(sdSyncButton) : AnyView(Color.clear)
                        default:
                            shouldShowSDSyncButton ? AnyView(sdSyncButton) : AnyView(Color.clear)
                            Spacer(minLength: geometry.size.width / horizontalSpacerRatio)
                            shouldShowFollowSessionButton ? AnyView(followSessionButton) : AnyView(Color.clear)
                        }
                    }
                    Spacer().frame(height: innerSpacerHeight)
                }
                .padding([.bottom, .vertical])
                .padding(.horizontal, 30)
                .background(Color.aircastingSecondaryBackground.ignoresSafeArea())
                .alert(item: $viewModel.alert, content: { $0.makeAlert() })
            }
            .onPreferenceChange(ViewHeightKey.self) {
                self.buttonHeight = $0
            }
            .background(Color.aircastingBackground.ignoresSafeArea())
        }
    }
}

// MARK: - Private View Functions
private extension ChooseSessionTypeView {
    func defineNextMove() {
        shouldGoToChooseSessionScreen ? (viewModel.handleMobileSessionState()) : (viewModel.isMobileLinkActive = false)
        viewModel.setStartSync(using: shouldGoToSyncScreen)
        viewModel.setSearchAndFollow(using: shouldGotToSearchScreen)
    }
}

// MARK: - Private View Components
private extension ChooseSessionTypeView {
    var titleLabel: some View {
        Text(Strings.ChooseSessionTypeView.title)
            .font(Fonts.moderateBoldTitle1)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.ChooseSessionTypeView.message)
            .font(Fonts.moderateRegularHeading1)
            .foregroundColor(.aircastingGray)
    }
    
    var recordNewLabel: some View {
        Text(Strings.ChooseSessionTypeView.recordNew)
            .font(Fonts.muliBoldHeading1)
            .foregroundColor(.aircastingGray)
    }
    
    var orLabel: some View {
        Text(Strings.ChooseSessionTypeView.orLabel)
            .font(Fonts.muliBoldHeading2)
            .foregroundColor(.aircastingGray)
    }
    
    var moreInfoLabel: some View {
        Text(Strings.ChooseSessionTypeView.moreInfo)
            .font(Fonts.moderateRegularHeading3)
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
        createButton(action: {
            viewModel.fixedSessionButtonTapped()
        }, label: fixedSessionLabel)
    }
    
    var mobileSessionButton: some View {
        createButton(action: {
            viewModel.mobileSessionButtonTapped()
        }, label: mobileSessionLabel)
    }
    
    var sdSyncButton: some View {
        createButton(action: {
            viewModel.syncButtonTapped()
        }, label: syncButtonLabel)
    }
    
    var followSessionButton: some View {
        createButton(action: {
            viewModel.searchAndFollowTapped()
        }, label: followButtonLabel)
    }
    
    private func createButton<T: View>(action: @escaping () -> Void, label: T) -> some View {
        Button(action: action) {
            label
        }.background(GeometryReader {
            Color.clear
                .preference(
                    key: ViewHeightKey.self,
                    value: $0.frame(in: .local).size.height
                )
        })
    }
    
    var fixedSessionLabel: some View {
        chooseSessionButton(title: StringCustomizer.customizeString(Strings.ChooseSessionTypeView.fixedLabel,
                                                                    using: [Strings.ChooseSessionTypeView.fixedSession],
                                                                    color: .accentColor,
                                                                    font: Fonts.muliBoldHeading1,
                                                                    makeNewLineAfterCustomized: true))
    }
    
    var mobileSessionLabel: some View {
        chooseSessionButton(title: StringCustomizer.customizeString(Strings.ChooseSessionTypeView.mobileLabel,
                                                                    using: [Strings.ChooseSessionTypeView.mobileSession],
                                                                    color: .accentColor,
                                                                    font: Fonts.muliBoldHeading1,
                                                                    makeNewLineAfterCustomized: true))
    }
    
    var syncButtonLabel: some View {
        chooseSessionButton(title: StringCustomizer.customizeString(Strings.ChooseSessionTypeView.syncTitle,
                                                                    using: [Strings.ChooseSessionTypeView.syncData],
                                                                    font: Fonts.muliBoldHeading1,
                                                                    makeNewLineAfterCustomized: true))
    }
    
    var followButtonLabel: some View {
        chooseSessionButton(title: StringCustomizer.customizeString(Strings.ChooseSessionTypeView.followButtonTitle,
                                                                    using: [Strings.ChooseSessionTypeView.followSession],
                                                                    font: Fonts.muliBoldHeading1,
                                                                    makeNewLineAfterCustomized: true))
    }
}

extension ChooseSessionTypeView {
    func chooseSessionButton(title: Text) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            title
                .font(Fonts.muliRegularHeading4)
                .foregroundColor(.aircastingGray)
        }
        .multilineTextAlignment(.leading)
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: buttonHeight, maxHeight: .infinity, alignment: .leading)
        .background(Color.aircastingBackground)
        .cornerRadius(8)
        .shadow(color: Color.shadow, radius: 9, x: 0, y: 1)
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = max(value, nextValue())
    }
}
