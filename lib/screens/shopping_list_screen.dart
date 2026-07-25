import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import '../services/shopping_list_service.dart';
import 'widgets/app_loading.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key, List? recipes}); // Kept optional for backward compatibility if needed

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _db = DatabaseHelper.instance;
  final _auth = AuthService();
  final _manualController = TextEditingController();
  
  List<ShoppingItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final items = await _db.getShoppingItems(userId);
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleItem(ShoppingItem item) async {
    final updated = item.copyWith(isChecked: !item.isChecked);
    await _db.updateShoppingItem(updated);
    _loadItems();
  }

  Future<void> _updateQuantity(ShoppingItem item, int delta) async {
    final newQty = item.quantity + delta;
    if (newQty <= 0) {
      await _db.deleteShoppingItem(item.id!);
    } else {
      await _db.updateShoppingItem(item.copyWith(quantity: newQty));
    }
    _loadItems();
  }

  Future<void> _deleteItem(int id) async {
    await _db.deleteShoppingItem(id);
    _loadItems();
  }

  Future<void> _addManualItem() async {
    final text = _manualController.text.trim();
    if (text.isEmpty) return;

    await ShoppingListService.instance.addManualItem(text);
    _manualController.clear();
    _loadItems();
  }

  Future<void> _clearChecked() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await _db.clearCheckedShoppingItems(userId);
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildManualInput(isDark),
            Expanded(
              child: _isLoading 
                ? const AppLoading() 
                : _items.isEmpty 
                  ? _buildEmptyState(isDark)
                  : _buildCategorizedList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Shopping List',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _clearChecked,
                icon: Icon(Icons.cleaning_services_outlined, color: isDark ? Colors.white38 : Colors.black38),
                tooltip: 'Clear Checked',
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
                style: IconButton.styleFrom(backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualInput(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
          boxShadow: !isDark ? [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
          ] : null,
        ),
        child: TextField(
          controller: _manualController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Add extra item...',
            hintStyle: TextStyle(color: isDark ? Colors.white10 : Colors.black12),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.orangeAccent),
              onPressed: _addManualItem,
            ),
          ),
          onSubmitted: (_) => _addManualItem(),
        ),
      ),
    );
  }

  Widget _buildCategorizedList(bool isDark) {
    final groups = <String, List<ShoppingItem>>{};
    for (var item in _items) {
      final cat = item.category ?? 'Other';
      groups.putIfAbsent(cat, () => []).add(item);
    }

    final sortedCategories = groups.keys.toList()..sort((a, b) {
      if (a == 'Other') return 1;
      if (b == 'Other') return -1;
      return a.compareTo(b);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final groupItems = groups[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 16.0, top: 8.0),
              child: Row(
                children: [
                  Text(_getCategoryIcon(category), style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: isDark ? Colors.white : Colors.black87
                    ),
                  ),
                ],
              ),
            ),
            ...groupItems.map((item) => _buildChecklistItem(item, isDark)),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'produce': return '🥦';
      case 'meat/seafood': return '🥩';
      case 'dairy/eggs': return '🥚';
      case 'bakery': return '🍞';
      case 'frozen': return '❄️';
      case 'pantry': return '🥫';
      case 'snacks': return '🍿';
      case 'household': return '🧼';
      default: return '🛒';
    }
  }

  Widget _buildChecklistItem(ShoppingItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          onTap: () => _toggleItem(item),
          onLongPress: () => _deleteItem(item.id!),
          leading: Icon(
            item.isChecked ? Icons.check_circle : Icons.circle_outlined,
            color: item.isChecked ? Colors.greenAccent : (isDark ? Colors.white24 : Colors.black12),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              color: item.isChecked ? (isDark ? Colors.white24 : Colors.black26) : (isDark ? Colors.white : Colors.black87),
              decoration: item.isChecked ? TextDecoration.lineThrough : null,
              fontSize: 16,
              fontWeight: item.isChecked ? FontWeight.normal : FontWeight.w500,
            ),
          ),
          subtitle: Row(
            children: [
              if (item.recipeName != null) 
                Expanded(
                  child: Text(
                    item.recipeName!,
                    style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (item.quantity > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'x${item.quantity}',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!item.isChecked) ...[
                _buildQtyBtn(Icons.remove, () => _updateQuantity(item, -1), isDark),
                const SizedBox(width: 4),
                _buildQtyBtn(Icons.add, () => _updateQuantity(item, 1), isDark),
                const SizedBox(width: 8),
              ],
              IconButton(
                icon: Icon(Icons.delete_outline, color: isDark ? Colors.white10 : Colors.black12, size: 20),
                onPressed: () => _deleteItem(item.id!),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: isDark ? Colors.white38 : Colors.black38),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 64, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          const SizedBox(height: 24),
          Text(
            'Your list is empty.\nAdd ingredients from recipes!',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
