class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static final Map<String, Map<String, String>> localizedStrings = {
    'en': {
      // General
      'settings': 'Settings',
      'language': 'Language',
      'clear scan history': 'Clear Scan History',
      'clear cache': 'Clear Cache',
      'scan history': 'Scan History',
      'no scans available': 'No scan history available.',
      'recent scans': 'List of recent scans:',
      'upload image': 'Upload Image',
      'scan now': 'Scan Now',
      'see more': 'See More',
      'help': 'Help',
      'home': 'Home',
      'timestamp': 'Timestamp',
      'close': 'Close',
      'uploaded_image': 'Uploaded Image',
      'failed_to_pick_image': 'Failed to pick image. Please try again.',
      'app_title': 'FreshEval',
      'history': 'History',
      'retake_scan': 'Retake Scan',
      'save': 'Save',
      'scan_saved_successfully': 'Scan saved successfully!',
      'failed_to_save_scan': 'Failed to save scan.',
      'camera_permission_denied': 'Camera permission denied.',
      'search': 'Search', // New translation
      'delete scans': 'Delete Scans', // New translation
      'confirm_delete_selected_scans': 'Are you sure you want to delete the selected scans?', // New translation
      'deleted': 'deleted', // New translation

      // Confirmation Dialogs
      'confirm_clear_history': 'Are you sure you want to clear the scan history?',
      'confirm_clear_cache': 'Are you sure you want to clear the cache?',
      'cancel': 'Cancel',
      'confirm': 'Confirm',

      // Settings Page
      'settings_description': 'Go to the Settings page to change the app’s language or clear history.',
      'language_set_to': 'Language set to',
      'english': 'English',
      'tagalog': 'Tagalog',

      // How to Use
      'how_to_use': 'How to Use the App',
      'scan_description': 'Use the "Scan Now" button to capture a photo of the food item for freshness analysis.',
      'upload_image_description': 'Tap the "Upload Image" button to choose an image from your gallery.',
      'view_scan_history': 'View Scan History',
      'history_description': 'Access your previous scans in the "Scan History" tab.',

      // Help
      'help_description': 'Visit the Help section for guidance and FAQs.',

      // FAQs
      'faqs': 'FAQs',
      'faq1_title': '1. What is this app for?',
      'faq1_description': 'This app helps detect the freshness of vegetables such as eggplant, tomato, and potato.',
      'faq2_title': '2. How does the app detect freshness?',
      'faq2_description': 'The app uses YOLOv8 and EfficientNetB7 models to analyze food freshness.',
      'faq3_title': '3. Can I view my previous scans?',
      'faq3_description': 'Yes, previous scans are saved in the "Scan History" section.',
      'faq4_title': '4. How can I delete my scan history?',
      'faq4_description': 'Go to the Settings page and tap "Clear Scan History."',
      'faq5_title': '5. Can the app work offline?',
      'faq5_description': 'Some features require an internet connection for cloud-based analysis.',
      'faq6_title': '6. What types of food items can the app analyze?',
      'faq6_description': 'It supports top vegetables in the Philippines: eggplant, tomato, and potato.',
    },
    'tl': {
      // General
      'settings': 'Mga Setting',
      'language': 'Wika',
      'clear scan history': 'Burahin ang Kasaysayan ng Scan',
      'clear cache': 'Burahin ang Cache',
      'scan history': 'Kasaysayan ng Scan',
      'no scans available': 'Walang kasaysayan ng scan.',
      'recent scans': 'Listahan ng mga kamakailang scan:',
      'upload image': 'Mag-upload ng Larawan',
      'scan now': 'I-scan Ngayon',
      'see more': 'Tingnan Pa',
      'help': 'Tulong',
      'home': 'Bahay',
      'timestamp': 'Panahon',
      'close': 'Isara',
      'uploaded_image': 'In-upload na Larawan',
      'failed_to_pick_image': 'Hindi nakuha ang larawan. Subukan muli.',
      'app_title': 'Pag-detect ng Kalidad ng Pagkain',
      'history': 'Kasaysayan',
      'retake_scan': 'Ulitin ang Scan',
      'save': 'I-save',
      'scan_saved_successfully': 'Matagumpay na nai-save ang scan!',
      'failed_to_save_scan': 'Hindi nai-save ang scan.',
      'camera_permission_denied': 'Hindi pinayagan ang permiso ng camera.',
      'search': 'Maghanap', // New translation
      'delete scans': 'Burahin ang Mga Scan', // New translation
      'confirm_delete_selected_scans': 'Sigurado ka bang nais mong burahin ang mga napiling scan?', // New translation
      'deleted': 'nabura', // New translation

      // Confirmation Dialogs
      'confirm_clear_history': 'Sigurado ka bang nais mong burahin ang kasaysayan ng scan?',
      'confirm_clear_cache': 'Sigurado ka bang nais mong burahin ang cache?',
      'cancel': 'Kanselahin',
      'confirm': 'Kumpirmahin',

      // Settings Page
      'settings_description': 'Puntahan ang Mga Setting upang baguhin ang wika o burahin ang kasaysayan.',
      'language_set_to': 'Itinakda ang wika sa',
      'english': 'Ingles',
      'tagalog': 'Tagalog',

      // How to Use
      'how_to_use': 'Paano Gamitin ang App',
      'scan_description': 'Gamitin ang "I-scan Ngayon" upang kumuha ng larawan ng gulay at suriin ang pagiging sariwa.',
      'upload_image_description': 'Pindutin ang "Mag-upload ng Larawan" upang pumili ng larawan mula sa gallery.',
      'view_scan_history': 'Tingnan ang Kasaysayan ng Scan',
      'history_description': 'Puntahan ang tab na "Kasaysayan ng Scan" para sa mga nakaraang scan.',

      // Help
      'help_description': 'Puntahan ang seksyong Tulong para sa gabay at FAQs.',

      // FAQs
      'faqs': 'Mga Madalas Itanong',
      'faq1_title': '1. Para saan ang app na ito?',
      'faq1_description': 'Tumutulong ang app na ito upang matukoy ang pagiging sariwa ng mga gulay tulad ng talong, kamatis, at patatas.',
      'faq2_title': '2. Paano natutukoy ng app ang pagiging sariwa?',
      'faq2_description': 'Ginagamit ng app ang mga modelo ng YOLOv8 at EfficientNetB7 upang suriin ang pagiging sariwa.',
      'faq3_title': '3. Makikita ko ba ang mga nakaraang scan?',
      'faq3_description': 'Oo, nakasave ang mga nakaraang scan sa seksyong "Kasaysayan ng Scan."',
      'faq4_title': '4. Paano ko mabubura ang kasaysayan ng scan?',
      'faq4_description': 'Pumunta sa Mga Setting at pindutin ang "Burahin ang Kasaysayan ng Scan."',
      'faq5_title': '5. Puwede bang gumana ang app offline?',
      'faq5_description': 'Kailangan ng koneksyon sa internet para sa ibang mga tampok tulad ng cloud analysis.',
      'faq6_title': '6. Anong mga uri ng pagkain ang kayang suriin ng app?',
      'faq6_description': 'Sumusuporta ito sa mga pangunahing gulay sa Pilipinas: talong, kamatis, at patatas.',
    },
  };

  String getTranslation(String key) {
    return localizedStrings[languageCode]?[key] ??
        localizedStrings['en']?[key] ??
        'Translation missing for $key';
  }
}
