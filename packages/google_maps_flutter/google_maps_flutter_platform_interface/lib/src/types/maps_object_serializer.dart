import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

/// Improves serializer performance by reusing BitmapDescriptors in
abstract class MapsObjectUpdatesSerializerContext {
  /// Gives the index of the [BitmapDescriptor] inserted.
  int pushBitmapDescriptor(BitmapDescriptor bitmapDescriptor);
}

class MapsObjectUpdatesSerializer<T extends MapsObject>
    implements MapsObjectUpdatesSerializerContext {
  final String objectName;

  MapsObjectUpdatesSerializer({
    required this.objectName,
  });

  final Map<BitmapDescriptor, int> _bitmapDescriptorIndex = {};
  final List<BitmapDescriptor> _bitmapDescriptors = [];

  List<Map<String, dynamic>> _objectsToAdd = const [];
  List<Map<String, dynamic>> _objectsToChange = const [];
  List<String> _objectIdsToRemove = const [];

  int pushBitmapDescriptor(BitmapDescriptor bitmapDescriptor) {
    return _bitmapDescriptorIndex.putIfAbsent(bitmapDescriptor, () {
      _bitmapDescriptors.add(bitmapDescriptor);
      final index = _bitmapDescriptors.length - 1;
      return index;
    });
  }

  void writeObjectsToAdd(List<T> objects) {
    _objectsToAdd = List.generate(
      objects.length,
      (index) => objects[index].serialize(
        context: this,
        previous: null,
      ),
    );
  }

  void writeObjectsToChange(List<T> objects, List<T> previous) {
    _objectsToChange = List.generate(
      objects.length,
      (index) => objects[index].serialize(
        context: this,
        previous: previous[index],
      ),
    );
  }

  void writeObjectsToRemove(List<MapsObjectId<T>> ids) {
    _objectIdsToRemove = List.generate(
      ids.length,
      (index) => ids[index].value,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "bitmapDescriptors": _bitmapDescriptors,
      '${objectName}sToAdd': _objectsToAdd,
      '${objectName}sToChange': _objectsToChange,
      '${objectName}IdsToRemove': _objectIdsToRemove,
    };
  }
}
