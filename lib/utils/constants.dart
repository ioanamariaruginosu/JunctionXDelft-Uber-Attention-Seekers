class Constants {
  static const String appName = 'Uber';
  static const String tagline = 'Get moving with Uber';

  static const int tripRequestTimeout = 15;
  static const int mockTripMinInterval = 30;
  static const int mockTripMaxInterval = 120;

  static const double baseFare = 3.0;
  static const double perMileRate = 1.5;
  static const double perMinuteRate = 0.3;
  static const double minimumFare = 5.0;

  static const double surgeMultiplierMin = 1.0;
  static const double surgeMultiplierMax = 3.0;

  static const List<String> locations = [
    'Downtown Financial District',
    'Airport Terminal 2',
    'University Campus',
    'Shopping Mall - West End',
    'Residential Area - Oak Hills',
    'Tech Park - Silicon Valley',
    'Hospital - St. Mary\'s',
    'Train Station - Central',
    'Beach Resort - Sunset Bay',
    'Convention Center',
    'Sports Stadium - North',
    'City Hall',
    'Museum District',
    'Restaurant Row',
    'Hotel Plaza',
    'Business Park East',
    'Waterfront District',
    'Arts Quarter',
    'Medical Center',
    'Entertainment Complex',
  ];

  static const List<String> maskotGreetings = [
    'Hello! I\'m Ube, your AI co-pilot. Ready to maximize your earnings today?',
    'Welcome back! Ube here, let\'s make today profitable!',
    'Hey there! Ube at your service. Time to optimize those earnings!',
    'Good to see you! I\'m Ube, and I\'ve got some hot spots for you.',
  ];

  static const List<String> maskotEncouragements = [
    'You\'re doing great! Keep it up!',
    'Excellent driving today! Your ratings are stellar.',
    'Nice work on that last trip!',
    'You\'re on fire today! 🔥',
    'That was a smart acceptance. Good call!',
  ];

  static const Map<String, List<String>> timeBasedMessages = {
    'morning': [
      'Good morning! Morning rush hour starting soon.',
      'Rise and shine! Airport runs are hot right now.',
      'Early bird gets the surge! Downtown is heating up.',
    ],
    'lunch': [
      'Lunch rush incoming! Position near business districts.',
      'Food delivery competition is high. Focus on passenger rides.',
      'Office workers need rides. Downtown is your friend.',
    ],
    'evening': [
      'Evening rush starting! This is prime time.',
      'Happy hour means busy bars. Position accordingly.',
      'Commuters heading home. Highways will be busy.',
    ],
    'night': [
      'Late night surges coming. Bar districts are hot.',
      'Stay safe out there! Well-lit areas recommended.',
      'Weekend nights = maximum earnings potential.',
    ],
  };

  static const Map<String, String> achievementTitles = {
    'early_bird': 'Early Bird',
    'night_owl': 'Night Owl',
    'century_club': 'Century Club',
    'five_star': '5-Star Driver',
    'speed_demon': 'Speed Demon',
    'marathoner': 'Marathoner',
    'weekend_warrior': 'Weekend Warrior',
    'surge_master': 'Surge Master',
    'tip_magnet': 'Tip Magnet',
    'perfect_week': 'Perfect Week',
  };

  static const Map<String, String> achievementDescriptions = {
    'early_bird': 'Started driving before 6 AM for 5 days',
    'night_owl': 'Drove past midnight for 5 days',
    'century_club': 'Completed 100 total trips',
    'five_star': 'Maintained 5.0 rating for 50 trips',
    'speed_demon': 'Completed 10 trips in 3 hours',
    'marathoner': 'Stayed online for 10 hours straight',
    'weekend_warrior': 'Earned \\\$500+ on a weekend',
    'surge_master': 'Caught 10 surge rides in a day',
    'tip_magnet': 'Received tips on 10 consecutive rides',
    'perfect_week': 'Met all weekly goals',
  };

  static const List<String> vehicleTypes = [
    'Car',
    'Motorcycle',
    'Bicycle',
    'Scooter',
  ];

  static const Map<String, dynamic> defaultPreferences = {
    'notifications': true,
    'soundEffects': false,
    'vibration': true,
    'autoBreaks': true,
    'breakInterval': 3,
    'maskotPersonality': 'balanced',
    'voiceAlerts': false,
    'nightMode': 'auto',
    'showEarningsGoal': true,
    'dailyGoal': 150.0,
    'weeklyGoal': 1000.0,
  };

  // Toggle demo features (set true for presentations to enable scripted mascot messages)
  static const bool kDemoMode = false;
}