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
  String get sessionExpired =>
      'Your session has expired. Please sign in again.';

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
  String get diagnostics => 'Diagnostics';

  @override
  String get runtimeCapture => 'Runtime capture';

  @override
  String get appLogs => 'App logs';

  @override
  String get appLogsEnabled =>
      'Capturing logger, bloc, print, and error events';

  @override
  String get appLogsDisabled => 'App log capture is off';

  @override
  String get networkInspector => 'Network inspector';

  @override
  String get networkLogsEnabled => 'Capturing API requests and responses';

  @override
  String get networkLogsDisabled => 'Network capture is off';

  @override
  String get notificationDiagnostics => 'Notification diagnostics';

  @override
  String get copyLogs => 'Copy';

  @override
  String get clearLogs => 'Clear';

  @override
  String get diagnosticsCopied => 'Diagnostics copied';

  @override
  String get noAppLogs => 'No app logs captured yet.';

  @override
  String get noNetworkLogs => 'No network requests captured yet.';

  @override
  String get capturedAtLabel => 'Captured at';

  @override
  String get statusLabel => 'Status';

  @override
  String get durationLabel => 'Duration';

  @override
  String get requestLabel => 'Request';

  @override
  String get requestHeadersLabel => 'Request headers';

  @override
  String get requestBodyLabel => 'Request body';

  @override
  String get responseHeadersLabel => 'Response headers';

  @override
  String get responseBodyLabel => 'Response body';

  @override
  String get errorLabel => 'Error';

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
  String get defaultPrice => 'Cost Price';

  @override
  String get defaultPriceRequired => 'Cost Price is required';

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
  String get itemType => 'Item Type';

  @override
  String get singleItem => 'Single';

  @override
  String get packItem => 'Pack';

  @override
  String get packSize => 'Pack Size';

  @override
  String get packSizeHint =>
      'Optional. If filled, the item will be saved as Name xQuantity.';

  @override
  String get packSizeValidation => 'Enter a pack size greater than 1';

  @override
  String get packSizeRequired => 'Enter the pack size';

  @override
  String get itemsSuffix => 'items';

  @override
  String get variants => 'Variants';

  @override
  String get variantLabel => 'Variant';

  @override
  String get addVariant => 'Add Variant';

  @override
  String get smallVariant => 'Small';

  @override
  String get bigVariant => 'Big';

  @override
  String get canVariant => 'Can';

  @override
  String get bottleVariant => 'Bottle';

  @override
  String get selectVariantError => 'Select at least one variant';

  @override
  String get addItems => 'Add Items';

  @override
  String get addLoaner => 'Add Loaner';

  @override
  String get loading => 'Loading';

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

  @override
  String get invalidPrice => 'Enter a whole number';

  @override
  String get syncing => 'Syncing…';

  @override
  String get synced => 'Synced';

  @override
  String changesWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting',
      one: '1 change waiting',
    );
    return '$_temp0';
  }

  @override
  String changesFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes failed',
      one: '1 change failed',
    );
    return '$_temp0';
  }

  @override
  String get failedChangesTitle => 'Changes not saved to the server';

  @override
  String get waitingToSync => 'Waiting to sync';

  @override
  String get syncFailed => 'Not saved to the server';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get googleSignInFailed =>
      'Couldn\'t sign in with Google. Please try again.';

  @override
  String get chooseUsername => 'Choose a username';

  @override
  String get chooseUsernameSubtitle =>
      'You\'ll use it to sign in. Pick one below or type your own.';

  @override
  String get username => 'Username';

  @override
  String get usernameRules => '3–30 letters, numbers, _ or .';

  @override
  String get credit => 'Credit';

  @override
  String get itemAdd => 'Add item';

  @override
  String get itemEdit => 'Edit item';

  @override
  String get itemName => 'Item name';

  @override
  String get itemPhoto => 'Photo';

  @override
  String get priceSection => 'Prices';

  @override
  String get priceUnit => 'Sold as';

  @override
  String get priceCount => 'Count';

  @override
  String get priceSelling => 'Selling price';

  @override
  String get priceWholesale => 'Wholesale price';

  @override
  String get priceCost => 'Cost price';

  @override
  String get priceAdd => 'Add item price';

  @override
  String get priceAddExample => 'e.g. case ×24, sack';

  @override
  String get priceMissing => 'No price yet';

  @override
  String get priceEdit => 'Edit price';

  @override
  String get optional => '(optional)';

  @override
  String get categoryChoose => 'Choose category';

  @override
  String get categoryNew => 'New category';

  @override
  String get categorySuggested => 'Suggested from the name · tap to change';

  @override
  String get noteLabel => 'Note';

  @override
  String get searchGoods => 'Search items';

  @override
  String get searchCustomers => 'Search customers';

  @override
  String get creditAdd => 'Add credit';

  @override
  String get creditEdit => 'Edit credit';

  @override
  String get creditCustomer => 'Customer';

  @override
  String get creditChoose => 'Choose';

  @override
  String get creditItems => 'Items taken';

  @override
  String get creditAddItems => 'Add from price list';

  @override
  String get creditAmountHint => 'Calculated from items';

  @override
  String get creditTakenAt => 'Date and time taken';

  @override
  String get creditDueDate => 'Due';

  @override
  String get creditUnpaid => 'Unpaid';

  @override
  String get creditPaid => 'Paid';

  @override
  String get creditMarkPaid => 'Mark as paid';

  @override
  String get creditTotalOwed => 'Total owed';

  @override
  String get creditNoAmount => 'No amount yet';

  @override
  String creditOwes(Object amount) {
    return 'Owes $amount';
  }

  @override
  String get customerAddNew => 'Add new customer';

  @override
  String get customerHasCredits =>
      'Can\'t delete: this customer still has credits';

  @override
  String get pickerTitle => 'Choose items';

  @override
  String get pickerAddToCredit => 'Add to credit';

  @override
  String pickerSelected(Object count) {
    return '$count selected';
  }

  @override
  String get timeAdd => 'Add time';

  @override
  String voiceSpeakingInto(Object field) {
    return 'Speaking into $field';
  }

  @override
  String get voiceListening => 'Listening…';

  @override
  String get voiceUse => 'Use this text';

  @override
  String get settingsTitle => 'Shop settings';

  @override
  String get settingsPricesUsed => 'Prices this shop uses';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsDefaultCurrency => 'Default currency';

  @override
  String get settingsRate => 'Exchange rate';

  @override
  String settingsRateFormat(Object rate) {
    return '\$1 = $rate ៛';
  }

  @override
  String get settingsRateConfirm =>
      'Old credits keep the rate they were made with.';

  @override
  String get settingsShowConverted => 'Show prices in both currencies';

  @override
  String get settingsCategoriesUnits => 'Categories and units';

  @override
  String categoriesCount(Object count) {
    return '$count categories';
  }

  @override
  String get categoryHidden => 'Hidden';

  @override
  String get categoryUnits => 'Units';

  @override
  String get scanTitle => 'Scan barcode';

  @override
  String scanFound(Object code) {
    return 'Found · $code';
  }

  @override
  String scanNotFound(Object code) {
    return 'Not found · $code';
  }

  @override
  String get scanThisBarcode => 'This barcode';

  @override
  String get scanDetails => 'View details';

  @override
  String get scanNext => 'Scan next';

  @override
  String get scanCameraError => 'Could not open the camera';

  @override
  String get settingsMembers => 'Members and roles';

  @override
  String lastEditedBy(Object date, Object name) {
    return 'Last edited $date by $name';
  }

  @override
  String get currencyKhr => 'Riel';

  @override
  String get currencyUsd => 'Dollar';

  @override
  String get authWelcome => 'Welcome';

  @override
  String get authWelcomeSub => 'Sign in to see your shop\'s prices';

  @override
  String get authOr => 'or';

  @override
  String get authUserOrEmail => 'Username or email';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get syncNoPermission => 'You no longer have permission to edit';

  @override
  String shopHello(Object name) {
    return 'Hello $name';
  }

  @override
  String get shopNoShop => 'You\'re not in a shop yet. Choose one:';

  @override
  String get shopJoin => 'Join a shop';

  @override
  String get shopJoinSub => 'For family members · scan a QR or type a code';

  @override
  String get shopCreate => 'Create a new shop';

  @override
  String get shopCreateSub => 'For shop owners';

  @override
  String get shopName => 'Shop name';

  @override
  String get shopStarterCats => 'Starter categories';

  @override
  String get shopCreateBtn => 'Create shop';

  @override
  String get shopJoinBtn => 'Join';

  @override
  String get shopSwitch => 'Switch shop';

  @override
  String get joinScan => 'Scan the QR on the owner\'s phone';

  @override
  String get joinCode => 'Type the invite code';

  @override
  String get joinInvalid => 'Invalid code';

  @override
  String get joinExpired => 'This code has expired';

  @override
  String get joinUsed => 'This code was already used';

  @override
  String get inviteTitle => 'Invite a member';

  @override
  String get inviteRole => 'Role for the new member';

  @override
  String get inviteExpires => 'Expires in 24 hours';

  @override
  String get inviteShare => 'Share code';

  @override
  String get roleViewer => 'Can\'t edit prices';

  @override
  String get roleEditor => 'Can edit prices';

  @override
  String get roleOwner => 'Owner';

  @override
  String get members => 'Members';

  @override
  String get itemNicknames => 'Other names';

  @override
  String get itemNicknamesHint => 'Helps search find it';

  @override
  String get itemAddNickname => '+ Other name';

  @override
  String get itemAddNicknameExample => 'e.g. ទឹកធំ, Kulen';

  @override
  String get itemNameMissing => 'Enter the item name';

  @override
  String get itemDuplicateName => 'An item with this name already exists';

  @override
  String get itemSaveAsNew => 'or save as a new item';

  @override
  String get itemView => 'View';

  @override
  String get priceRielNoDecimals => 'Riel prices can\'t have decimals';

  @override
  String get priceUsdTwoDecimals => 'Dollars take at most 2 decimals';

  @override
  String get priceNotNumber => 'Enter a number';

  @override
  String get pricePackPositive => 'The count must be more than 0';

  @override
  String priceBarcodeUsed(Object name) {
    return 'This barcode is already used by «$name»';
  }

  @override
  String priceUnitsFor(Object category) {
    return 'Units for «$category»';
  }

  @override
  String get priceWholesaleShort => 'Wholesale';

  @override
  String get priceCostShort => 'Cost';

  @override
  String get priceRemove => 'Remove this price';

  @override
  String itemListHeader(Object count) {
    return '$count items · A–Z';
  }

  @override
  String get itemListShowGrid => 'Show as grid';

  @override
  String get itemListShowList => 'Show as list';

  @override
  String get itemListEmpty => 'No items yet';

  @override
  String get itemSearchHint => 'Search items';

  @override
  String get currencySwitch => 'Switch currency';

  @override
  String get priceUnitHint => 'e.g. bottle';

  @override
  String lastEditedOn(Object date) {
    return 'Last edited $date';
  }

  @override
  String get itemNameHint => 'e.g. Jasmine rice';

  @override
  String get itemNoteHint => 'Supplier, where it is kept…';

  @override
  String get priceSellingHint => 'e.g. 3,000';

  @override
  String get priceCountHint => '1';

  @override
  String get categoryHint => 'Pick a category to find it faster later';

  @override
  String get categorySearch => 'Search categories';

  @override
  String get categoryNameHint => 'e.g. Drinks';

  @override
  String get priceWholesaleLabel => 'Wholesale';

  @override
  String get settingsPricesCurrency => 'Prices & currency';

  @override
  String get settingsPricesUsedHint => 'Ticked prices show on every item';

  @override
  String get settingsAlwaysOn => 'Always on';

  @override
  String get settingsWholesaleHint => 'For bulk buyers';

  @override
  String get settingsRateKeepsOld => 'Old credits keep their rate';

  @override
  String get settingsRateInvalid => 'The rate must be more than 0';

  @override
  String get settingsOwnerOnly =>
      'Only the shop owner can change shop settings';

  @override
  String get settingsAppSection => 'App';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String itemMorePrices(Object count) {
    return '+$count more';
  }

  @override
  String get itemRecentLabel => 'Recently viewed';

  @override
  String itemSearchResults(Object count) {
    return 'Results $count';
  }

  @override
  String get itemOtherName => 'Also called:';

  @override
  String get itemNotFound => 'Can\'t find the item?';

  @override
  String itemAddNamed(Object name) {
    return 'Add “$name”';
  }

  @override
  String get signInWelcome => 'Welcome';

  @override
  String get signInSubtitle => 'Sign in to see your shop prices';

  @override
  String get signInUsernameOrEmail => 'Username or email';

  @override
  String get signInUsernameOrEmailHint => 'e.g. dara or dara@gmail.com';

  @override
  String get signInOr => 'or';
}
