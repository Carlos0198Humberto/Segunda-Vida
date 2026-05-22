class AppConstants {
  static const String appName = 'Pulsador de Vida';

  // ── Cambia esto con la URL que Railway te da al desplegar ──────────────────
  // Ej: 'https://segunda-vida-production.up.railway.app/api/v1'
  static const String _railwayUrl = 'https://TU-APP.up.railway.app/api/v1';

  // Solo para desarrollo local con Docker o servidor local
  static const String _devUrlAndroid = 'http://10.0.2.2:8000/api/v1';
  static const String _devUrlLocal = 'http://localhost:8000/api/v1';

  // Usa _railwayUrl siempre que el backend esté en Railway
  static String get baseUrl => _railwayUrl;

  // Hive box names
  static const String authBox = 'auth_box';
  static const String settingsBox = 'settings_box';
  static const String cacheBox = 'cache_box';

  // Storage keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeModeKey = 'theme_mode';
  static const String pinEnabledKey = 'pin_enabled';
  static const String biometricEnabledKey = 'biometric_enabled';

  // Time categories
  static const List<String> timeCategories = [
    'study',
    'productive',
    'learning',
    'reading',
    'exercise',
    'phone',
    'entertainment',
    'social',
    'wasted',
  ];

  // Savings fund icons
  static const Map<String, String> savingsFundIcons = {
    'health': 'favorite',
    'car': 'directions_car',
    'studies': 'school',
    'emergency': 'shield',
    'pc': 'computer',
    'wedding': 'favorite_border',
    'nephew': 'child_care',
    'travel': 'flight',
    'home': 'home',
  };

  // Water amounts (ml)
  static const List<int> waterAmounts = [150, 200, 250, 300, 350, 500];

  // Meal types
  static const List<String> mealTypes = [
    'breakfast',
    'lunch',
    'dinner',
    'snack',
  ];

  // Activity types for planning
  static const List<Map<String, String>> activityTypes = [
    {'key': 'study', 'label': 'Study', 'icon': 'book'},
    {'key': 'work', 'label': 'Work', 'icon': 'work'},
    {'key': 'exercise', 'label': 'Exercise', 'icon': 'fitness_center'},
    {'key': 'learning', 'label': 'Learning', 'icon': 'lightbulb'},
    {'key': 'rest', 'label': 'Rest', 'icon': 'bedtime'},
    {'key': 'social', 'label': 'Social', 'icon': 'people'},
    {'key': 'creative', 'label': 'Creative', 'icon': 'palette'},
    {'key': 'routine', 'label': 'Routine', 'icon': 'repeat'},
    {'key': 'free', 'label': 'Free Time', 'icon': 'toys'},
    {'key': 'admin', 'label': 'Admin', 'icon': 'admin_panel_settings'},
  ];
}
