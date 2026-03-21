import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/home_inventory_item.dart';
import 'package:todoapp/models/shop_category.dart';
import 'package:todoapp/models/shopping_list_item.dart';
import 'package:todoapp/models/wishlist_item.dart';
import 'package:todoapp/providers/shopping_provider.dart';
import 'package:todoapp/screens/barcode_scan_screen.dart';

void _disposeControllersAfterDialog(List<TextEditingController> controllers) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final c in controllers) {
      c.dispose();
    }
  });
}

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int _tab = 0;
  String? _filterCategoryId;
  bool _hidePurchasedWishlist = false;

  final _money = NumberFormat.currency(symbol: r'$');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() => _tab = _tabs.index);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openScanner(BuildContext context) async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
    );
    if (!context.mounted || code == null || code.isEmpty) return;
    await _showAfterScanSheet(context, code);
  }

  Future<void> _showAfterScanSheet(BuildContext context, String barcode) async {
    final p = context.read<ShoppingProvider>();
    final hint = p.lookupBarcode(barcode);
    var target = 0;
    final nameC = TextEditingController(text: 'Item $barcode');
    var catId = p.defaultCategoryId;
    final qtyC = TextEditingController(text: '1');
    final locC = TextEditingController();
    final notesC = TextEditingController();
    final priceC = TextEditingController();
    final urlC = TextEditingController();
    final recipientC = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Barcode: $barcode',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Already have: $hint',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Shopping')),
                      ButtonSegment(value: 1, label: Text('Inventory')),
                      ButtonSegment(value: 2, label: Text('Wishlist')),
                    ],
                    selected: {target},
                    onSelectionChanged: (s) => setLocal(() => target = s.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameC,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  _CategoryDropdown(
                    categories: p.categories,
                    value: catId,
                    onChanged: (v) => setLocal(() => catId = v ?? catId),
                  ),
                  if (target == 0) ...[
                    TextField(
                      controller: qtyC,
                      decoration: const InputDecoration(
                        labelText: 'Qty / unit (e.g. 2, 1 kg)',
                      ),
                    ),
                    TextField(
                      controller: priceC,
                      decoration: const InputDecoration(
                        labelText: 'Store price (optional)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                    ),
                  ],
                  if (target == 1) ...[
                    TextField(
                      controller: qtyC,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    TextField(
                      controller: locC,
                      decoration: const InputDecoration(
                        labelText: 'Location (e.g. Kitchen)',
                      ),
                    ),
                    TextField(
                      controller: priceC,
                      decoration: const InputDecoration(
                        labelText: 'Value estimate (optional)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                    ),
                  ],
                  if (target == 2) ...[
                    TextField(
                      controller: recipientC,
                      decoration: const InputDecoration(
                        labelText: 'For (gift idea)',
                      ),
                    ),
                    TextField(
                      controller: priceC,
                      decoration: const InputDecoration(
                        labelText: 'Price estimate (optional)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                    ),
                    TextField(
                      controller: urlC,
                      decoration: const InputDecoration(
                        labelText: 'Link (optional)',
                      ),
                    ),
                  ],
                  TextField(
                    controller: notesC,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final name = nameC.text.trim();
                      if (name.isEmpty) return;
                      final price = double.tryParse(priceC.text);
                      if (target == 0) {
                        p.addShoppingItem(
                          categoryId: catId,
                          name: name,
                          quantityLabel: qtyC.text.trim(),
                          notes: notesC.text.trim(),
                          unitPrice: price,
                          barcode: barcode,
                        );
                      } else if (target == 1) {
                        p.addInventoryItem(
                          categoryId: catId,
                          name: name,
                          quantity: int.tryParse(qtyC.text) ?? 1,
                          location: locC.text.trim(),
                          notes: notesC.text.trim(),
                          barcode: barcode,
                          valueEstimate: price,
                        );
                      } else {
                        p.addWishlistItem(
                          title: name,
                          notes: notesC.text.trim(),
                          url: urlC.text.trim(),
                          priceEstimate: price,
                          recipient: recipientC.text.trim(),
                          categoryId: catId,
                          barcode: barcode,
                        );
                      }
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    _disposeControllersAfterDialog([
      nameC,
      qtyC,
      locC,
      notesC,
      priceC,
      urlC,
      recipientC,
    ]);
  }

  Future<void> _showManageCategories(BuildContext context) async {
    final p = context.read<ShoppingProvider>();
    final addC = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setS) {
          return AlertDialog(
            title: const Text('Categories'),
            content: SizedBox(
              width: 320,
              height: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      children: p.categories
                          .map(
                            (c) => ListTile(
                              title: Text(c.name),
                              trailing: p.categories.length <= 1
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () {
                                        p.deleteCategory(c.id);
                                        setS(() {});
                                      },
                                    ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  TextField(
                    controller: addC,
                    decoration: const InputDecoration(
                      labelText: 'New category',
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      if (addC.text.trim().isEmpty) return;
                      p.addCategory(addC.text.trim());
                      addC.clear();
                      setS(() {});
                    },
                    child: const Text('Add category'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );

    _disposeControllersAfterDialog([addC]);
  }

  Future<void> _showAddShoppingDialog(
    BuildContext context,
    ShoppingProvider p,
  ) async {
    final nameC = TextEditingController();
    final qtyC = TextEditingController();
    final notesC = TextEditingController();
    final priceC = TextEditingController();
    final barcodeC = TextEditingController();
    var catId = p.defaultCategoryId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add to shopping list'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                _CategoryDropdown(
                  categories: p.categories,
                  value: catId,
                  onChanged: (v) => setLocal(() => catId = v ?? catId),
                ),
                TextField(
                  controller: qtyC,
                  decoration: const InputDecoration(labelText: 'Qty / unit'),
                ),
                TextField(
                  controller: priceC,
                  decoration: const InputDecoration(
                    labelText: 'Store price (optional)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                ),
                TextField(
                  controller: barcodeC,
                  decoration: const InputDecoration(
                    labelText: 'Barcode (optional)',
                  ),
                ),
                TextField(
                  controller: notesC,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (ok == true &&
        nameC.text.trim().isNotEmpty &&
        context.mounted) {
      p.addShoppingItem(
        categoryId: catId,
        name: nameC.text.trim(),
        quantityLabel: qtyC.text.trim(),
        notes: notesC.text.trim(),
        unitPrice: double.tryParse(priceC.text),
        barcode: barcodeC.text.trim(),
      );
    }
    _disposeControllersAfterDialog([
      nameC,
      qtyC,
      notesC,
      priceC,
      barcodeC,
    ]);
  }

  Future<void> _showAddInventoryDialog(
    BuildContext context,
    ShoppingProvider p,
  ) async {
    final nameC = TextEditingController();
    final qtyC = TextEditingController(text: '1');
    final locC = TextEditingController();
    final notesC = TextEditingController();
    final priceC = TextEditingController();
    final barcodeC = TextEditingController();
    var catId = p.defaultCategoryId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add inventory item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                _CategoryDropdown(
                  categories: p.categories,
                  value: catId,
                  onChanged: (v) => setLocal(() => catId = v ?? catId),
                ),
                TextField(
                  controller: qtyC,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                TextField(
                  controller: locC,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                TextField(
                  controller: priceC,
                  decoration: const InputDecoration(
                    labelText: 'Value estimate (optional)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                ),
                TextField(
                  controller: barcodeC,
                  decoration: const InputDecoration(
                    labelText: 'Barcode (optional)',
                  ),
                ),
                TextField(
                  controller: notesC,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (ok == true &&
        nameC.text.trim().isNotEmpty &&
        context.mounted) {
      p.addInventoryItem(
        categoryId: catId,
        name: nameC.text.trim(),
        quantity: int.tryParse(qtyC.text) ?? 1,
        location: locC.text.trim(),
        notes: notesC.text.trim(),
        barcode: barcodeC.text.trim(),
        valueEstimate: double.tryParse(priceC.text),
      );
    }
    _disposeControllersAfterDialog([
      nameC,
      qtyC,
      locC,
      notesC,
      priceC,
      barcodeC,
    ]);
  }

  Future<void> _showAddWishlistDialog(
    BuildContext context,
    ShoppingProvider p,
  ) async {
    final titleC = TextEditingController();
    final notesC = TextEditingController();
    final urlC = TextEditingController();
    final priceC = TextEditingController();
    final recipientC = TextEditingController();
    final barcodeC = TextEditingController();
    var catId = p.defaultCategoryId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Wishlist / gift idea'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                _CategoryDropdown(
                  categories: p.categories,
                  value: catId,
                  onChanged: (v) => setLocal(() => catId = v ?? catId),
                ),
                TextField(
                  controller: recipientC,
                  decoration: const InputDecoration(
                    labelText: 'For (recipient)',
                  ),
                ),
                TextField(
                  controller: priceC,
                  decoration: const InputDecoration(
                    labelText: 'Price estimate (optional)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                ),
                TextField(
                  controller: urlC,
                  decoration: const InputDecoration(labelText: 'Link'),
                ),
                TextField(
                  controller: barcodeC,
                  decoration: const InputDecoration(
                    labelText: 'Barcode (optional)',
                  ),
                ),
                TextField(
                  controller: notesC,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (ok == true &&
        titleC.text.trim().isNotEmpty &&
        context.mounted) {
      p.addWishlistItem(
        title: titleC.text.trim(),
        notes: notesC.text.trim(),
        url: urlC.text.trim(),
        priceEstimate: double.tryParse(priceC.text),
        recipient: recipientC.text.trim(),
        categoryId: catId,
        barcode: barcodeC.text.trim(),
      );
    }
    _disposeControllersAfterDialog([
      titleC,
      notesC,
      urlC,
      priceC,
      recipientC,
      barcodeC,
    ]);
  }

  Widget _chipFilter(ShoppingProvider p) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _filterCategoryId == null,
            onSelected: (_) => setState(() => _filterCategoryId = null),
          ),
          ...p.categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: FilterChip(
                label: Text(c.name),
                selected: _filterCategoryId == c.id,
                onSelected: (_) =>
                    setState(() => _filterCategoryId = c.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingTab(BuildContext context, ShoppingProvider p) {
    final items = p.shoppingItems(categoryId: _filterCategoryId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chipFilter(p),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  p.clearCheckedShopping();
                },
                icon: const Icon(Icons.playlist_remove, size: 18),
                label: const Text('Clear checked'),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'Nothing on the list.\nTap + or scan a barcode.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final e = items[i];
                    return _ShoppingTile(
                      item: e,
                      categoryName: p.categoryName(e.categoryId),
                      money: _money,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInventoryTab(BuildContext context, ShoppingProvider p) {
    final items = p.inventoryItems(categoryId: _filterCategoryId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chipFilter(p),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'Track what you own at home.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final e = items[i];
                    return _InventoryTile(
                      item: e,
                      categoryName: p.categoryName(e.categoryId),
                      money: _money,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWishlistTab(BuildContext context, ShoppingProvider p) {
    final items = p.wishlistItems(
      categoryId: _filterCategoryId,
      hidePurchased: _hidePurchasedWishlist,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chipFilter(p),
        SwitchListTile(
          title: const Text('Hide purchased'),
          value: _hidePurchasedWishlist,
          onChanged: (v) => setState(() => _hidePurchasedWishlist = v),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'Save gift ideas and things to buy later.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    return _WishlistTile(item: items[i], p: p, money: _money);
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarBg =
        theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;

    return Consumer<ShoppingProvider>(
      builder: (context, p, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: appBarBg,
                  elevation: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: kToolbarHeight,
                          child: Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Shopping & inventory',
                                    style: theme.appBarTheme.titleTextStyle,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Scan barcode',
                                onPressed: () => _openScanner(context),
                                icon: const Icon(Icons.qr_code_scanner),
                              ),
                              IconButton(
                                tooltip: 'Categories',
                                onPressed: () => _showManageCategories(context),
                                icon: const Icon(Icons.category_outlined),
                              ),
                            ],
                          ),
                        ),
                        TabBar(
                          controller: _tabs,
                          isScrollable: true,
                          tabs: const [
                            Tab(text: 'Shopping list'),
                            Tab(text: 'Home inventory'),
                            Tab(text: 'Wishlist'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _buildShoppingTab(context, p),
                      _buildInventoryTab(context, p),
                      _buildWishlistTab(context, p),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () {
                  if (_tab == 0) {
                    _showAddShoppingDialog(context, p);
                  } else if (_tab == 1) {
                    _showAddInventoryDialog(context, p);
                  } else {
                    _showAddWishlistDialog(context, p);
                  }
                },
                child: Icon(
                  _tab == 2 ? Icons.card_giftcard : Icons.add_shopping_cart,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final List<ShopCategory> categories;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: DropdownButtonFormField<String>(
        key: ValueKey(value),
        initialValue: value.isEmpty ? null : value,
        decoration: const InputDecoration(labelText: 'Category'),
        items: categories
            .map(
              (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _ShoppingTile extends StatelessWidget {
  const _ShoppingTile({
    required this.item,
    required this.categoryName,
    required this.money,
  });

  final ShoppingListItem item;
  final String categoryName;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final p = context.read<ShoppingProvider>();
    final priceBits = <String>[];
    if (item.unitPrice != null && item.unitPrice! > 0) {
      priceBits.add('Store: ${money.format(item.unitPrice)}');
    }
    if (item.lastRecordedPrice != null && item.lastRecordedPrice! > 0) {
      priceBits.add('Last: ${money.format(item.lastRecordedPrice)}');
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: item.isChecked,
        onChanged: (_) => p.toggleShoppingChecked(item.id),
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$categoryName · ${item.quantityLabel}'.trim()),
            if (item.barcode.isNotEmpty) Text('Barcode: ${item.barcode}'),
            if (item.notes.isNotEmpty) Text(item.notes),
            if (priceBits.isNotEmpty) Text(priceBits.join(' · ')),
          ],
        ),
        isThreeLine: true,
        secondary: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => p.deleteShoppingItem(item.id),
        ),
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.item,
    required this.categoryName,
    required this.money,
  });

  final HomeInventoryItem item;
  final String categoryName;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final p = context.read<ShoppingProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(
          [
            categoryName,
            if (item.location.isNotEmpty) item.location,
            'Qty ${item.quantity}',
            if (item.barcode.isNotEmpty) 'Barcode: ${item.barcode}',
            if (item.valueEstimate != null && item.valueEstimate! > 0)
              money.format(item.valueEstimate),
            if (item.notes.isNotEmpty) item.notes,
          ].where((s) => s.toString().isNotEmpty).join(' · '),
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => p.deleteInventoryItem(item.id),
        ),
      ),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  const _WishlistTile({
    required this.item,
    required this.p,
    required this.money,
  });

  final WishlistItem item;
  final ShoppingProvider p;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: item.isPurchased,
        onChanged: (_) => p.toggleWishlistPurchased(item.id),
        title: Text(
          item.title,
          style: item.isPurchased
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        subtitle: Text(
          [
            if (item.recipient.isNotEmpty) 'For: ${item.recipient}',
            if (item.priceEstimate != null && item.priceEstimate! > 0)
              money.format(item.priceEstimate),
            if (item.url.isNotEmpty) item.url,
            if (item.barcode.isNotEmpty) 'Barcode: ${item.barcode}',
            if (item.notes.isNotEmpty) item.notes,
          ].where((s) => s.isNotEmpty).join('\n'),
        ),
        isThreeLine: true,
        secondary: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => p.deleteWishlistItem(item.id),
        ),
      ),
    );
  }
}
