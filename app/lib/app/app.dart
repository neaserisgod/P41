import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import 'models/session_context.dart';
import 'models/workspace_tab.dart';
import 'state/catalog_controller.dart';
import 'state/session_controller.dart';
import 'state/tab_manager.dart';
import 'widgets/side_navigation_panel.dart';
import 'widgets/top_tab_bar.dart';
import '../features/auth/screens/branch_selection_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/onboarding_home_screen.dart';
import '../features/auth/screens/setup_admin_screen.dart';
import '../features/auth/screens/user_selection_screen.dart';
import '../features/admin_branches/screens/branches_screen.dart';
import '../features/admin_users/screens/users_screen.dart';
import '../features/catalog_products/screens/products_screen.dart';
import '../features/cash_management/screens/cash_management_screen.dart';
import '../features/cash_management/models/cash_shift.dart';
import '../features/cash_management/state/cash_controller.dart';
import '../features/cash_management/widgets/cash_shift_dialog.dart';
import '../features/inventory/screens/inventory_screen.dart';
import '../features/pos/state/sales_controller.dart';
import '../features/pos/screens/pos_screen.dart';
import '../features/providers/screens/providers_screen.dart';
import '../features/providers/state/providers_controller.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/settings/screens/settings_screen.dart';

class P41App extends StatelessWidget {
  const P41App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'P41',
      theme: _buildTheme(),
      scrollBehavior: const _DesktopScrollBehavior(),
      home: const AppRoot(),
    );
  }

  ThemeData _buildTheme() {
    const canvas = Color(0xFFFAFAFC);
    const shell = Color(0xFFF1F3F6);
    const surface = Color(0xFFFFFFFF);
    const ink = Color(0xFF1A1C20);
    const accent = Color(0xFFE5BA4F);

    final base = ThemeData.light(useMaterial3: true);
    final textTheme = base.textTheme.copyWith(
      displayLarge: const TextStyle(fontFamily: 'GlacialIndifference', fontWeight: FontWeight.w700),
      displayMedium: const TextStyle(fontFamily: 'GlacialIndifference', fontWeight: FontWeight.w700),
      displaySmall: const TextStyle(fontFamily: 'GlacialIndifference', fontWeight: FontWeight.w700),
      headlineLarge: const TextStyle(fontFamily: 'GlacialIndifference', fontWeight: FontWeight.w700),
      headlineMedium: const TextStyle(fontFamily: 'GlacialIndifference', fontWeight: FontWeight.w700),
      headlineSmall: const TextStyle(fontFamily: 'GlacialIndifference', fontWeight: FontWeight.w700),
      titleLarge: const TextStyle(fontFamily: 'GlacialIndifference', fontWeight: FontWeight.w700),
      titleMedium: const TextStyle(fontFamily: 'GlacialIndifference', fontWeight: FontWeight.w700),
      titleSmall: const TextStyle(fontFamily: 'Questrial', fontWeight: FontWeight.w700),
      bodyLarge: const TextStyle(fontFamily: 'Questrial'),
      bodyMedium: const TextStyle(fontFamily: 'Questrial'),
      bodySmall: const TextStyle(fontFamily: 'Questrial'),
      labelLarge: const TextStyle(fontFamily: 'Questrial', fontWeight: FontWeight.w700),
      labelMedium: const TextStyle(fontFamily: 'Questrial', fontWeight: FontWeight.w700),
      labelSmall: const TextStyle(fontFamily: 'Questrial', fontWeight: FontWeight.w700),
    );

    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        surface: surface,
      ),
      textTheme: textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppPalette(
          shell: shell,
          surface: surface,
          surfaceMuted: Color(0xFFF7F7F8),
          border: Color(0xFFE0E2E6),
          textStrong: ink,
          textMuted: Color(0xFF6D7178),
          accent: accent,
          accentSoft: Color(0xFFF6E7BF),
          danger: Color(0xFFB04A3A),
          success: Color(0xFF3E8D7A),
          warning: Color(0xFFB7862F),
        ),
      ],
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late SessionController _sessionController;

  @override
  void initState() {
    super.initState();
    _sessionController = SessionController();
  }

  void _recreateSessionController() {
    final previous = _sessionController;
    setState(() {
      _sessionController = SessionController();
    });
    previous.dispose();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _sessionController,
      builder: (context, _) {
        switch (_sessionController.stage) {
          case SessionStage.loading:
            return const _SessionLoadingScreen();
          case SessionStage.setup:
            return SetupAdminScreen(
              onCreateAccount: ({
                required accountName,
                required ownerEmail,
                required password,
              }) {
                return _sessionController.setupInitialAccount(
                  accountName: accountName,
                  ownerEmail: ownerEmail,
                  password: password,
                );
              },
              errorMessage: _sessionController.sessionError,
              noticeMessage: _sessionController.sessionNotice,
              onOpenLogin: _sessionController.showLoginScreen,
            );
          case SessionStage.login:
            return LoginScreen(
              accountName: _sessionController.accountName ?? 'P41',
              rememberedAccounts: _sessionController.rememberedAccounts,
              onLocalPinLogin: ({
                required email,
                required userId,
                required pin,
              }) {
                return _sessionController.signInWithLocalPin(
                  email: email,
                  userId: userId,
                  pin: pin,
                );
              },
              onLoadLocalUsers: _sessionController.localUsersForAccount,
              onLogin: ({
                required email,
                required password,
              }) {
                return _sessionController.signIn(
                  email: email,
                  password: password,
                );
              },
              errorMessage: _sessionController.sessionError,
              noticeMessage: _sessionController.sessionNotice,
              onCreateAccount: _sessionController.showSetupScreen,
            );
          case SessionStage.branchSelection:
            return BranchSelectionScreen(
              branches: _sessionController.branches,
              onSelectBranch: _sessionController.selectBranch,
            );
          case SessionStage.userSelection:
            return UserSelectionScreen(
              users: _sessionController.users,
              branchName: _sessionController.hasSingleBranch
                  ? ''
                  : (_sessionController.activeBranch?.name ?? 'Sucursal'),
              onSelectUser: _sessionController.selectUser,
            );
          case SessionStage.ready:
            return OperationalShell(
              sessionController: _sessionController,
              onRequestAppReload: _recreateSessionController,
            );
        }
      },
    );
  }
}

class _SessionLoadingScreen extends StatelessWidget {
  const _SessionLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.shell,
      body: const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}

class OperationalShell extends StatefulWidget {
  const OperationalShell({
    super.key,
    required this.sessionController,
    required this.onRequestAppReload,
  });

  final SessionController sessionController;
  final VoidCallback onRequestAppReload;

  @override
  State<OperationalShell> createState() => _OperationalShellState();
}

class _OperationalShellState extends State<OperationalShell> {
  late final TabManager _tabManager;
  late final CatalogController _catalogController;
  late final CashController _cashController;
  late final SalesController _salesController;
  late final ProvidersController _providersController;
  bool _isSidebarOpen = false;
  bool _isCashDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _tabManager = TabManager.initial(
      activeKind: widget.sessionController.shouldStartOnboarding
          ? WorkspaceKind.home
          : WorkspaceKind.pos,
    );
    _catalogController = CatalogController(
      initialBranch: widget.sessionController.activeBranch!,
      scopeKey: widget.sessionController.account!.ownerEmail,
    );
    _cashController = CashController(
      initialBranch: widget.sessionController.activeBranch!,
      scopeKey: widget.sessionController.account!.ownerEmail,
    );
    _salesController = SalesController(
      initialBranch: widget.sessionController.activeBranch!,
      scopeKey: widget.sessionController.account!.ownerEmail,
    );
    _providersController = ProvidersController(
      catalogController: _catalogController,
      initialBranch: widget.sessionController.activeBranch!,
      scopeKey: widget.sessionController.account!.ownerEmail,
    );
    _tabManager.addListener(_handleTabStateChanged);
    _cashController.addListener(_handleCashStateChanged);
    widget.sessionController.addListener(_handleSessionChanged);
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_handleSessionChanged);
    _tabManager
      ..removeListener(_handleTabStateChanged)
      ..dispose();
    _cashController.removeListener(_handleCashStateChanged);
    _catalogController.dispose();
    _cashController.dispose();
    _salesController.dispose();
    _providersController.dispose();
    super.dispose();
  }

  void _handleTabStateChanged() {
    setState(() {});
  }

  void _handleCashStateChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _handleSessionChanged() {
    final branch = widget.sessionController.activeBranch;
    if (branch == null) {
      return;
    }
    unawaited(
      _catalogController.updateSession(
        activeBranch: branch,
        scopeKey: widget.sessionController.account?.ownerEmail ?? 'default',
      ),
    );
    unawaited(
      _providersController.updateSession(
        activeBranch: branch,
        scopeKey: widget.sessionController.account?.ownerEmail ?? 'default',
      ),
    );
    unawaited(
      _cashController.updateSession(
        activeBranch: branch,
        scopeKey: widget.sessionController.account?.ownerEmail ?? 'default',
      ),
    );
    unawaited(
      _salesController.updateSession(
        activeBranch: branch,
        scopeKey: widget.sessionController.account?.ownerEmail ?? 'default',
      ),
    );
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _handleSidebarSelection(WorkspaceKind kind) {
    _tabManager.activateWorkspace(kind);
    setState(() {
      _isSidebarOpen = false;
    });
  }

  void _handleUserSelection(SessionUser user) {
    widget.sessionController.switchUser(user);
    setState(() {});
  }

  void _handleBranchSelection(SessionBranch branch) {
    widget.sessionController.switchBranch(branch);
    _salesController.clearCart();
    setState(() {});
  }

  void _openCashDialog() {
    setState(() {
      _isCashDialogOpen = true;
      _isSidebarOpen = false;
    });
  }

  void _closeCashDialog() {
    setState(() {
      _isCashDialogOpen = false;
    });
  }

  void _confirmOpenCash(CashRegisterAmounts amounts) {
    final activeBranch = widget.sessionController.activeBranch;
    final activeUser = widget.sessionController.activeUser;
    if (activeBranch == null || activeUser == null) {
      return;
    }
    unawaited(
      _cashController.openShift(
        branch: activeBranch,
        user: activeUser,
        amounts: amounts,
      ),
    );
    setState(() {
      _isCashDialogOpen = false;
    });
  }

  void _confirmCloseCash(CashRegisterAmounts amounts) {
    final activeBranch = widget.sessionController.activeBranch;
    final activeUser = widget.sessionController.activeUser;
    if (activeBranch == null || activeUser == null) {
      return;
    }
    unawaited(
      _cashController.closeShift(
        branch: activeBranch,
        user: activeUser,
        amounts: amounts,
      ),
    );
    setState(() {
      _isCashDialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final activeTab = _tabManager.activeTab;
    final activeUser = widget.sessionController.activeUser!;
    final activeBranch = widget.sessionController.activeBranch!;
    final activeShift = _cashController.shiftForBranch(activeBranch);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isCompactDesktop = width < 1280;

          return Container(
            color: palette.shell,
            child: Column(
              children: [
                Container(
                  color: palette.shell,
                  child: TopTabBar(
                    tabs: _tabManager.tabs,
                    activeTabId: activeTab.id,
                    headerTitle: _headerTitleFor(activeTab.kind),
                    isSidebarOpen: _isSidebarOpen,
                    onToggleSidebar: _toggleSidebar,
                    onSelect: _tabManager.activate,
                    onReplaceSlot: (slotIndex, kind) {
                      _tabManager.replaceSlot(slotIndex: slotIndex, kind: kind);
                    },
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          width: double.infinity,
                          color: palette.surface,
                          child: Column(
                            children: [
                              if (isCompactDesktop)
                                _DesktopModeBanner(width: width),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 240),
                                  child: _buildWorkspace(activeTab),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isSidebarOpen)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _toggleSidebar,
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        left: _isSidebarOpen ? 0 : -264,
                        top: 0,
                        bottom: 0,
                        child: SideNavigationPanel(
                          activeKind: activeTab.kind,
                          activeUser: activeUser,
                          availableUsers: widget.sessionController.users,
                          onUserSelected: _handleUserSelection,
                          onSignOut: widget.sessionController.signOut,
                          activeBranch: activeBranch,
                          availableBranches: widget.sessionController.branches,
                          showBranchSwitcher: !widget.sessionController.hasSingleBranch,
                          onBranchSelected: _handleBranchSelection,
                          shift: activeShift,
                          onCashAction: _openCashDialog,
                          onSelect: _handleSidebarSelection,
                        ),
                      ),
                      if (_isCashDialogOpen)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _closeCashDialog,
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.16),
                              padding: const EdgeInsets.all(24),
                              child: GestureDetector(
                                onTap: () {},
                                child: CashShiftDialog(
                                  shift: activeShift,
                                  separateCigarettes: _cashController.separateCigarettes,
                                  cigaretteShift: _cashController.cigaretteShiftForBranch(activeBranch),
                                  activeUserName: activeUser.name,
                                  activeBranchName: activeBranch.name,
                                  onCancel: _closeCashDialog,
                                  onConfirmOpen: _confirmOpenCash,
                                  onConfirmClose: _confirmCloseCash,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkspace(WorkspaceTab tab) {
    final activeBranch = widget.sessionController.activeBranch!;
    final activeShift = _cashController.shiftForBranch(activeBranch);

    switch (tab.kind) {
      case WorkspaceKind.home:
        final hasTeam = widget.sessionController.users.where((user) => user.isActive).isNotEmpty;
        return OnboardingHomeScreen(
          key: ValueKey(tab.id),
          businessName: widget.sessionController.hasSingleBranch
              ? activeBranch.name
              : (widget.sessionController.accountName ?? activeBranch.name),
          branchName: activeBranch.name,
          showBranchName: !widget.sessionController.hasSingleBranch,
          hasTeam: hasTeam,
          productCount: _catalogController.products.length,
          hasOpenShift: activeShift.isOpen,
          onRenameBranch: () async {
            final renamed = await _promptForBranchName(
              context,
              currentName: activeBranch.name,
            );
            if (renamed == null || !mounted) {
              return;
            }
            await widget.sessionController.renameActiveBranch(renamed);
          },
          onOpenTeam: () => _tabManager.openWorkspace(WorkspaceKind.users),
          onOpenProducts: () => _tabManager.openWorkspace(WorkspaceKind.products),
          onOpenCash: _openCashDialog,
          onOpenPos: () => _tabManager.openWorkspace(WorkspaceKind.pos),
        );
      case WorkspaceKind.pos:
        return PosScreen(
          key: ValueKey(tab.id),
          shift: activeShift,
          activeUserName: widget.sessionController.activeUser!.name,
          activeBranchName: widget.sessionController.hasSingleBranch
              ? ''
              : widget.sessionController.activeBranch!.name,
          onCashAction: _openCashDialog,
          catalogController: _catalogController,
          salesController: _salesController,
          activeUser: widget.sessionController.activeUser!,
          activeBranch: widget.sessionController.activeBranch!,
          onCheckout: (transaction) {
            _cashController.registerSale(
              branch: widget.sessionController.activeBranch!,
              transaction: transaction,
            );
            unawaited(
              _catalogController.applyTransactionStockReduction(
                items: transaction.items
                    .map(
                      (item) => {
                        'sku': item.sku,
                        'quantity': item.quantity,
                      },
                    )
                    .toList(),
              ),
            );
            unawaited(_providersController.absorbSaleItems(transaction.items));
          },
        );
      case WorkspaceKind.inventory:
        return InventoryScreen(
          key: ValueKey(tab.id),
          catalogController: _catalogController,
        );
      case WorkspaceKind.providers:
        return ProvidersScreen(
          key: ValueKey(tab.id),
          controller: _providersController,
        );
      case WorkspaceKind.reports:
        return ReportsScreen(
          key: ValueKey(tab.id),
          activeBranchName: widget.sessionController.hasSingleBranch
              ? ''
              : widget.sessionController.activeBranch!.name,
          catalogController: _catalogController,
          providersController: _providersController,
          salesController: _salesController,
          cashController: _cashController,
        );
      case WorkspaceKind.users:
        return UsersScreen(
          key: ValueKey(tab.id),
          sessionController: widget.sessionController,
        );
      case WorkspaceKind.branches:
        return BranchesScreen(
          key: ValueKey(tab.id),
          sessionController: widget.sessionController,
        );
      case WorkspaceKind.products:
        return ProductsScreen(
          key: ValueKey(tab.id),
          catalogController: _catalogController,
        );
      case WorkspaceKind.cash:
        return CashManagementScreen(
          key: ValueKey(tab.id),
          cashController: _cashController,
          activeBranch: widget.sessionController.activeBranch!,
          activeUser: widget.sessionController.activeUser!,
          showBranchName: !widget.sessionController.hasSingleBranch,
          onCashAction: _openCashDialog,
        );
      case WorkspaceKind.settings:
        return SettingsScreen(
          key: ValueKey(tab.id),
          sessionController: widget.sessionController,
          catalogController: _catalogController,
          onOpenUsers: () => _tabManager.openWorkspace(WorkspaceKind.users),
          onOpenBranches: () => _tabManager.openWorkspace(WorkspaceKind.branches),
          onRestoreBackup: widget.onRequestAppReload,
          onSignOut: widget.sessionController.signOut,
        );
    }
  }

  String _headerTitleFor(WorkspaceKind kind) {
    switch (kind) {
      case WorkspaceKind.pos:
        return 'Punto de venta';
      case WorkspaceKind.products:
        return 'Mercadería';
      case WorkspaceKind.providers:
        return 'Proveedores';
      case WorkspaceKind.inventory:
        return 'Mercadería';
      case WorkspaceKind.cash:
        return 'Caja';
      case WorkspaceKind.reports:
        return 'Reportes';
      case WorkspaceKind.users:
        return 'Usuarios';
      case WorkspaceKind.branches:
        return 'Sucursales';
      case WorkspaceKind.settings:
        return 'Configuración';
      case WorkspaceKind.home:
        return 'Inicio';
    }
  }

  Future<String?> _promptForBranchName(
    BuildContext context, {
    required String currentName,
  }) {
    final controller = TextEditingController(text: currentName);
    final palette = context.palette;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Nombre del local'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Ej. La Plazoleta Centro',
              filled: true,
              fillColor: palette.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.border),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.shell,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textStrong,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
    required this.danger,
    required this.success,
    required this.warning,
  });

  final Color shell;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textStrong;
  final Color textMuted;
  final Color accent;
  final Color accentSoft;
  final Color danger;
  final Color success;
  final Color warning;

  @override
  AppPalette copyWith({
    Color? shell,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? textStrong,
    Color? textMuted,
    Color? accent,
    Color? accentSoft,
    Color? danger,
    Color? success,
    Color? warning,
  }) {
    return AppPalette(
      shell: shell ?? this.shell,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      textStrong: textStrong ?? this.textStrong,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }

    return AppPalette(
      shell: Color.lerp(shell, other.shell, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      textStrong: Color.lerp(textStrong, other.textStrong, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

class _DesktopScrollBehavior extends MaterialScrollBehavior {
  const _DesktopScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _DesktopModeBanner extends StatelessWidget {
  const _DesktopModeBanner({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Text(
        width < 1100
            ? 'Usá una ventana más ancha para trabajar más cómodo.'
            : 'Modo desktop listo.',
        style: TextStyle(
          color: palette.textStrong,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
