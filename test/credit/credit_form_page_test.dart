import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/credit/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:mocktail/mocktail.dart';

class _Connectivity extends Mock implements ConnectivityService {}

class _Scope implements ShopScope {
  @override
  MemberRole get role => MemberRole.owner;
  @override
  String get shopId => 's1';
  @override
  bool get syncs => false;
  @override
  String get userId => 'u1';
}

const _dara = CreditCustomer(id: 'dara', name: 'ដារ៉ា');

const _lines = [
  CreditLine(
    id: 'a',
    name: 'ទឹក',
    unit: 'ដប',
    qty: 2,
    currency: Currency.khr,
    unitPrice: 3000,
  ),
  CreditLine(
    id: 'b',
    name: 'អង្ករ',
    unit: 'គីឡូ',
    qty: 5,
    currency: Currency.khr,
    unitPrice: 3800,
  ),
];

void main() {
  late AppDatabase db;
  late CreditRepository repo;

  Future<void> pump(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> open(WidgetTester tester, {Credit? existing}) async {
    db = AppDatabase(NativeDatabase.memory());
    final connectivity = _Connectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    repo = CreditRepository(
      CreditDao(db),
      _Scope(),
      SyncEngine(database: db, transport: AdapterSyncTransport([])),
      connectivity,
    );
    await tester.runAsync(() async {
      await repo.saveCustomer(_dara);
      if (existing != null) await repo.saveCredit(existing);
    });
    tester.view.physicalSize = const Size(780, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final stored = existing == null
        ? null
        : await tester.runAsync(() => repo.credit(existing.id));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) =>
                        CreditFormCubit(repo, existing: stored)..load(),
                    child: CreditFormPage(
                      pickCustomer: (_, _) async => _dara,
                      pickItems: (
                        _, {
                        required currency,
                        required khrPerUsd,
                        required initial,
                      }) async => _lines,
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await pump(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  }

  Future<List<Credit>> saved(WidgetTester tester) async => (await tester
      .runAsync(() => repo.watchCredits(filter: CreditFilter.all).first))!;

  testWidgets('add: customer, items, a computed amount, save and leave', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('បន្ថែមការជំពាក់'), findsOneWidget);

    await tester.tap(find.text('ជ្រើសរើស'));
    await pump(tester);
    expect(find.text('ដារ៉ា'), findsOneWidget);

    await tester.tap(find.text('បន្ថែមទំនិញពីបញ្ជីតម្លៃ'));
    await pump(tester);
    expect(find.text('25,000'), findsOneWidget, reason: 'the computed amount');
    expect(find.text('19,000'), findsOneWidget, reason: '5 × 3,800');
    expect(find.text(r'≈ $6.25 · គណនាពីទំនិញ'), findsOneWidget);

    await tester.tap(find.text('រក្សាទុក'));
    await pump(tester);

    final credits = await saved(tester);
    expect(credits.single.amount, 25000);
    expect(credits.single.customerName, 'ដារ៉ា');
    expect(find.text('open'), findsOneWidget, reason: 'left the form');
    await close(tester);
  });

  testWidgets('saving without a customer shows the message and stays', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.text('រក្សាទុក'));
    await pump(tester);

    expect(find.text('សូមជ្រើសរើសអតិថិជន'), findsOneWidget);
    expect(await saved(tester), isEmpty);
    await close(tester);
  });

  testWidgets('without items the amount is typed', (tester) async {
    await open(tester);
    await tester.tap(find.text('ជ្រើសរើស'));
    await pump(tester);

    await tester.enterText(find.byType(TextField).first, '7000');
    await pump(tester);
    await tester.tap(find.text('រក្សាទុក'));
    await pump(tester);

    expect((await saved(tester)).single.amount, 7000);
    await close(tester);
  });

  testWidgets(r'a stepper changes a line; 0 removes it; ៛/$ re-converts', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('បន្ថែមទំនិញពីបញ្ជីតម្លៃ'));
    await pump(tester);

    await tester.tap(find.byIcon(Icons.add_rounded).first); // ទឹក 2 → 3
    await pump(tester);
    expect(find.text('28,000'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byIcon(Icons.remove_rounded).first);
      await pump(tester);
    }
    expect(find.text('ទឹក'), findsNothing);
    expect(find.text('19,000'), findsNWidgets(2), reason: 'line and amount');

    await tester.tap(find.byTooltip(r'៛ / $'));
    await pump(tester);
    expect(
      find.text('4.75'),
      findsNWidgets(2),
      reason: r'19,000 ៛ is $4.75, on the line and in the amount',
    );
    await close(tester);
  });

  testWidgets('edit: prefilled, and status and note can change', (
    tester,
  ) async {
    await open(
      tester,
      existing: Credit(
        id: 'c1',
        customerId: 'dara',
        currency: Currency.khr,
        khrPerUsd: 4000,
        takenAt: DateTime.utc(2026, 10, 14, 4, 5),
        amount: 7000,
        note: 'Hanuman 6',
        dueDate: '2026-11-02',
      ),
    );

    expect(find.text('កែការជំពាក់'), findsOneWidget);
    expect(find.text('ដារ៉ា'), findsOneWidget);
    expect(find.text('Hanuman 6'), findsOneWidget);
    expect(find.text('7,000'), findsOneWidget);
    expect(find.text('14 តុលា 2026'), findsOneWidget);
    expect(find.text('2 វិច្ឆិកា 2026'), findsOneWidget, reason: 'due date');

    await tester.tap(find.text('សងរួច'));
    await pump(tester);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await pump(tester);
    await tester.tap(find.text('រក្សាទុក'));
    await pump(tester);

    final credit = (await saved(tester)).single;
    expect(credit.isPaid, isTrue);
    expect(credit.amount, 7000);
    expect(credit.id, 'c1');
    expect(credit.dueDate, isNull, reason: 'cleared');
    await close(tester);
  });
}
