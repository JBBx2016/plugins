// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import GoogleMaps
import Testing

@testable import google_maps_flutter_ios

@MainActor struct MarkerControllerTests {

  @Test func batchesDecodeSharedIconsOnceAndKeepIndependentScales() throws {
    let mapView = MarkerControllerTests.mapView()
    let eventHandler = TestMapEventHandler()
    let provider = TestAssetProvider(
      image: GMSMarker.markerImage(with: .blue), forAssetName: "asset", package: nil)
    let controller = MarkersController(
      mapView: mapView, eventDelegate: eventHandler,
      clusterManagersController: nil, assetProvider: provider, markerType: .marker)
    func marker(_ identifier: String, iconIndex: Int64) -> PlatformMarker {
      PlatformMarker(
        alpha: 1, anchor: PlatformPoint(x: 0.5, y: 1), consumeTapEvents: false,
        draggable: false, flat: false, icon: PlatformBitmapReference(index: iconIndex),
        infoWindow: PlatformInfoWindow(anchor: PlatformPoint(x: 0.5, y: 0)),
        position: PlatformLatLng(latitude: 0, longitude: 0), rotation: 0, visible: true,
        zIndex: 0, markerId: identifier)
    }
    controller.updateWithDeltas(
      adding: [marker("a", iconIndex: 0), marker("b", iconIndex: 0), marker("c", iconIndex: 1)],
      changing: [], removing: [],
      bitmaps: [
        PlatformBitmapAssetImage(name: "asset", scale: 1),
        PlatformBitmapAssetImage(name: "asset", scale: 2),
      ])
    let first = try #require(controller.markerIdentifierToController["a"]?.marker.icon)
    let second = try #require(controller.markerIdentifierToController["b"]?.marker.icon)
    let scaled = try #require(controller.markerIdentifierToController["c"]?.marker.icon)
    #expect(provider.imageLoadCount == 2)
    #expect(first === second)
    #expect(scaled.scale == first.scale * 2)
    controller.updateWithDeltas(
      adding: [],
      changing: [
        PlatformMarkerPatch(markerId: "a", position: PlatformLatLng(latitude: 1, longitude: 2))
      ], removing: [], bitmaps: [])
    #expect(provider.imageLoadCount == 2)
    #expect(controller.markerIdentifierToController["a"]?.marker.icon === first)
  }

  @Test func sparseMovementPreservesIconAndClearsInfoWindow() {
    let mapView = MarkerControllerTests.mapView()
    let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    let icon = GMSMarker.markerImage(with: .blue)
    marker.icon = icon
    marker.title = "old title"
    marker.snippet = "old snippet"
    let controller = MarkerController(marker: marker, markerIdentifier: "a", mapView: mapView)
    controller.apply(
      PlatformMarkerPatch(
        markerId: "a",
        infoWindow: PlatformInfoWindow(
          title: nil, snippet: nil, anchor: PlatformPoint(x: 0.5, y: 0)),
        position: PlatformLatLng(latitude: 3, longitude: 4), rotation: 359),
      assetProvider: TestAssetProvider(), screenScale: 1, resolvedBitmaps: [])
    #expect(marker.icon === icon)
    #expect(marker.title == nil)
    #expect(marker.snippet == nil)
    #expect(marker.rotation == 359)
    #expect(marker.position.latitude == 3)
  }

  /// Returns a simple map view for use with marker controllers.
  static func mapView() -> GMSMapView {
    let mapViewOptions = GMSMapViewOptions()
    mapViewOptions.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    mapViewOptions.camera = GMSCameraPosition(latitude: 0, longitude: 0, zoom: 0)
    return PartiallyMockedMapView(options: mapViewOptions)
  }

  /// Returns a MarkersController instance instantiated with the given map view.
  ///
  /// The mapView should outlive the controller, as the controller keeps a weak reference to it.
  func markersController(
    withMapView mapView: GMSMapView,
    eventDelegate: MapEventDelegate
  ) -> MarkersController {
    return MarkersController(
      mapView: mapView,
      eventDelegate: eventDelegate,
      clusterManagersController: nil,
      assetProvider: TestAssetProvider(),
      markerType: .marker
    )
  }

  func placeholderBitmap() -> PlatformBitmap {
    return PlatformBitmapDefaultMarker(hue: 0)
  }

  @Test func setsMarkerNumericProperties() throws {
    let mapView = MarkerControllerTests.mapView()
    let eventHandler = TestMapEventHandler()
    let controller = markersController(withMapView: mapView, eventDelegate: eventHandler)

    let markerIdentifier = "marker"
    let anchorX = 3.14
    let anchorY = 2.718
    let alpha = 0.4
    let rotation = 90.0
    let zIndex: Int64 = 3
    let latitude = 10.0
    let longitude = 20.0
    controller.add([
      PlatformMarker(
        alpha: alpha,
        anchor: PlatformPoint(x: anchorX, y: anchorY),
        consumeTapEvents: true,
        draggable: true,
        flat: true,
        icon: placeholderBitmap(),
        infoWindow: PlatformInfoWindow(
          title: "info title",
          snippet: "info snippet",
          anchor: PlatformPoint(x: 0, y: 0)
        ),
        position: PlatformLatLng(latitude: latitude, longitude: longitude),
        rotation: rotation,
        visible: true,
        zIndex: zIndex,
        markerId: markerIdentifier,
        clusterManagerId: nil,
        collisionBehavior: nil
      )
    ])

    let markerController = try #require(controller.markerIdentifierToController[markerIdentifier])
    let marker = markerController.marker

    let delta = 0.0001
    #expect(abs(Double(marker.opacity) - alpha) <= delta)
    #expect(abs(marker.rotation - rotation) <= delta)
    #expect(abs(Double(marker.zIndex) - Double(zIndex)) <= delta)
    #expect(abs(Double(marker.groundAnchor.x) - anchorX) <= delta)
    #expect(abs(Double(marker.groundAnchor.y) - anchorY) <= delta)
    #expect(abs(marker.position.latitude - latitude) <= delta)
    #expect(abs(marker.position.longitude - longitude) <= delta)
  }

  @Test func setsDraggable() throws {
    let mapView = MarkerControllerTests.mapView()
    let eventHandler = TestMapEventHandler()
    let controller = markersController(withMapView: mapView, eventDelegate: eventHandler)

    let markerIdentifier = "marker"
    controller.add([
      PlatformMarker(
        alpha: 1.0,
        anchor: PlatformPoint(x: 0, y: 0),
        consumeTapEvents: false,
        draggable: true,
        flat: false,
        icon: placeholderBitmap(),
        infoWindow: PlatformInfoWindow(
          title: "info title",
          snippet: "info snippet",
          anchor: PlatformPoint(x: 0, y: 0)
        ),
        position: PlatformLatLng(latitude: 0.0, longitude: 0.0),
        rotation: 0,
        visible: false,
        zIndex: 0,
        markerId: markerIdentifier,
        clusterManagerId: nil,
        collisionBehavior: nil
      )
    ])

    let markerController = try #require(controller.markerIdentifierToController[markerIdentifier])
    let marker = markerController.marker

    #expect(marker.isDraggable)
  }

  // Boolean properties are tested individually to ensure they aren't accidentally cross-assigned from
  // another property.
  @Test func setsFlat() throws {
    let mapView = MarkerControllerTests.mapView()
    let eventHandler = TestMapEventHandler()
    let controller = markersController(withMapView: mapView, eventDelegate: eventHandler)

    let markerIdentifier = "marker"
    controller.add([
      PlatformMarker(
        alpha: 1.0,
        anchor: PlatformPoint(x: 0, y: 0),
        consumeTapEvents: false,
        draggable: false,
        flat: true,
        icon: placeholderBitmap(),
        infoWindow: PlatformInfoWindow(
          title: "info title",
          snippet: "info snippet",
          anchor: PlatformPoint(x: 0, y: 0)
        ),
        position: PlatformLatLng(latitude: 0.0, longitude: 0.0),
        rotation: 0,
        visible: false,
        zIndex: 0,
        markerId: markerIdentifier,
        clusterManagerId: nil,
        collisionBehavior: nil
      )
    ])

    let markerController = try #require(controller.markerIdentifierToController[markerIdentifier])
    let marker = markerController.marker

    #expect(marker.isFlat)
  }

  // Boolean properties are tested individually to ensure they aren't accidentally cross-assigned from
  // another property.
  @Test func setsVisible() throws {
    let mapView = MarkerControllerTests.mapView()
    let eventHandler = TestMapEventHandler()
    let controller = markersController(withMapView: mapView, eventDelegate: eventHandler)

    let markerIdentifier = "marker"
    controller.add([
      PlatformMarker(
        alpha: 1.0,
        anchor: PlatformPoint(x: 0, y: 0),
        consumeTapEvents: false,
        draggable: false,
        flat: false,
        icon: placeholderBitmap(),
        infoWindow: PlatformInfoWindow(
          title: "info title",
          snippet: "info snippet",
          anchor: PlatformPoint(x: 0, y: 0)
        ),
        position: PlatformLatLng(latitude: 0.0, longitude: 0.0),
        rotation: 0,
        visible: true,
        zIndex: 0,
        markerId: markerIdentifier,
        clusterManagerId: nil,
        collisionBehavior: nil
      )
    ])

    let markerController = try #require(controller.markerIdentifierToController[markerIdentifier])
    let marker = markerController.marker

    // Visibility is controlled by being set to a map.
    #expect(marker.map != nil)
  }

  @Test func setsMarkerInfoWindowProperties() throws {
    let mapView = MarkerControllerTests.mapView()
    let eventHandler = TestMapEventHandler()
    let controller = markersController(withMapView: mapView, eventDelegate: eventHandler)

    let markerIdentifier = "marker"
    let title = "info title"
    let snippet = "info snippet"
    let anchorX = 3.14
    let anchorY = 2.718
    controller.add([
      PlatformMarker(
        alpha: 1.0,
        anchor: PlatformPoint(x: 0, y: 0),
        consumeTapEvents: true,
        draggable: true,
        flat: true,
        icon: placeholderBitmap(),
        infoWindow: PlatformInfoWindow(
          title: title,
          snippet: snippet,
          anchor: PlatformPoint(x: anchorX, y: anchorY)
        ),
        position: PlatformLatLng(latitude: 0, longitude: 0),
        rotation: 0,
        visible: true,
        zIndex: 0,
        markerId: markerIdentifier,
        clusterManagerId: nil,
        collisionBehavior: nil
      )
    ])

    let markerController = try #require(controller.markerIdentifierToController[markerIdentifier])
    let marker = markerController.marker

    let delta = 0.0001
    #expect(abs(Double(marker.infoWindowAnchor.x) - anchorX) <= delta)
    #expect(abs(Double(marker.infoWindowAnchor.y) - anchorY) <= delta)
    #expect(marker.title == title)
    #expect(marker.snippet == snippet)
  }

  @Test func updateMarkerSetsVisibilityLast() {
    let marker = PropertyOrderValidatingAdvancedMarker()
    let collisionBehavior = PlatformMarkerCollisionBehavior.requiredAndHidesOptional
    MarkerController.update(
      marker,
      from: PlatformMarker(
        alpha: 1.0,
        anchor: PlatformPoint(x: 0, y: 0),
        consumeTapEvents: true,
        draggable: true,
        flat: true,
        icon: placeholderBitmap(),
        infoWindow: PlatformInfoWindow(
          title: "info title",
          snippet: "info snippet",
          anchor: PlatformPoint(x: 0, y: 0)
        ),
        position: PlatformLatLng(latitude: 0, longitude: 0),
        rotation: 0,
        visible: true,
        zIndex: 0,
        markerId: "marker",
        clusterManagerId: nil,
        collisionBehavior: collisionBehavior
      ),
      mapView: MarkerControllerTests.mapView(),
      assetProvider: TestAssetProvider(),
      screenScale: 1,
      usingOpacityForVisibility: false
    )
    #expect(marker.hasSetMap)
  }

  @Test func assetProviderIsRetained() {
    var markerController: MarkersController?
    weak var weakAssetProvider: TestAssetProvider?
    autoreleasepool {
      let assetProvider = TestAssetProvider()
      weakAssetProvider = assetProvider

      markerController = MarkersController(
        mapView: MarkerControllerTests.mapView(),
        eventDelegate: TestMapEventHandler(),
        clusterManagersController: nil,
        assetProvider: assetProvider,
        markerType: .marker
      )
    }
    #expect(markerController != nil)
    #expect(weakAssetProvider != nil)
  }
}

/// A GMSAdvancedMarker that ensures that property updates are made before the map is set.
class PropertyOrderValidatingAdvancedMarker: GMSAdvancedMarker {
  var hasSetMap = false

  override var position: CLLocationCoordinate2D {
    get { super.position }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.position = newValue
    }
  }

  override var snippet: String? {
    get { super.snippet }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.snippet = newValue
    }
  }

  override var icon: UIImage? {
    get { super.icon }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.icon = newValue
    }
  }

  override var iconView: UIView? {
    get { super.iconView }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.iconView = newValue
    }
  }

  override var tracksViewChanges: Bool {
    get { super.tracksViewChanges }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.tracksViewChanges = newValue
    }
  }

  override var tracksInfoWindowChanges: Bool {
    get { super.tracksInfoWindowChanges }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.tracksInfoWindowChanges = newValue
    }
  }

  override var groundAnchor: CGPoint {
    get { super.groundAnchor }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.groundAnchor = newValue
    }
  }

  override var infoWindowAnchor: CGPoint {
    get { super.infoWindowAnchor }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.infoWindowAnchor = newValue
    }
  }

  override var appearAnimation: GMSMarkerAnimation {
    get { super.appearAnimation }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.appearAnimation = newValue
    }
  }

  override var isDraggable: Bool {
    get { super.isDraggable }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.isDraggable = newValue
    }
  }

  override var isFlat: Bool {
    get { super.isFlat }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.isFlat = newValue
    }
  }

  override var rotation: CLLocationDegrees {
    get { super.rotation }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.rotation = newValue
    }
  }

  override var opacity: Float {
    get { super.opacity }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.opacity = newValue
    }
  }

  override var panoramaView: GMSPanoramaView? {
    get { super.panoramaView }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.panoramaView = newValue
    }
  }

  override var title: String? {
    get { super.title }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.title = newValue
    }
  }

  override var isTappable: Bool {
    get { super.isTappable }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.isTappable = newValue
    }
  }

  override var zIndex: Int32 {
    get { super.zIndex }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.zIndex = newValue
    }
  }

  override var userData: Any? {
    get { super.userData }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.userData = newValue
    }
  }

  override var collisionBehavior: GMSCollisionBehavior {
    get { super.collisionBehavior }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.collisionBehavior = newValue
    }
  }

  override var map: GMSMapView? {
    get { super.map }
    set {
      // Don't actually set the map, since that requires more test setup.
      if newValue != nil {
        hasSetMap = true
      }
    }
  }
}
