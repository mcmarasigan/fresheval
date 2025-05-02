import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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
      'one vegetable': 'One Vegetable at a time',
      'Scan one vegetable at a time. It can be eggplant, tomato, or potato':
          'Scan one vegetable at a time. It can be eggplant, tomato, or potato',
      'dont show again': "Don't show again",
      'got it': 'Got It',
      'upload front title': 'Upload Front Image',
      'upload front desc': 'Please select the FRONT view of the vegetable.',
      'upload back title': 'Upload Back Image',
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
      'front r': 'Front',
      'back r': 'Back',
      'overall': 'Overall',
      'shelf life': 'Shelf life',
      'recommendation': 'Recommendation',

      // Confirmation Dialogs & Popup Dialogs
      'confirm_clear_history':
          'Are you sure you want to clear the scan history?',
      'confirm_clear_cache': 'Are you sure you want to clear the cache?',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'pick image': 'Pick Image',
      'save successful': 'Save Successful',
      'save successful desc': 'Scan results have been saved successfully!',
      'already save': 'Already Saved',
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
          'Clarissa is the Main Programmer of FreshEval, leading the development of its core features including the camera system, image processing, and data handling to ensure accurate and reliable freshness evaluation.',
      'member2_name': 'Vhon Joshua Agbayani',
      'member2_role': 'Debugger/Model Trainer',
      'member2_about':
          'Vhon trains the AI models and handles debugging to ensure accurate freshness detection in the app.',
      'member3_name': 'Krysteen Clare Belen',
      'member3_role': 'FrontEnd Developer',
      'member3_about':
          'Krysteen is a skilled Front End Developer with a passion for crafting responsive and visually appealing interfaces',
      'member4_name': 'Clark Czedrick Limson',
      'member4_role': 'Debugger',
      'member4_about':
          'Clark focuses on identifying and fixing bugs to ensure smooth and reliable performance for FreshEval.',
      'contact_us': 'Contact Us',
      'website_label': 'Website',

      // Developer Detail Page
      'developer_details': 'Developer Details',
      'name_label': 'Name',
      'role_label': 'Role',
      'about_label': 'About',
      'email_label': 'Email:',

      // Errors
      'scan error': 'Oops! Something went wrong. Want to try again?',
      'different vegetable error':
          'Different vegetables detected: Front ({front}) vs. Back({back}). Please scan the same vegetable.',
      'error_different_vegetables': '❌ Error – Different vegetables detected',
      'no_valid_vegetable_detected':
          'No recognized vegetable found. Only eggplant, tomato, or potato are supported. Ensure the image is sharp and taken in good lighting.',
      'front': 'front',
      'back': 'back',

      // VQR Dialog
      'vqr_title': 'Visual Quality Rating (VQR)',
      'vqr_9_8': '9,8 - Excellent quality, field fresh',
      'vqr_7_6': '7,6 - Good quality; minor defects',
      'vqr_5_4':
          '5,4 - Fair quality; moderate defects; limit of marketability (supermarket condition)',
      'vqr_3': '3 - Poor quality; serious defects',
      'vqr_2': '2 - Limit of edibility',
      'vqr_1': '1 - Non-edible',
      'ok': 'OK',

      // Image Status Messages
      'image_too_dark': 'Image Too Dark',
      'image_too_bright': 'Image Too Bright',
      'image_too_blurry': 'Image Too Blurry',

      // Camera Screen Specific
      'cannot_capture_while_uploading':
          'Cannot capture a photo because an upload is in progress. Please reset first.',
      'cannot_upload_while_capturing':
          'Cannot upload images while capturing. Please reset or finish capturing first.',
      'front_image_reset': '🔄 Front image reset. You can retake.',

      // Freshness Status (from ModelService.interpretFreshness)
      'freshness_excellent': '🟢 Fresh (Excellent)',
      'freshness_good': '🟡 Fresh (Good)',
      'freshness_fair': '🟡 Fresh (Fair)',
      'rotten_spoiling': '🔴 Rotten (Spoiling)',
      'rotten': '🔴 Rotten',
      'unknown_status': '⚠️ Unknown',

      // Freshness Labels (from ModelService.getFreshnessLabel)
      'freshness_label_fresh': 'Fresh',
      'freshness_label_rotten': 'Rotten',
      'freshness_label_unknown': 'Unknown',

      // Explanations (from ModelService.getPredictionExplanation)
      'explanation_eggplant_vqr_8':
          'The skin looks shiny and smooth, with a healthy color — very fresh.',
      'explanation_eggplant_vqr_6':
          'Slightly soft and less shiny — still okay to use.',
      'explanation_eggplant_vqr_4':
          'Skin is getting dull and may have slight wrinkling — use soon.',
      'explanation_eggplant_vqr_3':
          'Has wrinkles and dark spots — might be starting to spoil.',
      'explanation_eggplant_vqr_1':
          'Very soft or wrinkled with spots — not good for eating.',
      'explanation_tomato_vqr_8':
          'Firm and smooth with a natural color — perfectly fresh.',
      'explanation_tomato_vqr_6':
          'A little soft when touched, but still looks fine.',
      'explanation_tomato_vqr_4':
          'Feels softer and skin is dull — best eaten soon.',
      'explanation_tomato_vqr_3':
          'Has soft spots and may look darker — might not be safe.',
      'explanation_tomato_vqr_1':
          'Very soft or looks damaged — not safe to eat.',
      'explanation_potato_vqr_8':
          'Very firm and clean — fresh and ready to use.',
      'explanation_potato_vqr_6':
          'Still firm but may have small marks or soft areas.',
      'explanation_potato_vqr_4':
          'Getting softer — use soon before it gets worse.',
      'explanation_potato_vqr_3':
          'Feels soft and may have green or dark spots — almost spoiled.',
      'explanation_potato_vqr_1':
          'Very soft or damaged — better to throw away.',
      'explanation_fallback':
          'We couldn\'t get a clear result. Try scanning again with better lighting.',

      // Shelf Life and Recommendations (from ModelService.getShelfLifeAndRecommendation)
      'shelf_life_eggplant_vqr_8': '🟢 Good for 5–6 days',
      'recommendation_eggplant_vqr_8':
          '✅ Keep in a cool, humid place. Handle gently.',
      'shelf_life_eggplant_vqr_6': '🟡 Use within 3–4 days',
      'recommendation_eggplant_vqr_6': '⚠️ Store properly and use soon.',
      'shelf_life_eggplant_vqr_4': '🟡 Use within 2 days',
      'recommendation_eggplant_vqr_4': '⚠️ Use quickly. Not the best quality.',
      'shelf_life_eggplant_vqr_3': '🔴 Use today',
      'recommendation_eggplant_vqr_3':
          '❌ Use now and remove any damaged parts.',
      'shelf_life_eggplant_vqr_2': '🔴 Not good for selling',
      'recommendation_eggplant_vqr_2': '❌ Throw away or give to animals.',
      'shelf_life_eggplant_vqr_1': '🔴 Spoiled',
      'recommendation_eggplant_vqr_1': '❌ Compost or throw away.',
      'shelf_life_tomato_vqr_8': '🟢 Lasts 14 days',
      'recommendation_tomato_vqr_8': '✅ Keep in cool area. Handle with care.',
      'shelf_life_tomato_vqr_6': '🟡 Lasts 10–12 days',
      'recommendation_tomato_vqr_6': '⚠️ Store properly and monitor daily.',
      'shelf_life_tomato_vqr_4': '🟡 Lasts 4–9 days',
      'recommendation_tomato_vqr_4': '⚠️ May be overripe. Use soon.',
      'shelf_life_tomato_vqr_3': '🔴 Use within 1–3 days',
      'recommendation_tomato_vqr_3': '❌ Use now. Cut off any bad parts.',
      'shelf_life_tomato_vqr_2': '🔴 Not for sale or human consumption',
      'recommendation_tomato_vqr_2': '❌ Feed to animals or dispose.',
      'shelf_life_tomato_vqr_1': '🔴 Spoiled',
      'recommendation_tomato_vqr_1': '❌ Compost or throw away.',
      'shelf_life_potato_vqr_8': '🟢 Lasts 1–2 months',
      'recommendation_potato_vqr_8':
          '✅ Keep in a cool, dark place. Don’t expose to sunlight.',
      'shelf_life_potato_vqr_6': '🟡 Lasts about 1 month',
      'recommendation_potato_vqr_6': '⚠️ Store in a dark, cool place.',
      'shelf_life_potato_vqr_4': '🟡 Use within 1–2 weeks',
      'recommendation_potato_vqr_4': '⚠️ Getting old. Use soon.',
      'shelf_life_potato_vqr_3': '🔴 Less than 3 days',
      'recommendation_potato_vqr_3': '❌ Use now. Check for soft or bad spots.',
      'shelf_life_potato_vqr_2': '🔴 Not safe for human consumption',
      'recommendation_potato_vqr_2': '❌ Feed to animals or discard.',
      'shelf_life_potato_vqr_1': '🔴 Spoiled',
      'recommendation_potato_vqr_1': '❌ Compost or throw away.',
      'shelf_life_unknown': '📆 Info not available',
      'recommendation_unknown': '📌 No recommendation yet.',
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
          'Kumuha ng mga larawan sa maayos na kondisyon. Iwasan ang direktang sikat ng araw o madilim na anino.',
      'steady and clear': 'Matatag at Malinaw',
      'steady and clear desc':
          'Hawakan nang matatag ang iyong telepono upang maiwasan ang malabong mga imahe. Mag-tap upang magpokus sa mga gulay.',
      'full view': 'Buong Tanaw',
      'full view desc':
          'Kunin ang buong gulay sa frame. Iwasan ang pagputol ng mga bahagi nito.',
      'one vegetable': 'Isang Gulay kada Scan',
      'Scan one vegetable at a time. It can be eggplant, tomato, or potato':
          'I-scan ang isang gulay lamang. Maaaring ito ay talong, kamatis, o patatas',
      'dont show again': 'Huwag nang ipakita',
      'got it': 'Naunawaan',
      'upload front title': 'Mag-upload ng Harapang Larawan',
      'upload front desc': 'Piliin ang harapang bahagi ng gulay.',
      'upload back title': 'Mag-upload ng Likod na Larawan',
      'upload back desc': 'Piliin ang likod na bahagi ng gulay.',
      'front captured':
          '✅ Nakuha ang harapang bahagi. Ngayon ay kunin ang likod na bahagi ng gulay.',
      'no front selected':
          '❌ Walang napiling harap na larawan mula sa gallery.',
      'no back selected': '❌ Walang napiling likod na larawan mula sa gallery.',
      'scan results': 'Resulta ng Scan',
      'scan details': 'Mga Detalye ng Scan',
      'front view': 'Harapang Bahagi',
      'back view': 'Likod na Bahagi',
      'eggplant': 'Talong',
      'tomato': 'Kamatis',
      'potato': 'Patatas',
      'unknown': 'Hindi Kilala',
      'front r': 'Harap',
      'back r': 'Likod',
      'overall': 'Kabuuan',
      'shelf life': 'Itinatagal sa estante',
      'recommendation': 'Rekomendasyon',

      // Confirmation Dialogs & Popup Dialogs
      'confirm_clear_history':
          'Sigurado ka bang nais mong burahin ang kasaysayan ng scan?',
      'confirm_clear_cache': 'Sigurado ka bang nais mong burahin ang cache?',
      'cancel': 'Kanselahin',
      'confirm': 'Kumpirmahin',
      'pick image': 'Mamili ng Larawan',
      'save successful': 'Matagumpay na Nai-save',
      'save successful desc':
          'Matagumpay na na-save ang mga resulta ng pag-scan!',
      'already save': 'Naka-save na',
      'already save desc':
          'Ang resulta ng pag-scan na ito ay nai-save na sa kasaysayan ng pag-scan.',

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
          'Si Clarissa ang nagsisilbing pangunahing programmer para sa FreshEval, na nag-aayos ng pangunahing pag-andar at bumuo ng matibay na lohika na nagpapatakbo sa kamera, pagproseso ng larawan, at pamamahala ng datos, na ginagawang isang maaasahang kagamitan para sa pagsusuri ng kasariwaan.',
      'member2_name': 'Vhon Joshua Agbayani',
      'member2_role': 'Debugger / Tagasanay ng Modelo',
      'member2_about':
          'Si Vhon ang nagsasanay sa modelo ng AI at nag-aayos ng mga error para masigurong tama at maayos ang pagtukoy ng kasariwaan sa app.',
      'member3_name': 'Krysteen Clare Belen',
      'member3_role': 'FrontEnd Developer',
      'member3_about':
          'Si Krysteen ay isang bihasang Front End Developer na may pagkahilig sa paglikha ng mga tumutugon at kaakit-akit na interface.',
      'member4_name': 'Clark Czedrick Limson',
      'member4_role': 'Debugger',
      'member4_about':
          'Si Clark ang responsable sa pag-aayos ng mga error at pagsisiguro na maayos at tuloy-tuloy ang takbo ng FreshEval.',
      'contact_us': 'Makipag-ugnayan Sa Amin',
      'website_label': 'Website',

      // Developer Detail Page
      'developer_details': 'Mga Detalye ng Developer',
      'name_label': 'Pangalan',
      'role_label': 'Tungkulin',
      'about_label': 'Tungkol Sa',
      'email_label': 'Email:',

      // Errors
      'scan error': 'Ay, may aberya sa pag-scan. Subukan ulit natin?',
      'different vegetable error':
          'Magkaiba ang gulay: Harap ({front}) kumpara sa Likod ({back}). Paki-scan ang parehong gulay.',
      'error_different_vegetables': '❌ Mali – Magkaibang gulay ang natukoy',
      'no_valid_vegetable_detected':
          'Walang nakilalang gulay. Pakisigurong talong, kamatis, o patatas lang ang nasa larawan. Tiyaking malinaw at maliwanag ang pagkuha ng litrato.',
      'front': 'harap',
      'back': 'likod',

      // VQR Dialog
      'vqr_title': 'Pagsusuri ng Kalidad ng Visual (VQR)',
      'vqr_9_8': '9,8 - Napakahusay na kalidad, sariwa mula sa bukirin',
      'vqr_7_6': '7,6 - Magandang kalidad; may kaunting depekto',
      'vqr_5_4':
          '5,4 - Katamtamang kalidad; may mga depekto; hangganan ng kakayahang maibenta (kundisyon sa supermarket)',
      'vqr_3': '3 - Mahinang kalidad; malubhang depekto',
      'vqr_2': '2 - Hangganan ng kakayahang kainin',
      'vqr_1': '1 - Hindi na maaaring kainin',
      'ok': 'OK',

      // Image Status Messages
      'image_too_dark': 'Masyadong Madilim ang Larawan',
      'image_too_bright': 'Masyadong Maliwanag ang Larawan',
      'image_too_blurry': 'Masyadong Malabo ang Larawan',

      // Camera Screen Specific
      'cannot_capture_while_uploading':
          'Hindi makakakuha ng larawan dahil may isinasagawa nang pag-upload. Paki-reset muna.',
      'cannot_upload_while_capturing':
          'Hindi makakapag-upload ng mga larawan habang kumukuha. Paki-reset o tapusin muna ang pagkuha.',
      'front_image_reset':
          '🔄 Na-reset ang harapang larawan. Maaari kang kumuha ulit.',

      // Freshness Status (from ModelService.interpretFreshness)
      'freshness_excellent': '🟢 Sariwa (Napakahusay)',
      'freshness_good': '🟡 Sariwa (Maganda)',
      'freshness_fair': '🟡 Sariwa (Katamtaman)',
      'rotten_spoiling': '🔴 Bulok (Nasisira)',
      'rotten': '🔴 Bulok',
      'unknown_status': '⚠️ Hindi Kilala',

      // Freshness Labels (from ModelService.getFreshnessLabel)
      'freshness_label_fresh': 'Sariwa',
      'freshness_label_rotten': 'Bulok',
      'freshness_label_unknown': 'Hindi Kilala',

      // Explanations (from ModelService.getPredictionExplanation)
      'explanation_eggplant_vqr_8':
          'Makintab at makinis ang balat, na may malusog na kulay — napakasariwa.',
      'explanation_eggplant_vqr_6':
          'Medyo malambot at hindi na gaanong makintab — pwede pa ring gamitin.',
      'explanation_eggplant_vqr_4':
          'Kumukupas ang balat at may kaunting kunot — gamitin agad.',
      'explanation_eggplant_vqr_3':
          'May mga kunot at madilim na batik — baka nagsisimula nang masira.',
      'explanation_eggplant_vqr_1':
          'Napakalambot o kunot na may batik — hindi na maganda para kainin.',
      'explanation_tomato_vqr_8':
          'Matigas at makinis na may natural na kulay — perpektong sariwa.',
      'explanation_tomato_vqr_6':
          'Medyo malambot kapag hinawakan, pero mukha pa ring maayos.',
      'explanation_tomato_vqr_4':
          'Mas malambot at kupas ang balat — kainin agad.',
      'explanation_tomato_vqr_3':
          'May malalambot na bahagi at maaaring mas madilim — baka hindi ligtas.',
      'explanation_tomato_vqr_1':
          'Napakalambot o nasira — hindi ligtas kainin.',
      'explanation_potato_vqr_8':
          'Napakatigas at malinis — sariwa at handa nang gamitin.',
      'explanation_potato_vqr_6':
          'Matigas pa rin pero may maliliit na marka o malambot na bahagi.',
      'explanation_potato_vqr_4': 'Lumalambot — gamitin agad bago lumala.',
      'explanation_potato_vqr_3':
          'Malambot at maaaring may berde o madilim na batik — halos masira na.',
      'explanation_potato_vqr_1':
          'Napakalambot o nasira — mas mabuting itapon.',
      'explanation_fallback':
          'Hindi namin maklaro ang resulta. Subukang i-scan muli gamit ang mas magandang ilaw.',

      // Shelf Life and Recommendations (from ModelService.getShelfLifeAndRecommendation)
      'shelf_life_eggplant_vqr_8': '🟢 Tatagal ng 5–6 na araw',
      'recommendation_eggplant_vqr_8':
          '✅ Itago sa malamig at mahalumigmig na lugar. Hawakan nang maingat.',
      'shelf_life_eggplant_vqr_6': '🟡 Gamitin sa loob ng 3–4 na araw',
      'recommendation_eggplant_vqr_6': '⚠️ Itago nang maayos at gamitin agad.',
      'shelf_life_eggplant_vqr_4': '🟡 Gamitin sa loob ng 2 araw',
      'recommendation_eggplant_vqr_4':
          '⚠️ Gamitin agad. Hindi na pinakamaganda ang kalidad.',
      'shelf_life_eggplant_vqr_3': '🔴 Gamitin ngayon',
      'recommendation_eggplant_vqr_3':
          '❌ Gamitin na at alisin ang mga nasirang bahagi.',
      'shelf_life_eggplant_vqr_2': '🔴 Hindi maganda para ibenta',
      'recommendation_eggplant_vqr_2': '❌ Itapon o ibigay sa mga hayop.',
      'shelf_life_eggplant_vqr_1': '🔴 Nasira na',
      'recommendation_eggplant_vqr_1': '❌ I-compost o itapon.',
      'shelf_life_tomato_vqr_8': '🟢 Tatagal ng 14 na araw',
      'recommendation_tomato_vqr_8':
          '✅ Itago sa malamig na lugar. Hawakan nang maingat.',
      'shelf_life_tomato_vqr_6': '🟡 Tatagal ng 10–12 araw',
      'recommendation_tomato_vqr_6':
          '⚠️ Itago nang maayos at bantayan araw-araw.',
      'shelf_life_tomato_vqr_4': '🟡 Tatagal ng 4–9 na araw',
      'recommendation_tomato_vqr_4': '⚠️ Maaaring sobrang hinog. Gamitin agad.',
      'shelf_life_tomato_vqr_3': '🔴 Gamitin sa loob ng 1–3 araw',
      'recommendation_tomato_vqr_3':
          '❌ Gamitin na at putulin ang mga nasirang bahagi.',
      'shelf_life_tomato_vqr_2': '🔴 Hindi para ibenta o kainin ng tao',
      'recommendation_tomato_vqr_2': '❌ Ipapakain sa hayop o itapon.',
      'shelf_life_tomato_vqr_1': '🔴 Nasira na',
      'recommendation_tomato_vqr_1': '❌ I-compost o itapon.',
      'shelf_life_potato_vqr_8': '🟢 Tatagal ng 1–2 buwan',
      'recommendation_potato_vqr_8':
          '✅ Itago sa malamig at madilim na lugar. Huwag ilantad sa araw.',
      'shelf_life_potato_vqr_6': '🟡 Tatagal ng halos 1 buwan',
      'recommendation_potato_vqr_6': '⚠️ Itago sa madilim at malamig na lugar.',
      'shelf_life_potato_vqr_4': '🟡 Gamitin sa loob ng 1–2 linggo',
      'recommendation_potato_vqr_4': '⚠️ Matanda na. Gamitin agad.',
      'shelf_life_potato_vqr_3': '🔴 Mas mababa sa 3 araw',
      'recommendation_potato_vqr_3':
          '❌ Gamitin na at tingnan ang malalambot o masamang batik.',
      'shelf_life_potato_vqr_2': '🔴 Hindi ligtas para kainin ng tao',
      'recommendation_potato_vqr_2': '❌ Ipapakain sa hayop o itapon.',
      'shelf_life_potato_vqr_1': '🔴 Nasira na',
      'recommendation_potato_vqr_1': '❌ I-compost o itapon.',
      'shelf_life_unknown': '📆 Walang impormasyon',
      'recommendation_unknown': '📌 Wala pang rekomendasyon.',
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}
