// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show hashValues, hashList;

import 'package:flutter/foundation.dart' show listEquals, objectRuntimeType;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter_platform_interface/src/types/maps_object_serializer.dart';

import 'maps_object.dart';

/// Update specification for a set of objects.
class MapsObjectUpdates<T extends MapsObject> {
  MapsObjectUpdates.from(
    Iterable<T> previous,
    Iterable<T> current, {
    required this.objectName,
  }) {
    _apply(previous, current);
  }

  /// Computes updates given previous and current object sets.
  ///
  /// [objectName] is the prefix to use when serializing the updates into a JSON
  /// dictionary. E.g., 'circle' will give 'circlesToAdd', 'circlesToUpdate',
  /// 'circleIdsToRemove'.
  MapsObjectUpdates.mapFrom(
    Map<MapsObjectId<T>, T> previousObjects,
    Map<MapsObjectId<T>, T> currentObjects, {
    required this.objectName,
  }) {
    _apply(previousObjects.values, currentObjects.values);
  }

  void _apply(Iterable<T> previousObjects, Iterable<T> currentObjects) {
    _objectIdsToRemove = [];
    _objectsToAdd = [];
    _objectsToChange = [];
    _objectsToChangePrevious = [];

    zipObjects<T>(previousObjects, currentObjects, (previous, current) {
      if (current != null && previous != null) {
        final hasChanged = !identical(current, previous) && current != previous;

        if (hasChanged) {
          _objectsToChange.add(current);
          _objectsToChangePrevious.add(previous);
        }
      } else if (current != null) {
        _objectsToAdd.add(current);
      } else if (previous != null) {
        _objectIdsToRemove.add(previous.mapsId as MapsObjectId<T>);
      }
    });
  }

  /// The name of the objects being updated, for use in serialization.
  final String objectName;

  /// Set of objects to be added in this update.
  List<T> get objectsToAdd {
    return _objectsToAdd;
  }

  late List<T> _objectsToAdd;

  /// Set of objects to be removed in this update.
  List<MapsObjectId<T>> get objectIdsToRemove {
    return _objectIdsToRemove;
  }

  late List<MapsObjectId<T>> _objectIdsToRemove;

  /// Set of objects to be changed in this update.
  List<T> get objectsToChange {
    return _objectsToChange;
  }

  late List<T> _objectsToChange;
  late List<T> _objectsToChangePrevious;

  /// Converts this object to JSON.
  Object toJson() {
    final serializer = MapsObjectUpdatesSerializer(objectName: objectName)
      ..writeObjectsToAdd(_objectsToAdd)
      ..writeObjectsToChange(_objectsToChange, _objectsToChangePrevious)
      ..writeObjectsToRemove(_objectIdsToRemove);

    return serializer.toJson();
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MapsObjectUpdates &&
        listEquals(_objectsToAdd, other._objectsToAdd) &&
        listEquals(_objectIdsToRemove, other._objectIdsToRemove) &&
        listEquals(_objectsToChange, other._objectsToChange);
  }

  @override
  int get hashCode => hashValues(hashList(_objectsToAdd),
      hashList(_objectIdsToRemove), hashList(_objectsToChange));

  @override
  String toString() {
    return '${objectRuntimeType(this, 'MapsObjectUpdates')}(add: $objectsToAdd, '
        'remove: $objectIdsToRemove, '
        'change: $objectsToChange)';
  }

  bool get isNotEmpty =>
      objectsToAdd.isNotEmpty ||
      objectsToChange.isNotEmpty ||
      objectIdsToRemove.isNotEmpty;
}

@visibleForTesting
void zipObjects<T extends MapsObject>(Iterable<T> previousObjects,
    Iterable<T> currentObjects, void Function(T? previous, T? current) callback,
    {bool debugRunDuplicateChecks = true}) {
  final currentIterator = currentObjects.iterator;
  final previousIterator = previousObjects.iterator;

  /// 99% of the time - exact same key order
  /// 1% of the time - fallback to map strategy

  int successIndex = 0;
  var failed = false;

  while (currentIterator.moveNext()) {
    final current = currentIterator.current;

    if (!previousIterator.moveNext()) {
      callback(null, current);
      continue;
    }

    final previous = previousIterator.current;

    if (current.mapsId == previous.mapsId) {
      callback(previous, current);
    } else {
      /// Always means that this was added, or previous removed.
      failed = true;
      break;
    }

    successIndex++;
  }

  bool done =
      !failed && !currentIterator.moveNext() && !previousIterator.moveNext();

  if (!done) {
    final previousMap = Map<MapsObjectId<T>, T>.fromIterable(
        previousObjects.skip(successIndex),
        key: (e) => (e as T).mapsId as MapsObjectId<T>,
        value: (e) => (e as T));

    for (var current in currentObjects.skip(successIndex)) {
      final previous = previousMap.remove(current.mapsId);
      callback(previous, current);
    }

    for (var previous in previousMap.values) {
      callback(previous, null);
    }
  }

  if (debugRunDuplicateChecks) {
    assert(_checkNoDuplicates(previousObjects));
    assert(_checkNoDuplicates(currentObjects));
  }
}

bool _checkNoDuplicates(Iterable<MapsObject> currentObjects) {
  final current = <MapsObject>{};

  for (var object in currentObjects) {
    if (!current.add(object)) {
      return false;
    }
  }

  return true;
}
