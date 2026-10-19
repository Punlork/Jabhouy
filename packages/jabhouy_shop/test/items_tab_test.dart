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

PriceOption _option(String unit, int? price, {int? packQty}) => PriceOption(
  id: newId(),
  unit: unit,
  currency: Currency.khr,
  price: price,
  packQty: packQty,
);

void main() {
  late AppDatabase db;
  late ItemRepository repo;
  final opened = <String>[];

  Future<void> pumpTab(
    WidgetTester tester, {
    MemberRole role = MemberRole.owner,
    bool grid = false,
  }) async {
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
      await repo.saveItem(
        Item(
          id: 'coke',
          name: 'Coca-Cola',
          prices: [_option('ដប', 3000), _option('កេះ', 60000, packQty: 24)],
        ),
      );
      await repo.saveItem(
        Item(id: 'rice', name: 'អង្ករផ្កាម្លិះ', prices: [_option('បេ', null)]),
      );
      // Quick add: a name only, priced later.
      await repo.saveItem(const Item(id: 'sugar', name: 'ស្ករ', prices: []));
    });
    opened.clear();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider(
            create: (_) => ItemListCubit(repo, scope, grid: grid)..start(),
            child: ItemsTab(onEditItem: (item) => opened.add(item.id)),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  }

  testWidgets('one row per item, one line per price, never 0 ៛', (
    tester,
  ) async {
    await pumpTab(tester);

    expect(find.text('Coca-Cola'), findsOneWidget);
    expect(find.text('ដប'), findsOneWidget);
    expect(find.text('3,000 ៛'), findsOneWidget);
    expect(find.text('កេះ (24)'), findsOneWidget);
    expect(find.text('60,000 ៛'), findsOneWidget);
    // The warning chip, the rice row's missing price, and the unpriced
    // sugar row.
    expect(find.text('មិនទាន់មានតម្លៃ'), findsNWidgets(3));
    expect(find.text('0 ៛'), findsNothing);
    expect(find.text('ទំនិញ 3 មុខ · ក–អ'), findsOneWidget);

    await tester.tap(find.text('Coca-Cola'));
    await settle(tester);
    expect(find.byType(ItemDetailsSheet), findsOneWidget);
    final recent = await tester.runAsync(() => repo.watchRecentItems().first);
    expect(recent!.map((i) => i.id), ['coke'], reason: 'opening is recorded');
    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(
      sheet.backgroundColor,
      isNot(Colors.transparent),
      reason: 'AppSheet relies on the sheet theme for its background',
    );
    expect(opened, isEmpty, reason: 'a tap shows details first');
    await tester.tap(find.text('កែតម្លៃ'));
    await settle(tester);
    expect(opened, ['coke']);
    await close(tester);
  });

  testWidgets('the warning chip narrows to items missing a price', (
    tester,
  ) async {
    await pumpTab(tester);

    await tester.tap(find.text('មិនទាន់មានតម្លៃ').first);
    await settle(tester);

    expect(find.text('អង្ករផ្កាម្លិះ'), findsOneWidget);
    expect(find.text('ស្ករ'), findsOneWidget, reason: 'no price is missing');
    expect(find.text('Coca-Cola'), findsNothing);
    await close(tester);
  });

  testWidgets('a viewer sees no warning chip', (tester) async {
    await pumpTab(tester, role: MemberRole.viewer);

    // Only the rows' own missing prices; no chip.
    expect(find.text('មិនទាន់មានតម្លៃ'), findsNWidgets(2));
    await close(tester);
  });

  testWidgets('pulling the list down refreshes it', (tester) async {
    await pumpTab(tester);

    await tester.fling(find.text('Coca-Cola'), const Offset(0, 400), 1000);
    await tester.pump();
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);
    await settle(tester);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
    await close(tester);
  });

  testWidgets('a card shows three prices, then how many more', (tester) async {
    await pumpTab(tester);
    await tester.runAsync(
      () => repo.saveItem(
        Item(
          id: 'many',
          name: 'Many',
          prices: [for (var i = 0; i < 5; i++) _option('u$i', 1000 + i)],
        ),
      ),
    );
    await settle(tester);

    expect(find.text('u2'), findsOneWidget);
    expect(find.text('u3'), findsNothing);
    expect(find.text('+2 ទៀត'), findsOneWidget);
    await close(tester);
  });

  testWidgets('the grid shows the same price lines', (tester) async {
    await pumpTab(tester, grid: true);

    expect(find.text('កេះ (24)'), findsOneWidget);
    expect(find.text('60,000 ៛'), findsOneWidget);
    await close(tester);
  });
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}
