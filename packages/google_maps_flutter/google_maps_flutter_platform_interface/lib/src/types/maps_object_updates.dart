// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart' show immutable, objectRuntimeType, setEquals;

import 'maps_object.dart';
import 'utils/maps_object.dart';

/// Update specification for a set of objects.
@immutable
class MapsObjectUpdates<T extends MapsObject<T>> {
  /// Computes updates given previous and current object sets.
  ///
  /// [objectName] is the prefix to use when serializing the updates into a JSON
  /// dictionary. E.g., 'circle' will give 'circlesToAdd', 'circlesToUpdate',
  /// 'circleIdsToRemove'.
  MapsObjectUpdates.from(Set<T> previous, Set<T> current, {required this.objectName})
    : assert(_hasUniqueIds(previous), 'Previous objects must have unique IDs.'),
      assert(_hasUniqueIds(current), 'Current objects must have unique IDs.') {
    final Iterator<T> previousIterator = previous.iterator;
    final Iterator<T> currentIterator = current.iterator;
    bool hasPrevious = previousIterator.moveNext();
    bool hasCurrent = currentIterator.moveNext();

    // Match the ordered prefix without allocating keyed copies of every object.
    while (hasPrevious &&
        hasCurrent &&
        previousIterator.current.mapsId == currentIterator.current.mapsId) {
      _compare(previousIterator.current, currentIterator.current);
      hasPrevious = previousIterator.moveNext();
      hasCurrent = currentIterator.moveNext();
    }
    if (!hasPrevious) {
      while (hasCurrent) {
        _objectsToAdd.add(currentIterator.current.clone());
        hasCurrent = currentIterator.moveNext();
      }
      return;
    }
    if (!hasCurrent) {
      while (hasPrevious) {
        _objectIdsToRemove.add(previousIterator.current.mapsId);
        hasPrevious = previousIterator.moveNext();
      }
      return;
    }

    // Only the unmatched suffix needs lookup storage when IDs are reordered.
    final remaining = <MapsObjectId<T>, T>{};
    while (hasPrevious) {
      final T object = previousIterator.current;
      remaining[object.mapsId] = object;
      hasPrevious = previousIterator.moveNext();
    }
    while (hasCurrent) {
      final T object = currentIterator.current;
      final T? oldObject = remaining.remove(object.mapsId);
      if (oldObject == null) {
        _objectsToAdd.add(object.clone());
      } else {
        _compare(oldObject, object);
      }
      hasCurrent = currentIterator.moveNext();
    }
    _objectIdsToRemove.addAll(remaining.keys);
  }

  void _compare(T previous, T current) {
    if (previous != current) {
      _objectsToChange.add(current.clone());
      _previousObjects[previous.mapsId] = previous.clone();
    }
  }

  static bool _hasUniqueIds<T extends MapsObject<T>>(Iterable<T> objects) {
    final ids = <MapsObjectId<T>>{};
    return objects.every((T object) => ids.add(object.mapsId));
  }

  /// Previous snapshots for changed objects, keyed by object ID.
  ///
  /// Platform implementations can compare these snapshots with [objectsToChange]
  /// to send only changed properties. Added objects have no previous snapshot.
  Map<MapsObjectId<T>, T> get previousObjects => UnmodifiableMapView(_previousObjects);

  final Map<MapsObjectId<T>, T> _previousObjects = <MapsObjectId<T>, T>{};

  /// Whether this update contains no additions, changes, or removals.
  bool get isEmpty =>
      _objectsToAdd.isEmpty && _objectsToChange.isEmpty && _objectIdsToRemove.isEmpty;

  /// Whether this update contains additions, changes, or removals.
  bool get isNotEmpty => !isEmpty;

  /// The name of the objects being updated, for use in serialization.
  final String objectName;

  /// Set of objects to be added in this update.
  Set<T> get objectsToAdd {
    return _objectsToAdd;
  }

  final Set<T> _objectsToAdd = <T>{};

  /// Set of objects to be removed in this update.
  Set<MapsObjectId<T>> get objectIdsToRemove {
    return _objectIdsToRemove;
  }

  final Set<MapsObjectId<T>> _objectIdsToRemove = <MapsObjectId<T>>{};

  /// Set of objects to be changed in this update.
  Set<T> get objectsToChange {
    return _objectsToChange;
  }

  final Set<T> _objectsToChange = <T>{};

  /// Converts this object to JSON.
  Object toJson() {
    final updateMap = <String, Object>{};

    void addIfNonNull(String fieldName, Object? value) {
      if (value != null) {
        updateMap[fieldName] = value;
      }
    }

    addIfNonNull('${objectName}sToAdd', serializeMapsObjectSet(_objectsToAdd));
    addIfNonNull('${objectName}sToChange', serializeMapsObjectSet(_objectsToChange));
    addIfNonNull(
      '${objectName}IdsToRemove',
      _objectIdsToRemove.map<String>((MapsObjectId<T> m) => m.value).toList(),
    );

    return updateMap;
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MapsObjectUpdates &&
        setEquals(_objectsToAdd, other._objectsToAdd) &&
        setEquals(_objectIdsToRemove, other._objectIdsToRemove) &&
        setEquals(_objectsToChange, other._objectsToChange);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(_objectsToAdd),
    Object.hashAll(_objectIdsToRemove),
    Object.hashAll(_objectsToChange),
  );

  @override
  String toString() {
    return '${objectRuntimeType(this, 'MapsObjectUpdates')}(add: $objectsToAdd, '
        'remove: $objectIdsToRemove, '
        'change: $objectsToChange)';
  }
}
