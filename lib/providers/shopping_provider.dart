import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:todoapp/models/home_inventory_item.dart';
import 'package:todoapp/models/shop_category.dart';
import 'package:todoapp/models/shopping_list_item.dart';
import 'package:todoapp/models/wishlist_item.dart';
import 'package:uuid/uuid.dart';

class ShoppingProvider extends ChangeNotifier {
  final Box<ShopCategory> _catBox = Hive.box<ShopCategory>('shop_categories');
  final Box<ShoppingListItem> _shopBox =
      Hive.box<ShoppingListItem>('shopping_items');
  final Box<HomeInventoryItem> _invBox =
      Hive.box<HomeInventoryItem>('home_inventory');
  final Box<WishlistItem> _wishBox = Hive.box<WishlistItem>('wishlist_items');

  final _uuid = const Uuid();

  ShoppingProvider() {
    _seedCategories();
  }

  void _seedCategories() {
    if (_catBox.isNotEmpty) return;
    const defaults = [
      'Groceries',
      'Electronics',
      'Household',
      'Clothing',
      'Other',
    ];
    var order = 0;
    for (final name in defaults) {
      final id = _uuid.v4();
      _catBox.put(id, ShopCategory(id: id, name: name, sortOrder: order++));
    }
  }

  List<ShopCategory> get categories =>
      _catBox.values.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  ShopCategory? categoryById(String id) => _catBox.get(id);

  String categoryName(String id) => _catBox.get(id)?.name ?? 'Other';

  /// First category id (fallback).
  String get defaultCategoryId {
    final c = categories;
    return c.isEmpty ? '' : c.first.id;
  }

  void addCategory(String name) {
    final max = categories.isEmpty
        ? 0
        : categories.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b);
    final id = _uuid.v4();
    _catBox.put(id, ShopCategory(id: id, name: name.trim(), sortOrder: max + 1));
    notifyListeners();
  }

  void updateCategory(ShopCategory c) {
    c.save();
    notifyListeners();
  }

  void deleteCategory(String id) {
    String? fallback;
    for (final c in categories) {
      if (c.id != id) {
        fallback = c.id;
        break;
      }
    }
    if (fallback == null || fallback.isEmpty || fallback == id) return;
    for (final s in _shopBox.values.where((e) => e.categoryId == id)) {
      s.categoryId = fallback;
      s.save();
    }
    for (final i in _invBox.values.where((e) => e.categoryId == id)) {
      i.categoryId = fallback;
      i.save();
    }
    for (final w in _wishBox.values.where((e) => e.categoryId == id)) {
      w.categoryId = fallback;
      w.save();
    }
    _catBox.delete(id);
    notifyListeners();
  }

  // —— Shopping list ——
  List<ShoppingListItem> shoppingItems({String? categoryId}) {
    var list = _shopBox.values.toList();
    if (categoryId != null && categoryId.isNotEmpty) {
      list = list.where((e) => e.categoryId == categoryId).toList();
    }
    list.sort((a, b) {
      if (a.isChecked != b.isChecked) return a.isChecked ? 1 : -1;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return list;
  }

  void addShoppingItem({
    required String categoryId,
    required String name,
    String quantityLabel = '',
    String notes = '',
    double? unitPrice,
    double? lastRecordedPrice,
    String barcode = '',
  }) {
    final list = _shopBox.values.toList();
    final next = list.isEmpty
        ? 0
        : list.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    final id = _uuid.v4();
    _shopBox.put(
      id,
      ShoppingListItem(
        id: id,
        categoryId: categoryId,
        name: name,
        quantityLabel: quantityLabel,
        notes: notes,
        unitPrice: unitPrice,
        lastRecordedPrice: lastRecordedPrice,
        barcode: barcode,
        sortOrder: next,
      ),
    );
    notifyListeners();
  }

  void updateShoppingItem(ShoppingListItem item) {
    item.save();
    notifyListeners();
  }

  void toggleShoppingChecked(String id) {
    final i = _shopBox.get(id);
    if (i == null) return;
    i.isChecked = !i.isChecked;
    if (i.isChecked && i.unitPrice != null && i.unitPrice! > 0) {
      i.lastRecordedPrice = i.unitPrice;
    }
    i.save();
    notifyListeners();
  }

  void deleteShoppingItem(String id) {
    _shopBox.delete(id);
    notifyListeners();
  }

  void clearCheckedShopping() {
    final toRemove = _shopBox.values.where((e) => e.isChecked).map((e) => e.id);
    for (final id in toRemove) {
      _shopBox.delete(id);
    }
    notifyListeners();
  }

  // —— Inventory ——
  List<HomeInventoryItem> inventoryItems({String? categoryId}) {
    var list = _invBox.values.toList();
    if (categoryId != null && categoryId.isNotEmpty) {
      list = list.where((e) => e.categoryId == categoryId).toList();
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  void addInventoryItem({
    required String categoryId,
    required String name,
    String location = '',
    int quantity = 1,
    String notes = '',
    String barcode = '',
    double? valueEstimate,
  }) {
    final list = _invBox.values.toList();
    final next = list.isEmpty
        ? 0
        : list.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    final id = _uuid.v4();
    _invBox.put(
      id,
      HomeInventoryItem(
        id: id,
        categoryId: categoryId,
        name: name,
        location: location,
        quantity: quantity,
        notes: notes,
        barcode: barcode,
        valueEstimate: valueEstimate,
        sortOrder: next,
      ),
    );
    notifyListeners();
  }

  void updateInventoryItem(HomeInventoryItem item) {
    item.save();
    notifyListeners();
  }

  void deleteInventoryItem(String id) {
    _invBox.delete(id);
    notifyListeners();
  }

  // —— Wishlist ——
  List<WishlistItem> wishlistItems({String? categoryId, bool hidePurchased = false}) {
    var list = _wishBox.values.toList();
    if (hidePurchased) {
      list = list.where((e) => !e.isPurchased).toList();
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      list = list.where((e) => e.categoryId == categoryId).toList();
    }
    list.sort((a, b) {
      if (a.isPurchased != b.isPurchased) return a.isPurchased ? 1 : -1;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return list;
  }

  void addWishlistItem({
    required String title,
    String notes = '',
    String url = '',
    double? priceEstimate,
    String recipient = '',
    String categoryId = '',
    String barcode = '',
  }) {
    final list = _wishBox.values.toList();
    final next = list.isEmpty
        ? 0
        : list.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    final id = _uuid.v4();
    _wishBox.put(
      id,
      WishlistItem(
        id: id,
        title: title,
        notes: notes,
        url: url,
        priceEstimate: priceEstimate,
        recipient: recipient,
        categoryId: categoryId,
        barcode: barcode,
        sortOrder: next,
      ),
    );
    notifyListeners();
  }

  void updateWishlistItem(WishlistItem item) {
    item.save();
    notifyListeners();
  }

  void toggleWishlistPurchased(String id) {
    final w = _wishBox.get(id);
    if (w == null) return;
    w.isPurchased = !w.isPurchased;
    w.save();
    notifyListeners();
  }

  void deleteWishlistItem(String id) {
    _wishBox.delete(id);
    notifyListeners();
  }

  /// Find existing barcode across lists (for scan hints).
  String? lookupBarcode(String code) {
    if (code.isEmpty) return null;
    for (final s in _shopBox.values) {
      if (s.barcode == code) return 'Shopping: ${s.name}';
    }
    for (final i in _invBox.values) {
      if (i.barcode == code) return 'Inventory: ${i.name}';
    }
    for (final w in _wishBox.values) {
      if (w.barcode == code) return 'Wishlist: ${w.title}';
    }
    return null;
  }
}
