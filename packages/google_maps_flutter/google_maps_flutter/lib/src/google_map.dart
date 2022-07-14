// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of google_maps_flutter;

/// Callback method for when the map is ready to be used.
///
/// Pass to [GoogleMap.onMapCreated] to receive a [GoogleMapController] when the
/// map is created.
typedef MapCreatedCallback = void Function(GoogleMapController controller);

// This counter is used to provide a stable "constant" initialization id
// to the buildView function, so the web implementation can use it as a
// cache key. This needs to be provided from the outside, because web
// views seem to re-render much more often that mobile platform views.
int _nextMapCreationId = 0;

/// Error thrown when an unknown map object ID is provided to a method.
class UnknownMapObjectIdError extends Error {
  /// Creates an assertion error with the provided [message].
  UnknownMapObjectIdError(this.objectType, this.objectId, [this.context]);

  /// The name of the map object whose ID is unknown.
  final String objectType;

  /// The unknown maps object ID.
  final MapsObjectId<Object> objectId;

  /// The context where the error occurred.
  final String? context;

  @override
  String toString() {
    if (context != null) {
      return 'Unknown $objectType ID "${objectId.value}" in $context';
    }
    return 'Unknown $objectType ID "${objectId.value}"';
  }
}

/// Android specific settings for [GoogleMap].
class AndroidGoogleMapsFlutter {
  AndroidGoogleMapsFlutter._();

  /// Whether to render [GoogleMap] with a [AndroidViewSurface] to build the Google Maps widget.
  ///
  /// This implementation uses hybrid composition to render the Google Maps
  /// Widget on Android. This comes at the cost of some performance on Android
  /// versions below 10. See
  /// https://flutter.dev/docs/development/platform-integration/platform-views#performance for more
  /// information.
  ///
  /// Defaults to false.
  static bool get useAndroidViewSurface {
    final GoogleMapsFlutterPlatform platform =
        GoogleMapsFlutterPlatform.instance;
    if (platform is MethodChannelGoogleMapsFlutter) {
      return platform.useAndroidViewSurface;
    }
    return false;
  }

  /// Set whether to render [GoogleMap] with a [AndroidViewSurface] to build the Google Maps widget.
  ///
  /// This implementation uses hybrid composition to render the Google Maps
  /// Widget on Android. This comes at the cost of some performance on Android
  /// versions below 10. See
  /// https://flutter.dev/docs/development/platform-integration/platform-views#performance for more
  /// information.
  ///
  /// Defaults to false.
  static set useAndroidViewSurface(bool useAndroidViewSurface) {
    final GoogleMapsFlutterPlatform platform =
        GoogleMapsFlutterPlatform.instance;
    if (platform is MethodChannelGoogleMapsFlutter) {
      platform.useAndroidViewSurface = useAndroidViewSurface;
    }
  }
}

/// A widget which displays a map with data obtained from the Google Maps service.
class GoogleMap extends StatefulWidget {
  /// Creates a widget displaying data from Google Maps services.
  ///
  /// [AssertionError] will be thrown if [initialCameraPosition] is null;
  const GoogleMap({
    Key? key,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    this.compassEnabled = true,
    this.mapToolbarEnabled = true,
    this.cameraTargetBounds = CameraTargetBounds.unbounded,
    this.mapType = MapType.normal,
    this.minMaxZoomPreference = MinMaxZoomPreference.unbounded,
    this.rotateGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.zoomControlsEnabled = true,
    this.zoomGesturesEnabled = true,
    this.liteModeEnabled = false,
    this.tiltGesturesEnabled = true,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = true,
    this.layoutDirection,

    /// If no padding is specified default padding will be 0.
    this.padding = const EdgeInsets.all(0),
    this.indoorViewEnabled = false,
    this.trafficEnabled = false,
    this.buildingsEnabled = true,
    this.markers = const <Marker>[],
    this.polygons = const <Polygon>{},
    this.polylines = const <Polyline>{},
    this.circles = const <Circle>{},
    this.onCameraMoveStarted,
    this.tileOverlays = const <TileOverlay>{},
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
    this.onLongPress,
  })  : assert(initialCameraPosition != null),
        super(key: key);

  /// Callback method for when the map is ready to be used.
  ///
  /// Used to receive a [GoogleMapController] for this [GoogleMap].
  final MapCreatedCallback? onMapCreated;

  /// The initial position of the map's camera.
  final CameraPosition initialCameraPosition;

  /// True if the map should show a compass when rotated.
  final bool compassEnabled;

  /// True if the map should show a toolbar when you interact with the map. Android only.
  final bool mapToolbarEnabled;

  /// Geographical bounding box for the camera target.
  final CameraTargetBounds cameraTargetBounds;

  /// Type of map tiles to be rendered.
  final MapType mapType;

  /// The layout direction to use for the embedded view.
  ///
  /// If this is null, the ambient [Directionality] is used instead. If there is
  /// no ambient [Directionality], [TextDirection.ltr] is used.
  final TextDirection? layoutDirection;

  /// Preferred bounds for the camera zoom level.
  ///
  /// Actual bounds depend on map data and device.
  final MinMaxZoomPreference minMaxZoomPreference;

  /// True if the map view should respond to rotate gestures.
  final bool rotateGesturesEnabled;

  /// True if the map view should respond to scroll gestures.
  final bool scrollGesturesEnabled;

  /// True if the map view should show zoom controls. This includes two buttons
  /// to zoom in and zoom out. The default value is to show zoom controls.
  ///
  /// This is only supported on Android. And this field is silently ignored on iOS.
  final bool zoomControlsEnabled;

  /// True if the map view should respond to zoom gestures.
  final bool zoomGesturesEnabled;

  /// True if the map view should be in lite mode. Android only.
  ///
  /// See https://developers.google.com/maps/documentation/android-sdk/lite#overview_of_lite_mode for more details.
  final bool liteModeEnabled;

  /// True if the map view should respond to tilt gestures.
  final bool tiltGesturesEnabled;

  /// Padding to be set on map. See https://developers.google.com/maps/documentation/android-sdk/map#map_padding for more details.
  final EdgeInsets padding;

  /// Markers to be placed on the map.
  final List<Marker> markers;

  /// Polygons to be placed on the map.
  final Set<Polygon> polygons;

  /// Polylines to be placed on the map.
  final Set<Polyline> polylines;

  /// Circles to be placed on the map.
  final Set<Circle> circles;

  /// Tile overlays to be placed on the map.
  final Set<TileOverlay> tileOverlays;

  /// Called when the camera starts moving.
  ///
  /// This can be initiated by the following:
  /// 1. Non-gesture animation initiated in response to user actions.
  ///    For example: zoom buttons, my location button, or marker clicks.
  /// 2. Programmatically initiated animation.
  /// 3. Camera motion initiated in response to user gestures on the map.
  ///    For example: pan, tilt, pinch to zoom, or rotate.
  final ValueChanged<CameraMoveStartedEvent>? onCameraMoveStarted;

  /// Called repeatedly as the camera continues to move after an
  /// onCameraMoveStarted call.
  ///
  /// This may be called as often as once every frame and should
  /// not perform expensive operations.
  final CameraPositionCallback? onCameraMove;

  /// Called when camera movement has ended, there are no pending
  /// animations and the user has stopped interacting with the map.
  final VoidCallback? onCameraIdle;

  /// Called every time a [GoogleMap] is tapped.
  final ArgumentCallback<LatLng>? onTap;

  /// Called every time a [GoogleMap] is long pressed.
  final ArgumentCallback<LatLng>? onLongPress;

  /// True if a "My Location" layer should be shown on the map.
  ///
  /// This layer includes a location indicator at the current device location,
  /// as well as a My Location button.
  /// * The indicator is a small blue dot if the device is stationary, or a
  /// chevron if the device is moving.
  /// * The My Location button animates to focus on the user's current location
  /// if the user's location is currently known.
  ///
  /// Enabling this feature requires adding location permissions to both native
  /// platforms of your app.
  /// * On Android add either
  /// `<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />`
  /// or `<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />`
  /// to your `AndroidManifest.xml` file. `ACCESS_COARSE_LOCATION` returns a
  /// location with an accuracy approximately equivalent to a city block, while
  /// `ACCESS_FINE_LOCATION` returns as precise a location as possible, although
  /// it consumes more battery power. You will also need to request these
  /// permissions during run-time. If they are not granted, the My Location
  /// feature will fail silently.
  /// * On iOS add a `NSLocationWhenInUseUsageDescription` key to your
  /// `Info.plist` file. This will automatically prompt the user for permissions
  /// when the map tries to turn on the My Location layer.
  final bool myLocationEnabled;

  /// Enables or disables the my-location button.
  ///
  /// The my-location button causes the camera to move such that the user's
  /// location is in the center of the map. If the button is enabled, it is
  /// only shown when the my-location layer is enabled.
  ///
  /// By default, the my-location button is enabled (and hence shown when the
  /// my-location layer is enabled).
  ///
  /// See also:
  ///   * [myLocationEnabled] parameter.
  final bool myLocationButtonEnabled;

  /// Enables or disables the indoor view from the map
  final bool indoorViewEnabled;

  /// Enables or disables the traffic layer of the map
  final bool trafficEnabled;

  /// Enables or disables showing 3D buildings where available
  final bool buildingsEnabled;

  /// Which gestures should be consumed by the map.
  ///
  /// It is possible for other gesture recognizers to be competing with the map on pointer
  /// events, e.g if the map is inside a [ListView] the [ListView] will want to handle
  /// vertical drags. The map will claim gestures that are recognized by any of the
  /// recognizers on this list.
  ///
  /// When this set is empty, the map will only handle pointer events for gestures that
  /// were not claimed by any other gesture recognizer.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// Creates a [State] for this [GoogleMap].
  @override
  State createState() => _GoogleMapState();
}

class _GoogleMapState extends State<GoogleMap> {
  final int _mapId = _nextMapCreationId++;

  // final Completer<GoogleMapController> _controllerCompleter =
  // Completer<GoogleMapController>();
  GoogleMapController? _controller;

  List<Marker> _markers = <Marker>[];
  Map<PolygonId, Polygon> _polygons = <PolygonId, Polygon>{};
  Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};
  Map<CircleId, Circle> _circles = <CircleId, Circle>{};
  _GoogleMapOptions? _googleMapOptions;

  final _MessagingSampler _markerSampler = _MessagingSampler();
  final _MessagingSampler _polylineSampler = _MessagingSampler();
  final _MessagingSampler _circleSampler = _MessagingSampler();

  @override
  Widget build(BuildContext context) {
    return GoogleMapsFlutterPlatform.instance.buildViewWithTextDirection(
      _mapId,
      onPlatformViewCreated,
      textDirection: widget.layoutDirection ??
          Directionality.maybeOf(context) ??
          TextDirection.ltr,
      initialCameraPosition: widget.initialCameraPosition,
      markers: const {},
      polygons: const {},
      polylines: const {},
      circles: const {},
      gestureRecognizers: widget.gestureRecognizers,
      mapOptions: _googleMapOptions,
    );
  }

  @override
  void initState() {
    super.initState();
    _googleMapOptions = _GoogleMapOptions.fromWidget(widget);
  }

  @override
  void dispose() {
    _clearCaches();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(GoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller != null) {
      _updateOptions();

      if (widget.markers != oldWidget.markers) {
        _markerSampler.submit(_updateMarkers);
      }
      if (widget.polygons != oldWidget.polygons) {
        _updatePolygons();
      }
      if (widget.polylines != oldWidget.polylines) {
        _polylineSampler.submit(_updatePolylines);
      }
      if (widget.circles != oldWidget.circles) {
        _circleSampler.submit(_updateCircles);
      }
      if (widget.tileOverlays != oldWidget.tileOverlays) {
        _updateTileOverlays(oldWidget);
      }
    }
  }

  void _updateOptions() {
    assert(_controller != null);
    final _GoogleMapOptions newOptions = _GoogleMapOptions.fromWidget(widget);
    final Map<String, dynamic> updates = newOptions.toMap(_googleMapOptions);
    if (updates.isEmpty) {
      return;
    }
    // ignore: unawaited_futures
    _controller!._updateMapOptions(updates);
    _googleMapOptions = newOptions;
  }

  Future<void>? _updateMarkers() {
    assert(_controller != null);
    // ignore: unawaited_futures
    final List<Marker> newMarkers = widget.markers;
    final MarkerUpdates update = MarkerUpdates.from(_markers, newMarkers);
    _markers = newMarkers;
    if (update.isNotEmpty) {
      return _controller!._updateMarkers(update);
    } else {
      return null;
    }
  }

  void _updatePolygons() {
    assert(_controller != null);
    final PolygonUpdates update =
        PolygonUpdates.from(_polygons.values.toSet(), widget.polygons);
    // ignore: unawaited_futures
    if (update.isNotEmpty) {
      _controller!._updatePolygons(update);
    }
    _polygons = keyByPolygonId(widget.polygons);
  }

  Future<void>? _updatePolylines() {
    assert(_controller != null);
    final Map<PolylineId, Polyline> keyedPolylines =
        keyByPolylineId(widget.polylines);
    final PolylineUpdates update =
        PolylineUpdates.from(_polylines, keyedPolylines);
    _polylines = keyedPolylines;
    if (update.isNotEmpty) {
      return _controller!._updatePolylines(update);
    } else {
      return null;
    }
  }

  Future<void>? _updateCircles() {
    assert(_controller != null);
    final CircleUpdates update =
        CircleUpdates.from(_circles.values.toSet(), widget.circles);
    _circles = keyByCircleId(widget.circles);
    if (update.isNotEmpty) {
      return _controller!._updateCircles(update);
    } else {
      return null;
    }
  }

  void _updateTileOverlays(GoogleMap? oldWidget) {
    // ignore: unawaited_futures
    if (oldWidget?.tileOverlays != widget.tileOverlays) {
      _controller!._updateTileOverlays(widget.tileOverlays);
    }
  }

  void _clearCaches() {
    _polygons = {};
    _polylines = {};
    _circles = {};
    _markers = [];
    _googleMapOptions = null;
  }

  Future<void> onPlatformViewCreated(int id) async {
    final GoogleMapController controller = await GoogleMapController.init(
      id,
      widget.initialCameraPosition,
      this,
    );

    if (!mounted) {
      controller.dispose();
      return;
    }

    _controller = controller;
    _clearCaches();
    _updateOptions();
    _updateMarkers();
    _updatePolygons();
    _updatePolylines();
    _updateCircles();

    _updateTileOverlays(null);
    final MapCreatedCallback? onMapCreated = widget.onMapCreated;
    if (onMapCreated != null) {
      onMapCreated(controller);
    }
  }

  void onMarkerTap(MarkerId markerId) {
    assert(markerId != null);
    final Marker? marker = _markers
        .lastWhereOrNull((Marker element) => element.markerId == markerId);
    if (marker == null) {
      throw UnknownMapObjectIdError('marker', markerId, 'onTap');
    }
    final VoidCallback? onTap = marker.onTap;
    if (onTap != null) {
      onTap();
    }
  }

  void onMarkerDragStart(MarkerId markerId, LatLng position) {
    assert(false, 'Not supported by fork');
  }

  void onMarkerDrag(MarkerId markerId, LatLng position) {
    assert(false, 'Not supported by fork');
  }

  void onMarkerDragEnd(MarkerId markerId, LatLng position) {
    assert(false, 'Not supported by fork');
  }

  void onPolygonTap(PolygonId polygonId) {
    assert(polygonId != null);
    final Polygon? polygon = _polygons[polygonId];
    if (polygon == null) {
      throw UnknownMapObjectIdError('polygon', polygonId, 'onTap');
    }
    final VoidCallback? onTap = polygon.onTap;
    if (onTap != null) {
      onTap();
    }
  }

  void onPolylineTap(PolylineId polylineId) {
    assert(polylineId != null);
    final Polyline? polyline = _polylines[polylineId];
    if (polyline == null) {
      throw UnknownMapObjectIdError('polyline', polylineId, 'onTap');
    }
    final VoidCallback? onTap = polyline.onTap;
    if (onTap != null) {
      onTap();
    }
  }

  void onCircleTap(CircleId circleId) {
    assert(circleId != null);
    final Circle? circle = _circles[circleId];
    if (circle == null) {
      throw UnknownMapObjectIdError('marker', circleId, 'onTap');
    }
    final VoidCallback? onTap = circle.onTap;
    if (onTap != null) {
      onTap();
    }
  }

  void onInfoWindowTap(MarkerId markerId) {
    assert(false, 'Unsupported operation');
  }

  void onTap(LatLng position) {
    assert(position != null);
    final ArgumentCallback<LatLng>? onTap = widget.onTap;
    if (onTap != null) {
      onTap(position);
    }
  }

  void onLongPress(LatLng position) {
    assert(position != null);
    final ArgumentCallback<LatLng>? onLongPress = widget.onLongPress;
    if (onLongPress != null) {
      onLongPress(position);
    }
  }
}

class _MessagingSampler {
  bool _working = false;
  Future<void>? Function()? _pendingJobBuilder;

  void submit(Future<void>? Function() jobBuilder) {
    if (_working) {
      _pendingJobBuilder = jobBuilder;
    } else {
      _start(jobBuilder());
    }
  }

  void _start(Future<void>? job) {
    assert(!_working);

    if (job == null) {
      return;
    }

    _working = true;
    job.whenComplete(_onJobComplete);
  }

  void _onJobComplete() {
    _working = false;

    final Future<void>? Function()? pending = _pendingJobBuilder;
    if (pending != null) {
      _pendingJobBuilder = null;
      _start(pending());
    }
  }
}

/// Configuration options for the GoogleMaps user interface.
class _GoogleMapOptions {
  _GoogleMapOptions.fromWidget(GoogleMap map)
      : compassEnabled = map.compassEnabled,
        mapToolbarEnabled = map.mapToolbarEnabled,
        cameraTargetBounds = map.cameraTargetBounds,
        mapType = map.mapType,
        minMaxZoomPreference = map.minMaxZoomPreference,
        rotateGesturesEnabled = map.rotateGesturesEnabled,
        scrollGesturesEnabled = map.scrollGesturesEnabled,
        tiltGesturesEnabled = map.tiltGesturesEnabled,
        trackCameraPosition = map.onCameraMove != null,
        zoomControlsEnabled = map.zoomControlsEnabled,
        zoomGesturesEnabled = map.zoomGesturesEnabled,
        liteModeEnabled = map.liteModeEnabled,
        myLocationEnabled = map.myLocationEnabled,
        myLocationButtonEnabled = map.myLocationButtonEnabled,
        padding = map.padding,
        indoorViewEnabled = map.indoorViewEnabled,
        trafficEnabled = map.trafficEnabled,
        buildingsEnabled = map.buildingsEnabled,
        assert(!map.liteModeEnabled || Platform.isAndroid);

  final bool compassEnabled;

  final bool mapToolbarEnabled;

  final CameraTargetBounds cameraTargetBounds;

  final MapType mapType;

  final MinMaxZoomPreference minMaxZoomPreference;

  final bool rotateGesturesEnabled;

  final bool scrollGesturesEnabled;

  final bool tiltGesturesEnabled;

  final bool trackCameraPosition;

  final bool zoomControlsEnabled;

  final bool zoomGesturesEnabled;

  final bool liteModeEnabled;

  final bool myLocationEnabled;

  final bool myLocationButtonEnabled;

  final EdgeInsets padding;

  final bool indoorViewEnabled;

  final bool trafficEnabled;

  final bool buildingsEnabled;

  Map<String, dynamic> toMap([_GoogleMapOptions? filterOnlyDifferent]) {
    return <String, dynamic>{
      if (compassEnabled != filterOnlyDifferent?.compassEnabled)
        'compassEnabled': compassEnabled,
      if (mapToolbarEnabled != filterOnlyDifferent?.mapToolbarEnabled)
        'mapToolbarEnabled': mapToolbarEnabled,
      if (cameraTargetBounds != filterOnlyDifferent?.cameraTargetBounds)
        'cameraTargetBounds': cameraTargetBounds.toJson(),
      if (mapType != filterOnlyDifferent?.mapType) 'mapType': mapType.index,
      if (minMaxZoomPreference != filterOnlyDifferent?.minMaxZoomPreference)
        'minMaxZoomPreference': minMaxZoomPreference.toJson(),
      if (rotateGesturesEnabled != filterOnlyDifferent?.rotateGesturesEnabled)
        'rotateGesturesEnabled': rotateGesturesEnabled,
      if (scrollGesturesEnabled != filterOnlyDifferent?.scrollGesturesEnabled)
        'scrollGesturesEnabled': scrollGesturesEnabled,
      if (tiltGesturesEnabled != filterOnlyDifferent?.tiltGesturesEnabled)
        'tiltGesturesEnabled': tiltGesturesEnabled,
      if (zoomControlsEnabled != filterOnlyDifferent?.zoomControlsEnabled)
        'zoomControlsEnabled': zoomControlsEnabled,
      if (zoomGesturesEnabled != filterOnlyDifferent?.zoomGesturesEnabled)
        'zoomGesturesEnabled': zoomGesturesEnabled,
      if (liteModeEnabled != filterOnlyDifferent?.liteModeEnabled)
        'liteModeEnabled': liteModeEnabled,
      if (trackCameraPosition != filterOnlyDifferent?.trackCameraPosition)
        'trackCameraPosition': trackCameraPosition,
      if (myLocationEnabled != filterOnlyDifferent?.myLocationEnabled)
        'myLocationEnabled': myLocationEnabled,
      if (myLocationButtonEnabled !=
          filterOnlyDifferent?.myLocationButtonEnabled)
        'myLocationButtonEnabled': myLocationButtonEnabled,
      if (padding != filterOnlyDifferent?.padding)
        'padding': <double>[
          padding.top,
          padding.left,
          padding.bottom,
          padding.right,
        ],
      if (indoorViewEnabled != filterOnlyDifferent?.indoorViewEnabled)
        'indoorEnabled': indoorViewEnabled,
      if (trafficEnabled != filterOnlyDifferent?.trafficEnabled)
        'trafficEnabled': trafficEnabled,
      if (buildingsEnabled != filterOnlyDifferent?.buildingsEnabled)
        'buildingsEnabled': buildingsEnabled,
    };
  }
}
