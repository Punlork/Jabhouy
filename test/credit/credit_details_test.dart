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
  late CreditRepository repo;
  late CreditListCubit cubit;
  final edited = <String>[];

  Future<void> pump(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Credit credit(
    String id, {
    int? amount,
    bool paid = false,
    String? note,
    List<CreditLine> lines = const [],
  }) => Credit(
    id: id,
    customerId: 'bol',
    currency: Currency.khr,
    khrPerUsd: 4000,
    takenAt: DateTime.utc(2026, 4, 5, 4),
    amount: amount,
    note: note,
    lines: lines,
    status: paid ? CreditStatus.paid : CreditStatus.unpaid,
  );

  Future<void> open(
    WidgetTester tester,
    Credit toSave, {
    MemberRole role = MemberRole.owner,
    bool withEdit = true,
  }) async {
    db = AppDatabase(NativeDatabase.memory());
    final connectivity = _Connectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    repo = CreditRepository(
      CreditDao(db),
      _Scope(role),
      SyncEngine(database: db, transport: AdapterSyncTransport([])),
      connectivity,
    );
    await tester.runAsync(() async {
      await repo.saveCustomer(const CreditCustomer(id: 'bol', name: 'ពូ បុល'));
      await repo.saveCredit(toSave);
    });
    edited.clear();
    cubit = CreditListCubit(repo)..start();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showCreditDetails(
                  context,
                  toSave,
                  onEdit: withEdit ? (c) => edited.add(c.id) : null,
                ),
                child: const Text('open'),
              ),
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
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() async {
      await cubit.close();
      await db.close();
    });
  }

  testWidgets('shows who, status, amount in both currencies, items, note', (
    tester,
  ) async {
    await open(
      tester,
      credit(
        'c1',
        note: 'Hanuman 6',
        lines: const [
          CreditLine(
            id: 'l1',
            name: 'ទឹក',
            unit: 'ដប',
            qty: 2,
            currency: Currency.khr,
            unitPrice: 3000,
          ),
          CreditLine(
            id: 'l2',
            name: 'អង្ករ',
            unit: 'គីឡូ',
            qty: 5,
            currency: Currency.khr,
            unitPrice: 3800,
          ),
        ],
      ),
    );

    expect(find.text('ពូ បុល'), findsOneWidget);
    expect(find.text('មិនទាន់សង'), findsOneWidget);
    expect(find.text('5 មេសា 2026'), findsOneWidget);
    expect(find.text('ចំនួនត្រូវសង'), findsOneWidget);
    expect(find.text('25,000 ៛'), findsOneWidget);
    expect(find.text(r'≈ $6.25'), findsOneWidget);
    expect(find.text('2 ដប · 3,000 ៛'), findsOneWidget);
    expect(find.text('19,000 ៛'), findsOneWidget, reason: '5 × 3,800');
    expect(find.text('Hanuman 6'), findsOneWidget);
    await close(tester);
  });

  testWidgets('សម្គាល់ថាសងរួច marks it paid', (tester) async {
    await open(tester, credit('c1', amount: 5000));

    await tester.tap(find.text('សម្គាល់ថាសងរួច'));
    await pump(tester);

    final saved = await tester.runAsync(() => repo.credit('c1'));
    expect(saved!.isPaid, isTrue);
    expect(saved.paidAt, isNotNull);
    await close(tester);
  });

  testWidgets('a paid Credit has no mark-paid button; no amount says so', (
    tester,
  ) async {
    await open(tester, credit('c1', paid: true));

    expect(find.text('សម្គាល់ថាសងរួច'), findsNothing);
    expect(find.text('សងរួច'), findsOneWidget);
    expect(find.text('មិនទាន់មានចំនួន'), findsOneWidget);
    await close(tester);
  });

  testWidgets('កែ hands the Credit to the form; hidden without a form', (
    tester,
  ) async {
    await open(tester, credit('c1', amount: 100));
    await tester.tap(find.text('កែ'));
    await pump(tester);
    expect(edited, ['c1']);
    await close(tester);

    await open(tester, credit('c1', amount: 100), withEdit: false);
    expect(find.text('កែ'), findsNothing);
    await close(tester);
  });

  testWidgets('លុប asks first; cancel keeps it, confirm deletes it', (
    tester,
  ) async {
    await open(tester, credit('c1', amount: 100));

    await tester.tap(find.text('លុប'));
    await pump(tester);
    await tester.tap(find.text('បោះបង់'));
    await pump(tester);
    expect(await tester.runAsync(() => repo.credit('c1')), isNotNull);

    await tester.tap(find.text('លុប'));
    await pump(tester);
    await tester.tap(find.text('លុប').last);
    await pump(tester);
    expect(await tester.runAsync(() => repo.credit('c1')), isNull);
    await close(tester);
  });

  testWidgets('a viewer can mark paid but sees no លុប', (tester) async {
    await open(tester, credit('c1', amount: 100), role: MemberRole.viewer);

    expect(find.text('លុប'), findsNothing);
    expect(find.text('សម្គាល់ថាសងរួច'), findsOneWidget);
    await close(tester);
  });
}
