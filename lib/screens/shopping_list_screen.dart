import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/shopping_item.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import '../services/shopping_list_service.dart';
import 'widgets/app_loading.dart';
import 'widgets/app_toast.dart';

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

  Future<void> _clearAll() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Clear List?', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        content: Text(
          'This will remove ALL items from your shopping list. This action cannot be undone.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.clearAllShoppingItems(userId);
      _loadItems();
    }
  }

  Future<void> _exportList() async {
    if (_items.isEmpty) return;

    final uncheckedItems = _items.where((i) => !i.isChecked).toList();
    if (uncheckedItems.isEmpty) {
      AppToast.show(context, message: 'All items are checked. Nothing to export.', type: ToastType.info);
      return;
    }

    final dateStr = DateFormat('MMMM dd, yyyy').format(DateTime.now());
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('🍎 FoodGapp Grocery Receipt');
    buffer.writeln('📅 Date: $dateStr');
    buffer.writeln('--------------------------------');

    // Group by category
    final groups = <String, List<ShoppingItem>>{};
    for (var item in uncheckedItems) {
      final cat = item.category ?? 'Other';
      groups.putIfAbsent(cat, () => []).add(item);
    }

    double grandTotal = 0;

    for (var entry in groups.entries) {
      buffer.writeln('\n${entry.key.toUpperCase()}');
      for (var item in entry.value) {
        final itemTotal = (item.pricePhp ?? 0) * item.quantity;
        grandTotal += itemTotal;
        
        String priceText = '';
        if (item.pricePhp != null) {
          priceText = ' - ₱${itemTotal.toStringAsFixed(2)}';
        }
        
        buffer.writeln('[ ] ${item.quantity}x ${item.name}$priceText');
      }
    }

    buffer.writeln('\n--------------------------------');
    buffer.writeln('💰 TOTAL BUDGET: ₱${grandTotal.toStringAsFixed(2)}');
    buffer.writeln('--------------------------------');
    buffer.writeln('\nGenerated by FoodGapp AI');

    await Share.share(buffer.toString(), subject: 'FoodGapp Grocery List');
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
            if (_items.isNotEmpty) _buildBudgetFooter(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetFooter(bool isDark) {
    final uncheckedItems = _items.where((i) => !i.isChecked);
    final total = uncheckedItems.fold<double>(0, (sum, i) => sum + ((i.pricePhp ?? 0) * i.quantity));

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ESTIMATED BUDGET',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38, 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1
                ),
              ),
              Text(
                '₱${total.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isDark ? Colors.greenAccent : Colors.green[700], 
                  fontSize: 24, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: total > 0 ? _exportList : null, 
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Export List', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white10 : Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Shopping List',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              IconButton(
                onPressed: _clearChecked,
                icon: Icon(Icons.cleaning_services_outlined, color: isDark ? Colors.white38 : Colors.black38),
                tooltip: 'Clear Checked',
              ),
              IconButton(
                onPressed: _clearAll,
                icon: Icon(Icons.delete_sweep_outlined, color: isDark ? Colors.redAccent.withValues(alpha: 0.5) : Colors.redAccent.withValues(alpha: 0.7)),
                tooltip: 'Clear All',
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
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
          boxShadow: !isDark ? [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
          ] : null,
        ),
        child: TextField(
          controller: _manualController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Add extra item...',
            hintStyle: TextStyle(color: isDark ? Colors.white10 : Colors.black12, fontSize: 14),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.orangeAccent, size: 22),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final groupItems = groups[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 12.0, top: 4.0),
              child: Row(
                children: [
                  Text(_getCategoryIcon(category), style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 17, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : Colors.black87
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ...groupItems.map((item) => _buildChecklistItem(item, isDark)),
            const SizedBox(height: 16),
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: () => _toggleItem(item),
          onLongPress: () => _deleteItem(item.id!),
          leading: Icon(
            item.isChecked ? Icons.check_circle : Icons.circle_outlined,
            color: item.isChecked ? Colors.greenAccent : (isDark ? Colors.white24 : Colors.black12),
            size: 22,
          ),
          title: Text(
            item.name,
            style: TextStyle(
              color: item.isChecked ? (isDark ? Colors.white24 : Colors.black26) : (isDark ? Colors.white : Colors.black87),
              decoration: item.isChecked ? TextDecoration.lineThrough : null,
              fontSize: 15,
              fontWeight: item.isChecked ? FontWeight.normal : FontWeight.w500,
            ),
          ),
          subtitle: Row(
            children: [
              if (item.recipeName != null) 
                Expanded(
                  child: Text(
                    item.recipeName!,
                    style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (item.quantity > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'x${item.quantity}',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              if (item.pricePhp != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '₱${(item.pricePhp! * item.quantity).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: item.isChecked ? (isDark ? Colors.white10 : Colors.black12) : (isDark ? Colors.greenAccent.withValues(alpha: 0.7) : Colors.green[700]),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
                const SizedBox(width: 4),
              ],
              IconButton(
                icon: Icon(Icons.delete_outline, color: isDark ? Colors.white10 : Colors.black12, size: 18),
                onPressed: () => _deleteItem(item.id!),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 13, color: isDark ? Colors.white38 : Colors.black38),
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
