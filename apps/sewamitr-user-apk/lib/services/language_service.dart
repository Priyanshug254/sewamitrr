import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;

  LanguageService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'en';
    notifyListeners();
  }

  final Map<String, Map<String, String>> _translations = {
    'en': {
      // Auth
      'login': 'Login',
      'signup': 'Sign Up',
      'create_account': 'Create Account',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'name': 'Name',
      'full_name': 'Full Name',
      'language': 'Language',
      'preferred_language': 'Preferred Language',
      'english': 'English',
      'hindi': 'Hindi',
      
      // Welcome
      'civic_issue_reporting_platform': 'Civic Issue Reporting Platform',
      'welcome_back': 'Welcome Back',
      'login_to_report_issues': 'Login to report and track civic issues',
      'join_sewamitr': 'Join SewaMitr',
      'help_improve_your_community': 'Help improve your community',
      'government_of_india_initiative': 'Government of India Initiative',
      
      // Form placeholders
      'enter_your_email': 'Enter your email',
      'enter_your_password': 'Enter your password',
      'enter_your_name': 'Enter your name',
      'create_password': 'Create a strong password',
      'confirm_your_password': 'Confirm your password',
      
      // Navigation
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      
      // Dashboard
      'dashboard': 'Dashboard',
      'welcome_to_sewamitr': 'Welcome to SewaMitr',
      'your_reports': 'Your Reports',
      'resolved': 'Resolved',
      'in_progress': 'In Progress',
      'community': 'Community',
      'quick_actions': 'Quick Actions',
      'report_new_issue': 'Report New Issue',
      'recent_activity': 'Recent Activity',
      'home': 'Home',
      'report': 'Report',
      'feed': 'Feed',
      
      // Profile
      'profile': 'Profile',
      'citizen_hero': 'Citizen Hero',
      'civic_hero': 'Civic Hero',
      'level': 'Level',
      'points': 'pts',
      'more_points_to_reach': 'more points to reach',
      'civic_champion': 'Civic Champion',
      'total_reports': 'Total Reports',
      'issues_resolved': 'Issues Resolved',
      'community_rank': 'Community Rank',
      'days_active': 'Days Active',
      'contact_information': 'Contact Information',
      'phone': 'Phone',
      'edit_profile': 'Edit Profile',
      'settings': 'Settings',
      'change_photo': 'Change Photo',
      'save_changes': 'Save Changes',
      
      // Issue reporting
      'report_issue': 'Report Issue',
      'category': 'Category',
      'description': 'Description',
      'location': 'Location',
      'media': 'Media',
      'road': 'Road',
      'water': 'Water',
      'electricity': 'Electricity',
      'garbage': 'Garbage',
      'street_light': 'Street Light',
      'drainage': 'Drainage',
      'park': 'Park',
      'traffic': 'Traffic',
      'noise': 'Noise',
      'other': 'Other',
      'submit': 'Submit',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'record_audio': 'Record Audio',
      'take_photo': 'Take Photo',
      'choose_from_gallery': 'Choose from Gallery',
      
      // Issue status
      'pending': 'Pending',
      'assigned': 'Assigned',
      'completed': 'Completed',
      'my_reports': 'My Reports',
      'all': 'All',
      'search_issues': 'Search issues...',
      'progress': 'Progress',
      'view_details': 'View Details',
      
      // Map
      'map_view': 'Map View',
      'heatmap': 'Heatmap',
      'your_location': 'Your Location',
      'community_feed': 'Community Feed',
      'nearby': 'Nearby',
      'trending': 'Trending',
      'highest_priority': 'Highest Priority',
      'new': 'New',
      'issues_nearby': 'issues nearby',
      
      // General
      'logout': 'Logout',
      'please_fill_all_fields': 'Please fill all fields',
      'passwords_do_not_match': 'Passwords do not match',
      'account_created_successfully': 'Account created successfully',
      'profile_updated': 'Profile updated successfully',
      'error_occurred': 'An error occurred',
      'loading': 'Loading...',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'ok': 'OK',
      'issue_reported_successfully': 'Issue reported successfully',
      'notifications': 'Notifications',
      'mark_all_read': 'Mark All Read',
      'no_notifications': 'No notifications',
      'change_language': 'Language',
      'help_support': 'Help & Support',
      'sign_out': 'Sign Out',
      'view_all': 'View All',
      'submit_report': 'Submit Report',
      'please_enter_description': 'Please enter a description',
      'feature_coming_soon': 'Feature coming soon!',
      'select_language': 'Select Language',
      'profile_picture_updated': 'Profile picture updated!',
    },
    'hi': {
      // Auth
      'login': 'लॉगिन',
      'signup': 'साइन अप',
      'create_account': 'खाता बनाएं',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'confirm_password': 'पासवर्ड की पुष्टि करें',
      'name': 'नाम',
      'full_name': 'पूरा नाम',
      'language': 'भाषा',
      'preferred_language': 'पसंदीदा भाषा',
      'english': 'अंग्रेजी',
      'hindi': 'हिंदी',
      
      // Welcome
      'civic_issue_reporting_platform': 'नागरिक समस्या रिपोर्टिंग प्लेटफॉर्म',
      'welcome_back': 'वापस स्वागत है',
      'login_to_report_issues': 'नागरिक समस्याओं की रिपोर्ट और ट्रैक करने के लिए लॉगिन करें',
      'join_sewamitr': 'सेवामित्र में शामिल हों',
      'help_improve_your_community': 'अपने समुदाय को बेहतर बनाने में मदद करें',
      'government_of_india_initiative': 'भारत सरकार की पहल',
      
      // Form placeholders
      'enter_your_email': 'अपना ईमेल दर्ज करें',
      'enter_your_password': 'अपना पासवर्ड दर्ज करें',
      'enter_your_name': 'अपना नाम दर्ज करें',
      'create_password': 'एक मजबूत पासवर्ड बनाएं',
      'confirm_your_password': 'अपने पासवर्ड की पुष्टि करें',
      
      // Navigation
      'dont_have_account': 'खाता नहीं है?',
      'already_have_account': 'पहले से खाता है?',
      
      // Dashboard
      'dashboard': 'डैशबोर्ड',
      'welcome_to_sewamitr': 'सेवामित्र में आपका स्वागत है',
      'your_reports': 'आपकी रिपोर्ट्स',
      'resolved': 'हल हो गया',
      'in_progress': 'प्रगति में',
      'community': 'समुदाय',
      'quick_actions': 'त्वरित कार्य',
      'report_new_issue': 'नई समस्या रिपोर्ट करें',
      'recent_activity': 'हाल की गतिविधि',
      'home': 'होम',
      'report': 'रिपोर्ट',
      'feed': 'फीड',
      
      // Profile
      'profile': 'प्रोफाइल',
      'citizen_hero': 'नागरिक हीरो',
      'civic_hero': 'नागरिक हीरो',
      'level': 'स्तर',
      'points': 'अंक',
      'more_points_to_reach': 'तक पहुंचने के लिए और अंक',
      'civic_champion': 'नागरिक चैंपियन',
      'total_reports': 'कुल रिपोर्ट्स',
      'issues_resolved': 'हल की गई समस्याएं',
      'community_rank': 'समुदायिक रैंक',
      'days_active': 'सक्रिय दिन',
      'contact_information': 'संपर्क जानकारी',
      'phone': 'फोन',
      'edit_profile': 'प्रोफाइल संपादित करें',
      'settings': 'सेटिंग्स',
      'change_photo': 'फोटो बदलें',
      'save_changes': 'परिवर्तन सहेजें',
      
      // Issue reporting
      'report_issue': 'समस्या रिपोर्ट करें',
      'category': 'श्रेणी',
      'description': 'विवरण',
      'location': 'स्थान',
      'media': 'मीडिया',
      'road': 'सड़क',
      'water': 'पानी',
      'electricity': 'बिजली',
      'garbage': 'कचरा',
      'street_light': 'स्ट्रीट लाइट',
      'drainage': 'जल निकासी',
      'park': 'पार्क',
      'traffic': 'यातायात',
      'noise': 'शोर',
      'other': 'अन्य',
      'submit': 'जमा करें',
      'camera': 'कैमरा',
      'gallery': 'गैलरी',
      'record_audio': 'ऑडियो रिकॉर्ड करें',
      'take_photo': 'फोटो लें',
      'choose_from_gallery': 'गैलरी से चुनें',
      
      // Issue status
      'pending': 'लंबित',
      'assigned': 'सौंपा गया',
      'completed': 'पूर्ण',
      'my_reports': 'मेरी रिपोर्ट्स',
      'all': 'सभी',
      'search_issues': 'समस्याएं खोजें...',
      'progress': 'प्रगति',
      'view_details': 'विवरण देखें',
      
      // Map
      'map_view': 'मैप व्यू',
      'heatmap': 'हीटमैप',
      'your_location': 'आपका स्थान',
      'community_feed': 'समुदायिक फीड',
      'nearby': 'आस-पास',
      'trending': 'ट्रेंडिंग',
      'highest_priority': 'उच्चतम प्राथमिकता',
      'new': 'नया',
      'issues_nearby': 'आस-पास की समस्याएं',
      
      // General
      'logout': 'लॉगआउट',
      'please_fill_all_fields': 'कृपया सभी फील्ड भरें',
      'passwords_do_not_match': 'पासवर्ड मेल नहीं खाते',
      'account_created_successfully': 'खाता सफलतापूर्वक बनाया गया',
      'profile_updated': 'प्रोफाइल सफलतापूर्वक अपडेट किया गया',
      'error_occurred': 'एक त्रुटि हुई',
      'loading': 'लोड हो रहा है...',
      'retry': 'पुनः प्रयास करें',
      'cancel': 'रद्द करें',
      'ok': 'ठीक है',
      'issue_reported_successfully': 'समस्या सफलतापूर्वक रिपोर्ट की गई',
      'notifications': 'सूचनाएं',
      'mark_all_read': 'सभी को पढ़ा हुआ चिह्नित करें',
      'no_notifications': 'कोई सूचना नहीं',
      'change_language': 'भाषा',
      'help_support': 'सहायता और समर्थन',
      'sign_out': 'साइन आउट',
      'view_all': 'सभी देखें',
      'submit_report': 'रिपोर्ट जमा करें',
      'please_enter_description': 'कृपया विवरण दर्ज करें',
      'feature_coming_soon': 'फीचर जल्द आ रहा है!',
      'select_language': 'भाषा चुनें',
      'profile_picture_updated': 'प्रोफाइल फोटो अपडेट किया गया!',
    },
  };

  String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }

  Future<void> changeLanguage(String language) async {
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    notifyListeners();
  }
}