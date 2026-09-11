import Flutter
import SwiftUI
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard let flutterController = window?.rootViewController as? FlutterViewController else {
      return
    }

    let selection = NativeTabSelection { index in
      AppDelegate.navigationChannel?.invokeMethod("selectTab", arguments: index)
    }
    let host = SwiftUITabHostController(
      flutterController: flutterController,
      selection: selection
    )
    AppDelegate.selectNativeTab = { [weak selection] index in
      selection?.selectFromFlutter(index)
    }
    AppDelegate.setNativeTabBarVisible = { [weak host] isVisible in
      host?.setTabBarVisible(isVisible)
    }
    window?.rootViewController = host
  }
}

private final class NativeTabSelection: ObservableObject {
  @Published private(set) var selectedIndex = 0

  private let onUserSelection: (Int) -> Void

  init(onUserSelection: @escaping (Int) -> Void) {
    self.onUserSelection = onUserSelection
  }

  func selectFromFlutter(_ index: Int) {
    guard NativeTabView.validIndices.contains(index), index != selectedIndex else {
      return
    }
    selectedIndex = index
  }

  func selectFromUser(_ index: Int) {
    guard NativeTabView.validIndices.contains(index), index != selectedIndex else {
      return
    }
    selectedIndex = index
    onUserSelection(index)
  }
}

private struct NativeTabView: View {
  fileprivate static let validIndices = 0..<5

  @ObservedObject var selection: NativeTabSelection

  private var selectedIndex: Binding<Int> {
    Binding(
      get: { selection.selectedIndex },
      set: { selection.selectFromUser($0) }
    )
  }

  var body: some View {
    TabView(selection: selectedIndex) {
      webPage("看帖", image: "TabPosts", index: 0)
      webPage("项目", image: "TabProjects", index: 1)
      webPage("航海", image: "TabVoyage", index: 2)
      webPage("聚会", image: "TabGathering", index: 3)
      webPage("我的", image: "TabProfile", index: 4)
    }
    .tint(Color(red: 0.13, green: 0.72, blue: 0.62))
  }

  private func webPage(
    _ title: String,
    image: String,
    index: Int
  ) -> some View {
    Color.clear
      .tabItem {
        Label(title, image: image)
      }
      .tag(index)
  }
}

private final class SwiftUITabHostController: UIViewController {
  private let flutterController: FlutterViewController
  private let selection: NativeTabSelection
  private weak var tabOverlay: TabBarPassthroughView?
  private weak var tabHostingController: TransparentTabHostingController?

  init(
    flutterController: FlutterViewController,
    selection: NativeTabSelection
  ) {
    self.flutterController = flutterController
    self.selection = selection
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var childForStatusBarStyle: UIViewController? {
    flutterController
  }

  override var childForStatusBarHidden: UIViewController? {
    flutterController
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    attachFlutterContent()
    attachSwiftUITabView()
  }

  private func attachFlutterContent() {
    addChild(flutterController)
    flutterController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(flutterController.view)
    NSLayoutConstraint.activate([
      flutterController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      flutterController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      flutterController.view.topAnchor.constraint(equalTo: view.topAnchor),
      flutterController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    flutterController.didMove(toParent: self)
  }

  private func attachSwiftUITabView() {
    let hostingController = TransparentTabHostingController(
      rootView: NativeTabView(selection: selection)
    )

    let overlay = TabBarPassthroughView()
    overlay.translatesAutoresizingMaskIntoConstraints = false
    overlay.backgroundColor = .clear
    overlay.isOpaque = false
    view.addSubview(overlay)
    NSLayoutConstraint.activate([
      overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      overlay.topAnchor.constraint(equalTo: view.topAnchor),
      overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    addChild(hostingController)
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    overlay.addSubview(hostingController.view)
    NSLayoutConstraint.activate([
      hostingController.view.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: overlay.trailingAnchor),
      hostingController.view.topAnchor.constraint(equalTo: overlay.topAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: overlay.bottomAnchor),
    ])
    hostingController.didMove(toParent: self)
    tabOverlay = overlay
    tabHostingController = hostingController
  }

  func setTabBarVisible(_ isVisible: Bool) {
    tabOverlay?.isTabBarVisible = isVisible
    tabHostingController?.setTabBarVisible(isVisible)
  }
}

private final class TransparentTabHostingController: UIHostingController<NativeTabView> {
  private var isTabBarVisible = true

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    makeTransparentOutsideTabBar(view)
    updateTabBarVisibility(in: view)
  }

  func setTabBarVisible(_ isVisible: Bool) {
    self.isTabBarVisible = isVisible
    updateTabBarVisibility(in: view)
  }

  private func updateTabBarVisibility(in view: UIView) {
    if let tabBar = view as? UITabBar {
      tabBar.isHidden = !isTabBarVisible
      return
    }
    view.subviews.forEach(updateTabBarVisibility)
  }

  private func makeTransparentOutsideTabBar(_ view: UIView) {
    guard !(view is UITabBar) else {
      return
    }
    view.isOpaque = false
    view.backgroundColor = .clear
    view.layer.backgroundColor = UIColor.clear.cgColor
    view.subviews.forEach(makeTransparentOutsideTabBar)
  }
}

private final class TabBarPassthroughView: UIView {
  var isTabBarVisible = true

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard isTabBarVisible else {
      return nil
    }
    let tabBarRegionHeight = max(110, safeAreaInsets.bottom + 96)
    guard point.y >= bounds.maxY - tabBarRegionHeight else {
      return nil
    }
    return super.hitTest(point, with: event)
  }
}
