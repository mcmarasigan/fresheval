import 'package:flutter/foundation.dart';
import 'package:flutter/src/widgets/framework.dart';

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
      'cache': 'Cache',
      'camera': 'Camera',
      'developers': 'Developers',
      'scan history': 'Scan History',
      'no scans available': 'No scan history available.',
      'no bookmarked scans': 'No bookmarked scans yet.',
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
      'search': 'Search',
      'delete': 'Delete',
      'delete scans': 'Delete Scans',
      'confirm_delete_selected_scans':
          'Are you sure you want to delete the selected scans?',
      'deleted': 'deleted',
      'scans_deleted': 'Selected scans deleted.',
      'all_scans': 'All Scans',
      'bookmarks': 'Bookmarks',
      'clean your camera': 'Clean Your Camera',
      'clean camera desc':
          'Wipe your camera lens with a soft cloth to remove smudges and dust for clearer photos.',
      'good lighting': 'Good Lighting',
      'good lighting desc':
          'Take photos in well-lit conditions. Avoid direct sunlight or dark shadows.',
      'steady and clear': 'Steady & Clear',
      'steady and clear desc':
          'Hold your phone steady to avoid blurry images. Tap to focus on the vegetables.',
      'full view': 'Full View',
      'full view desc':
          'Capture the entire vegetable in the frame. Avoid cutting off parts of it.',
      'one object': 'One Object', // Added
      'Scan one object at a time. It can be eggplant, tomato, or potato':
          'Scan one object at a time. It can be eggplant, tomato, or potato', // Added
      'dont show again': "Don't show again",
      'got it': 'Got It',
      'upload front title': 'Upload Front Image',
      'upload front desc': 'Please select the FRONT view of the vegetable.',
      'upload back title': 'Upload Back Title',
      'upload back desc': 'Now select the BACK view of the vegetable.',
      'front captured':
          '✅ Front side captured. Now take the back side of the vegetable.',
      'no front selected': '❌ No front image selected from gallery',
      'no back selected': '❌ No back image selected from gallery',
      'scan results': 'Scan Results',
      'scan details': 'Scan Details',
      'front view': 'Front view',
      'back view': 'Back view',
      'eggplant': 'Eggplant',
      'tomato': 'Tomato',
      'potato': 'Potato',
      'unknown': 'Unknown',

      // Confirmation Dialogs & Popup Dialogs
      'confirm_clear_history':
          'Are you sure you want to clear the scan history?',
      'confirm_clear_cache': 'Are you sure you want to clear the cache?',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'pick image': 'Pick Image',
      'save successful': 'Save Successful',
      'save successful desc': 'Scan results have been saved successfully!',
      'already save': 'Already Save',
      'already save desc':
          'This scan result has already been saved to scan history.',

      // Settings Page
      'settings_description':
          'Go to the Settings page to change the app’s language or clear history.',
      'language_set_to': 'Language set to',
      'english': 'English',
      'tagalog': 'Tagalog',

      // How to Use
      'how_to_use': 'How to Use the App',
      'scan_description':
          'Use the "Scan Now" button to capture a photo of the food item for freshness analysis.',
      'upload_image_description':
          'Tap the "Upload Image" button to choose an image from your gallery.',
      'view_scan_history': 'View Scan History',
      'history_description':
          'Access your previous scans in the "Scan History" tab.',

      // Help
      'help_description': 'Visit the Help section for guidance and FAQs.',

      // FAQs
      'faqs': 'FAQs',
      'faq1_title': '1. What is this app for?',
      'faq1_description':
          'This app helps detect the freshness of vegetables such as eggplant, tomato, and potato.',
      'faq2_title': '2. How does the app detect freshness?',
      'faq2_description':
          'The app uses YOLOv8 and EfficientNetB7 models to analyze food freshness.',
      'faq3_title': '3. Can I view my previous scans?',
      'faq3_description':
          'Yes, previous scans are saved in the "Scan History" section.',
      'faq4_title': '4. How can I delete my scan history?',
      'faq4_description':
          'Go to the Settings page and tap "Clear Scan History."',
      'faq6_title': '6. What types of food items can the app analyze?',
      'faq6_description':
          'It supports the following vegetables: eggplant, tomato, and potato.',

      // Developers Page
      'developers_title': 'Developers',
      'about_developers': 'About the Developers',
      'developers_description':
          'Meet the team behind FreshEval, dedicated to bringing you the best in vegetable freshness detection.',
      'team_members': 'Team Members',
      'member1_name': 'Ma. Clarissa Marasigan',
      'member1_role': 'Main Programmer',
      'member1_about':
          'Clarissa serves as the Main Programmer for FreshEval, orchestrating the core functionality and developed the robust logic that powers the camera, image processing, and data management, making FreshEval a reliable tool for freshness evaluation.',
      'member2_name': 'Vhon Joshua Agbayani',
      'member2_role': 'AI Specialist',
      'member2_about':
          'Vhon is an AI expert and the Model Trainer behind the cutting-edge freshness detection of the application',
      'member3_name': 'Krysteen Clare Belen',
      'member3_role': 'FrontEnd Developer',
      'member3_about':
          'Krysteen is a skilled Front End Developer with a passion for crafting responsive and visually appealing interfaces',
      'member4_name': 'Clark Czedrick Limson',
      'member4_role': 'UI/UX Designer',
      'member4_about':
          'Clark designs intuitive user interfaces and ensures a seamless user experience for FreshEval.',
      'contact_us': 'Contact Us',
      'website_label': 'Website',

      // Developer Detail Page
      'developer_details': 'Developer Details',
      'name_label': 'Name',
      'role_label': 'Role',
      'about_label': 'About',
      'email_label': 'Email:',

      // Errors
      'scan error': 'Scan Error',
      'different vegetable error':
          'Different vegetables detected: Front ({front}) vs. Back({back}). Please scan the same vegetable.',
      'no objects detected': 'No objects detected in the {side} image',
      'front': 'front',
      'back': 'back',
    },
    'tl': {
      // General
      'settings': 'Mga Setting',
      'language': 'Wika',
      'clear scan history': 'Burahin ang Kasaysayan ng Scan',
      'clear cache': 'Burahin ang Cache',
      'cache': 'Nabura ang Cache',
      'camera': 'Kamera',
      'developers': 'Mga Developer',
      'scan history': 'Kasaysayan ng Scan',
      'no scans available': 'Walang kasaysayan ng Scan.',
      'no bookmarked scans': 'Wala pang naka-bookmark na Scan',
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
      'camera_permission_denied': 'Tinanggihan ng pahintulot para sa kamera.',
      'search': 'Maghanap',
      'delete': 'Burahin',
      'delete scans': 'Burahin ang Mga Scan',
      'confirm_delete_selected_scans':
          'Sigurado ka bang nais mong burahin ang mga napiling scan?',
      'deleted': 'nabura',
      'scans_deleted': 'Nabura ang mga napiling scan.',
      'all_scans': 'Lahat ng Scan',
      'bookmarks': 'Mga Bookmark',
      'clean your camera': 'Linisin ang iyong Kamera',
      'clean camera desc':
          'Punasan ang lens ng iyong camera gamit ang malambot na tela upang alisin ang mga mantsa at alikabok para sa mas malinaw na mga larawan.',
      'good lighting': 'Magandang Ilaw',
      'good lighting desc':
          'Kumuha ng mga larawas sa maayos na kondisyon. Iwasan ang direktang sikat ng araw o madilim na anino.',
      'steady and clear': 'Matatag at Malinaw',
      'steady and clear desc':
          'Hawakan nang matatag ang iyong telepono upang maiwasan ang malabong mga imahe. Mag-tap upang magpokus sa mga gulay.',
      'full view': 'Buong tanaw',
      'full view desc':
          'Kunin ang buong gulay sa frame. Iwasan ang pagputol ng mga bahagi nito.',
      'one object': 'Isang Bagay', // Added
      'Scan one object at a time. It can be eggplant, tomato, or potato':
          'I-scan ang isang bagay sa isang pagkakataon. Maaaring ito ay talong, kamatis, o patatas', // Added
      'dont show again': "Huwag nang ipakita",
      'got it': 'Naunawaan',
      'upload front title': 'Mag-upload ng harapang larawan',
      'upload front desc': 'Maaaring piliin ang harapang bahagi ng gulay.',
      'upload back title': 'Mag-upload ng likod na larawan',
      'upload back desc': 'Ngayon, piliin ang likod na bahagi ng gulay.',
      'front captured':
          '✅ Nakuha ang harapang bahagi. Ngayon ay kunin ang likod na bahagi ng gulay.',
      'no front selected':
          '❌ Walang napiling harap na larawan mula sa gallery.',
      'no back selected': '❌ Walang napiling likod na larawan mula sa gallery.',
      'scan results': 'Resulta ng Scan',
      'scan details': 'Mga Detalye ng Scan',
      'front view': 'Harapan na bahagi',
      'back view': 'Likod na bahagi',
      'eggplant': 'Talong',
      'tomato': 'Kamatis',
      'potato': 'Patatas',
      'unknown': 'Hindi Kilala',

      // Confirmation Dialogs & Popup Dialogs
      'confirm_clear_history':
          'Sigurado ka bang nais mong burahin ang kasaysayan ng scan?',
      'confirm_clear_cache': 'Sigurado ka bang nais mong burahin ang cache?',
      'cancel': 'Kanselahin',
      'confirm': 'Kumpirmahin',
      'pick image': 'Mamili ng Larawan',
      'save successful': 'Matagumpay na i-save',
      'save successful desc':
          'Matagumpay na na-save ang mga resulta ng pag-scan!',
      'already save': 'Naka-save na',
      'already save desc':
          'Ang resulta ng pag-scan na ito ay nai-save na sa kasaysayan ng pag-scan',

      // Settings Page
      'settings_description':
          'Puntahan ang Mga Setting upang baguhin ang wika o burahin ang kasaysayan.',
      'language_set_to': 'Itinakda ang wika sa',
      'english': 'Ingles',
      'tagalog': 'Tagalog',

      // How to Use
      'how_to_use': 'Paano Gamitin ang App',
      'scan_description':
          'Gamitin ang "I-scan Ngayon" upang kumuha ng larawan ng gulay at suriin ang pagiging sariwa.',
      'upload_image_description':
          'Pindutin ang "Mag-upload ng Larawan" upang pumili ng larawan mula sa gallery.',
      'view_scan_history': 'Tingnan ang Kasaysayan ng Scan',
      'history_description':
          'Puntahan ang tab na "Kasaysayan ng Scan" para sa mga nakaraang scan.',

      // Help
      'help_description': 'Puntahan ang seksyong Tulong para sa gabay at FAQs.',

      // FAQs
      'faqs': 'Mga Madalas Itanong',
      'faq1_title': '1. Para saan ang app na ito?',
      'faq1_description':
          'Tumutulong ang app na ito upang matukoy ang pagiging sariwa ng mga gulay tulad ng talong, kamatis, at patatas.',
      'faq2_title': '2. Paano natutukoy ng app ang pagiging sariwa?',
      'faq2_description':
          'Ginagamit ng app ang mga modelo ng YOLOv8 at EfficientNetB7 upang suriin ang pagiging sariwa.',
      'faq3_title': '3. Makikita ko ba ang mga nakaraang scan?',
      'faq3_description':
          'Oo, nakasave ang mga nakaraang scan sa seksyong "Kasaysayan ng Scan."',
      'faq4_title': '4. Paano ko mabubura ang kasaysayan ng scan?',
      'faq4_description':
          'Pumunta sa Mga Setting at pindutin ang "Burahin ang Kasaysayan ng Scan."',
      'faq6_title': '6. Anong mga uri ng pagkain ang kayang suriin ng app?',
      'faq6_description':
          'Sumusuporta ito sa mga gulay: talong, kamatis, at patatas.',

      // Developers Page
      'developers_title': 'Mga Developer',
      'about_developers': 'Tungkol sa Mga Developer',
      'developers_description':
          'Kilalanin ang koponan sa likod ng FreshEval, na nakatuon sa pagbibigay ng pinakamahusay na pagtukoy sa pagiging sariwa ng gulay.',
      'team_members': 'Mga Miyembro ng Koponan',
      'member1_name': 'Ma. Clarissa Marasigan',
      'member1_role': 'Pangunahing Programmer',
      'member1_about':
          'Si Clarissa ang nagsisilbing pangunahing programmer para sa Fresheval, na nag-aayos ng pangunahing pag-andar at bumuo ng matibay na lohika na nagpapatakbo sa kamera, pagproseso ng larawan, at pamamahala ng datos, na ginagawang isang maaasahang kagamitan para sa pagsusuri ng kasariwaan.',
      'member2_name': 'Vhon Joshua Agbayani',
      'member2_role': 'Eksperto sa AI',
      'member2_about':
          'Si Vhon ay isang eksperto sa AI at ang tagapagsanay ng modelo sa likod ng makabagong sistema ng pagtukoy sa kasariwaan ng aplikasyon.',
      'member3_name': 'Krysteen Clare Belen',
      'member3_role': 'FrontEnd Developer',
      'member3_about':
          'Si Krysteen ay isang bihasang Front End Developer na may pagkahilig sa paglikha ng mga tumutugon at kaakit-akit na interface.',
      'member4_name': 'Clark Czedrick Limson',
      'member4_role': 'Designer ng UI/UX',
      'member4_about':
          'Taga-disenyo si Clark ng mga makatuwiran na interface ng mga gumagamit at tinitiyak ang isang maayos na karanasan ng mga gumagamit para sa FreshEval.',
      'contact_us': 'Makipag-ugnayan Sa Amin',
      'website_label': 'Website',

      // Developer Detail Page
      'developer_details': 'Mga Detalye ng Developer',
      'name_label': 'Pangalan',
      'role_label': 'Tungkulin',
      'about_label': 'Tungkol Sa',
      'email_label': 'Email:',

      // Errors
      'scan error': 'Error sa Scan',
      'different vegetable error':
          'Magkaiba ang gulay: Harap ({front}) kumpara sa Likod ({back}). Paki-scan ang parehong gulay.',
      'no objects detected': 'Walang bagay na nakita sa {side} ng imahe',
      'front': 'harap',
      'back': 'likod',
    },
  };

  String getTranslation(String key) {
    final translation = localizedStrings[languageCode]?[key] ??
        localizedStrings['en']?[key] ??
        '';
    if (translation.isEmpty) {
      debugPrint(
        'Translation missing for key: $key in language: $languageCode',
      );
    }
    return translation;
  }

  String getVegetableLabel(String key) {
    final labelMap = {
      'eggplant': getTranslation('eggplant'),
      'tomato': getTranslation('tomato'),
      'potato': getTranslation('potato'),
    };

    return labelMap[key.toLowerCase()] ?? key;
  }

  static of(BuildContext context) {}
}
