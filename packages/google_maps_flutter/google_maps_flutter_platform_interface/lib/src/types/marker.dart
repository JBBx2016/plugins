// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart' show immutable, VoidCallback;

import 'maps_object_serializer.dart';
import 'types.dart';

Object _offsetToJson(Offset offset) {
  return <Object>[offset.dx, offset.dy];
}

/// Uniquely identifies a [Marker] among [GoogleMap] markers.
///
/// This does not have to be globally unique, only unique among the list.
@immutable
class MarkerId extends MapsObjectId<Marker> {
  /// Creates an immutable identifier for a [Marker].
  const MarkerId(String value) : super(value);
}

/// Marks a geographical location on the map.
///
/// A marker icon is drawn oriented against the device's screen rather than
/// the map's surface; that is, it will not necessarily change orientation
/// due to map rotations, tilting, or zooming.
@immutable
class Marker implements MapsObject {
  /// Creates a set of marker configuration options.
  ///
  /// Default marker options.
  ///
  /// Specifies a marker that
  /// * is fully opaque; [alpha] is 1.0
  /// * uses icon bottom center to indicate map position; [anchor] is (0.5, 1.0)
  /// * has default tap handling; [consumeTapEvents] is false
  /// * is stationary; [draggable] is false
  /// * is drawn against the screen, not the map; [flat] is false
  /// * has a default icon; [icon] is `BitmapDescriptor.defaultMarker`
  /// * anchors the info window at top center; [infoWindowAnchor] is (0.5, 0.0)
  /// * has no info window text; [infoWindowText] is `InfoWindowText.noText`
  /// * is positioned at 0, 0; [position] is `LatLng(0.0, 0.0)`
  /// * has an axis-aligned icon; [rotation] is 0.0
  /// * is visible; [visible] is true
  /// * is placed at the base of the drawing order; [zIndex] is 0.0
  /// * reports [onTap] events
  /// * reports [onDragEnd] events
  const Marker({
    required this.markerId,
    this.alpha = 1.0,
    this.anchor = const Offset(0.5, 1.0),
    this.consumeTapEvents = false,
    this.flat = false,
    this.icon = BitmapDescriptor.defaultMarker,
    this.position = const LatLng(0.0, 0.0),
    this.rotation = 0.0,
    this.visible = true,
    this.zIndex = 0.0,
    this.onTap,
  }) : assert(alpha == null || (0.0 <= alpha && alpha <= 1.0));

  /// Uniquely identifies a [Marker].
  final MarkerId markerId;

  @override
  MarkerId get mapsId => markerId;

  /// The opacity of the marker, between 0.0 and 1.0 inclusive.
  ///
  /// 0.0 means fully transparent, 1.0 means fully opaque.
  final double alpha;

  /// The icon image point that will be placed at the [position] of the marker.
  ///
  /// The image point is specified in normalized coordinates: An anchor of
  /// (0.0, 0.0) means the top left corner of the image. An anchor
  /// of (1.0, 1.0) means the bottom right corner of the image.
  final Offset anchor;

  /// True if the marker icon consumes tap events. If not, the map will perform
  /// default tap handling by centering the map on the marker and displaying its
  /// info window.
  final bool consumeTapEvents;

  /// True if the marker is rendered flatly against the surface of the Earth, so
  /// that it will rotate and tilt along with map camera movements.
  final bool flat;

  /// A description of the bitmap used to draw the marker icon.
  final BitmapDescriptor icon;

  /// Geographical location of the marker.
  final LatLng position;

  /// Rotation of the marker image in degrees clockwise from the [anchor] point.
  final double rotation;

  /// True if the marker is visible.
  final bool visible;

  /// The z-index of the marker, used to determine relative drawing order of
  /// map overlays.
  ///
  /// Overlays are drawn in order of z-index, so that lower values means drawn
  /// earlier, and thus appearing to be closer to the surface of the Earth.
  final double zIndex;

  /// Callbacks to receive tap events for markers placed on this map.
  final VoidCallback? onTap;

  /// Creates a new [Marker] object whose values are the same as this instance,
  /// unless overwritten by the specified parameters.
  Marker copyWith({
    double? alphaParam,
    Offset? anchorParam,
    bool? consumeTapEventsParam,
    bool? flatParam,
    BitmapDescriptor? iconParam,
    LatLng? positionParam,
    double? rotationParam,
    bool? visibleParam,
    double? zIndexParam,
    VoidCallback? onTapParam,
  }) {
    return Marker(
      markerId: markerId,
      alpha: alphaParam ?? alpha,
      anchor: anchorParam ?? anchor,
      consumeTapEvents: consumeTapEventsParam ?? consumeTapEvents,
      flat: flatParam ?? flat,
      icon: iconParam ?? icon,
      position: positionParam ?? position,
      rotation: rotationParam ?? rotation,
      visible: visibleParam ?? visible,
      zIndex: zIndexParam ?? zIndex,
      onTap: onTapParam ?? onTap,
    );
  }

  /// Creates a new [Marker] object whose values are the same as this instance.
  Marker clone() => copyWith();

  /// Converts this object to something serializable in JSON.
  Map<String, Object> toJson([covariant Marker? previous]) {
    return serialize(
      context: null,
      previous: previous,
    );
  }

  @override
  Map<String, Object> serialize({
    required MapsObjectUpdatesSerializerContext? context,
    required covariant Marker? previous,
  }) {
    final Map<String, Object> json = <String, Object>{
      "markerId": markerId.value,
    };

    assert(!position.latitude.isNaN, "Marker has position.latitude NaN");
    assert(!position.longitude.isNaN, "Marker has position.longitude NaN");

    if (alpha != previous?.alpha) {
      json['alpha'] = alpha;
    }
    if (anchor != previous?.anchor) {
      json['anchor'] = _offsetToJson(anchor);
    }
    if (consumeTapEvents != previous?.consumeTapEvents) {
      json['consumeTapEvents'] = consumeTapEvents;
    }
    if (flat != previous?.flat) {
      json['flat'] = flat;
    }
    if (icon != previous?.icon) {
      if (context != null) {
        json['iconIndex'] = context.pushBitmapDescriptor(icon);
      } else {
        json['icon'] = icon.toJson();
      }
    }
    if (position != previous?.position) {
      json['position'] = position.toJson();
    }
    if (rotation != previous?.rotation) {
      json['rotation'] = rotation;
    }
    if (visible != previous?.visible) {
      json['visible'] = visible;
    }
    if (zIndex != previous?.zIndex) {
      json['zIndex'] = zIndex;
    }
    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final Marker typedOther = other as Marker;
    return markerId == typedOther.markerId &&
        alpha == typedOther.alpha &&
        anchor == typedOther.anchor &&
        consumeTapEvents == typedOther.consumeTapEvents &&
        flat == typedOther.flat &&
        icon == typedOther.icon &&
        position == typedOther.position &&
        rotation == typedOther.rotation &&
        visible == typedOther.visible &&
        zIndex == typedOther.zIndex;
  }

  @override
  int get hashCode => markerId.hashCode;

  @override
  String toString() {
    return 'Marker{markerId: $markerId, alpha: $alpha, anchor: $anchor, '
        'consumeTapEvents: $consumeTapEvents, flat: $flat, '
        'icon: $icon, position: $position, rotation: $rotation, '
        'visible: $visible, zIndex: $zIndex, onTap: $onTap}';
  }
}
