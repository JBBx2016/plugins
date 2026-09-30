// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

void main() {
  test('ordered diff agrees with keyed reference for changing object order', () {
    final random = Random(42);
    for (var iteration = 0; iteration < 500; iteration++) {
      Set<Marker> markers() {
        final ids = List<int>.generate(12, (int i) => i)..shuffle(random);
        return ids
            .take(random.nextInt(13))
            .map(
              (int id) => Marker(
                markerId: MarkerId('$id'),
                position: LatLng(random.nextInt(3).toDouble(), 0),
              ),
            )
            .toSet();
      }

      final Set<Marker> previous = markers();
      final Set<Marker> current = markers();
      final previousById = <MarkerId, Marker>{
        for (final marker in previous) marker.markerId: marker,
      };
      final currentById = <MarkerId, Marker>{for (final marker in current) marker.markerId: marker};
      final updates = MarkerUpdates.from(previous, current);
      expect(
        updates.markersToAdd,
        current.where((marker) => !previousById.containsKey(marker.markerId)).toSet(),
      );
      expect(
        updates.markerIdsToRemove,
        previousById.keys.where((id) => !currentById.containsKey(id)).toSet(),
      );
      expect(
        updates.markersToChange,
        current
            .where(
              (marker) =>
                  previousById.containsKey(marker.markerId) &&
                  previousById[marker.markerId] != marker,
            )
            .toSet(),
      );
      expect(
        updates.previousMarkers.keys.toSet(),
        updates.markersToChange.map((marker) => marker.markerId).toSet(),
      );
      for (final Marker marker in updates.markersToChange) {
        expect(updates.previousMarkers[marker.markerId], previousById[marker.markerId]);
      }
    }
  });

  test('duplicate IDs with different values are rejected', () {
    const first = Marker(markerId: MarkerId('same'));
    final Marker second = first.copyWith(rotationParam: 30);
    expect(
      () => MarkerUpdates.from(const <Marker>{}, <Marker>{first, second}),
      throwsAssertionError,
    );
    expect(
      () => MarkerUpdates.from(<Marker>{first, second}, const <Marker>{}),
      throwsAssertionError,
    );
  });

  test('previous marker and circle snapshots are read-only and no-op updates empty', () {
    const marker = Marker(markerId: MarkerId('m'));
    final updates = MarkerUpdates.from(
      <Marker>{marker},
      <Marker>{marker.copyWith(rotationParam: 5)},
    );
    expect(updates.previousMarkers[marker.markerId], marker);
    expect(() => updates.previousMarkers.clear(), throwsUnsupportedError);
    expect(MarkerUpdates.from(<Marker>{marker}, <Marker>{marker}).isEmpty, isTrue);
    const circle = Circle(circleId: CircleId('c'), radius: 1);
    final circles = CircleUpdates.from(<Circle>{circle}, <Circle>{circle.copyWith(radiusParam: 2)});
    expect(circles.previousCircles[circle.circleId], circle);
    expect(() => circles.previousCircles.clear(), throwsUnsupportedError);
  });

  test('changed geometry and prior geometry are independent snapshots', () {
    final oldPoints = <LatLng>[const LatLng(1, 2), const LatLng(3, 4)];
    final newPoints = <LatLng>[const LatLng(1, 2), const LatLng(5, 6)];
    const id = PolylineId('p');
    final updates = PolylineUpdates.from(
      <Polyline>{Polyline(polylineId: id, points: oldPoints)},
      <Polyline>{Polyline(polylineId: id, points: newPoints)},
    );
    oldPoints.clear();
    newPoints.clear();
    expect(updates.previousObjects[id]!.points.last, const LatLng(3, 4));
    expect(updates.polylinesToChange.single.points.last, const LatLng(5, 6));
  });

  test('raw RGBA descriptors own their data and use identity equality', () {
    final bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
    final image = RawRgbaBitmap(bytes: bytes, width: 1, height: 1);
    final equalImage = RawRgbaBitmap(bytes: bytes, width: 1, height: 1);
    expect(image, same(image));
    expect(image, isNot(equalImage));
    bytes[0] = 99;
    expect(image.bytes[0], 1);
    expect(() => image.bytes[0] = 99, throwsUnsupportedError);
    expect(
      image,
      isNot(RawRgbaBitmap(bytes: image.bytes, width: 1, height: 1, imagePixelRatio: 2)),
    );
    expect(
      image,
      isNot(RawRgbaBitmap(bytes: image.bytes, width: 1, height: 1, premultipliedAlpha: false)),
    );
    expect(image, isNot(RawRgbaBitmap(bytes: bytes, width: 1, height: 1)));
    expect((image.toJson() as List<Object>)[0], RawRgbaBitmap.type);
  });

  test('raw RGBA rejects invalid dimensions, scale and length in release too', () {
    expect(() => RawRgbaBitmap(bytes: Uint8List(4), width: 0, height: 1), throwsArgumentError);
    expect(() => RawRgbaBitmap(bytes: Uint8List(3), width: 1, height: 1), throwsArgumentError);
    for (final ratio in <double>[0, -1, double.nan, double.infinity]) {
      expect(
        () => RawRgbaBitmap(bytes: Uint8List(4), width: 1, height: 1, imagePixelRatio: ratio),
        throwsArgumentError,
      );
    }
  });

  test('polyline stamp survives cloning and can be explicitly cleared', () {
    const line = Polyline(
      polylineId: PolylineId('p'),
      iosStampStyle: BitmapDescriptor.defaultMarker,
    );
    expect(line.clone().iosStampStyle, line.iosStampStyle);
    final Polyline cleared = line.copyWith(clearIosStampStyle: true);
    expect(cleared.iosStampStyle, isNull);
    expect(line, isNot(cleared));
    expect((line.toJson() as Map<String, Object>)['iosStampStyle'], isNotNull);
  });

  test('asset bitmap equality includes every rendering parameter', () {
    // ignore: deprecated_member_use_from_same_package
    final BitmapDescriptor first = BitmapDescriptor.fromJson(<Object>[
      'fromAssetImage',
      'icon.png',
      2.0,
    ]);
    // ignore: deprecated_member_use_from_same_package
    final BitmapDescriptor second = BitmapDescriptor.fromJson(<Object>[
      'fromAssetImage',
      'icon.png',
      2.0,
    ]);
    // ignore: deprecated_member_use_from_same_package
    final BitmapDescriptor scaled = BitmapDescriptor.fromJson(<Object>[
      'fromAssetImage',
      'icon.png',
      3.0,
    ]);
    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first, isNot(scaled));
    final image = AssetMapBitmap('icon.png', imagePixelRatio: 2, width: 12, height: 8);
    final equalImage = AssetMapBitmap('icon.png', imagePixelRatio: 2, width: 12, height: 8);
    expect(image, equalImage);
    expect(image.hashCode, equalImage.hashCode);
    expect(image, isNot(AssetMapBitmap('icon.png', imagePixelRatio: 2, width: 13, height: 8)));
    expect(image, isNot(AssetMapBitmap('icon.png', imagePixelRatio: 3, width: 12, height: 8)));
    expect(
      AssetMapBitmap('icon.png'),
      isNot(AssetMapBitmap('icon.png', bitmapScaling: MapBitmapScaling.none)),
    );
  });

  test('camera gesture reason is additive', () {
    expect(CameraMoveStartedEvent(7).isGesture, isFalse);
    final event = CameraMoveStartedEvent(7, isGesture: true);
    expect(event.mapId, 7);
    expect(event.isGesture, isTrue);
  });
}
