// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/src/map_object_update_queue.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('keeps one request in flight and skips intermediate states', () async {
    final firstAck = Completer<void>();
    final calls = <MarkerUpdates>[];
    final queue = MapObjectUpdateQueue<Marker>(
      initialObjects: <Marker>[],
      sendUpdate: (previous, current) async {
        calls.add(MarkerUpdates.from(previous, current));
        if (calls.length == 1) {
          await firstAck.future;
        }
      },
      onError: (error, stack) => fail('$error'),
    );
    const marker = Marker(markerId: MarkerId('m'));
    queue.submit(<Marker>[marker]);
    queue.submit(<Marker>[marker.copyWith(rotationParam: 10)]);
    queue.submit(<Marker>[marker.copyWith(rotationParam: 20)]);
    expect(calls, hasLength(1));
    firstAck.complete();
    await flush();
    expect(calls, hasLength(2));
    expect(calls.last.markersToChange.single.rotation, 20);
    expect(calls.last.previousMarkers[marker.markerId]!.rotation, 0);
    queue.dispose();
  });

  test('failed partial update is removed before the next full snapshot', () async {
    final native = <MarkerId, Marker>{};
    final calls = <MarkerUpdates>[];
    final errors = <Object>[];
    var failNext = true;
    final queue = MapObjectUpdateQueue<Marker>(
      initialObjects: <Marker>[],
      sendUpdate: (previous, current) async {
        final updates = MarkerUpdates.from(previous, current);
        calls.add(updates);
        updates.markerIdsToRemove.forEach(native.remove);
        for (final marker in <Marker>{...updates.markersToAdd, ...updates.markersToChange}) {
          native[marker.markerId] = marker;
        }
        if (failNext) {
          failNext = false;
          throw StateError('Partial update');
        }
      },
      onError: (error, stack) => errors.add(error),
    );
    const first = Marker(markerId: MarkerId('first'));
    const second = Marker(markerId: MarkerId('second'));
    queue.submit(<Marker>[first]);
    await flush();
    expect(errors, hasLength(1));
    expect(calls, hasLength(1)); // No retry loop without another submission.
    expect(native.keys, <MarkerId>[first.markerId]);
    queue.submit(<Marker>[second]);
    await flush();
    expect(calls, hasLength(3));
    expect(calls[1].markerIdsToRemove, <MarkerId>{first.markerId});
    expect(calls[2].markersToAdd, <Marker>{second});
    expect(native, <MarkerId, Marker>{second.markerId: second});
    queue.dispose();
  });

  test('pending geometry is snapshotted before callers can mutate it', () async {
    final firstAck = Completer<void>();
    final calls = <PolylineUpdates>[];
    final queue = MapObjectUpdateQueue<Polyline>(
      initialObjects: <Polyline>[],
      sendUpdate: (previous, current) async {
        calls.add(PolylineUpdates.from(previous, current));
        if (calls.length == 1) {
          await firstAck.future;
        }
      },
      onError: (error, stack) => fail('$error'),
    );
    const id = PolylineId('p');
    queue.submit(<Polyline>[const Polyline(polylineId: id)]);
    final points = <LatLng>[const LatLng(1, 2), const LatLng(3, 4)];
    queue.submit(<Polyline>[Polyline(polylineId: id, points: points)]);
    points.clear();
    firstAck.complete();
    await flush();
    expect(calls.last.polylinesToChange.single.points, hasLength(2));
    queue.dispose();
  });

  test('dispose drops pending work and ignores an in-flight error', () async {
    final ack = Completer<void>();
    var calls = 0;
    final errors = <Object>[];
    final queue = MapObjectUpdateQueue<Marker>(
      initialObjects: <Marker>[],
      sendUpdate: (previous, current) {
        calls++;
        return ack.future;
      },
      onError: (error, stack) => errors.add(error),
    );
    queue.submit(<Marker>[const Marker(markerId: MarkerId('first'))]);
    queue.submit(<Marker>[const Marker(markerId: MarkerId('second'))]);
    queue.dispose();
    ack.completeError(StateError('Disposed'));
    await flush();
    queue.submit(<Marker>[]);
    expect(calls, 1);
    expect(errors, isEmpty);
  });
}
