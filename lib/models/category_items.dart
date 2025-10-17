class CategoryItems {
  static const Map<String, List<String>> items = {
    'vegetables': [
      'Tomato',
      'Potato',
      'Bandakka',
      'Bean',
      'Beetroot',
      'Carrot',
    ],
    'fruits': [
      'Watermelon',
      'Pear',
      'Pinapple',
      'Mango',
    ],
    'grains': [
      'Green Grams',
      'Red Lentils',
      'Soy Beans',
      'Red Cowpea',
    ],
    'leafy_greens': [
      'Cabbage',
      'Gotukola',
      'Nivithi',
      'Minchi',
    ],
  };

  static List<String> getItemsForCategory(String category) {
    return items[category.toLowerCase()] ?? [];
  }

  static bool isValidItem(String category, String itemName) {
    final categoryItems = items[category.toLowerCase()];
    return categoryItems?.contains(itemName) ?? false;
  }
}
