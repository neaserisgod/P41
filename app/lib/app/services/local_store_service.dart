import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

class LocalStoreService {
  LocalStoreService();

  static const String _appScopeKey = '__app__';
  static const String _offlineOnlySection = 'offline_only';
  static Database? _database;
  static bool _isInitialized = false;

  String get databasePath => _databaseFile.path;

  File get _databaseFile => _horseposFile('p41.sqlite');
  File get _legacyJsonFile => _horseposFile('local_state_v1.json');

  Future<Map<String, dynamic>> readScope(String scopeKey) async {
    final db = await _openDatabase();
    final result = db.select(
      'SELECT section, value_json FROM kv_store WHERE scope_key = ?',
      [scopeKey],
    );
    final scope = <String, dynamic>{};
    for (final row in result) {
      scope[row['section'] as String] = _decodeValue(row['value_json'] as String?);
    }
    return scope;
  }

  Future<dynamic> readSection(String scopeKey, String section) async {
    final db = await _openDatabase();
    final result = db.select(
      'SELECT value_json FROM kv_store WHERE scope_key = ? AND section = ? LIMIT 1',
      [scopeKey, section],
    );
    if (result.isEmpty) {
      return null;
    }
    return _decodeValue(result.first['value_json'] as String?);
  }

  Future<void> writeSection(
    String scopeKey,
    String section,
    dynamic value,
  ) async {
    final db = await _openDatabase();
    db.execute(
      '''
      INSERT INTO kv_store(scope_key, section, value_json)
      VALUES(?, ?, ?)
      ON CONFLICT(scope_key, section) DO UPDATE SET value_json = excluded.value_json
      ''',
      [scopeKey, section, jsonEncode(value)],
    );
  }

  Future<void> mergeScope(
    String scopeKey,
    Map<String, dynamic> values,
  ) async {
    final db = await _openDatabase();
    db.execute('BEGIN');
    try {
      for (final entry in values.entries) {
        db.execute(
          '''
          INSERT INTO kv_store(scope_key, section, value_json)
          VALUES(?, ?, ?)
          ON CONFLICT(scope_key, section) DO UPDATE SET value_json = excluded.value_json
          ''',
          [scopeKey, entry.key, jsonEncode(entry.value)],
        );
      }
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> deleteScope(String scopeKey) async {
    final db = await _openDatabase();
    db.execute('DELETE FROM kv_store WHERE scope_key = ?', [scopeKey]);
  }

  Future<bool> isOfflineOnly() async {
    return true;
  }

  Future<void> setOfflineOnly(bool value) {
    return writeSection(_appScopeKey, _offlineOnlySection, true);
  }

  Future<List<Map<String, String>>> listRememberedAccounts() async {
    final db = await _openDatabase();
    final rows = db.select(
      '''
      SELECT scope_key, owner_email, account_name
      FROM session_accounts
      ORDER BY account_name COLLATE NOCASE
      ''',
    );

    final remembered = <Map<String, String>>[];
    for (final row in rows) {
      final scopeKey = row['scope_key']?.toString() ?? '';
      final email = row['owner_email']?.toString().trim() ?? '';
      if (scopeKey.isEmpty || email.isEmpty) {
        continue;
      }
      remembered.add({
        'scope_key': scopeKey,
        'email': email,
        'account_name': row['account_name']?.toString().trim().isNotEmpty == true
            ? row['account_name']!.toString().trim()
            : 'Cuenta local',
      });
    }
    remembered.sort((a, b) => a['account_name']!.compareTo(b['account_name']!));
    return remembered;
  }

  Future<void> saveSessionSnapshot({
    required String scopeKey,
    required String ownerEmail,
    required String accountName,
    required String password,
    required String accessToken,
    required String? businessId,
    required List<Map<String, dynamic>> users,
    required List<Map<String, dynamic>> branches,
  }) async {
    final db = await _openDatabase();
    db.execute('BEGIN');
    try {
      db.execute(
        '''
        INSERT INTO session_accounts(scope_key, owner_email, account_name, local_password, access_token, business_id)
        VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(scope_key) DO UPDATE SET
          owner_email = excluded.owner_email,
          account_name = excluded.account_name,
          local_password = excluded.local_password,
          access_token = excluded.access_token,
          business_id = excluded.business_id
        ''',
        [scopeKey, ownerEmail, accountName, password, accessToken, businessId],
      );
      db.execute('DELETE FROM session_users WHERE scope_key = ?', [scopeKey]);
      db.execute('DELETE FROM session_branches WHERE scope_key = ?', [scopeKey]);

      for (final user in users) {
        db.execute(
          '''
          INSERT INTO session_users(
            scope_key, user_id, name, role, initials, branch_ids_json, pin, is_active
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            scopeKey,
            user['id']?.toString() ?? '',
            user['name']?.toString() ?? '',
            user['role']?.toString() ?? '',
            user['initials']?.toString() ?? '',
            jsonEncode(user['branch_ids'] ?? const []),
            user['pin']?.toString(),
            _boolInt(user['is_active']),
          ],
        );
      }

      for (final branch in branches) {
        db.execute(
          '''
          INSERT INTO session_branches(scope_key, branch_id, name, label, is_active)
          VALUES (?, ?, ?, ?, ?)
          ''',
          [
            scopeKey,
            branch['id']?.toString() ?? '',
            branch['name']?.toString() ?? '',
            branch['label']?.toString() ?? '',
            _boolInt(branch['is_active']),
          ],
        );
      }

      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> readSessionSnapshot(String scopeKey) async {
    final db = await _openDatabase();
    final accountRows = db.select(
      '''
      SELECT owner_email, account_name, access_token, business_id
      , local_password
      FROM session_accounts WHERE scope_key = ? LIMIT 1
      ''',
      [scopeKey],
    );
    if (accountRows.isEmpty) {
      return null;
    }

    final userRows = db.select(
      '''
      SELECT user_id, name, role, initials, branch_ids_json, pin, is_active
      FROM session_users WHERE scope_key = ? ORDER BY name COLLATE NOCASE
      ''',
      [scopeKey],
    );
    final branchRows = db.select(
      '''
      SELECT branch_id, name, label, is_active
      FROM session_branches WHERE scope_key = ? ORDER BY name COLLATE NOCASE
      ''',
      [scopeKey],
    );

    final account = accountRows.first;
    return {
      'access_token': account['access_token']?.toString() ?? 'offline-local',
      'business_id': account['business_id']?.toString(),
      'account': {
        'account_name': account['account_name']?.toString() ?? 'P41',
        'owner_email': account['owner_email']?.toString() ?? scopeKey,
        'password': account['local_password']?.toString() ?? '',
      },
      'users': userRows
          .map(
            (row) => {
              'id': row['user_id'],
              'name': row['name'],
              'role': row['role'],
              'initials': row['initials'],
              'branch_ids': _decodeDynamic(row['branch_ids_json'] as String?) ?? const [],
              'pin': row['pin'],
              'is_active': (row['is_active'] as int? ?? 1) == 1,
            },
          )
          .toList(),
      'branches': branchRows
          .map(
            (row) => {
              'id': row['branch_id'],
              'name': row['name'],
              'label': row['label'],
              'is_active': (row['is_active'] as int? ?? 1) == 1,
            },
          )
          .toList(),
    };
  }

  Future<Map<String, dynamic>?> loadPersistedSession() async {
    final value = await readSection(_appScopeKey, 'persisted_session');
    if (value is Map<String, dynamic>) {
      return value;
    }
    final db = await _openDatabase();
    final rows = db.select(
      'SELECT email, password, branch_id, user_id FROM persisted_session LIMIT 1',
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.first;
    return {
      'email': row['email'],
      'branch_id': row['branch_id'],
      'user_id': row['user_id'],
    };
  }

  Future<void> savePersistedSession(Map<String, dynamic> session) async {
    final db = await _openDatabase();
    db.execute('DELETE FROM persisted_session');
    db.execute(
      '''
      INSERT INTO persisted_session(email, password, branch_id, user_id)
      VALUES (?, ?, ?, ?)
      ''',
      [
        session['email']?.toString() ?? '',
        '',
        session['branch_id']?.toString(),
        session['user_id']?.toString(),
      ],
    );
  }

  Future<void> clearPersistedSession() async {
    final db = await _openDatabase();
    db.execute('DELETE FROM persisted_session');
  }

  Future<void> exportDatabase(String destinationPath) async {
    final db = await _openDatabase();
    db.execute("VACUUM INTO '${_escapeSqlPath(destinationPath)}'");
  }

  Future<void> restoreDatabase(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw StateError('Backup no encontrado');
    }

    _database?.dispose();
    _database = null;
    _isInitialized = false;

    final destination = _databaseFile;
    final directory = destination.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    if (await destination.exists()) {
      await destination.delete();
    }
    await sourceFile.copy(destination.path);
  }

  Future<void> saveCatalogSnapshot({
    required String scopeKey,
    required String branchId,
    required List<Map<String, dynamic>> products,
    required Map<String, String> suppliersById,
    required List<Map<String, dynamic>> inventorySpaces,
  }) async {
    final db = await _openDatabase();
    db.execute('BEGIN');
    try {
      db.execute(
        'DELETE FROM catalog_products WHERE scope_key = ? AND branch_id = ?',
        [scopeKey, branchId],
      );
      db.execute(
        'DELETE FROM catalog_inventory_spaces WHERE scope_key = ? AND branch_id = ?',
        [scopeKey, branchId],
      );
      db.execute(
        'DELETE FROM catalog_supplier_refs WHERE scope_key = ?',
        [scopeKey],
      );

      for (final product in products) {
        db.execute(
          '''
          INSERT INTO catalog_products(
            scope_key, branch_id, product_id, name, sku, barcode, category,
            supplier_id, supplier_name, location_id, location_name, location_type,
            image_url, price, cost, stock, min_stock, expiration_date, is_active
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            scopeKey,
            branchId,
            product['id']?.toString() ?? '',
            product['name']?.toString() ?? '',
            product['sku']?.toString() ?? '',
            product['barcode']?.toString() ?? '',
            product['category']?.toString() ?? '',
            product['supplier_id']?.toString() ?? '',
            product['supplier_name']?.toString() ?? '',
            product['location_id']?.toString() ?? '',
            product['location_name']?.toString() ?? '',
            product['location_type']?.toString() ?? '',
            product['image_url']?.toString() ?? '',
            _doubleValue(product['price']),
            _doubleValue(product['cost']),
            _intValue(product['stock']),
            _intValue(product['min_stock']),
            product['expiration_date']?.toString(),
            _boolInt(product['is_active']),
          ],
        );
      }

      for (final entry in suppliersById.entries) {
        db.execute(
          '''
          INSERT INTO catalog_supplier_refs(scope_key, supplier_id, supplier_name)
          VALUES (?, ?, ?)
          ''',
          [scopeKey, entry.key, entry.value],
        );
      }

      for (final location in inventorySpaces) {
        db.execute(
          '''
          INSERT INTO catalog_inventory_spaces(scope_key, branch_id, location_id, name, type)
          VALUES (?, ?, ?, ?, ?)
          ''',
          [
            scopeKey,
            branchId,
            location['id']?.toString() ?? '',
            location['name']?.toString() ?? '',
            location['type']?.toString() ?? '',
          ],
        );
      }
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> saveCatalogSupplierRefs({
    required String scopeKey,
    required Map<String, String> suppliersById,
  }) async {
    final db = await _openDatabase();
    db.execute('BEGIN');
    try {
      db.execute(
        'DELETE FROM catalog_supplier_refs WHERE scope_key = ?',
        [scopeKey],
      );
      for (final entry in suppliersById.entries) {
        db.execute(
          '''
          INSERT INTO catalog_supplier_refs(scope_key, supplier_id, supplier_name)
          VALUES (?, ?, ?)
          ''',
          [scopeKey, entry.key, entry.value],
        );
      }
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> readCatalogSnapshot({
    required String scopeKey,
    required String branchId,
  }) async {
    final db = await _openDatabase();
    final products = db.select(
      '''
      SELECT product_id, name, sku, barcode, category, supplier_id, supplier_name,
             location_id, location_name, location_type, image_url, price, cost,
             stock, min_stock, expiration_date, is_active
      FROM catalog_products
      WHERE scope_key = ? AND branch_id = ?
      ORDER BY name COLLATE NOCASE
      ''',
      [scopeKey, branchId],
    );
    if (products.isEmpty) {
      return null;
    }

    final suppliers = db.select(
      'SELECT supplier_id, supplier_name FROM catalog_supplier_refs WHERE scope_key = ?',
      [scopeKey],
    );
    final spaces = db.select(
      '''
      SELECT location_id, name, type
      FROM catalog_inventory_spaces
      WHERE scope_key = ? AND branch_id = ?
      ORDER BY type COLLATE NOCASE, name COLLATE NOCASE
      ''',
      [scopeKey, branchId],
    );

    return {
      'products': products
          .map(
            (row) => {
              'id': row['product_id'],
              'name': row['name'],
              'sku': row['sku'],
              'barcode': row['barcode'],
              'category': row['category'],
              'supplier_id': row['supplier_id'],
              'supplier_name': row['supplier_name'],
              'location_id': row['location_id'],
              'location_name': row['location_name'],
              'location_type': row['location_type'],
              'image_url': row['image_url'],
              'price': row['price'],
              'cost': row['cost'],
              'stock': row['stock'],
              'min_stock': row['min_stock'],
              'expiration_date': row['expiration_date'],
              'is_active': (row['is_active'] as int? ?? 1) == 1,
            },
          )
          .toList(),
      'suppliers': {
        for (final row in suppliers) row['supplier_id'].toString(): row['supplier_name'].toString(),
      },
      'inventory_spaces': spaces
          .map(
            (row) => {
              'id': row['location_id'],
              'name': row['name'],
              'type': row['type'],
            },
          )
          .toList(),
    };
  }

  Future<void> saveProvidersSnapshot({
    required String scopeKey,
    required String branchId,
    required List<Map<String, dynamic>> providers,
    required List<Map<String, dynamic>> orders,
    required Map<String, List<Map<String, dynamic>>> draftsByProvider,
  }) async {
    final db = await _openDatabase();
    db.execute('BEGIN');
    try {
      db.execute('DELETE FROM provider_records WHERE scope_key = ? AND branch_id = ?', [scopeKey, branchId]);
      db.execute('DELETE FROM provider_orders WHERE scope_key = ? AND branch_id = ?', [scopeKey, branchId]);
      db.execute('DELETE FROM provider_drafts WHERE scope_key = ? AND branch_id = ?', [scopeKey, branchId]);

      for (final provider in providers) {
        db.execute(
          '''
          INSERT INTO provider_records(
            scope_key, branch_id, provider_id, name, contact, phone, email, category,
            is_active, order_days_json, delivery_days_json
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            scopeKey,
            branchId,
            provider['id']?.toString() ?? '',
            provider['name']?.toString() ?? '',
            provider['contact']?.toString() ?? '',
            provider['phone']?.toString() ?? '',
            provider['email']?.toString() ?? '',
            provider['category']?.toString() ?? '',
            _boolInt(provider['is_active']),
            jsonEncode(provider['order_days'] ?? const []),
            jsonEncode(provider['delivery_days'] ?? const []),
          ],
        );
      }

      for (final order in orders) {
        db.execute(
          '''
          INSERT INTO provider_orders(
            scope_key, branch_id, order_id, provider_id, date_label, created_at, status, total, items_json
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            scopeKey,
            branchId,
            order['id']?.toString() ?? '',
            order['provider_id']?.toString() ?? '',
            order['date_label']?.toString() ?? '',
            order['created_at']?.toString(),
            order['status']?.toString() ?? '',
            _doubleValue(order['total']),
            jsonEncode(order['items'] ?? const []),
          ],
        );
      }

      for (final entry in draftsByProvider.entries) {
        for (final item in entry.value) {
          db.execute(
            '''
            INSERT INTO provider_drafts(
              scope_key, branch_id, provider_id, item_id, product_id, name, pack, price, quantity
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              scopeKey,
              branchId,
              entry.key,
              item['item_id']?.toString() ?? '',
              item['product_id']?.toString() ?? '',
              item['name']?.toString() ?? '',
              item['pack']?.toString() ?? '',
              _doubleValue(item['price']),
              _intValue(item['quantity']),
            ],
          );
        }
      }

      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> readProvidersSnapshot({
    required String scopeKey,
    required String branchId,
  }) async {
    final db = await _openDatabase();
    final providers = db.select(
      '''
      SELECT provider_id, name, contact, phone, email, category, is_active, order_days_json, delivery_days_json
      FROM provider_records WHERE scope_key = ? AND branch_id = ? ORDER BY name COLLATE NOCASE
      ''',
      [scopeKey, branchId],
    );
    if (providers.isEmpty) {
      return null;
    }
    final orders = db.select(
      '''
      SELECT order_id, provider_id, date_label, created_at, status, total, items_json
      FROM provider_orders WHERE scope_key = ? AND branch_id = ? ORDER BY created_at
      ''',
      [scopeKey, branchId],
    );
    final drafts = db.select(
      '''
      SELECT provider_id, item_id, product_id, name, pack, price, quantity
      FROM provider_drafts WHERE scope_key = ? AND branch_id = ? ORDER BY provider_id, name COLLATE NOCASE
      ''',
      [scopeKey, branchId],
    );

    final draftsByProvider = <String, List<Map<String, dynamic>>>{};
    for (final row in drafts) {
      final providerId = row['provider_id'].toString();
      draftsByProvider.putIfAbsent(providerId, () => []);
      draftsByProvider[providerId]!.add({
        'item_id': row['item_id'],
        'product_id': row['product_id'],
        'name': row['name'],
        'pack': row['pack'],
        'price': row['price'],
        'quantity': row['quantity'],
      });
    }

    return {
      'providers': providers
          .map(
            (row) => {
              'id': row['provider_id'],
              'name': row['name'],
              'contact': row['contact'],
              'phone': row['phone'],
              'email': row['email'],
              'category': row['category'],
              'is_active': (row['is_active'] as int? ?? 1) == 1,
              'order_days': _decodeList(row['order_days_json'] as String?),
              'delivery_days': _decodeList(row['delivery_days_json'] as String?),
            },
          )
          .toList(),
      'orders': orders
          .map(
            (row) => {
              'id': row['order_id'],
              'provider_id': row['provider_id'],
              'date_label': row['date_label'],
              'created_at': row['created_at'],
              'status': row['status'],
              'total': row['total'],
              'items': _decodeDynamic(row['items_json'] as String?) ?? const [],
            },
          )
          .toList(),
      'drafts': draftsByProvider,
    };
  }

  Future<void> saveCashSnapshot({
    required String scopeKey,
    required String branchId,
    required List<Map<String, dynamic>> shifts,
  }) async {
    final db = await _openDatabase();
    db.execute('DELETE FROM cash_shifts WHERE scope_key = ? AND branch_id = ?', [scopeKey, branchId]);
    for (final shift in shifts) {
      db.execute(
        '''
        INSERT INTO cash_shifts(
          scope_key, branch_id, shift_id, branch_name, register_name, status,
          opened_by, opened_at_label, opening_amount, expected_amount,
          counted_amount, closed_at_label, closed_by
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          scopeKey,
          branchId,
          shift['id']?.toString() ?? '',
          shift['branch_name']?.toString() ?? '',
          shift['register_name']?.toString() ?? 'Caja',
          shift['status']?.toString() ?? 'closed',
          shift['opened_by']?.toString(),
          shift['opened_at_label']?.toString(),
          _nullableDouble(shift['opening_amount']),
          _nullableDouble(shift['expected_amount']),
          _nullableDouble(shift['counted_amount']),
          shift['closed_at_label']?.toString(),
          shift['closed_by']?.toString(),
        ],
      );
    }
  }

  Future<List<Map<String, dynamic>>?> readCashSnapshot({
    required String scopeKey,
    required String branchId,
  }) async {
    final rows = (await _openDatabase()).select(
      '''
      SELECT shift_id, branch_id, branch_name, register_name, status, opened_by, opened_at_label,
             opening_amount, expected_amount, counted_amount, closed_at_label, closed_by
      FROM cash_shifts WHERE scope_key = ? AND branch_id = ? ORDER BY rowid
      ''',
      [scopeKey, branchId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows
        .map(
          (row) => {
            'id': row['shift_id'],
            'branch_id': row['branch_id'],
            'branch_name': row['branch_name'],
            'register_name': row['register_name'],
            'status': row['status'],
            'opened_by': row['opened_by'],
            'opened_at_label': row['opened_at_label'],
            'opening_amount': row['opening_amount'],
            'expected_amount': row['expected_amount'],
            'counted_amount': row['counted_amount'],
            'closed_at_label': row['closed_at_label'],
            'closed_by': row['closed_by'],
          },
        )
        .toList();
  }

  Future<void> saveSalesSnapshot({
    required String scopeKey,
    required String branchId,
    required List<Map<String, dynamic>> transactions,
  }) async {
    final db = await _openDatabase();
    db.execute('DELETE FROM sales_transactions WHERE scope_key = ? AND branch_id = ?', [scopeKey, branchId]);
    for (final transaction in transactions) {
      db.execute(
        '''
        INSERT INTO sales_transactions(
          scope_key, branch_id, transaction_id, time_label, occurred_at, cashier,
          branch_name, payment_method, total, item_count, items_json
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          scopeKey,
          branchId,
          transaction['id']?.toString() ?? '',
          transaction['time_label']?.toString() ?? '',
          transaction['occurred_at']?.toString(),
          transaction['cashier']?.toString() ?? '',
          transaction['branch_name']?.toString() ?? '',
          transaction['payment_method']?.toString() ?? '',
          _doubleValue(transaction['total']),
          _intValue(transaction['item_count']),
          jsonEncode(transaction['items'] ?? const []),
        ],
      );
    }
  }

  Future<List<Map<String, dynamic>>?> readSalesSnapshot({
    required String scopeKey,
    required String branchId,
  }) async {
    final rows = (await _openDatabase()).select(
      '''
      SELECT transaction_id, time_label, occurred_at, cashier, branch_id, branch_name,
             payment_method, total, item_count, items_json
      FROM sales_transactions WHERE scope_key = ? AND branch_id = ? ORDER BY occurred_at
      ''',
      [scopeKey, branchId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows
        .map(
          (row) => {
            'id': row['transaction_id'],
            'time_label': row['time_label'],
            'occurred_at': row['occurred_at'],
            'cashier': row['cashier'],
            'branch_id': row['branch_id'],
            'branch_name': row['branch_name'],
            'payment_method': row['payment_method'],
            'total': row['total'],
            'item_count': row['item_count'],
            'items': _decodeDynamic(row['items_json'] as String?) ?? const [],
          },
        )
        .toList();
  }

  Future<Database> _openDatabase() async {
    if (_database != null) {
      return _database!;
    }

    final file = _databaseFile;
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    _database = sqlite3.open(file.path);
    if (!_isInitialized) {
      _initializeSchema(_database!);
      await _migrateLegacyJsonIfNeeded(_database!);
      _isInitialized = true;
    }
    return _database!;
  }

  void _initializeSchema(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS kv_store (
        scope_key TEXT NOT NULL,
        section TEXT NOT NULL,
        value_json TEXT NOT NULL,
        PRIMARY KEY (scope_key, section)
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS catalog_products (
        scope_key TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        name TEXT NOT NULL,
        sku TEXT NOT NULL,
        barcode TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL,
        supplier_id TEXT NOT NULL,
        supplier_name TEXT NOT NULL,
        location_id TEXT NOT NULL,
        location_name TEXT NOT NULL,
        location_type TEXT NOT NULL,
        image_url TEXT NOT NULL DEFAULT '',
        price REAL NOT NULL,
        cost REAL NOT NULL,
        stock INTEGER NOT NULL,
        min_stock INTEGER NOT NULL,
        expiration_date TEXT,
        is_active INTEGER NOT NULL,
        PRIMARY KEY (scope_key, branch_id, product_id)
      )
    ''');
    _ensureCatalogProductColumns(db);
    db.execute('''
      CREATE TABLE IF NOT EXISTS catalog_supplier_refs (
        scope_key TEXT NOT NULL,
        supplier_id TEXT NOT NULL,
        supplier_name TEXT NOT NULL,
        PRIMARY KEY (scope_key, supplier_id)
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS catalog_inventory_spaces (
        scope_key TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        location_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        PRIMARY KEY (scope_key, branch_id, location_id)
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS provider_records (
        scope_key TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        provider_id TEXT NOT NULL,
        name TEXT NOT NULL,
        contact TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        category TEXT NOT NULL,
        is_active INTEGER NOT NULL,
        order_days_json TEXT NOT NULL,
        delivery_days_json TEXT NOT NULL,
        PRIMARY KEY (scope_key, branch_id, provider_id)
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS provider_orders (
        scope_key TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        order_id TEXT NOT NULL,
        provider_id TEXT NOT NULL,
        date_label TEXT NOT NULL,
        created_at TEXT,
        status TEXT NOT NULL,
        total REAL NOT NULL,
        items_json TEXT NOT NULL,
        PRIMARY KEY (scope_key, branch_id, order_id)
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS provider_drafts (
        scope_key TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        provider_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        name TEXT NOT NULL,
        pack TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        PRIMARY KEY (scope_key, branch_id, provider_id, item_id)
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS cash_shifts (
        scope_key TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        shift_id TEXT NOT NULL,
        branch_name TEXT NOT NULL,
        register_name TEXT NOT NULL,
        status TEXT NOT NULL,
        opened_by TEXT,
        opened_at_label TEXT,
        opening_amount REAL,
        expected_amount REAL,
        counted_amount REAL,
        closed_at_label TEXT,
        closed_by TEXT,
        PRIMARY KEY (scope_key, branch_id, shift_id)
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS sales_transactions (
        scope_key TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        transaction_id TEXT NOT NULL,
        time_label TEXT NOT NULL,
        occurred_at TEXT,
        cashier TEXT NOT NULL,
        branch_name TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        total REAL NOT NULL,
        item_count INTEGER NOT NULL,
        items_json TEXT NOT NULL,
        PRIMARY KEY (scope_key, branch_id, transaction_id)
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS session_accounts (
        scope_key TEXT PRIMARY KEY,
        owner_email TEXT NOT NULL,
        account_name TEXT NOT NULL,
        local_password TEXT NOT NULL DEFAULT '',
        access_token TEXT NOT NULL,
        business_id TEXT
      )
    ''');
    _ensureSessionAccountColumns(db);
    db.execute('''
      CREATE TABLE IF NOT EXISTS session_users (
        scope_key TEXT NOT NULL,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        initials TEXT NOT NULL,
        branch_ids_json TEXT NOT NULL,
        pin TEXT,
        is_active INTEGER NOT NULL,
        PRIMARY KEY (scope_key, user_id)
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS session_branches (
        scope_key TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        name TEXT NOT NULL,
        label TEXT NOT NULL,
        is_active INTEGER NOT NULL,
        PRIMARY KEY (scope_key, branch_id)
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS persisted_session (
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        branch_id TEXT,
        user_id TEXT
      )
    ''');
  }

  void _ensureSessionAccountColumns(Database db) {
    final rows = db.select("PRAGMA table_info('session_accounts')");
    final names = rows
        .map((row) => row['name']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet();
    if (!names.contains('local_password')) {
      db.execute("ALTER TABLE session_accounts ADD COLUMN local_password TEXT NOT NULL DEFAULT ''");
    }
  }

  void _ensureCatalogProductColumns(Database db) {
    final rows = db.select("PRAGMA table_info('catalog_products')");
    final names = rows
        .map((row) => row['name']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet();
    if (!names.contains('barcode')) {
      db.execute("ALTER TABLE catalog_products ADD COLUMN barcode TEXT NOT NULL DEFAULT ''");
    }
    if (!names.contains('image_url')) {
      db.execute("ALTER TABLE catalog_products ADD COLUMN image_url TEXT NOT NULL DEFAULT ''");
    }
  }

  Future<void> _migrateLegacyJsonIfNeeded(Database db) async {
    final countResult = db.select('SELECT COUNT(*) AS total FROM kv_store');
    final existingCount = (countResult.first['total'] as int?) ?? 0;
    if (existingCount > 0 || !await _legacyJsonFile.exists()) {
      return;
    }

    try {
      final raw = await _legacyJsonFile.readAsString();
      if (raw.trim().isEmpty) {
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final scopes = decoded['scopes'];
      if (scopes is! Map<String, dynamic>) {
        return;
      }

      db.execute('BEGIN');
      try {
        for (final scopeEntry in scopes.entries) {
          final scopeValue = scopeEntry.value;
          if (scopeValue is! Map<String, dynamic>) {
            continue;
          }
          for (final sectionEntry in scopeValue.entries) {
            db.execute(
              '''
              INSERT INTO kv_store(scope_key, section, value_json)
              VALUES(?, ?, ?)
              ON CONFLICT(scope_key, section) DO UPDATE SET value_json = excluded.value_json
              ''',
              [scopeEntry.key, sectionEntry.key, jsonEncode(sectionEntry.value)],
            );
          }
        }
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    } catch (_) {
      // Preserve startup even if legacy migration is malformed.
    }
  }

  dynamic _decodeValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  dynamic _decodeDynamic(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  List<int> _decodeList(String? raw) {
    final decoded = _decodeDynamic(raw);
    if (decoded is! List<dynamic>) {
      return const [];
    }
    return decoded.whereType<num>().map((value) => value.toInt()).toList();
  }

  int _boolInt(dynamic value) {
    if (value is bool) {
      return value ? 1 : 0;
    }
    if (value is num) {
      return value == 0 ? 0 : 1;
    }
    return 1;
  }

  double _doubleValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double? _nullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  int _intValue(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  File _horseposFile(String name) {
    final home = Platform.environment['HOME'] ?? '.';
    return File('$home/.p41/$name');
  }

  String _escapeSqlPath(String path) {
    return path.replaceAll("'", "''");
  }
}
