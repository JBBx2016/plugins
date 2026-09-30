// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'fake_google_maps_flutter_platform.dart';

Widget mapWidget({
  Set<Marker> markers = const <Marker>{},
  VoidCallback? onCameraMoveStarted,
  ValueChanged<CameraMoveStartedEvent>? onCameraMoveStartedWithReason,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: GoogleMap(
    initialCameraPosition: const CameraPosition(target: LatLng(0, 0)),
    markers: markers,
    onCameraMoveStarted: onCameraMoveStarted,
    onCameraMoveStartedWithReason: onCameraMoveStartedWithReason,
  ),
);

class DelayedMarkerPlatform extends FakeGoogleMapsFlutterPlatform {
  final calls = <MarkerUpdates>[];
  final acknowledgments = <Completer<void>>[];

  @override
  Future<void> updateMarkers(MarkerUpdates updates, {required int mapId}) {
    calls.add(updates);
    final ack = Completer<void>();
    acknowledgments.add(ack);
    return ack.future;
  }
}

void main() {
  testWidgets('widget coalesces marker updates while platform acknowledgment is pending', (
    tester,
  ) async {
    final platform = DelayedMarkerPlatform();
    GoogleMapsFlutterPlatform.instance = platform;
    const marker = Marker(markerId: MarkerId('m'));
    await tester.pumpWidget(mapWidget(markers: <Marker>{marker}));
    for (final rotation in <double>[10, 20, 30]) {
      await tester.pumpWidget(
        mapWidget(markers: <Marker>{marker.copyWith(rotationParam: rotation)}),
      );
    }
    expect(platform.calls, hasLength(1));
    expect(platform.calls.first.markersToChange.single.rotation, 10);
    platform.acknowledgments.first.complete();
    await tester.pump();
    expect(platform.calls, hasLength(2));
    expect(platform.calls.last.markersToChange.single.rotation, 30);
    expect(platform.calls.last.previousMarkers[marker.markerId]!.rotation, 10);
    platform.acknowledgments.last.complete();
    await tester.pump();
  });

  testWidgets('callback-only changes skip native updates but use the newest callback', (
    tester,
  ) async {
    final platform = FakeGoogleMapsFlutterPlatform();
    GoogleMapsFlutterPlatform.instance = platform;
    var oldTaps = 0;
    var newTaps = 0;
    const id = MarkerId('m');
    await tester.pumpWidget(
      mapWidget(
        markers: <Marker>{Marker(markerId: id, onTap: () => oldTaps++)},
      ),
    );
    final int initialCalls = platform.lastCreatedMap.markerUpdates.length;
    await tester.pumpWidget(
      mapWidget(
        markers: <Marker>{Marker(markerId: id, onTap: () => newTaps++)},
      ),
    );
    expect(platform.lastCreatedMap.markerUpdates, hasLength(initialCalls));
    platform.mapEventStreamController.add(MarkerTapEvent(platform.createdIds.last, id));
    await tester.pump();
    expect(oldTaps, 0);
    expect(newTaps, 1);
  });

  testWidgets('legacy and reason callbacks can be added and removed after creation', (
    tester,
  ) async {
    final platform = FakeGoogleMapsFlutterPlatform();
    GoogleMapsFlutterPlatform.instance = platform;
    var calls = 0;
    final gestures = <bool>[];
    await tester.pumpWidget(mapWidget());
    await tester.pumpWidget(
      mapWidget(
        onCameraMoveStarted: () => calls++,
        onCameraMoveStartedWithReason: (event) => gestures.add(event.isGesture),
      ),
    );
    final int id = platform.createdIds.last;
    platform.mapEventStreamController.add(CameraMoveStartedEvent(id, isGesture: true));
    await tester.pump();
    platform.mapEventStreamController.add(CameraMoveStartedEvent(id));
    await tester.pump();
    expect(calls, 2);
    expect(gestures, <bool>[true, false]);
    await tester.pumpWidget(mapWidget());
    platform.mapEventStreamController.add(CameraMoveStartedEvent(id, isGesture: true));
    await tester.pump();
    expect(calls, 2);
    expect(gestures, hasLength(2));
  });
}
