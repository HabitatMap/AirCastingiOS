import Foundation
import Combine

class TabBarSelector: ObservableObject {
    enum Tab {
        case dashboard
        case createSession
        case settings
    }
    
    @Published private(set) var selection = Tab.dashboard {
        didSet {
            updateSelectedIcon()
        }
    }
    
    var dashboardSelectionNotifier = PassthroughSubject<Void, Never>()
    private var tabBarIcons: [Tab: TabIcon] = [
        .dashboard: TabIcon(state: .selected,
                            selectedString: Strings.MainTabBarView.homeBlueIcon,
                            unselectedString: Strings.MainTabBarView.homeIcon),
        .settings: TabIcon(selectedString: Strings.MainTabBarView.settingsBlueIcon,
                           unselectedString: Strings.MainTabBarView.settingsIcon),
        .createSession: TabIcon(selectedString: Strings.MainTabBarView.plusBlueIcon,
                                unselectedString: Strings.MainTabBarView.plusIcon)
    ]
    
    func updateSelection(to newSelection: Tab) {
        selection = newSelection
        
        if newSelection == .dashboard {
            dashboardSelectionNotifier.send(())
        }
    }
    
    func getImageFor(_ tab: Tab) -> String {
        guard let imageName = tabBarIcons[tab]?.imageName else { return "" }
        return imageName
    }
    
    private func updateSelectedIcon() {
        tabBarIcons.keys.forEach { tab in
            tabBarIcons[tab]?.state = (tab == selection) ? .selected : .unselected
        }
    }
}

extension TabBarSelector {
    struct TabIcon {
        enum TabIconState {
            case selected
            case unselected
        }
        
        var imageName: String
        var state: TabIconState {
            didSet {
                if state == .selected {
                    imageName = selectedString
                } else {
                    imageName = unselectedString
                }
            }
        }
        
        private let selectedString: String
        private let unselectedString: String
        
        init(state: TabIconState = .unselected,
             selectedString: String,
             unselectedString: String) {
            self.state = state
            self.imageName = (state == .selected ? selectedString : unselectedString)
            self.selectedString = selectedString
            self.unselectedString = unselectedString
        }
    }
}
