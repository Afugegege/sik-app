enum StorageLocation { fridge, freezer, pantry, seasoning }

enum QuantityMode { exact, approximate, none }

class FridgeItem {
  final String id;
  final String name;
  final StorageLocation location;
  final QuantityMode quantityMode;
  final String? quantityDisplay; // e.g. "6 pieces", "500 ml", "A little", "Plenty"
  final String status; // 'Have' | 'Running low' | 'Missing' | 'Want'

  const FridgeItem({
    required this.id,
    required this.name,
    required this.location,
    this.quantityMode = QuantityMode.approximate,
    this.quantityDisplay,
    this.status = 'Have',
  });

  FridgeItem copyWith({
    String? id,
    String? name,
    StorageLocation? location,
    QuantityMode? quantityMode,
    String? quantityDisplay,
    String? status,
  }) {
    return FridgeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      quantityMode: quantityMode ?? this.quantityMode,
      quantityDisplay: quantityDisplay ?? this.quantityDisplay,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location.name,
      'quantityMode': quantityMode.name,
      'quantityDisplay': quantityDisplay,
      'status': status,
    };
  }

  factory FridgeItem.fromJson(Map<String, dynamic> json) {
    StorageLocation loc;
    final locStr = (json['location'] as String? ?? 'fridge').toLowerCase();
    switch (locStr) {
      case 'freezer':
        loc = StorageLocation.freezer;
        break;
      case 'pantry':
        loc = StorageLocation.pantry;
        break;
      case 'seasoning':
        loc = StorageLocation.seasoning;
        break;
      default:
        loc = StorageLocation.fridge;
    }

    QuantityMode mode;
    final modeStr = (json['quantityMode'] as String? ?? 'approximate').toLowerCase();
    switch (modeStr) {
      case 'exact':
        mode = QuantityMode.exact;
        break;
      case 'none':
        mode = QuantityMode.none;
        break;
      default:
        mode = QuantityMode.approximate;
    }

    return FridgeItem(
      id: json['id'] as String? ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? '',
      location: loc,
      quantityMode: mode,
      quantityDisplay: json['quantityDisplay'] as String?,
      status: json['status'] as String? ?? 'Have',
    );
  }
}
