import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_shop/src/ui/widgets/whole_number_input.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockShopBloc extends Mock implements ShopBloc {}

class MockCategoryBloc extends Mock implements CategoryBloc {}

class MockUploadBloc extends Mock implements UploadBloc {}

void main() {
  group('whole numbers', () {
    test('Khmer digits read as the same number', () {
      expect(parseWholeNumber('១៥០០'), 1500);
    });

    test('separators a seller might paste are dropped', () {
      expect(parseWholeNumber('1,500'), 1500);
      expect(normalizeWholeNumber('1 500 ៛'), '1500');
    });

    test('an empty field is no number, not zero', () {
      expect(parseWholeNumber(''), isNull);
    });
  });

  group('variant problems', () {
    test('a new single card needs a customer price', () {
      expect(
        ShopItemVariantDraft.single().problems,
        {VariantProblem.missingCustomerPrice},
      );
    });

    test('a pack needs at least two items', () {
      final draft = ShopItemVariantDraft.pack()
        ..customerPriceController.text = '9000'
        ..packAmountController.text = '1';
      expect(draft.problems, {VariantProblem.invalidPackSize});
    });

    test('opening or closing a card is not an unsaved change', () {
      final controller = ShopItemFormController(onChanged: () {});
      controller.setExpanded(
        controller.variantDrafts.single,
        isExpanded: false,
      );
      expect(
        controller.hasChanges(
          uploadState: const UploadInitial(),
          selectedImage: null,
        ),
        isFalse,
      );
    });
  });

  group('the form', () {
    late MockShopBloc shop;
    late MockCategoryBloc category;
    late MockUploadBloc upload;

    setUpAll(() {
      registerFallbackValue(ShopCreateItemsEvent(items: const []));
    });

    setUp(() {
      shop = MockShopBloc();
      category = MockCategoryBloc();
      upload = MockUploadBloc();
      when(() => shop.state).thenReturn(const ShopInitial());
      when(() => shop.stream).thenAnswer((_) => const Stream.empty());
      when(() => shop.upload).thenReturn(upload);
      when(() => category.state)
          .thenReturn(const CategoryLoaded(items: []));
      when(() => category.stream).thenAnswer((_) => const Stream.empty());
      when(() => upload.state).thenReturn(const UploadInitial());
      when(() => upload.stream).thenAnswer((_) => const Stream.empty());
      when(() => upload.selectedImage).thenReturn(null);
    });

    Future<void> pumpForm(WidgetTester tester, {ShopItemModel? editing}) async {
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShopItemFormPage(
            shop: shop,
            category: category,
            existingItem: editing,
            onSaved: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// The input under the visible label [label], by its place on screen.
    Finder field(String label, {int at = 0}) => find
        .descendant(
          of: find.ancestor(
            of: find.text(label),
            matching: find.byType(Column),
          ),
          matching: find.byType(TextFormField),
        )
        .at(at);

    /// Taps the chip labelled [label]: an add-variant chip, or the
    /// Single/Pack toggle in a card header.
    Future<void> tapChip<T extends Widget>(
      WidgetTester tester,
      String label,
    ) async {
      await tester.tap(find.widgetWithText(T, label));
      await tester.pumpAndSettle();
    }

    Future<void> save(WidgetTester tester, String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    List<ShopItemModel> savedItems() {
      final event = verify(() => shop.add(captureAny())).captured.single;
      return (event as ShopCreateItemsEvent).items;
    }

    testWidgets('a price typed in Khmer digits saves as that number',
        (tester) async {
      await pumpForm(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Coke');
      await tester.enterText(field('Customer Price *'), '១៥០០');
      await tester.pump();

      await save(tester, 'Add Item');

      expect(savedItems().single.customerPrice, 1500);
    });

    testWidgets('fixing a field clears its error without saving',
        (tester) async {
      await pumpForm(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Coke');
      await save(tester, 'Add Item');
      expect(find.text('Customer Price is required'), findsOneWidget);

      await tester.enterText(field('Customer Price *'), '400');
      await tester.pumpAndSettle();

      expect(find.text('Customer Price is required'), findsNothing);
      verifyNever(() => shop.add(any()));
    });

    testWidgets('typing in one field does not flag the untouched ones',
        (tester) async {
      await pumpForm(tester);
      await tester.enterText(field('Customer Price *'), '400');
      await tapChip<ActionChip>(tester, 'Pack');

      await tester.enterText(field('Pack Size'), '1');
      await tester.pumpAndSettle();

      expect(find.text('Enter a pack size greater than 1'), findsOneWidget);
      expect(find.text('Customer Price is required'), findsNothing);
    });

    testWidgets('adding a card collapses the ones that could already save',
        (tester) async {
      await pumpForm(tester);
      await tester.enterText(field('Customer Price *'), '400');

      await tapChip<ActionChip>(tester, 'Pack');

      expect(find.text('Single · 400 រៀល'), findsOneWidget);
      // Only the new pack card shows its fields.
      expect(find.text('Customer Price *'), findsOneWidget);
      expect(find.text('Pack Size'), findsOneWidget);
    });

    testWidgets('a collapsed card that cannot save blocks save and opens',
        (tester) async {
      await pumpForm(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Coke');
      await tester.tap(find.byIcon(Icons.expand_less_rounded));
      await tester.pumpAndSettle();
      expect(find.text('⚠ Customer Price is required'), findsOneWidget);
      expect(find.text('Customer Price *'), findsNothing);

      await save(tester, 'Add Item');

      verifyNever(() => shop.add(any()));
      expect(find.text('Customer Price *'), findsOneWidget);
    });

    testWidgets('edit shows one card that cannot be removed or collapsed',
        (tester) async {
      await pumpForm(
        tester,
        editing: const ShopItemModel(id: 5, name: 'Coke', customerPrice: 400),
      );

      expect(find.text('Customer Price *'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(find.byIcon(Icons.expand_less_rounded), findsNothing);
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('edit can turn a single item into a pack of 24',
        (tester) async {
      registerFallbackValue(
        ShopEditItemEvent(body: const ShopItemModel(id: 0, name: '')),
      );
      await pumpForm(
        tester,
        editing: const ShopItemModel(id: 5, name: 'Coke', customerPrice: 400),
      );

      await tapChip<ChoiceChip>(tester, 'Pack');
      await tester.enterText(field('Pack Size'), '24');
      await tester.pump();
      await save(tester, 'Save Changes');

      final event = verify(() => shop.add(captureAny())).captured.single
          as ShopEditItemEvent;
      expect(event.body.name, 'Coke x24');
      expect(event.body.packAmount, 24);
    });
  });
}
