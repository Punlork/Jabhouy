import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
  CreditCustomer? picked;

  Credit credit(String id, String customer, {int? amount, bool paid = false}) =>
      Credit(
        id: id,
        customerId: customer,
        currency: Currency.khr,
        khrPerUsd: 4000,
        takenAt: DateTime.utc(2026, 10, 14),
        amount: amount,
        status: paid ? CreditStatus.paid : CreditStatus.unpaid,
      );

  Future<void> pump(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> open(
    WidgetTester tester, {
    MemberRole role = MemberRole.owner,
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
      for (final c in [
        const CreditCustomer(id: 'bol', name: 'ពូ បុល'),
        const CreditCustomer(id: 'mak', name: 'មាក់ អាពុញ'),
        const CreditCustomer(id: 'khuo', name: 'ពូ ខួរ'),
        const CreditCustomer(id: 'new', name: 'អ្នកថ្មី'),
      ]) {
        await repo.saveCustomer(c);
      }
      await repo.saveCredit(credit('c1', 'bol', amount: 23000));
      await repo.saveCredit(credit('c2', 'mak'));
      await repo.saveCredit(credit('c3', 'khuo', amount: 500, paid: true));
    });
    picked = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  picked = await showCustomerPicker(context, repo),
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
    // Lets the cubits' stream cancels finish under the fake clock.
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  }

  testWidgets('rows show what each customer owes; a tap picks one', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('ជំពាក់ 23,000 ៛'), findsOneWidget);
    expect(find.text('ជំពាក់ · មិនទាន់មានចំនួន'), findsOneWidget);
    expect(find.text('សងរួច'), findsOneWidget);
    expect(find.text('អ្នកថ្មី'), findsOneWidget, reason: 'no Credit: no text');

    await tester.tap(find.text('ពូ បុល'));
    await pump(tester);
    expect(picked?.id, 'bol');
    await close(tester);
  });

  testWidgets('search narrows by name', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'មាក់');
    await pump(tester);

    expect(find.text('មាក់ អាពុញ'), findsOneWidget);
    expect(find.text('ពូ បុល'), findsNothing);
    await close(tester);
  });

  testWidgets('បន្ថែមអតិថិជនថ្មី creates the customer and picks it', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.text('បន្ថែមអតិថិជនថ្មី'));
    await pump(tester);
    await tester.enterText(find.byType(TextField).last, 'ដារ៉ា');
    await tester.tap(find.text('រក្សាទុក'));
    await pump(tester);

    expect(picked?.name, 'ដារ៉ា');
    final names = await tester.runAsync(
      () => repo.watchCustomers().first.then(
        (all) => all.map((b) => b.customer.name).toList(),
      ),
    );
    expect(names, contains('ដារ៉ា'));
    await close(tester);
  });

  testWidgets('⋯ renames; a customer with credits has no delete', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byTooltip('កែសម្រួលអតិថិជន').first);
    await pump(tester);
    await tester.enterText(find.byType(TextField).last, 'ពូ បុល ២');
    await tester.tap(find.text('រក្សាទុក'));
    await pump(tester);
    expect(find.text('ពូ បុល ២'), findsOneWidget);

    await tester.tap(find.byTooltip('កែសម្រួលអតិថិជន').first);
    await pump(tester);
    expect(find.text('លុប'), findsNothing, reason: 'has a Credit');
    expect(
      find.text('មិនអាចលុបបានទេ ព្រោះអតិថិជននេះនៅមានការជំពាក់'),
      findsOneWidget,
    );
    await close(tester);
  });

  testWidgets('a customer with no Credit can be deleted; a viewer cannot', (
    tester,
  ) async {
    await open(tester);
    // "អ្នកថ្មី" is the last row alphabetically after the ពូ/មាក់ ones.
    await tester.tap(find.byTooltip('កែសម្រួលអតិថិជន').last);
    await pump(tester);
    await tester.tap(find.text('លុប'));
    await pump(tester);
    expect(find.text('អ្នកថ្មី'), findsNothing);
    await close(tester);

    await open(tester, role: MemberRole.viewer);
    await tester.tap(find.byTooltip('កែសម្រួលអតិថិជន').first);
    await pump(tester);
    expect(find.text('លុប'), findsNothing);
    expect(find.text('រក្សាទុក'), findsOneWidget);
    await close(tester);
  });
}
