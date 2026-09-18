import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAiService {
  // Generate realistic food photo preview using OpenAI DALL-E API
  static Future<String?> generateFoodPhoto({
    required String apiKey,
    required String recipeTitle,
  }) async {
    if (apiKey.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'dall-e-2',
          'prompt': 'Professional studio food photography of $recipeTitle, appetizing Korean gourmet plating, neutral minimalist background, soft natural lighting',
          'n': 1,
          'size': '512x512',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['data']?[0]?['url'];
        if (url != null && url is String) {
          return url;
        }
      }
    } catch (_) {
      // Return null on network error to allow smart fallback
    }
    return null;
  }

  // Ask OpenAI GPT to suggest recipe modifications
  static Future<Map<String, dynamic>?> modifyRecipeWithAi({
    required String apiKey,
    required String recipeTitle,
    required String promptQuery,
  }) async {
    if (apiKey.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are 식 (sik) AI, a minimalist Korean culinary assistant. Return JSON with keys: "substituted" (array of strings), "removed" (array of strings), "timeChange" (string or null).'
            },
            {
              'role': 'user',
              'content': 'Recipe: $recipeTitle. Modification request: $promptQuery.'
            }
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null && content is String) {
          final jsonStart = content.indexOf('{');
          final jsonEnd = content.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd != -1) {
            final jsonStr = content.substring(jsonStart, jsonEnd + 1);
            return jsonDecode(jsonStr) as Map<String, dynamic>;
          }
        }
      }
    } catch (_) {
      // Graceful fallback on network exception
    }
    return null;
  }

  // Ask OpenAI GPT to parse arbitrary natural language into structured app actions
  static Future<Map<String, dynamic>?> parseNaturalLanguageIntent({
    required String apiKey,
    required String userPrompt,
    required List<String> currentFridgeItems,
  }) async {
    if (apiKey.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': '''You are the intelligent brain of "식 (sik)", a Korean home-cooking app.
The user will give you a natural language instruction. You must interpret their intent and return a JSON object with one or more actions to execute across the app.
Current fridge inventory items: ${currentFridgeItems.join(", ")}.

Valid action types and their parameters:
1. "add_inventory":
   - "items": Array of objects {"name": string, "location": "fridge"|"freezer"|"pantry", "quantity": string (optional, e.g. "2 packs", "1kg", "Plenty")}
   (Use when user bought, got, or wants to add items to their inventory/fridge/freezer/pantry)
2. "remove_inventory":
   - "items": Array of item names to remove (e.g. user ate, finished, used up, or deleted)
3. "update_inventory":
   - "items": Array of objects {"name": string, "quantity": string} (e.g. set eggs to Low)
4. "clear_inventory": {} (clear all inventory)
5. "reset_inventory": {} (reset inventory to default seed items)
6. "add_shopping":
   - "items": Array of strings to add to shopping/want list
7. "remove_shopping":
   - "items": Array of strings to remove from shopping/want list
8. "add_reminder":
   - "title": string, "reminderType": "defrost"|"ingredient"|"prep", "hoursFromNow": number (default 3)
9. "log_meal":
   - "recipeTitle": string
10. "random_recipe": {} (triggers the random recipe card picker modal)
11. "filter_recipes":
    - "query": string (ONLY when user explicitly asks for recipes, dishes to cook, or searches meals)
12. "clear_filters": {} (resets recipe search query & filters)
13. "switch_view":
    - "isGrid": boolean
14. "change_theme":
    - "colorName": "Matcha Sage"|"Warm Amber"|"Persimmon"|"Berry Plum"|"Korean Indigo"|"Terracotta"|"Black & White"
15. "navigate":
    - "tab": 0 (Explore) | 1 (Fridge) | 2 (Journal) | 3 (Saved) | 4 (Profile)
16. "culinary_advice":
    - "advice": string (answering questions about ingredients, substitutions, cooking tips)

Return ONLY a JSON object in this format:
{
  "actions": [ ... list of action objects ... ],
  "feedback": "Concise, friendly message explaining what was done in 1 sentence"
}'''
            },
            {
              'role': 'user',
              'content': userPrompt,
            }
          ],
          'temperature': 0.2,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null && content is String) {
          final jsonStart = content.indexOf('{');
          final jsonEnd = content.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd != -1) {
            final jsonStr = content.substring(jsonStart, jsonEnd + 1);
            return jsonDecode(jsonStr) as Map<String, dynamic>;
          }
        }
      }
    } catch (_) {
      // Graceful fallback on network exception
    }
    return null;
  }
}
