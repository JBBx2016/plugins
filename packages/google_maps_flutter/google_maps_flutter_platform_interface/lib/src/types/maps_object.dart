// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart'
    show immutable, objectRuntimeType, visibleForTesting;
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'maps_object_serializer.dart';

/// Uniquely identifies object an among [GoogleMap] collections of a specific
/// type.
///
/// This does not have to be globally unique, only unique among the collection.
@immutable
class MapsObjectId<T> {
  /// Creates an immutable object representing a [T] among [GoogleMap] Ts.
  ///
  /// An [AssertionError] will be thrown if [value] is null.
  const MapsObjectId(this.value) : assert(value != null);

  /// The value of the id.
  final String value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final MapsObjectId<T> typedOther = other as MapsObjectId<T>;
    return value == typedOther.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return '${objectRuntimeType(this, 'MapsObjectId')}($value)';
  }
}

/// A common interface for maps types.
abstract class MapsObject<T> {
  /// A identifier for this object.
  MapsObjectId<T> get mapsId;

  /// Returns a duplicate of this object.
  @visibleForTesting
  T clone();

  /// Uses the [MapsObjectUpdatesSerializerContext] to optimize passing of
  /// [BitmapDescriptor]s.
  Map<String, dynamic> serialize({
    required MapsObjectUpdatesSerializerContext context,
    required MapsObject<T>? previous,
  }) {
    return toJson(previous);
  }

  /// Converts this object to something serializable in JSON.
  Map<String, dynamic> toJson([MapsObject<T>? previous]);
}
