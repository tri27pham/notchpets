import Combine

final class PanelState: ObservableObject {
    @Published var isExpanded = false
    @Published var needsKeyFocus = false
}
