import 'fridge_item.dart';

enum BatchActionType { add, update, remove }

class InventoryBatchActionItem {
  String id;
  String name;
  StorageLocation location;
  String quantityDisplay;
  String status; // 'Have' | 'Running low' | 'Missing'
  BatchActionType actionType;
  bool isSelected;

  InventoryBatchActionItem({
    required this.id,
    required this.name,
    this.location = StorageLocation.fridge,
    this.quantityDisplay = 'Plenty',
    this.status = 'Have',
    this.actionType = BatchActionType.add,
    this.isSelected = true,
  });

  InventoryBatchActionItem copyWith({
    String? id,
    String? name,
    StorageLocation? location,
    String? quantityDisplay,
    String? status,
    BatchActionType? actionType,
    bool? isSelected,
  }) {
    return InventoryBatchActionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      quantityDisplay: quantityDisplay ?? this.quantityDisplay,
      status: status ?? this.status,
      actionType: actionType ?? this.actionType,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
