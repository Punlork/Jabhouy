import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('km')
  ];

  /// Headline text welcoming the user back on the sign-in page
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Subtitle text prompting the user to sign in
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// Hint text for the email input field
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// Label for the email input field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Validation message when email is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// Validation message when email format is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterAValidEmail;

  /// Hint text for the password input field
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// Label for the password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Validation message when password is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPassword;

  /// Validation message when password is too short
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// Text for the login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Text for the sign-up button
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Success message after signing in
  ///
  /// In en, this message translates to:
  /// **'Signin successful'**
  String get signinSuccessful;

  /// Headline text for the sign-up page
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Subtitle text prompting the user to sign up
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started'**
  String get signUpToGetStarted;

  /// Hint text for the name input field
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// Label for the name input field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Validation message when name is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// Text for the sign-in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Success message after signing up, with user name
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}!'**
  String welcomeUser(String name);

  /// Default text displayed when user name is not available
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get noName;

  /// Label for the list view option in segmented button
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// Label for the grid view option in segmented button
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// Hint text for the search input field
  ///
  /// In en, this message translates to:
  /// **'Search items...'**
  String get searchItems;

  /// Text for sign-out action in dialog title and button
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Confirmation message in the sign-out dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get confirmSignOut;

  /// Text for the cancel button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Success message after signing out
  ///
  /// In en, this message translates to:
  /// **'Signout successful'**
  String get signoutSuccessful;

  /// Text displaying the number of items, with a count placeholder
  ///
  /// In en, this message translates to:
  /// **'Counts: {count}'**
  String itemCount(String count);

  /// Default text when a value (e.g., category) is not available
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// Label for the customer price of an item
  ///
  /// In en, this message translates to:
  /// **'Customer Price'**
  String get customerPrice;

  /// Label for the seller price of an item
  ///
  /// In en, this message translates to:
  /// **'Seller Price'**
  String get sellerPrice;

  /// Title for the note section of an item
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// Label for the edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Label for the delete button and action in dialog
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Title for the delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// Confirmation message in the delete dialog, with item name
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String confirmDeleteMessage(String name);

  /// Label for the settings button and sheet title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for the switch language option
  ///
  /// In en, this message translates to:
  /// **'Switch Language'**
  String get switchLanguage;

  /// Label for English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Label for Khmer language option
  ///
  /// In en, this message translates to:
  /// **'Khmer'**
  String get languageKhmer;

  /// AppBar title when editing an item
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItem;

  /// AppBar title when adding a new item
  ///
  /// In en, this message translates to:
  /// **'Add New Item'**
  String get addNewItem;

  /// Validation message when name is empty
  ///
  /// In en, this message translates to:
  /// **'{name} is required'**
  String nameRequired(String name);

  /// Label for the default price input field
  ///
  /// In en, this message translates to:
  /// **'Default Price (per unit)'**
  String get defaultPrice;

  /// Validation message when default price is empty
  ///
  /// In en, this message translates to:
  /// **'Default Price is required'**
  String get defaultPriceRequired;

  /// Label for switching to seller mode
  ///
  /// In en, this message translates to:
  /// **'Change to seller'**
  String get changeToSeller;

  /// Label for switching to distributor mode
  ///
  /// In en, this message translates to:
  /// **'Change to distributor'**
  String get changeToDistributor;

  /// Label for the category dropdown
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Label for the profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Label for the save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Label for the editProfile
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Label for the profileUpdated
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// Category option for electronics
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get electronics;

  /// Category option for accessories
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get accessories;

  /// Category option for beverages
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get beverages;

  /// Category option for other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// Label for the image URL input field
  ///
  /// In en, this message translates to:
  /// **'Image URL (optional)'**
  String get imageUrl;

  /// Button text for saving changes in edit mode
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Button text for adding a new item
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// Title for the unsaved changes dialog
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// Content for the unsaved changes dialog
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to discard them?'**
  String get confirmDiscardChanges;

  /// Text for the discard button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Text for the addCategory button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// Text for the editCategory button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// Text for the deleteCategory button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// Text for the add button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Text for the image button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// Text for the selectImageSource button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// Text for the uploadImage button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// Text for the takePhoto button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Text for the chooseFromGallery button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// Message displayed when the app is getting ready
  ///
  /// In en, this message translates to:
  /// **'Getting Ready'**
  String get gettingReady;

  /// Message displayed when the app is preparing the user experience
  ///
  /// In en, this message translates to:
  /// **'Preparing your experience...'**
  String get preparingExperience;

  /// Message displayed when the app is loading content
  ///
  /// In en, this message translates to:
  /// **'Loading your content...'**
  String get loadingContent;

  /// Message displayed when the app is almost ready
  ///
  /// In en, this message translates to:
  /// **'Almost there...'**
  String get almostThere;

  /// Message displayed when the app is almost ready
  ///
  /// In en, this message translates to:
  /// **'Image Uploaded Successfully'**
  String get imageUploadedSuccessfully;

  /// App version display
  ///
  /// In en, this message translates to:
  /// **'v{version}'**
  String appVersion(String version);

  /// Label for the customers section or page
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// Label for editing a customer
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomer;

  /// Label for adding a new customer
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// Label for the customer name input field
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// Label for deleting a customer
  ///
  /// In en, this message translates to:
  /// **'Delete Customer'**
  String get deleteCustomer;

  /// Label for nickname
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// Title for the loaner filter sheet
  ///
  /// In en, this message translates to:
  /// **'Filter Loaners'**
  String get filterLoaners;

  /// Title for the loaner filter sheet
  ///
  /// In en, this message translates to:
  /// **'Filter Items'**
  String get filterItems;

  /// Label for the start date field in the filter
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get fromDate;

  /// Label for the end date field in the filter
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get toDate;

  /// Placeholder text when no date is selected
  ///
  /// In en, this message translates to:
  /// **'Not Set'**
  String get notSet;

  /// Text for the reset button in the filter sheet
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Text for the apply button in the filter sheet
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Title for the dialog when no categories are available
  ///
  /// In en, this message translates to:
  /// **'No Categories Available'**
  String get noCategoriesAvailable;

  /// Message in the dialog prompting the user to create a category
  ///
  /// In en, this message translates to:
  /// **'Please create a category first.'**
  String get pleaseCreateCategoryFirst;

  /// Text for the button to create a new category in the dialog
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get createCategory;

  /// Text for the button to create a new category in the dialog
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemFound;

  /// Text for the button to create a new category in the dialog
  ///
  /// In en, this message translates to:
  /// **'No Loaner found'**
  String get noLoanerFound;

  /// Title for the app bar when editing an existing loaner
  ///
  /// In en, this message translates to:
  /// **'Edit Loaner'**
  String get editLoaner;

  /// Title for the app bar when adding a new loaner
  ///
  /// In en, this message translates to:
  /// **'Add New Loaner'**
  String get addNewLoaner;

  /// Label for the amount field in the loaner form
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Text for the button to add a new loaner
  ///
  /// In en, this message translates to:
  /// **'Add Loaner'**
  String get addLoaner;

  /// Text for the button to add a new loaner
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// Image found in clipboard. Tap to use it.
  ///
  /// In en, this message translates to:
  /// **'Image found in clipboard. Tap to use it.'**
  String get imgFound;

  /// Label indicating a loan has been paid
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get paid;

  /// Label indicating a loan has been paid
  ///
  /// In en, this message translates to:
  /// **'UNPAID'**
  String get unpaid;

  /// Label for the shop section or page
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// Label for the loaner section or page
  ///
  /// In en, this message translates to:
  /// **'Loaner'**
  String get loaner;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
