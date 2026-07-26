import 'package:flutter/material.dart';
import '../../models/ingredient.dart';
import '../../services/api/usda_service.dart';
import '../../services/api/spoonacular_service.dart';
import '../../services/api/foodgapp_ai_service.dart';
import 'app_loading.dart';
import 'app_toast.dart';

class AddIngredientModal extends StatefulWidget {
  const AddIngredientModal({super.key});

  @override
  State<AddIngredientModal> createState() => _AddIngredientModalState();
}

class _AddIngredientModalState extends State<AddIngredientModal> {
  final _usda = UsdaService();
  final _spoonacular = SpoonacularService();
  final _ai = FoodGappAiService();
  
  int _activeTab = 0; // 0: USDA Search, 1: Quick Paste
  final _searchController = TextEditingController();
  final _pasteController = TextEditingController();
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _pasteController.dispose();
    _usda.dispose();
    _spoonacular.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final results = await _usda.searchFoods(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _handleQuickPaste() async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final result = await _ai.parseIngredient(text);

      if (mounted) {
        if (result != null) {
          Navigator.pop(context, result);
        } else {
          setState(() => _isSearching = false);
          AppToast.show(context, message: 'Try "100g chicken"', title: 'Parsing Failed', type: ToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        final msg = e.toString().contains('Key not set') 
          ? 'Gemini API Key missing in config.' 
          : 'AI processing failed. Try again.';
        AppToast.show(context, message: msg, title: 'AI Error', type: ToastType.error);
      }
    }
  }

  Future<void> _showAmountDialog(Map<String, dynamic> food) async {
    final controller = TextEditingController(text: '100');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(food['description'], style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter amount consumed', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03), 
                borderRadius: BorderRadius.circular(12)
              ),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  border: InputBorder.none, 
                  suffixText: 'g', 
                  suffixStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38)
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final ingredient = Ingredient.fromUsda(food, result);
      Navigator.pop(context, ingredient);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: screenHeight * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          _buildHandle(isDark),
          _buildHeader(isDark),
          _buildTabSelector(isDark),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _activeTab == 0 ? _buildSearchTab(isDark) : _buildPasteTab(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black12,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Add Ingredients', 
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
            style: IconButton.styleFrom(backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _buildTabItem('Search', 0, isDark),
            _buildTabItem('Quick Paste', 1, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index, bool isDark) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _activeTab = index;
          _searchResults.clear();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? const Color(0xFF333333) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected && !isDark ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))
            ] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white38 : Colors.black38),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchTab(bool isDark) {
    return Column(
      children: [
        _buildInputContainer(
          isDark: isDark,
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Search foods (e.g. Milk, Egg)',
              hintStyle: TextStyle(color: isDark ? Colors.white10 : Colors.black12),
              border: InputBorder.none,
              icon: Icon(Icons.search, color: isDark ? Colors.white38 : Colors.black38),
            ),
            onSubmitted: _performSearch,
          ),
        ),
        const SizedBox(height: 24),
        if (_isSearching)
          const Padding(padding: EdgeInsets.only(top: 48), child: AppLoading())
        else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
          _buildEmptyResults(isDark)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final food = _searchResults[index];
              return _buildFoodResultCard(food, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildPasteTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type your ingredient and amount', 
          style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13)
        ),
        const SizedBox(height: 12),
        _buildInputContainer(
          isDark: isDark,
          child: TextField(
            controller: _pasteController,
            maxLines: 3,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'e.g. 100g chicken breast',
              hintStyle: TextStyle(color: isDark ? Colors.white10 : Colors.black12),
              border: InputBorder.none,
            ),
            autofocus: true,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSearching ? null : _handleQuickPaste,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSearching 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Add to Meal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildInputContainer({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: child,
    );
  }

  Widget _buildFoodResultCard(Map<String, dynamic> food, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
        ] : null,
      ),
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          onTap: () => _showAmountDialog(food),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  food['description'] ?? 'Unknown', 
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.greenAccent, size: 8),
                    const SizedBox(width: 4),
                    Text(
                      'USDA Verified', 
                      style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Text(
            food['brandOwner'] ?? food['dataType'] ?? '', 
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle
            ),
            child: Icon(Icons.add, color: isDark ? Colors.greenAccent : Colors.green, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyResults(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 48.0),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: isDark ? Colors.white10 : Colors.black12),
            const SizedBox(height: 16),
            Text(
              'No matches found in USDA database', 
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)
            ),
          ],
        ),
      ),
    );
  }
}
