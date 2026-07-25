import 'dart:convert';
import 'package:http/http.dart' as http;

// Mocking config since I can't import easily here without setup
const spoonacularApiKey = 'a9a50b2061a54dcd9fba835d834a4e58';
const usdaApiKey = '1Gh9aX5i52jcmajtdUqAEOX41tkarc4JNHaT1NSN';

Future<void> main() async {
  final input = "100 chicken breast cooked";
  
  print("--- Parsing with Spoonacular ---");
  final spoonUri = Uri.https('api.spoonacular.com', '/recipes/parseIngredients', {'apiKey': spoonacularApiKey});
  final spoonRes = await http.post(spoonUri, body: {'ingredientList': input, 'includeNutrition': 'true'});
  print("Spoonacular Status: ${spoonRes.statusCode}");
  final spoonData = jsonDecode(spoonRes.body);
  print("Spoonacular Data: ${jsonEncode(spoonData)}");

  if (spoonData is List && spoonData.isNotEmpty) {
    final item = spoonData[0];
    final parsedName = item['name'] ?? item['originalName'];
    print("Parsed Name: $parsedName");

    print("\n--- Searching USDA with '$parsedName' ---");
    final usdaUri = Uri.https('api.nal.usda.gov', '/fdc/v1/foods/search', {
      'api_key': usdaApiKey,
      'query': parsedName,
      'pageSize': '5',
      'dataType': 'Foundation,SR Legacy,Branded'
    });
    final usdaRes = await http.get(usdaUri);
    print("USDA Status: ${usdaRes.statusCode}");
    final usdaData = jsonDecode(usdaRes.body);
    print("USDA Results Count: ${usdaData['foods']?.length}");
    
    if (usdaData['foods'] != null && usdaData['foods'].isNotEmpty) {
      final bestMatch = usdaData['foods'][0];
      print("Best USDA Match: ${bestMatch['description']}");
      print("Nutrients: ${jsonEncode(bestMatch['foodNutrients'])}");
    }
  }
}
