import '../models/fridge_item.dart';

class RegionalSubstitution {
  final String originalIngredient;
  final String localSubstitute;
  final String localSupermarketNote; // e.g. "Available in Tesco, SuperValu, Dunnes"

  const RegionalSubstitution({
    required this.originalIngredient,
    required this.localSubstitute,
    required this.localSupermarketNote,
  });
}

class IngredientIntelligence {
  // Intelligent storage location detection for kitchen items
  static StorageLocation autoDetectLocation(String ingredientName) {
    final lower = ingredientName.toLowerCase();

    // 1. Seasonings, Spices & Small Condiments detection
    if (lower.contains('seasoning') ||
        lower.contains('spice') ||
        lower.contains('condensed milk') ||
        lower.contains('salt') ||
        (lower.contains('pepper') && !lower.contains('bell pepper')) ||
        lower.contains('peppercorn') ||
        lower.contains('cinnamon') ||
        lower.contains('cumin') ||
        lower.contains('paprika') ||
        lower.contains('oregano') ||
        lower.contains('rosemary') ||
        lower.contains('thyme') ||
        lower.contains('basil') ||
        lower.contains('curry powder') ||
        lower.contains('turmeric') ||
        lower.contains('garlic powder') ||
        lower.contains('onion powder') ||
        lower.contains('msg') ||
        lower.contains('sesame oil') ||
        lower.contains('fish sauce') ||
        lower.contains('oyster sauce') ||
        lower.contains('soy sauce') ||
        lower.contains('dark soy') ||
        lower.contains('gochugaru') ||
        lower.contains('chili powder') ||
        lower.contains('chilli powder') ||
        lower.contains('chili flake') ||
        lower.contains('chilli flake') ||
        lower.contains('tomyum paste') ||
        lower.contains('miso paste') ||
        lower.contains('lao gan ma') ||
        lower.contains('老干妈') ||
        lower.contains('star anise') ||
        lower.contains('cardamom') ||
        lower.contains('nutmeg') ||
        lower.contains('clove') ||
        lower.contains('mustard') ||
        lower.contains('wasabi')) {
      return StorageLocation.seasoning;
    }

    // 2. Freezer detection (Meats, seafood, dumplings, frozen items)
    if (lower.contains('pork') ||
        lower.contains('beef') ||
        lower.contains('steak') ||
        lower.contains('chicken') ||
        lower.contains('meat') ||
        lower.contains('fish') ||
        lower.contains('salmon') ||
        lower.contains('shrimp') ||
        lower.contains('prawn') ||
        lower.contains('squid') ||
        lower.contains('brisket') ||
        lower.contains('rib') ||
        lower.contains('dumpling') ||
        lower.contains('mandu') ||
        lower.contains('ice cream') ||
        lower.contains('frozen')) {
      return StorageLocation.freezer;
    }

    // 3. Pantry detection (Shelf-stable, grains, dry goods, canned)
    if (lower.contains('rice') ||
        lower.contains('noodle') ||
        lower.contains('ramen') ||
        lower.contains('pasta') ||
        lower.contains('flour') ||
        lower.contains('sugar') ||
        lower.contains('oil') ||
        lower.contains('sauce') ||
        lower.contains('gochujang') ||
        lower.contains('doenjang') ||
        lower.contains('vinegar') ||
        lower.contains('mirin') ||
        lower.contains('canned') ||
        lower.contains('can') ||
        lower.contains('tuna') ||
        lower.contains('spam') ||
        lower.contains('seaweed') ||
        lower.contains('gim') ||
        lower.contains('flake') ||
        lower.contains('powder') ||
        lower.contains('cereal') ||
        lower.contains('bean') ||
        lower.contains('lentil') ||
        lower.contains('honey')) {
      return StorageLocation.pantry;
    }

    // 4. Default fresh / produce / dairy to Fridge
    return StorageLocation.fridge;
  }

  // Fuzzy amount mapper: translates approximate user quantities into recipe match confidence
  static String evaluateFuzzyQuantity(String ingredientName, String? quantityDisplay) {
    if (quantityDisplay == null || quantityDisplay.isEmpty) {
      return 'Available in kitchen';
    }

    final lower = quantityDisplay.toLowerCase();
    if (lower.contains('plenty') || lower.contains('full')) {
      return 'Plenty for 3+ servings';
    } else if (lower.contains('some') || lower.contains('half')) {
      return 'Probably enough for recipe';
    } else if (lower.contains('little') || lower.contains('almost empty') || lower.contains('low')) {
      return 'Running low — check before cooking';
    }
    return quantityDisplay;
  }

  // Regional Substitutions DB (Tailored for Ireland & European Supermarkets)
  static final Map<String, RegionalSubstitution> _irelandSubstitutions = {
    'gochujang': const RegionalSubstitution(
      originalIngredient: 'Gochujang',
      localSubstitute: 'Sriracha + 1 tsp Miso Paste',
      localSupermarketNote: 'Available in Tesco, Dunnes Stores, & SuperValu',
    ),
    'mirin': const RegionalSubstitution(
      originalIngredient: 'Mirin (Rice Wine)',
      localSubstitute: 'Dry White Wine or Sherry + 1 tsp sugar',
      localSupermarketNote: 'Common in all Irish wine aisles',
    ),
    'gochugaru': const RegionalSubstitution(
      originalIngredient: 'Gochugaru (Korean Chili Flakes)',
      localSubstitute: 'Crushed Red Pepper Flakes + Sweet Paprika (1:1 ratio)',
      localSupermarketNote: 'Available in spice rack at Lidl / Aldi',
    ),
    'firm tofu': const RegionalSubstitution(
      originalIngredient: 'Firm Tofu',
      localSubstitute: 'Cauldron Organic Tofu or Clearspring Tofu',
      localSupermarketNote: 'Found in chilled organic section at SuperValu',
    ),
    'sesame oil': const RegionalSubstitution(
      originalIngredient: 'Toasted Sesame Oil',
      localSubstitute: 'Dark Sesame Oil',
      localSupermarketNote: 'Available in Asian food aisle in Tesco',
    ),
  };

  static RegionalSubstitution? getSubstitution(String ingredientName, String region) {
    final key = ingredientName.toLowerCase();
    if (region.contains('Ireland')) {
      for (final entry in _irelandSubstitutions.entries) {
        if (key.contains(entry.key)) {
          return entry.value;
        }
      }
    }
    return null;
  }
}
