// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get email => 'Email';

  @override
  String get pleaseEnterYourEmail => 'Please enter your email';

  @override
  String get pleaseEnterAValidEmail => 'Please enter a valid email';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get password => 'Password';

  @override
  String get pleaseEnterYourPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signinSuccessful => 'Signin successful';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signUpToGetStarted => 'Sign up to get started';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get name => 'Name';

  @override
  String get pleaseEnterYourName => 'Please enter your name';

  @override
  String get signIn => 'Sign In';

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get noName => 'No name';

  @override
  String get list => 'List';

  @override
  String get grid => 'Grid';

  @override
  String get searchItems => 'Search items...';

  @override
  String get signOut => 'Sign Out';

  @override
  String get confirmSignOut => 'Are you sure you want to sign out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get signoutSuccessful => 'Signout successful';

  @override
  String itemCount(String count) {
    return 'Counts: $count';
  }

  @override
  String get na => 'N/A';

  @override
  String get customerPrice => 'Customer Price';

  @override
  String get sellerPrice => 'Seller Price';

  @override
  String get note => 'Note';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String confirmDeleteMessage(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get settings => 'Settings';

  @override
  String get switchLanguage => 'Switch Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKhmer => 'Khmer';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeOn => 'Dark theme enabled';

  @override
  String get darkModeOff => 'Light theme enabled';

  @override
  String get editItem => 'Edit Item';

  @override
  String get addNewItem => 'Add New Item';

  @override
  String nameRequired(String name) {
    return '$name is required';
  }

  @override
  String get defaultPrice => 'Default Price (per unit)';

  @override
  String get defaultPriceRequired => 'Default Price is required';

  @override
  String get changeToSeller => 'Change to seller';

  @override
  String get changeToDistributor => 'Change to distributor';

  @override
  String get category => 'Category';

  @override
  String get profile => 'Profile';

  @override
  String get save => 'Save';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get electronics => 'Electronics';

  @override
  String get accessories => 'Accessories';

  @override
  String get beverages => 'Beverages';

  @override
  String get other => 'Other';

  @override
  String get imageUrl => 'Image URL (optional)';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get addItem => 'Add Item';

  @override
  String get unsavedChanges => 'Unsaved Changes';

  @override
  String get confirmDiscardChanges =>
      'You have unsaved changes. Are you sure you want to discard them?';

  @override
  String get discard => 'Discard';

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get add => 'Add';

  @override
  String get image => 'Image';

  @override
  String get selectImageSource => 'Select Image Source';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get gettingReady => 'Getting Ready';

  @override
  String get preparingExperience => 'Preparing your experience...';

  @override
  String get loadingContent => 'Loading your content...';

  @override
  String get almostThere => 'Almost there...';

  @override
  String get imageUploadedSuccessfully => 'Image Uploaded Successfully';

  @override
  String appVersion(String version) {
    return 'v$version';
  }

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String updateAvailableMessage(String currentVersion, String latestVersion) {
    return 'A newer version is available.\nCurrent: v$currentVersion\nLatest: v$latestVersion';
  }

  @override
  String get updateLater => 'Later';

  @override
  String get updateNow => 'Update now';

  @override
  String get customers => 'Customers';

  @override
  String get editCustomer => 'Edit Customer';

  @override
  String get addCustomer => 'Add Customer';

  @override
  String get customerName => 'Customer Name';

  @override
  String get deleteCustomer => 'Delete Customer';

  @override
  String get displayName => 'Display Name';

  @override
  String get filterLoaners => 'Filter Loaners';

  @override
  String get filterItems => 'Filter Items';

  @override
  String get fromDate => 'From Date';

  @override
  String get toDate => 'To Date';

  @override
  String get notSet => 'Not Set';

  @override
  String get reset => 'Reset';

  @override
  String get apply => 'Apply';

  @override
  String get noCategoriesAvailable => 'No Categories Available';

  @override
  String get pleaseCreateCategoryFirst => 'Please create a category first.';

  @override
  String get createCategory => 'Create Category';

  @override
  String get noItemFound => 'No items found';

  @override
  String get noLoanerFound => 'No Loaner found';

  @override
  String get editLoaner => 'Edit Loaner';

  @override
  String get addNewLoaner => 'Add New Loaner';

  @override
  String get amount => 'Amount';

  @override
  String get addLoaner => 'Add Loaner';

  @override
  String get loading => 'Loading';

  @override
  String get imgFound => 'Image found in clipboard. Tap to use it.';

  @override
  String get paid => 'PAID';

  @override
  String get unpaid => 'UNPAID';

  @override
  String get shop => 'Shop';

  @override
  String get loaner => 'Loaner';

  @override
  String get all => 'All';

  @override
  String get income => 'Income';

  @override
  String get notifications => 'Notifications';

  @override
  String get searchIncome => 'Search income notifications...';

  @override
  String get filterIncome => 'Filter Income';

  @override
  String get notificationTracking => 'Notification tracking';

  @override
  String get notificationTrackingEnabled =>
      'Bank notification tracking is active on this device.';

  @override
  String get notificationTrackingDisabled =>
      'Enable notification access so this main device can capture ABA, Chip Mong, and ACLEDA notifications.';

  @override
  String get enableNotificationAccess => 'Enable access';

  @override
  String get refreshStatus => 'Refresh status';

  @override
  String get mainDeviceTrackingHint =>
      'Use this on the main Android phone. Sub-device sync can be added later on top of the same data model.';

  @override
  String get bankNotificationUnsupported =>
      'This device cannot capture bank notifications. Use Android for the main tracking phone.';

  @override
  String get incomeByBank => 'Income by bank';

  @override
  String get noIncomeChartData =>
      'No income data yet. Add demo data or enable tracking to see the chart.';

  @override
  String get totalIncome => 'Total income';

  @override
  String get totalExpense => 'Total expense';

  @override
  String get trackedCount => 'Tracked count';

  @override
  String get trackedNotifications => 'Tracked notifications';

  @override
  String get allRecords => 'All records';

  @override
  String get incomeOnly => 'Income';

  @override
  String get expenseOnly => 'Expense';

  @override
  String get noTrackedNotifications => 'No tracked bank notifications found';

  @override
  String get addDemoData => 'Demo data';

  @override
  String get demoDataAdded => 'Demo bank notifications added';

  @override
  String get bankLabel => 'Bank';

  @override
  String get deviceRole => 'Device role';

  @override
  String get mainDeviceRole => 'Main device';

  @override
  String get subDeviceRole => 'Sub device';

  @override
  String get deviceRoleMainDescription =>
      'This device captures bank notifications.';

  @override
  String get deviceRoleSubDescription =>
      'This device is a sub device for viewing synced data later.';

  @override
  String get subDeviceTrackingDisabled =>
      'Sub devices do not capture bank notifications in the current local-only setup.';

  @override
  String get subDeviceTrackingHint =>
      'Set this device as main if you want it to capture ABA, Chip Mong, and ACLEDA notifications on this phone.';

  @override
  String get mainDeviceRoleRequired =>
      'Set this device as Main device before adding demo or tracked notifications.';

  @override
  String get setAsMainDevice => 'Set as main device';

  @override
  String get releaseMainDevice => 'Release main device';

  @override
  String get mainDeviceOnly => 'Main only';

  @override
  String get singleMainDeviceHint =>
      'Only one main device can be active for the same synced income scope at a time.';

  @override
  String get anotherMainDeviceActive =>
      'Another main device is already active for this income sync.';
}
