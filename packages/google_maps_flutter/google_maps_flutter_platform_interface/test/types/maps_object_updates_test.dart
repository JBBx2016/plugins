// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_platform_interface/src/types/maps_object.dart';
import 'package:google_maps_flutter_platform_interface/src/types/maps_object_updates.dart';
import 'package:google_maps_flutter_platform_interface/src/types/utils/maps_object.dart';

import 'test_maps_object.dart';

class TestMapsObjectUpdate extends MapsObjectUpdates<TestMapsObject> {
  TestMapsObjectUpdate.from(
      Set<TestMapsObject> previous, Set<TestMapsObject> current)
      : super.from(previous, current, objectName: 'testObject');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tile overlay updates tests', () {
    test('Correctly set toRemove, toAdd and toChange', () async {
      const TestMapsObject to1 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id1'));
      const TestMapsObject to2 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id2'));
      const TestMapsObject to3 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id3'));
      const TestMapsObject to3Changed =
          TestMapsObject(MapsObjectId<TestMapsObject>('id3'), data: 2);
      const TestMapsObject to4 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id4'));
      final Set<TestMapsObject> previous =
          Set.from(<TestMapsObject>[to1, to2, to3]);
      final Set<TestMapsObject> current =
          Set.from(<TestMapsObject>[to2, to3Changed, to4]);
      final TestMapsObjectUpdate updates =
          TestMapsObjectUpdate.from(previous, current);

      final Set<MapsObjectId<TestMapsObject>> toRemove =
          Set.from(<MapsObjectId<TestMapsObject>>[
        const MapsObjectId<TestMapsObject>('id1')
      ]);
      expect(updates.objectIdsToRemove, toRemove);

      final Set<TestMapsObject> toAdd = Set.from(<TestMapsObject>[to4]);
      expect(updates.objectsToAdd, toAdd);

      final Set<TestMapsObject> toChange =
          Set.from(<TestMapsObject>[to3Changed]);
      expect(updates.objectsToChange, toChange);
    });

    test('toJson', () async {
      const TestMapsObject to1 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id1'));
      const TestMapsObject to2 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id2'));
      const TestMapsObject to3 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id3'));
      const TestMapsObject to3Changed =
          TestMapsObject(MapsObjectId<TestMapsObject>('id3'), data: 2);
      const TestMapsObject to4 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id4'));
      final Set<TestMapsObject> previous =
          Set.from(<TestMapsObject>[to1, to2, to3]);
      final Set<TestMapsObject> current =
          Set.from(<TestMapsObject>[to2, to3Changed, to4]);
      final TestMapsObjectUpdate updates =
          TestMapsObjectUpdate.from(previous, current);

      final Object json = updates.toJson();
      expect(json, <String, Object>{
        'bitmapDescriptors': const <dynamic>[],
        'testObjectsToAdd': serializeMapsObjectSet(updates.objectsToAdd),
        'testObjectsToChange': serializeMapsObjectSet(updates.objectsToChange),
        'testObjectIdsToRemove': updates.objectIdsToRemove
            .map<String>((MapsObjectId<TestMapsObject> m) => m.value)
            .toList()
      });
    });

    test('equality', () async {
      const TestMapsObject to1 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id1'));
      const TestMapsObject to2 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id2'));
      const TestMapsObject to3 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id3'));
      const TestMapsObject to3Changed =
          TestMapsObject(MapsObjectId<TestMapsObject>('id3'), data: 2);
      const TestMapsObject to4 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id4'));
      final Set<TestMapsObject> previous =
          Set.from(<TestMapsObject>[to1, to2, to3]);
      final Set<TestMapsObject> current1 =
          Set.from(<TestMapsObject>[to2, to3Changed, to4]);
      final Set<TestMapsObject> current2 =
          Set.from(<TestMapsObject>[to2, to3Changed, to4]);
      final Set<TestMapsObject> current3 = Set.from(<TestMapsObject>[to2, to4]);
      final TestMapsObjectUpdate updates1 =
          TestMapsObjectUpdate.from(previous, current1);
      final TestMapsObjectUpdate updates2 =
          TestMapsObjectUpdate.from(previous, current2);
      final TestMapsObjectUpdate updates3 =
          TestMapsObjectUpdate.from(previous, current3);
      expect(updates1, updates2);
      expect(updates1, isNot(updates3));
    });

    test('hashCode', () async {
      const TestMapsObject to1 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id1'));
      const TestMapsObject to2 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id2'));
      const TestMapsObject to3 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id3'));
      const TestMapsObject to3Changed =
          TestMapsObject(MapsObjectId<TestMapsObject>('id3'), data: 2);
      const TestMapsObject to4 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id4'));
      final Set<TestMapsObject> previous =
          Set.from(<TestMapsObject>[to1, to2, to3]);
      final Set<TestMapsObject> current =
          Set.from(<TestMapsObject>[to2, to3Changed, to4]);
      final TestMapsObjectUpdate updates =
          TestMapsObjectUpdate.from(previous, current);
      expect(
          updates.hashCode,
          Object.hash(
              Object.hashAll(updates.objectsToAdd),
              Object.hashAll(updates.objectIdsToRemove),
              Object.hashAll(updates.objectsToChange)));
    });

    test('toString', () async {
      const TestMapsObject to1 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id1'));
      const TestMapsObject to2 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id2'));
      const TestMapsObject to3 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id3'));
      const TestMapsObject to3Changed =
          TestMapsObject(MapsObjectId<TestMapsObject>('id3'), data: 2);
      const TestMapsObject to4 =
          TestMapsObject(MapsObjectId<TestMapsObject>('id4'));
      final Set<TestMapsObject> previous =
          Set.from(<TestMapsObject>[to1, to2, to3]);
      final Set<TestMapsObject> current =
          Set.from(<TestMapsObject>[to2, to3Changed, to4]);
      final TestMapsObjectUpdate updates =
          TestMapsObjectUpdate.from(previous, current);
      expect(
          updates.toString(),
          'TestMapsObjectUpdate(add: ${updates.objectsToAdd}, '
          'remove: ${updates.objectIdsToRemove}, '
          'change: ${updates.objectsToChange})');
    });
  });

  group("zipObjects", () {
    test("Removed one item", () {
      final marker1 = Marker(markerId: MarkerId("1"));

      final removedSet = <Marker>{};

      zipObjects<Marker>([marker1], [],
          (previous, next) {
        if (next == null) {
          removedSet.add(previous!);
        }
      });

      expect(removedSet, {marker1});
    });

    test("Removed duplicate item", () {
      final marker1 = Marker(markerId: MarkerId("1"));

      final removedSet = <Marker>{};

      zipObjects<Marker>([marker1, marker1], [],
          (previous, next) {
        if (next == null) {
          removedSet.add(previous!);
        }
      }, debugRunDuplicateChecks: false);

      expect(removedSet, {marker1});
    });

    test("Rearranging and removing", () {
      final marker1 = Marker(markerId: MarkerId("1"));
      final marker2 = Marker(markerId: MarkerId("2"));
      final marker3 = Marker(markerId: MarkerId("3"));

      final removedSet = <Marker>{};

      zipObjects<Marker>([marker2, marker1, marker3], [marker1, marker2],
          (previous, next) {
        if (next == null) {
          removedSet.add(previous!);
        }
      });

      expect(removedSet, {marker3});
    });

    test("Rearranging and removing", () {
      final marker1 = Marker(markerId: MarkerId("1"));
      final marker2 = Marker(markerId: MarkerId("2"));
      final marker3 = Marker(markerId: MarkerId("3"));

      final removedSet = <Marker>{};

      zipObjects<Marker>([marker2, marker1, marker3], [marker1, marker2],
          (previous, next) {
        if (next == null) {
          removedSet.add(previous!);
        }
      });

      expect(removedSet, {marker3});
    });

    test("Replacing last item", () {
      final marker1 = Marker(markerId: MarkerId("1"));
      final marker2 = Marker(markerId: MarkerId("2"));
      final marker3 = Marker(markerId: MarkerId("3"));

      final removedSet = <Marker>{};

      zipObjects<Marker>([marker1, marker2], [marker1, marker3],
          (previous, next) {
        if (next == null) {
          removedSet.add(previous!);
        }
      });

      expect(removedSet, equals({marker2}));
    });

    test("Removing first item", () {
      final marker1 = Marker(markerId: MarkerId("1"));
      final marker2 = Marker(markerId: MarkerId("2"));

      final removedSet = <Marker>{};

      zipObjects<Marker>([marker1, marker2], [marker2], (previous, next) {
        if (next == null) {
          removedSet.add(previous!);
        }
      });

      expect(removedSet, equals({marker1}));
    });
    test("Removing last item", () {
      final marker1 = Marker(markerId: MarkerId("1"));
      final marker2 = Marker(markerId: MarkerId("2"));

      final removedSet = <Marker>{};

      zipObjects<Marker>([marker1, marker2], [], (previous, next) {
        expect(next, isNull);
        removedSet.add(previous!);
      });

      expect(removedSet, equals({marker1, marker2}));
    });
  });
}
