import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements ConnectivityService {}

class _Scope implements ShopScope {
  _Scope(this.role);

  @override
  final MemberRole role;
  @override
  String get shopId => 's1';
  @override
  bool get syncs => false;
  @override
  String get userId => 'u1';
}

void main() {
  late AppDatabase db;
  late ItemRepository repo;
  late CategoriesCubit cubit;

  Future<void> pumpPage(WidgetTester tester, MemberRole role) async {
    db = AppDatabase(NativeDatabase.memory());
    final connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    final scope = _Scope(role);
    repo = ItemRepository(
      ItemDao(db),
      scope,
      SyncEngine(database: db, transport: AdapterSyncTransport([])),
      connectivity,
    );
    await tester.runAsync(() async {
      final dao = ItemDao(db);
      final now = DateTime.utc(2026, 10, 19);
      await dao.saveCategory(
        's1',
        const ItemCategory(
          id: 'drinks',
          name: 'ភេសជ្ជៈ',
          units: [
            CategoryUnit(unit: 'ដប'),
            CategoryUnit(unit: 'កេះ'),
          ],
        ),
        now: now,
      );
      await dao.saveCategory(
        's1',
        const ItemCategory(id: 'rice', name: 'អង្ករ', sortOrder: 1),
        now: now,
      );
      await dao.saveCategory(
        's1',
        const ItemCategory(id: 'old', name: 'ចាស់', sortOrder: 2, hidden: true),
        now: now,
      );
    });
    cubit = CategoriesCubit(repo, scope)..load();
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: const CategoriesUnitsPage(),
        ),
      ),
    );
    await settle(tester);
  }

  Future<ItemCategory> saved(WidgetTester tester, String id) async =>
      (await tester.runAsync(() => repo.watchCategories().first))!
          .singleWhere((c) => c.id == id);

  Future<void> close(WidgetTester tester) async {
    await tester.runAsync(() async {
      await cubit.close();
      await db.close();
    });
  }

  testWidgets('lists every category; a hidden one carries a tag', (
    tester,
  ) async {
    await pumpPage(tester, MemberRole.owner);

    expect(find.text('ភេសជ្ជៈ'), findsOneWidget);
    expect(find.text('ចាស់'), findsOneWidget);
    expect(find.text('លាក់'), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(3));
    await close(tester);
  });

  testWidgets('the owner renames, hides a unit and adds one', (tester) async {
    await pumpPage(tester, MemberRole.owner);

    await tester.tap(find.text('ភេសជ្ជៈ'));
    await settle(tester);
    await tester.enterText(
      find.byKey(CategoriesUnitsPage.nameKey),
      'ភេសជ្ជៈត្រជាក់',
    );
    await tester.tap(find.text('កេះ'));
    await tester.tap(find.text('+ ពាក្យកាត់'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'កំប៉ុង');
    await tester.tap(find.text('រក្សាទុក').last);
    await settle(tester);
    await tester.tap(find.text('រក្សាទុក'));
    await settle(tester);

    final drinks = await saved(tester, 'drinks');
    expect(drinks.name, 'ភេសជ្ជៈត្រជាក់');
    expect(
      {for (final u in drinks.units) u.unit: u.hidden},
      {'ដប': false, 'កេះ': true, 'កំប៉ុង': false},
    );
    // The item form's chips: the hidden unit drops out.
    expect(
      await tester.runAsync(() => repo.unitsFor('drinks')),
      unorderedEquals(['ដប', 'កំប៉ុង']),
    );
    await close(tester);
  });

  testWidgets('the owner hides a category', (tester) async {
    await pumpPage(tester, MemberRole.owner);

    await tester.tap(find.text('អង្ករ'));
    await settle(tester);
    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('រក្សាទុក'));
    await settle(tester);

    expect((await saved(tester, 'rice')).hidden, isTrue);
    await close(tester);
  });

  testWidgets('moving a category keeps the new order', (tester) async {
    await pumpPage(tester, MemberRole.owner);

    await tester.runAsync(() => cubit.move(2, 0));
    await settle(tester);

    final order = await tester.runAsync(() => repo.watchCategories().first);
    expect([for (final c in order!) c.id], ['old', 'drinks', 'rice']);
    await close(tester);
  });

  testWidgets('a viewer reads but cannot edit', (tester) async {
    await pumpPage(tester, MemberRole.viewer);

    expect(find.byIcon(Icons.drag_handle_rounded), findsNothing);
    expect(find.text('បង្កើតប្រភេទថ្មី'), findsNothing);
    await tester.tap(find.text('ភេសជ្ជៈ'));
    await settle(tester);
    expect(find.text('កេះ'), findsOneWidget);
    expect(find.text('រក្សាទុក'), findsNothing);
    expect(
      tester.widget<TextField>(find.byKey(CategoriesUnitsPage.nameKey)).enabled,
      isFalse,
    );
    await close(tester);
  });
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}
