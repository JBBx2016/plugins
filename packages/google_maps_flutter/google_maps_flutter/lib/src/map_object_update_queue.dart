// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

/// Serializes state updates, replacing pending work with the newest snapshot.
///
/// Inputs are cloned before they can be retained across an asynchronous call.
/// On failure the native state is uncertain, so the next submission removes all
/// possibly present IDs before recreating the requested state. There is no
/// automatic retry when no newer state has been submitted.
class MapObjectUpdateQueue<T extends MapsObject<T>> {
  /// Creates a queue whose initial objects already exist on the native map.
  MapObjectUpdateQueue({
    required Iterable<T> initialObjects,
    required this.sendUpdate,
    required this.onError,
  }) {
    _acknowledged = _snapshot(initialObjects);
    _latest = _acknowledged;
  }

  /// Applies a change from the previous state to the current state.
  final Future<void> Function(Set<T> previous, Set<T> current) sendUpdate;

  /// Reports a failed update without discarding subsequent submissions.
  final void Function(Object error, StackTrace stack) onError;

  late Map<MapsObjectId<T>, T> _acknowledged;
  late Map<MapsObjectId<T>, T> _latest;
  Map<MapsObjectId<T>, T>? _pending;
  Map<MapsObjectId<T>, T>? _uncertain;
  bool _working = false;
  bool _disposed = false;

  /// The latest submitted objects, including callback-only changes.
  Map<MapsObjectId<T>, T> get latest => UnmodifiableMapView(_latest);

  /// Replaces the pending state. At most one native update is in flight.
  void submit(Iterable<T> objects) {
    if (_disposed) {
      return;
    }
    _latest = _snapshot(objects);
    _pending = _latest;
    if (!_working) {
      _working = true;
      unawaited(_drain());
    }
  }

  Map<MapsObjectId<T>, T> _snapshot(Iterable<T> objects) {
    final result = <MapsObjectId<T>, T>{};
    for (final object in objects) {
      assert(!result.containsKey(object.mapsId), 'Map objects must have unique IDs.');
      result[object.mapsId] = object.clone();
    }
    return result;
  }

  Future<void> _drain() async {
    try {
      while (!_disposed && _pending != null) {
        final Map<MapsObjectId<T>, T> target = _pending!;
        _pending = null;
        try {
          final Map<MapsObjectId<T>, T>? uncertain = _uncertain;
          if (uncertain != null) {
            await sendUpdate(uncertain.values.toSet(), <T>{});
            if (_disposed) {
              return;
            }
            _acknowledged = <MapsObjectId<T>, T>{};
            _uncertain = null;
          }
          await sendUpdate(_acknowledged.values.toSet(), target.values.toSet());
          if (!_disposed) {
            _acknowledged = target;
          }
        } catch (error, stack) {
          if (_disposed) {
            return;
          }
          _uncertain = <MapsObjectId<T>, T>{...?_uncertain, ..._acknowledged, ...target};
          onError(error, stack);
        }
      }
    } finally {
      _working = false;
    }
  }

  /// Drops pending work and ignores completion of any in-flight request.
  void dispose() {
    _disposed = true;
    _pending = null;
    _uncertain = null;
    _latest = <MapsObjectId<T>, T>{};
    _acknowledged = <MapsObjectId<T>, T>{};
  }
}
