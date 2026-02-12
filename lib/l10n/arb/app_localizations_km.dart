// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get welcomeBack => 'សូមស្វាគមន៍ត្រឡប់មកវិញ';

  @override
  String get signInToContinue => 'ចូលដើម្បីបន្ត';

  @override
  String get enterYourEmail => 'បញ្ចូលអ៊ីមែលរបស់អ្នក';

  @override
  String get email => 'អ៊ីមែល';

  @override
  String get pleaseEnterYourEmail => 'សូមបញ្ចូលអ៊ីមែលរបស់អ្នក';

  @override
  String get pleaseEnterAValidEmail => 'សូមបញ្ចូលអ៊ីមែលត្រឹមត្រូវ';

  @override
  String get enterYourPassword => 'បញ្ចូលលេខសម្ងាត់របស់អ្នក';

  @override
  String get password => 'លេខសម្ងាត់';

  @override
  String get pleaseEnterYourPassword => 'សូមបញ្ចូលលេខសម្ងាត់របស់អ្នក';

  @override
  String get passwordMinLength => 'លេខសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៦ តួអក្សរ';

  @override
  String get login => 'ចូល';

  @override
  String get signUp => 'ចុះឈ្មោះ';

  @override
  String get signinSuccessful => 'ចូលបានជោគជ័យ';

  @override
  String get createAccount => 'បង្កើតគណនី';

  @override
  String get signUpToGetStarted => 'ចុះឈ្មោះដើម្បីចាប់ផ្តើម';

  @override
  String get enterYourName => 'បញ្ចូលឈ្មោះរបស់អ្នក';

  @override
  String get name => 'ឈ្មោះ';

  @override
  String get pleaseEnterYourName => 'សូមបញ្ចូលឈ្មោះរបស់អ្នក';

  @override
  String get signIn => 'ចូល';

  @override
  String welcomeUser(String name) {
    return 'សូមស្វាគមន៍, $name!';
  }

  @override
  String get noName => 'គ្មានឈ្មោះ';

  @override
  String get list => 'បញ្ជី';

  @override
  String get grid => 'ក្រឡា';

  @override
  String get searchItems => 'ស្វែងរកធាតុ...';

  @override
  String get signOut => 'ចាកចេញ';

  @override
  String get confirmSignOut => 'តើអ្នកប្រាកដថាចង់ចាកចេញទេ?';

  @override
  String get cancel => 'បោះបង់';

  @override
  String get signoutSuccessful => 'ចាកចេញជោគជ័យ';

  @override
  String itemCount(String count) {
    return 'ចំនួន: $count';
  }

  @override
  String get na => 'គ្មាន';

  @override
  String get customerPrice => 'តម្លៃសម្រាប់អតិថិជន';

  @override
  String get sellerPrice => 'តម្លៃសម្រាប់អ្នកលក់';

  @override
  String get note => 'កំណត់សម្គាល់';

  @override
  String get edit => 'កែសម្រួល';

  @override
  String get delete => 'លុប';

  @override
  String get confirmDelete => 'បញ្ជាក់ការលុប';

  @override
  String confirmDeleteMessage(String name) {
    return 'តើអ្នកប្រាកដថាចង់លុប \"$name\" មែនទេ?';
  }

  @override
  String get settings => 'ការកំណត់';

  @override
  String get switchLanguage => 'ប្តូរភាសា';

  @override
  String get languageEnglish => 'អង់គ្លេស';

  @override
  String get languageKhmer => 'ខ្មែរ';

  @override
  String get editItem => 'កែសម្រួលធាតុ';

  @override
  String get addNewItem => 'បន្ថែមធាតុថ្មី';

  @override
  String nameRequired(String name) {
    return '$nameត្រូវបានទាមទារ';
  }

  @override
  String get defaultPrice => 'តម្លៃដើម';

  @override
  String get defaultPriceRequired => 'តម្លៃដើមត្រូវបានទាមទារ';

  @override
  String get changeToSeller => 'ប្តូរទៅជាអ្នកលក់';

  @override
  String get changeToDistributor => 'ប្តូរទៅជាអ្នកចែកចាយ';

  @override
  String get category => 'ប្រភេទ';

  @override
  String get profile => 'គណនី';

  @override
  String get save => 'រក្សាទុក';

  @override
  String get editProfile => 'កែសម្រួលគណនី';

  @override
  String get profileUpdated => 'ធ្វើបច្ចុប្បន្នភាពគណនី';

  @override
  String get electronics => 'អេឡិចត្រូនិក';

  @override
  String get accessories => 'គ្រឿងបន្លាស់';

  @override
  String get beverages => 'ភេសជ្ជៈ';

  @override
  String get other => 'ផ្សេងទៀត';

  @override
  String get imageUrl => 'URL រូបភាព (ជាជម្រើស)';

  @override
  String get saveChanges => 'រក្សាទុកការផ្លាស់ប្តូរ';

  @override
  String get addItem => 'បន្ថែមធាតុ';

  @override
  String get unsavedChanges => 'ការផ្លាស់ប្តូរមិនទាន់រក្សាទុក';

  @override
  String get confirmDiscardChanges =>
      'អ្នកមានការផ្លាស់ប្តូរមិនទាន់រក្សាទុក។ តើអ្នកប្រាកដថាចង់បោះបង់វាទេ?';

  @override
  String get discard => 'បោះបង់';

  @override
  String get addCategory => 'បន្ថែមប្រភេទ';

  @override
  String get editCategory => 'កែសម្រួលប្រភេទ';

  @override
  String get deleteCategory => 'លុបប្រភេទ';

  @override
  String get add => 'បន្ថែម';

  @override
  String get image => 'រូបភាព';

  @override
  String get selectImageSource => 'ជ្រើសរើសប្រភពរូបភាព';

  @override
  String get uploadImage => 'បន្ថែមរូបភាព';

  @override
  String get takePhoto => 'ថតរូប';

  @override
  String get chooseFromGallery => 'ជ្រើសរើសពីវិចិត្រសាល';

  @override
  String get gettingReady => 'កំពុងរៀបចំ';

  @override
  String get preparingExperience => 'កំពុងរៀបចំបទពិសោធន៍របស់អ្នក...';

  @override
  String get loadingContent => 'កំពុងផ្ទុកមាតិការបស់អ្នក...';

  @override
  String get almostThere => 'ជិតរួចរាល់...';

  @override
  String get imageUploadedSuccessfully => 'រូបភាពបានបង្ហោះដោយជោគជ័យ';

  @override
  String appVersion(String version) {
    return 'v$version';
  }

  @override
  String get customers => 'អតិថិជន';

  @override
  String get editCustomer => 'កែសម្រួលអតិថិជន';

  @override
  String get addCustomer => 'បន្ថែមអតិថិជន';

  @override
  String get customerName => 'ឈ្មោះអតិថិជន';

  @override
  String get deleteCustomer => 'លុបអតិថិជន';

  @override
  String get displayName => 'ឈ្មោះបង្ហាញ';

  @override
  String get filterLoaners => 'ត្រងអ្នកខ្ចី';

  @override
  String get filterItems => 'តម្រងធាតុ';

  @override
  String get fromDate => 'ចាប់ពីថ្ងៃ';

  @override
  String get toDate => 'ដល់ថ្ងៃ';

  @override
  String get notSet => 'មិនបានកំណត់';

  @override
  String get reset => 'កំណត់ឡើងវិញ';

  @override
  String get apply => 'អនុវត្ត';

  @override
  String get noCategoriesAvailable => 'មិនមានប្រភេទទេ';

  @override
  String get pleaseCreateCategoryFirst => 'សូមបង្កើតប្រភេទជាមុនសិន';

  @override
  String get createCategory => 'បង្កើតប្រភេទ';

  @override
  String get noItemFound => 'រកមិនឃើញធាតុ';

  @override
  String get noLoanerFound => 'រកមិនឃើញអ្នកខ្ចីទេ';

  @override
  String get editLoaner => 'កែសម្រួលអ្នកខ្ចី';

  @override
  String get addNewLoaner => 'បន្ថែមអ្នកខ្ចីថ្មី';

  @override
  String get amount => 'ចំនួនទឹកប្រាក់';

  @override
  String get addLoaner => 'បន្ថែមអ្នកខ្ចី';

  @override
  String get loading => 'កំពុងផ្ទុក';

  @override
  String get imgFound => 'រូបភាពមាននៅក្នុងក្តារតម្បៀតខ្ទាស់។ប៉ះដើម្បីប្រើវា។';

  @override
  String get paid => 'បានសង';

  @override
  String get unpaid => 'មិនបានសង';

  @override
  String get shop => 'ហាង';

  @override
  String get loaner => 'អ្នកខ្ចី';

  @override
  String get all => 'ទាំងអស់';
}
