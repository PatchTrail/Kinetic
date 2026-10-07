class EstimatedNutrition {
  final String foodName;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String source;

  const EstimatedNutrition({
    required this.foodName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.source,
  });
}

class NutritionService {
  static final NutritionService instance = NutritionService._internal();
  NutritionService._internal();

  // Curated knowledge base of macro profiles per standard serving
  final Map<String, Map<String, dynamic>> _foodKnowledgeBase = {
    // Proteins
    'chicken': {'cal': 165, 'p': 31.0, 'c': 0.0, 'f': 3.6, 'unit': '100g'},
    'chicken breast': {'cal': 165, 'p': 31.0, 'c': 0.0, 'f': 3.6, 'unit': '100g'},
    'egg': {'cal': 74, 'p': 6.3, 'c': 0.4, 'f': 5.0, 'unit': '1 large'},
    'eggs': {'cal': 148, 'p': 12.6, 'c': 0.8, 'f': 10.0, 'unit': '2 large'},
    'egg whites': {'cal': 50, 'p': 11.0, 'c': 0.7, 'f': 0.2, 'unit': '100g'},
    'steak': {'cal': 250, 'p': 26.0, 'c': 0.0, 'f': 16.0, 'unit': '100g'},
    'beef': {'cal': 250, 'p': 26.0, 'c': 0.0, 'f': 16.0, 'unit': '100g'},
    'salmon': {'cal': 208, 'p': 20.0, 'c': 0.0, 'f': 13.0, 'unit': '100g'},
    'tuna': {'cal': 132, 'p': 28.0, 'c': 0.0, 'f': 1.3, 'unit': '1 can (100g)'},
    'whey': {'cal': 120, 'p': 24.0, 'c': 3.0, 'f': 1.5, 'unit': '1 scoop (30g)'},
    'protein shake': {'cal': 160, 'p': 30.0, 'c': 4.0, 'f': 2.5, 'unit': '1 shake'},
    'greek yogurt': {'cal': 130, 'p': 17.0, 'c': 6.0, 'f': 0.7, 'unit': '1 cup (170g)'},
    'cottage cheese': {'cal': 160, 'p': 28.0, 'c': 6.0, 'f': 2.3, 'unit': '1 cup'},
    'tofu': {'cal': 94, 'p': 10.0, 'c': 2.3, 'f': 5.3, 'unit': '100g'},

    // Carbs & Grains
    'oats': {'cal': 150, 'p': 5.0, 'c': 27.0, 'f': 3.0, 'unit': '1/2 cup (40g)'},
    'oatmeal': {'cal': 150, 'p': 5.0, 'c': 27.0, 'f': 3.0, 'unit': '1 bowl'},
    'rice': {'cal': 205, 'p': 4.3, 'c': 45.0, 'f': 0.4, 'unit': '1 cup cooked'},
    'white rice': {'cal': 205, 'p': 4.3, 'c': 45.0, 'f': 0.4, 'unit': '1 cup cooked'},
    'brown rice': {'cal': 216, 'p': 5.0, 'c': 45.0, 'f': 1.8, 'unit': '1 cup cooked'},
    'bread': {'cal': 80, 'p': 3.5, 'c': 15.0, 'f': 1.0, 'unit': '1 slice'},
    'sourdough': {'cal': 100, 'p': 4.0, 'c': 20.0, 'f': 0.5, 'unit': '1 slice'},
    'toast': {'cal': 80, 'p': 3.5, 'c': 15.0, 'f': 1.0, 'unit': '1 slice'},
    'sweet potato': {'cal': 103, 'p': 2.3, 'c': 24.0, 'f': 0.2, 'unit': '1 medium'},
    'potato': {'cal': 160, 'p': 4.0, 'c': 37.0, 'f': 0.2, 'unit': '1 medium'},
    'pasta': {'cal': 220, 'p': 8.0, 'c': 43.0, 'f': 1.3, 'unit': '1 cup cooked'},
    'banana': {'cal': 105, 'p': 1.3, 'c': 27.0, 'f': 0.4, 'unit': '1 medium'},
    'apple': {'cal': 95, 'p': 0.5, 'c': 25.0, 'f': 0.3, 'unit': '1 medium'},
    'berries': {'cal': 60, 'p': 1.0, 'c': 14.0, 'f': 0.5, 'unit': '1 cup'},

    // Fats
    'peanut butter': {'cal': 190, 'p': 8.0, 'c': 7.0, 'f': 16.0, 'unit': '2 tbsp (32g)'},
    'almonds': {'cal': 160, 'p': 6.0, 'c': 6.0, 'f': 14.0, 'unit': '1 handful (28g)'},
    'avocado': {'cal': 240, 'p': 3.0, 'c': 12.0, 'f': 22.0, 'unit': '1 medium'},
    'olive oil': {'cal': 120, 'p': 0.0, 'c': 0.0, 'f': 14.0, 'unit': '1 tbsp'},

    // Beverages
    'coffee': {'cal': 5, 'p': 0.3, 'c': 0.0, 'f': 0.0, 'unit': '1 cup'},
    'black coffee': {'cal': 2, 'p': 0.3, 'c': 0.0, 'f': 0.0, 'unit': '1 cup'},
    'cappuccino': {'cal': 120, 'p': 6.0, 'c': 10.0, 'f': 4.0, 'unit': '1 cup (8 oz)'},
    'latte': {'cal': 150, 'p': 9.0, 'c': 15.0, 'f': 6.0, 'unit': '1 cup (12 oz)'},
    'espresso': {'cal': 5, 'p': 0.1, 'c': 0.5, 'f': 0.0, 'unit': '1 shot'},
    'milk': {'cal': 120, 'p': 8.0, 'c': 12.0, 'f': 5.0, 'unit': '1 cup'},
    'almond milk': {'cal': 40, 'p': 1.5, 'c': 2.0, 'f': 3.0, 'unit': '1 cup'},
    'tea': {'cal': 2, 'p': 0.0, 'c': 0.4, 'f': 0.0, 'unit': '1 cup'},
    'green tea': {'cal': 2, 'p': 0.0, 'c': 0.0, 'f': 0.0, 'unit': '1 cup'},
    'orange juice': {'cal': 110, 'p': 2.0, 'c': 26.0, 'f': 0.5, 'unit': '1 glass'},

    // Fast / Popular Meals
    'pizza': {'cal': 285, 'p': 12.0, 'c': 36.0, 'f': 10.0, 'unit': '1 slice'},
    'burger': {'cal': 550, 'p': 30.0, 'c': 45.0, 'f': 28.0, 'unit': '1 burger'},
    'salad': {'cal': 180, 'p': 4.0, 'c': 12.0, 'f': 12.0, 'unit': '1 bowl with dressing'},
    'sandwich': {'cal': 380, 'p': 22.0, 'c': 42.0, 'f': 14.0, 'unit': '1 sandwich'},
  };

  Future<EstimatedNutrition> estimateCaloriesAndMacros(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {
      return const EstimatedNutrition(
        foodName: 'Custom Item',
        calories: 250,
        proteinG: 15.0,
        carbsG: 30.0,
        fatG: 8.0,
        source: 'Estimated standard meal',
      );
    }

    // 1. Check quantity multiplier (e.g. "2 eggs", "3 slices pizza", "200g chicken")
    double multiplier = 1.0;
    final words = clean.split(RegExp(r'\s+'));
    if (words.isNotEmpty) {
      final firstWord = words.first;
      final parsedNum = double.tryParse(firstWord);
      if (parsedNum != null && parsedNum > 0 && parsedNum <= 20) {
        multiplier = parsedNum;
      } else if (clean.contains('200g') || clean.contains('200 g')) {
        multiplier = 2.0;
      } else if (clean.contains('300g') || clean.contains('300 g')) {
        multiplier = 3.0;
      } else if (clean.contains('150g') || clean.contains('150 g')) {
        multiplier = 1.5;
      } else if (clean.contains('50g') || clean.contains('50 g')) {
        multiplier = 0.5;
      }
    }

    // 2. Multi-item parsing (e.g. "eggs and toast", "chicken and rice")
    int totalCal = 0;
    double totalP = 0;
    double totalC = 0;
    double totalF = 0;
    int matchedCount = 0;

    for (final entry in _foodKnowledgeBase.entries) {
      if (clean.contains(entry.key)) {
        final profile = entry.value;
        totalCal += ((profile['cal'] as num) * multiplier).round();
        totalP += (profile['p'] as num) * multiplier;
        totalC += (profile['c'] as num) * multiplier;
        totalF += (profile['f'] as num) * multiplier;
        matchedCount++;
      }
    }

    if (matchedCount > 0) {
      return EstimatedNutrition(
        foodName: query,
        calories: totalCal,
        proteinG: double.parse(totalP.toStringAsFixed(1)),
        carbsG: double.parse(totalC.toStringAsFixed(1)),
        fatG: double.parse(totalF.toStringAsFixed(1)),
        source: 'Nutritional Intelligence ($matchedCount ingredients recognized)',
      );
    }

    // 3. Fallback heuristic based on generic food characteristics
    int fallbackCal = 300;
    double fallbackP = 15.0;
    double fallbackC = 35.0;
    double fallbackF = 10.0;

    if (clean.contains('shake') || clean.contains('protein') || clean.contains('bar')) {
      fallbackCal = 240;
      fallbackP = 28.0;
      fallbackC = 18.0;
      fallbackF = 5.0;
    } else if (clean.contains('juice') || clean.contains('soda') || clean.contains('coke')) {
      fallbackCal = 140;
      fallbackP = 0.0;
      fallbackC = 36.0;
      fallbackF = 0.0;
    } else if (clean.contains('snack') || clean.contains('cookie') || clean.contains('chips')) {
      fallbackCal = 220;
      fallbackP = 3.0;
      fallbackC = 28.0;
      fallbackF = 12.0;
    }

    return EstimatedNutrition(
      foodName: query,
      calories: fallbackCal,
      proteinG: fallbackP,
      carbsG: fallbackC,
      fatG: fallbackF,
      source: 'Estimated standard portion · Tap to refine',
    );
  }
}
