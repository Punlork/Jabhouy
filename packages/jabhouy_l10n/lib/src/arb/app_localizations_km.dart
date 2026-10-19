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
  String get searchItems => 'ស្វែងរកទំនិញ...';

  @override
  String get signOut => 'ចាកចេញ';

  @override
  String get confirmSignOut => 'តើអ្នកប្រាកដថាចង់ចាកចេញទេ?';

  @override
  String get cancel => 'បោះបង់';

  @override
  String get sessionExpired => 'វគ្គចូលរបស់អ្នកបានផុតកំណត់។ សូមចូលម្តងទៀត។';

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
  String get diagnostics => 'ការត្រួតពិនិត្យ';

  @override
  String get runtimeCapture => 'ការចាប់យកពេលដំណើរការ';

  @override
  String get appLogs => 'កំណត់ហេតុកម្មវិធី';

  @override
  String get appLogsEnabled => 'កំពុងចាប់យក logger, bloc, print និងកំហុស';

  @override
  String get appLogsDisabled => 'បានបិទការចាប់យកកំណត់ហេតុកម្មវិធី';

  @override
  String get networkInspector => 'ការត្រួតពិនិត្យបណ្ដាញ';

  @override
  String get networkLogsEnabled => 'កំពុងចាប់យកសំណើ និងចម្លើយ API';

  @override
  String get networkLogsDisabled => 'បានបិទការចាប់យកបណ្ដាញ';

  @override
  String get notificationDiagnostics => 'ការត្រួតពិនិត្យការជូនដំណឹង';

  @override
  String get copyLogs => 'ចម្លង';

  @override
  String get clearLogs => 'សម្អាត';

  @override
  String get diagnosticsCopied => 'បានចម្លងការត្រួតពិនិត្យ';

  @override
  String get noAppLogs => 'មិនទាន់មានកំណត់ហេតុកម្មវិធីទេ។';

  @override
  String get noNetworkLogs => 'មិនទាន់មានសំណើបណ្ដាញទេ។';

  @override
  String get capturedAtLabel => 'ពេលចាប់យក';

  @override
  String get statusLabel => 'ស្ថានភាព';

  @override
  String get durationLabel => 'រយៈពេល';

  @override
  String get requestLabel => 'សំណើ';

  @override
  String get requestHeadersLabel => 'ក្បាលសំណើ';

  @override
  String get requestBodyLabel => 'ខ្លឹមសារសំណើ';

  @override
  String get responseHeadersLabel => 'ក្បាលចម្លើយ';

  @override
  String get responseBodyLabel => 'ខ្លឹមសារចម្លើយ';

  @override
  String get errorLabel => 'កំហុស';

  @override
  String get switchLanguage => 'ប្តូរភាសា';

  @override
  String get languageEnglish => 'អង់គ្លេស';

  @override
  String get languageKhmer => 'ខ្មែរ';

  @override
  String get darkMode => 'របៀបងងឹត';

  @override
  String get darkModeOn => 'បានបើកផ្ទាំងពណ៌ងងឹត';

  @override
  String get darkModeOff => 'បានបើកផ្ទាំងពណ៌ភ្លឺ';

  @override
  String get editItem => 'កែសម្រួលទំនិញ';

  @override
  String get addNewItem => 'បន្ថែមទំនិញថ្មី';

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
  String get addItem => 'បន្ថែមទំនិញ';

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
  String get updateAvailableTitle => 'មានកំណែថ្មី';

  @override
  String updateAvailableMessage(String currentVersion, String latestVersion) {
    return 'មានកំណែថ្មីសម្រាប់អាប់ដេត។\nកំណែបច្ចុប្បន្ន៖ v$currentVersion\nកំណែចុងក្រោយ៖ v$latestVersion';
  }

  @override
  String get updateLater => 'ពេលក្រោយ';

  @override
  String get updateNow => 'អាប់ដេតឥឡូវនេះ';

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
  String get filterItems => 'តម្រងទំនិញ';

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
  String get noItemFound => 'រកមិនឃើញទំនិញ';

  @override
  String get noLoanerFound => 'រកមិនឃើញអ្នកខ្ចីទេ';

  @override
  String get editLoaner => 'កែសម្រួលអ្នកខ្ចី';

  @override
  String get addNewLoaner => 'បន្ថែមអ្នកខ្ចីថ្មី';

  @override
  String get amount => 'ចំនួនទឹកប្រាក់';

  @override
  String get itemType => 'ប្រភេទទំនិញ';

  @override
  String get singleItem => 'ទំនិញរាយ';

  @override
  String get packItem => 'ទំនិញកញ្ចប់';

  @override
  String get packSize => 'ចំនួនក្នុងកញ្ចប់';

  @override
  String get packSizeHint =>
      'មិនបាច់បំពេញក៏បាន។ បើបំពេញ វានឹងរក្សាទុកជា ឈ្មោះ xចំនួន។';

  @override
  String get packSizeValidation => 'សូមបញ្ចូលចំនួនក្នុងកញ្ចប់ធំជាង 1';

  @override
  String get packSizeRequired => 'សូមបញ្ចូលចំនួនក្នុងកញ្ចប់';

  @override
  String get itemsSuffix => 'មុខទំនិញ';

  @override
  String get variants => 'ជម្រើសទំនិញ';

  @override
  String get variantLabel => 'ឈ្មោះជម្រើស';

  @override
  String get addVariant => 'បន្ថែមជម្រើស';

  @override
  String get smallVariant => 'តូច';

  @override
  String get bigVariant => 'ធំ';

  @override
  String get canVariant => 'កំប៉ុង';

  @override
  String get bottleVariant => 'ដប';

  @override
  String get selectVariantError => 'សូមជ្រើសយ៉ាងហោចណាស់មួយជម្រើស';

  @override
  String get addItems => 'បន្ថែមទំនិញ';

  @override
  String get addLoaner => 'បន្ថែមអ្នកខ្ចី';

  @override
  String get loading => 'កំពុងផ្ទុក';

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

  @override
  String get income => 'ចំណូល';

  @override
  String get notifications => 'ការជូនដំណឹង';

  @override
  String get searchIncome => 'ស្វែងរកការជូនដំណឹងចំណូល...';

  @override
  String get filterIncome => 'តម្រងចំណូល';

  @override
  String get notificationTracking => 'ការតាមដានការជូនដំណឹង';

  @override
  String get notificationTrackingEnabled =>
      'ការតាមដានការជូនដំណឹងធនាគារកំពុងដំណើរការនៅលើឧបករណ៍នេះ។';

  @override
  String get notificationTrackingDisabled =>
      'សូមបើកសិទ្ធិការជូនដំណឹង ដើម្បីឱ្យឧបករណ៍មេនេះអាចចាប់ ABA, Chip Mong និង ACLEDA បាន។';

  @override
  String get enableNotificationAccess => 'បើកសិទ្ធិ';

  @override
  String get refreshStatus => 'ផ្ទុកស្ថានភាពឡើងវិញ';

  @override
  String get mainDeviceTrackingHint =>
      'សូមប្រើវានៅលើទូរស័ព្ទ Android មេ។ ការធ្វើសមកាលកម្មទៅឧបករណ៍រងអាចបន្ថែមនៅពេលក្រោយលើទិន្នន័យដូចគ្នា។';

  @override
  String get bankNotificationUnsupported =>
      'ឧបករណ៍នេះមិនអាចចាប់ការជូនដំណឹងធនាគារបានទេ។ សូមប្រើ Android សម្រាប់ទូរស័ព្ទមេ។';

  @override
  String get incomeByBank => 'ចំណូលតាមធនាគារ';

  @override
  String get noIncomeChartData =>
      'មិនទាន់មានទិន្នន័យចំណូលទេ។ បន្ថែមទិន្នន័យសាកល្បង ឬបើកការតាមដានដើម្បីមើលគំនូសតាង។';

  @override
  String get totalIncome => 'ចំណូលសរុប';

  @override
  String get totalExpense => 'ចំណាយសរុប';

  @override
  String get trackedCount => 'ចំនួនតាមដាន';

  @override
  String get trackedNotifications => 'ការជូនដំណឹងដែលបានតាមដាន';

  @override
  String get allRecords => 'កំណត់ត្រាទាំងអស់';

  @override
  String get incomeOnly => 'ចំណូល';

  @override
  String get expenseOnly => 'ចំណាយ';

  @override
  String get noTrackedNotifications => 'រកមិនឃើញការជូនដំណឹងធនាគារដែលបានតាមដាន';

  @override
  String get addDemoData => 'ទិន្នន័យសាកល្បង';

  @override
  String get demoDataAdded => 'បានបន្ថែមការជូនដំណឹងធនាគារសាកល្បង';

  @override
  String get bankLabel => 'ធនាគារ';

  @override
  String get deviceRole => 'តួនាទីឧបករណ៍';

  @override
  String get mainDeviceRole => 'ឧបករណ៍មេ';

  @override
  String get subDeviceRole => 'ឧបករណ៍រង';

  @override
  String get deviceRoleMainDescription => 'ឧបករណ៍នេះចាប់ការជូនដំណឹងធនាគារ។';

  @override
  String get deviceRoleSubDescription =>
      'ឧបករណ៍នេះជាឧបករណ៍រងសម្រាប់មើលទិន្នន័យសមកាលកម្មនៅពេលក្រោយ។';

  @override
  String get subDeviceTrackingDisabled =>
      'ឧបករណ៍រងមិនចាប់ការជូនដំណឹងធនាគារនៅក្នុងការរៀបចំ local-only បច្ចុប្បន្នទេ។';

  @override
  String get subDeviceTrackingHint =>
      'កំណត់ឧបករណ៍នេះជា ឧបករណ៍មេ ប្រសិនបើអ្នកចង់ឱ្យវាចាប់ ABA, Chip Mong និង ACLEDA នៅលើទូរស័ព្ទនេះ។';

  @override
  String get mainDeviceRoleRequired =>
      'សូមកំណត់ឧបករណ៍នេះជា ឧបករណ៍មេ មុននឹងបន្ថែមទិន្នន័យសាកល្បង ឬការជូនដំណឹងដែលបានតាមដាន។';

  @override
  String get setAsMainDevice => 'កំណត់ជា ឧបករណ៍មេ';

  @override
  String get releaseMainDevice => 'បោះបង់ឧបករណ៍មេ';

  @override
  String get mainDeviceOnly => 'សម្រាប់មេប៉ុណ្ណោះ';

  @override
  String get singleMainDeviceHint =>
      'អាចមានឧបករណ៍មេបានតែមួយប៉ុណ្ណោះ សម្រាប់ income sync ដូចគ្នា នៅពេលតែមួយ។';

  @override
  String get anotherMainDeviceActive =>
      'មានឧបករណ៍មេមួយផ្សេងទៀតកំពុងសកម្មសម្រាប់ income sync នេះ។';

  @override
  String get invalidPrice => 'សូមបញ្ចូលចំនួនគត់';

  @override
  String get syncing => 'កំពុងធ្វើសមកាលកម្ម…';

  @override
  String get synced => 'បានធ្វើសមកាលកម្ម';

  @override
  String changesWaiting(int count) {
    return '$count ការផ្លាស់ប្តូរកំពុងរង់ចាំ';
  }

  @override
  String changesFailed(int count) {
    return '$count ការផ្លាស់ប្តូរបរាជ័យ';
  }

  @override
  String get failedChangesTitle =>
      'ការផ្លាស់ប្តូរដែលមិនទាន់រក្សាទុកលើម៉ាស៊ីនមេ';

  @override
  String get waitingToSync => 'កំពុងរង់ចាំធ្វើសមកាលកម្ម';

  @override
  String get syncFailed => 'មិនទាន់រក្សាទុកលើម៉ាស៊ីនមេ';

  @override
  String get continueWithGoogle => 'បន្តជាមួយ Google';

  @override
  String get googleSignInFailed =>
      'មិនអាចចូលជាមួយ Google បានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get chooseUsername => 'ជ្រើសរើសឈ្មោះអ្នកប្រើ';

  @override
  String get chooseUsernameSubtitle =>
      'អ្នកនឹងប្រើវាដើម្បីចូល។ ជ្រើសរើសមួយខាងក្រោម ឬវាយបញ្ចូលដោយខ្លួនឯង។';

  @override
  String get username => 'ឈ្មោះអ្នកប្រើ';

  @override
  String get usernameRules => 'អក្សរ លេខ _ ឬ . ពី 3 ដល់ 30 តួ';

  @override
  String get credit => 'ជំពាក់';

  @override
  String get itemAdd => 'បន្ថែមទំនិញ';

  @override
  String get itemEdit => 'កែទំនិញ';

  @override
  String get itemName => 'ឈ្មោះទំនិញ';

  @override
  String get itemPhoto => 'រូបថត';

  @override
  String get priceSection => 'តម្លៃ';

  @override
  String get priceUnit => 'លក់ជា';

  @override
  String get priceCount => 'ចំនួន';

  @override
  String get priceSelling => 'តម្លៃលក់';

  @override
  String get priceWholesale => 'តម្លៃលក់ដុំ';

  @override
  String get priceCost => 'តម្លៃដើម';

  @override
  String get priceAdd => 'បន្ថែមតម្លៃ';

  @override
  String get priceAddExample => 'ឧ. កេះ ×24, បេ';

  @override
  String get priceMissing => 'មិនទាន់មានតម្លៃ';

  @override
  String get priceEdit => 'កែតម្លៃ';

  @override
  String get optional => '(មិនចាំបាច់)';

  @override
  String get categoryChoose => 'ជ្រើសរើសប្រភេទ';

  @override
  String get categoryNew => 'បង្កើតប្រភេទថ្មី';

  @override
  String get categorySuggested => 'បានណែនាំតាមឈ្មោះ · ចុចដើម្បីប្តូរ';

  @override
  String get noteLabel => 'កំណត់ចំណាំ';

  @override
  String get searchGoods => 'ស្វែងរកទំនិញ';

  @override
  String get searchCustomers => 'ស្វែងរកអតិថិជន';

  @override
  String get creditAdd => 'បន្ថែមការជំពាក់';

  @override
  String get creditEdit => 'កែការជំពាក់';

  @override
  String get creditCustomer => 'អតិថិជន';

  @override
  String get creditChoose => 'ជ្រើសរើស';

  @override
  String get creditItems => 'ទំនិញដែលយក';

  @override
  String get creditAddItems => 'បន្ថែមទំនិញពីបញ្ជីតម្លៃ';

  @override
  String get creditAmountHint => 'គណនាពីទំនិញ';

  @override
  String get creditTakenAt => 'ថ្ងៃ និងម៉ោងជំពាក់';

  @override
  String get creditDueDate => 'ត្រូវសង';

  @override
  String get creditUnpaid => 'មិនទាន់សង';

  @override
  String get creditPaid => 'សងរួច';

  @override
  String get creditMarkPaid => 'សម្គាល់ថាសងរួច';

  @override
  String get creditTotalOwed => 'នៅជំពាក់សរុប';

  @override
  String get creditNoAmount => 'មិនទាន់មានចំនួន';

  @override
  String creditOwes(Object amount) {
    return 'ជំពាក់ $amount';
  }

  @override
  String get customerAddNew => 'បន្ថែមអតិថិជនថ្មី';

  @override
  String get customerHasCredits =>
      'មិនអាចលុបបានទេ ព្រោះអតិថិជននេះនៅមានការជំពាក់';

  @override
  String get pickerTitle => 'ជ្រើសទំនិញ';

  @override
  String get pickerAddToCredit => 'បន្ថែមទៅការជំពាក់';

  @override
  String pickerSelected(Object count) {
    return 'បានជ្រើស $count មុខ';
  }

  @override
  String get timeAdd => 'បន្ថែមម៉ោង';

  @override
  String voiceSpeakingInto(Object field) {
    return 'កំពុងបញ្ចូលទៅ $field';
  }

  @override
  String get voiceListening => 'កំពុងស្តាប់…';

  @override
  String get voiceUse => 'ប្រើអត្ថបទនេះ';

  @override
  String get settingsTitle => 'ការកំណត់ហាង';

  @override
  String get settingsPricesUsed => 'តម្លៃដែលហាងប្រើ';

  @override
  String get settingsCurrency => 'រូបិយប័ណ្ណ';

  @override
  String get settingsDefaultCurrency => 'រូបិយប័ណ្ណលំនាំដើម';

  @override
  String get settingsRate => 'អត្រាប្តូរប្រាក់';

  @override
  String settingsRateFormat(Object rate) {
    return '\$1 = $rate ៛';
  }

  @override
  String get settingsRateConfirm => 'ការជំពាក់ចាស់នៅតែប្រើអត្រាដើមរបស់វា។';

  @override
  String get settingsShowConverted => 'បង្ហាញតម្លៃជារូបិយប័ណ្ណទាំងពីរ';

  @override
  String get settingsCategoriesUnits => 'ប្រភេទ និងឯកតា';

  @override
  String get settingsMembers => 'សមាជិក និងសិទ្ធិ';

  @override
  String lastEditedBy(Object date, Object name) {
    return 'កែចុងក្រោយ $date ដោយ $name';
  }

  @override
  String get currencyKhr => 'រៀល';

  @override
  String get currencyUsd => 'ដុល្លារ';

  @override
  String get authWelcome => 'សូមស្វាគមន៍';

  @override
  String get authWelcomeSub => 'ចូលដើម្បីមើលតម្លៃហាងរបស់អ្នក';

  @override
  String get authOr => 'ឬ';

  @override
  String get authUserOrEmail => 'ឈ្មោះអ្នកប្រើ ឬអ៊ីមែល';

  @override
  String get authSignOut => 'ចេញពីគណនី';

  @override
  String get syncNoPermission => 'អ្នកលែងមានសិទ្ធិកែ';

  @override
  String shopHello(Object name) {
    return 'សួស្តី $name';
  }

  @override
  String get shopNoShop => 'អ្នកមិនទាន់នៅក្នុងហាងណាមួយទេ។ ជ្រើសមួយ៖';

  @override
  String get shopJoin => 'ចូលរួមហាង';

  @override
  String get shopJoinSub => 'សម្រាប់សមាជិកគ្រួសារ · ស្កេន QR ឬវាយលេខកូដ';

  @override
  String get shopCreate => 'បង្កើតហាងថ្មី';

  @override
  String get shopCreateSub => 'សម្រាប់ម្ចាស់ហាង';

  @override
  String get shopName => 'ឈ្មោះហាង';

  @override
  String get shopStarterCats => 'ប្រភេទចាប់ផ្តើម';

  @override
  String get shopCreateBtn => 'បង្កើតហាង';

  @override
  String get shopJoinBtn => 'ចូលរួម';

  @override
  String get shopSwitch => 'ប្តូរហាង';

  @override
  String get joinScan => 'ស្កេន QR ពីទូរស័ព្ទម្ចាស់ហាង';

  @override
  String get joinCode => 'វាយលេខកូដអញ្ជើញ';

  @override
  String get joinInvalid => 'លេខកូដមិនត្រឹមត្រូវ';

  @override
  String get joinExpired => 'លេខកូដផុតកំណត់ហើយ';

  @override
  String get joinUsed => 'លេខកូដត្រូវបានប្រើរួចហើយ';

  @override
  String get inviteTitle => 'អញ្ជើញសមាជិក';

  @override
  String get inviteRole => 'សិទ្ធិរបស់អ្នកចូលរួម';

  @override
  String get inviteExpires => 'ផុតកំណត់ក្នុង ២៤ ម៉ោង';

  @override
  String get inviteShare => 'ចែករំលែកលេខកូដ';

  @override
  String get roleViewer => 'មិនអាចកែតម្លៃ';

  @override
  String get roleEditor => 'អាចកែតម្លៃ';

  @override
  String get roleOwner => 'ម្ចាស់ហាង';

  @override
  String get members => 'សមាជិក';

  @override
  String get itemNicknames => 'ឈ្មោះផ្សេង';

  @override
  String get itemNicknamesHint => 'ជួយឱ្យស្វែងរកឃើញ';

  @override
  String get itemAddNickname => '+ ឈ្មោះផ្សេង';

  @override
  String get itemAddNicknameExample => 'ឧ. ទឹកធំ, Kulen';

  @override
  String get itemNameMissing => 'សូមបញ្ចូលឈ្មោះទំនិញ';

  @override
  String get itemDuplicateName => 'មានទំនិញឈ្មោះនេះរួចហើយ';

  @override
  String get itemSaveAsNew => 'ឬរក្សាទុកជាទំនិញថ្មី';

  @override
  String get itemView => 'មើល';

  @override
  String get priceRielNoDecimals => 'តម្លៃរៀលមិនអាចមានទសភាគ';

  @override
  String get priceUsdTwoDecimals => 'ដុល្លារមានទសភាគបានតែ ២ ខ្ទង់';

  @override
  String get priceNotNumber => 'សូមបញ្ចូលតម្លៃជាលេខ';

  @override
  String get pricePackOverOne => 'ចំនួនក្នុងកញ្ចប់ត្រូវលើសពី ១';

  @override
  String priceBarcodeUsed(Object name) {
    return 'បាកូដនេះប្រើរួចហើយសម្រាប់ «$name»';
  }

  @override
  String get priceNoRow => 'សូមបញ្ចូលឯកតា ឬតម្លៃយ៉ាងហោចណាស់មួយ';

  @override
  String priceUnitsFor(Object category) {
    return 'ឯកតាសម្រាប់ «$category»';
  }

  @override
  String get priceWholesaleShort => 'ដុំ';

  @override
  String get priceCostShort => 'ដើម';

  @override
  String get priceRemove => 'លុបតម្លៃនេះ';

  @override
  String itemListHeader(Object count) {
    return 'ទំនិញ $count មុខ · ក–អ';
  }

  @override
  String get itemListShowGrid => 'បង្ហាញជាក្រឡា';

  @override
  String get itemListShowList => 'បង្ហាញជាបញ្ជី';

  @override
  String get itemListEmpty => 'មិនទាន់មានទំនិញ';

  @override
  String get itemSearchHint => 'ស្វែងរកឈ្មោះទំនិញ';

  @override
  String get currencySwitch => 'ប្តូររូបិយប័ណ្ណ';

  @override
  String get priceUnitHint => 'ឧ. ដប';

  @override
  String lastEditedOn(Object date) {
    return 'កែចុងក្រោយ $date';
  }

  @override
  String get itemNameHint => 'ឧ. អង្ករផ្កាម្លិះ';

  @override
  String get itemNoteHint => 'អ្នកផ្គត់ផ្គង់, កន្លែងដាក់ទំនិញ…';

  @override
  String get priceSellingHint => 'ឧ. 3,000';
}
