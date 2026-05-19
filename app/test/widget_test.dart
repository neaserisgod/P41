import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:p41/app/app.dart';
import 'package:p41/app/models/catalog_product.dart';
import 'package:p41/app/models/product_pricing_rules.dart';
import 'package:p41/app/models/session_context.dart';
import 'package:p41/app/models/workspace_tab.dart';
import 'package:p41/app/state/tab_manager.dart';
import 'package:p41/app/state/session_controller.dart';
import 'package:p41/features/auth/screens/login_screen.dart';
import 'package:p41/features/auth/screens/onboarding_home_screen.dart';
import 'package:p41/features/cash_management/models/cash_shift.dart';
import 'package:p41/features/cash_management/widgets/cash_shift_dialog.dart';
import 'package:p41/features/pos/state/sales_controller.dart';
import 'package:p41/features/pos/widgets/pos_search_bar.dart';
import 'package:p41/features/auth/screens/setup_admin_screen.dart';
import 'package:p41/app/services/local_store_service.dart';
import 'package:p41/app/services/remote_auth_service.dart';
import 'package:p41/app/services/session_persistence_service.dart';

void main() {
  ThemeData buildTheme() {
    return ThemeData.light(useMaterial3: true).copyWith(
      extensions: const <ThemeExtension<dynamic>>[
        AppPalette(
          shell: Color(0xFFF1F3F6),
          surface: Colors.white,
          surfaceMuted: Color(0xFFF7F7F8),
          border: Color(0xFFE0E2E6),
          textStrong: Color(0xFF1A1C20),
          textMuted: Color(0xFF6D7178),
          accent: Color(0xFFE5BA4F),
          accentSoft: Color(0xFFF6E7BF),
          danger: Color(0xFFB04A3A),
          success: Color(0xFF3E8D7A),
          warning: Color(0xFFB7862F),
        ),
      ],
    );
  }

  testWidgets('renders setup admin flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: SetupAdminScreen(
          onCreateAccount: ({
            required accountName,
            required ownerEmail,
            required password,
          }) async {},
          onOpenLogin: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Prepará el local y arrancá.'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsNWidgets(2));
    expect(find.text('Nombre del negocio'), findsOneWidget);
    expect(find.text('Email del administrador'), findsOneWidget);
    expect(find.text('Clave de acceso'), findsOneWidget);
  });

  testWidgets('renders login flow with remembered accounts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: LoginScreen(
          accountName: 'La Plazoleta',
          rememberedAccounts: const [
            RememberedAccount(
              scopeKey: 'laplazoleta25@gmail.com',
              email: 'laplazoleta25@gmail.com',
              accountName: 'La Plazoleta',
            ),
          ],
          onCreateAccount: () {},
          onLoadLocalUsers: (_) async => const [],
          onLocalPinLogin: ({
            required email,
            required userId,
            required pin,
          }) async => false,
          onLogin: ({
            required email,
            required password,
          }) async => false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Abrir cuenta'), findsOneWidget);
    expect(find.text('Cuentas de este equipo'), findsOneWidget);
    expect(find.text('La Plazoleta'), findsWidgets);
    expect(find.text('laplazoleta25@gmail.com'), findsOneWidget);
  });

  test('starts onboarding tab when requested', () {
    final tabManager = TabManager.initial(activeKind: WorkspaceKind.home);

    expect(tabManager.activeTab.kind, WorkspaceKind.home);
  });

  testWidgets('onboarding shows next actionable step', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: OnboardingHomeScreen(
          businessName: 'La Plazoleta',
          branchName: 'La Plazoleta',
          showBranchName: false,
          hasTeam: false,
          productCount: 0,
          hasOpenShift: false,
          onRenameBranch: () async {},
          onOpenTeam: () {},
          onOpenProducts: () {},
          onOpenCash: () {},
          onOpenPos: () {},
        ),
      ),
    );

    expect(find.text('Progreso'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('Crear equipo'), findsOneWidget);
    expect(find.text('Te faltan 3 pasos para poder vender.'), findsOneWidget);
  });

  testWidgets('cash dialog explains separate cigarettes flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: CashShiftDialog(
            shift: const CashShift(
              id: 'shift-1',
              branchId: 'branch-1',
              branchName: 'La Plazoleta',
              registerName: 'Caja',
              status: CashShiftStatus.open,
              expectedAmount: 1000,
              cashSalesTotal: 500,
              virtualSalesTotal: 0,
              openedAtLabel: '18/05 · 10:00',
            ),
            separateCigarettes: true,
            cigaretteShift: const CashShift(
              id: 'shift-cig-1',
              branchId: 'branch-1',
              branchName: 'La Plazoleta',
              registerName: 'Caja cigarrillos',
              registerKind: CashRegisterKind.cigarettes,
              status: CashShiftStatus.open,
              expectedAmount: 300,
              cashSalesTotal: 100,
              virtualSalesTotal: 200,
            ),
            activeUserName: 'Churro',
            activeBranchName: 'La Plazoleta',
            onCancel: () {},
            onConfirmOpen: (_) {},
            onConfirmClose: (_) {},
          ),
        ),
      ),
    );

    expect(find.textContaining('opera con caja separada para cigarrillos'), findsOneWidget);
    expect(find.text('Contado real en caja'), findsOneWidget);
    expect(find.text('Contado real caja cigarrillos'), findsOneWidget);
  });

  testWidgets('pos search bar submits first result flow', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final salesController = SalesController(
      initialBranch: const SessionBranch(
        id: 'branch-1',
        name: 'La Plazoleta',
        label: 'Sucursal',
        isActive: true,
      ),
      scopeKey: 'laplazoleta25@gmail.com',
    );
    final product = const CatalogProduct(
      id: 'p-1',
      name: 'Marlboro Box',
      sku: 'MARL-BOX',
      barcode: '123',
      category: 'Cigarrillos',
      supplierId: 'prov-1',
      supplierName: 'Proveedor',
      locationId: 'loc-1',
      locationName: 'Mostrador',
      locationType: 'Mueble',
      price: 2500,
      cost: 1800,
      stock: 10,
      minStock: 2,
      pricingRules: ProductPricingRules.defaults,
    );
    addTearDown(() {
      controller.dispose();
      focusNode.dispose();
      salesController.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: PosSearchBar(
            controller: controller,
            focusNode: focusNode,
            onChanged: salesController.setQuery,
            onSubmit: (_) => salesController.addProduct(product),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'marl');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(salesController.cartItems.length, 1);
    expect(salesController.cartItems.first.product.name, 'Marlboro Box');
  });

  test('restores persisted login from local snapshot on bootstrap', () async {
    final controller = SessionController(
      persistenceService: _FakeSessionPersistenceService(
        const PersistedSession(
          email: 'laplazoleta25@gmail.com',
          branchId: 'branch-1',
          userId: 'user-1',
        ),
      ),
      localStoreService: _FakeLocalStoreService(),
      remoteAuthService: _FakeRemoteAuthService(),
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(controller.stage, SessionStage.ready);
    expect(controller.account?.ownerEmail, 'laplazoleta25@gmail.com');
    expect(controller.activeBranch?.id, 'branch-1');
    expect(controller.activeUser?.id, 'user-1');
    expect(controller.rememberedAccounts.length, 1);
  });

  test('sign out returns to login and keeps remembered account', () async {
    final controller = SessionController(
      persistenceService: _FakeSessionPersistenceService(
        const PersistedSession(
          email: 'laplazoleta25@gmail.com',
          branchId: 'branch-1',
          userId: 'user-1',
        ),
      ),
      localStoreService: _FakeLocalStoreService(),
      remoteAuthService: _FakeRemoteAuthService(),
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    controller.signOut();

    expect(controller.stage, SessionStage.login);
    expect(controller.rememberedAccounts.length, 1);
    expect(controller.rememberedAccounts.first.email, 'laplazoleta25@gmail.com');
  });
}

class _FakeLocalStoreService extends LocalStoreService {
  @override
  Future<bool> isOfflineOnly() async => true;

  @override
  Future<void> setOfflineOnly(bool value) async {}

  @override
  Future<List<Map<String, String>>> listRememberedAccounts() async {
    return const [
      {
        'scope_key': 'laplazoleta25@gmail.com',
        'email': 'laplazoleta25@gmail.com',
        'account_name': 'La Plazoleta',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>?> readSessionSnapshot(String scopeKey) async {
    if (scopeKey != 'laplazoleta25@gmail.com') {
      return null;
    }
    return {
      'access_token': 'offline-local',
      'business_id': 'business-1',
      'account': {
        'account_name': 'La Plazoleta',
        'owner_email': 'laplazoleta25@gmail.com',
        'password': '1234',
      },
      'users': [
        {
          'id': 'user-1',
          'name': 'Churro',
          'role': 'admin',
          'initials': 'CH',
          'branch_ids': ['branch-1'],
          'pin': '1234',
          'is_active': true,
        },
      ],
      'branches': [
        {
          'id': 'branch-1',
          'name': 'La Plazoleta',
          'label': 'Sucursal',
          'is_active': true,
        },
      ],
    };
  }
}

class _FakeSessionPersistenceService extends SessionPersistenceService {
  _FakeSessionPersistenceService(this._session);

  PersistedSession? _session;

  @override
  Future<PersistedSession?> load() async => _session;

  @override
  Future<void> save(PersistedSession session) async {
    _session = session;
  }

  @override
  Future<void> clear() async {
    _session = null;
  }
}

class _FakeRemoteAuthService extends RemoteAuthService {
  _FakeRemoteAuthService() : super(baseUrl: 'http://127.0.0.1');
}
