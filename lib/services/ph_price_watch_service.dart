import 'database_helper.dart';

class PhPriceWatchService {
  PhPriceWatchService._internal();
  static final PhPriceWatchService instance = PhPriceWatchService._internal();

  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>>? _marketPricesCache;

  /// Fetches the estimated price for an ingredient using a 3-Tier Hierarchical Engine.
  Future<double?> getEstimatedPrice(String ingredientName) async {
    final trimmed = ingredientName.toLowerCase().trim();
    if (trimmed.isEmpty) return null;

    if (_marketPricesCache == null) {
      _marketPricesCache = await _db.getMarketPrices();
    }
    if (_marketPricesCache == null || _marketPricesCache!.isEmpty) return null;

    // --- TIER 1: HIGH-FIDELITY MATCH ---
    final noiseWords = {'wild', 'fresh', 'diced', 'sliced', 'fillet', 'spears', 'cooked', 'whole', 'halved', 'cloves', 'minced', 'organic', 'frozen', 'local', 'juiced', 'zested', 'black'};
    final rawKeywords = trimmed.split(RegExp(r'[\s,()]+')).where((w) => w.length > 2).toList();
    final keywords = rawKeywords.where((w) => !noiseWords.contains(w)).toList();

    // Special low-cost seasoning rule
    if (trimmed.contains('salt') || trimmed.contains('pepper') || trimmed.contains('spice') || trimmed.contains('oregano') || trimmed.contains('herb')) {
      return 1.50;
    }
    
    if (trimmed.contains('garlic')) {
      // 1 clove of garlic is typically ₱2-₱3 in a market setting
      return 2.50;
    }

    Map<String, dynamic>? bestMatch;
    int bestScore = 0;

    for (var marketItem in _marketPricesCache!) {
      final itemName = (marketItem['name'] as String).toLowerCase();
      int currentScore = 0;
      for (var word in keywords) {
        if (itemName.contains(word)) currentScore++;
      }
      if (currentScore > bestScore) {
        bestScore = currentScore;
        bestMatch = marketItem;
      }
    }

    if (bestMatch != null && bestScore > 0) {
      return _calculatePortionPrice(trimmed, bestMatch);
    }

    // --- TIER 2: SUB-CATEGORY PROXY ---
    // If no specific item match, look for the "Anchor" item in the same category
    // We try to guess the category from keywords if not found
    String guessedCategory = _guessCategory(keywords);
    final anchor = _marketPricesCache!.firstWhere(
      (m) => (m['name'] as String).contains('Anchor') && (m['category'] as String) == guessedCategory,
      orElse: () => _marketPricesCache!.firstWhere((m) => (m['name'] as String).contains('Anchor')),
    );

    return _calculatePortionPrice(trimmed, anchor);
  }

  double _calculatePortionPrice(String ingredientName, Map<String, dynamic> marketItem) {
    final pricePerUnit = (marketItem['price'] as num).toDouble();
    final marketUnit = (marketItem['unit'] as String).toLowerCase();

    // Household Unit Intelligence (Weights in grams)
    final unitWeights = {
      'clove': 5.0,
      'cup': 240.0,
      'tbsp': 15.0,
      'tsp': 5.0,
      'oz': 28.35,
      'stalk': 40.0,
      'slice': 30.0,
      'pinch': 1.0,
      'pc': 80.0, // Average medium fruit/veg
    };

    final weightMatch = RegExp(r'([\d\./]+)\s*(g|kg|ml|liter|oz|cup|tbsp|tsp|clove|stalk|slice|pinch|pc)').firstMatch(ingredientName);
    
    double amount = 1.0;
    String recipeUnit = 'pc';

    if (weightMatch != null) {
      final rawAmount = weightMatch.group(1)!;
      recipeUnit = weightMatch.group(2)!;
      if (rawAmount.contains('/')) {
        final parts = rawAmount.split('/');
        amount = (double.tryParse(parts[0]) ?? 1) / (double.tryParse(parts[1]) ?? 1);
      } else {
        amount = double.tryParse(rawAmount) ?? 1;
      }
    }

    double gramsEquivalent = amount;
    if (unitWeights.containsKey(recipeUnit)) {
      gramsEquivalent = amount * unitWeights[recipeUnit]!;
    } else if (recipeUnit == 'kg' || recipeUnit == 'liter') {
      gramsEquivalent = amount * 1000;
    }

    double ratio = 1.0;
    if (marketUnit == 'kg' || marketUnit == 'liter') {
      ratio = gramsEquivalent / 1000.0;
    } else if (marketUnit == 'pc') {
      // If market sells by piece (e.g. Lemon), and recipe uses grams/tbsp
      ratio = gramsEquivalent / (unitWeights['pc']!);
    } else if (marketUnit == 'loaf') {
      ratio = gramsEquivalent / 400.0; // Assume 400g loaf
    }

    return pricePerUnit * ratio;
  }

  String _guessCategory(List<String> keywords) {
    final meatKeys = {'beef', 'pork', 'meat', 'steak', 'sirloin', 'liempo'};
    final fishKeys = {'fish', 'shrimp', 'salmon', 'seafood', 'squid', 'bangus', 'tuna'};
    final vegKeys = {'veg', 'lettuce', 'tomato', 'onion', 'garlic', 'cabbage', 'broccoli', 'asparagus'};
    final grainKeys = {'rice', 'quinoa', 'oats', 'corn', 'bread', 'flour'};

    if (keywords.any((k) => meatKeys.contains(k))) return 'Meat';
    if (keywords.any((k) => fishKeys.contains(k))) return 'Fish';
    if (keywords.any((k) => vegKeys.contains(k))) return 'Vegetables';
    if (keywords.any((k) => grainKeys.contains(k))) return 'Grains';
    
    return 'Pantry';
  }

  Future<double> calculateTotal(List<String> ingredientNames) async {
    double total = 0.0;
    for (var name in ingredientNames) {
      final price = await getEstimatedPrice(name);
      total += (price ?? 0.0);
    }
    return total;
  }
}
