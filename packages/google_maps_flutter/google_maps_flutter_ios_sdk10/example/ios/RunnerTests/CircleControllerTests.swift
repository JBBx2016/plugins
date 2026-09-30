// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import GoogleMaps
import Testing

@testable import google_maps_flutter_ios_sdk10

@MainActor struct CircleControllerTests {

  @Test func sparseCircleUpdatePreservesStyleAndCanHide() {
    let mapView = CircleControllerTests.mapView()
    let controller = CircleController(
      circle: PlatformCircle(
        consumeTapEvents: true,
        fillColor: PlatformColor(red: 0, green: 0, blue: 1, alpha: 1),
        strokeColor: PlatformColor(red: 1, green: 0, blue: 0, alpha: 1), visible: true,
        strokeWidth: 4, zIndex: 2, center: PlatformLatLng(latitude: 1, longitude: 2),
        radius: 5, circleId: "a"), mapView: mapView)
    let fill = controller.circle.fillColor
    controller.apply(PlatformCirclePatch(circleId: "a", visible: false, radius: 9))
    #expect(controller.circle.radius == 9)
    #expect(controller.circle.fillColor == fill)
    #expect(controller.circle.strokeWidth == 4)
    #expect(controller.circle.position.latitude == 1)
    #expect(controller.circle.map == nil)
  }

  @Test func updateCircleSetsVisibilityLast() {
    let circle = PropertyOrderValidatingCircle()
    CircleController.update(
      circle,
      from: PlatformCircle(
        consumeTapEvents: false,
        fillColor: PlatformColor(red: 0, green: 0, blue: 0, alpha: 0),
        strokeColor: PlatformColor(red: 0, green: 0, blue: 0, alpha: 0),
        visible: true,
        strokeWidth: 0,
        zIndex: 0,
        center: PlatformLatLng(latitude: 0, longitude: 0),
        radius: 10,
        circleId: "circle"
      ),
      with: CircleControllerTests.mapView()
    )
    #expect(circle.hasSetMap)
  }

  /// Returns a simple map view to add map objects to.
  static func mapView() -> GMSMapView {
    let mapViewOptions = GMSMapViewOptions()
    mapViewOptions.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    mapViewOptions.camera = GMSCameraPosition(latitude: 0, longitude: 0, zoom: 0)
    return PartiallyMockedMapView(options: mapViewOptions)
  }
}

/// A GMSCircle that ensures that property updates are made before the map is set.
class PropertyOrderValidatingCircle: GMSCircle {
  var hasSetMap = false

  override var position: CLLocationCoordinate2D {
    get { super.position }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.position = newValue
    }
  }

  override var radius: CLLocationDistance {
    get { super.radius }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.radius = newValue
    }
  }

  override var strokeWidth: CGFloat {
    get { super.strokeWidth }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.strokeWidth = newValue
    }
  }

  override var strokeColor: UIColor? {
    get { super.strokeColor }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.strokeColor = newValue
    }
  }

  override var fillColor: UIColor? {
    get { super.fillColor }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.fillColor = newValue
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
