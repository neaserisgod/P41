import 'package:flutter/material.dart';

import '../models/inventory_location.dart';

enum InventoryStep { locations, providers, products }

class InventoryViewModel extends ChangeNotifier {
  InventoryViewModel();

  List<InventoryLocation> _locations = const [];
  InventoryStep _step = InventoryStep.locations;
  String? _selectedLocationId;
  String? _selectedProviderId;

  List<InventoryLocation> get locations => List.unmodifiable(_locations);
  InventoryStep get step => _step;
  InventoryLocation? get selectedLocation {
    for (final location in _locations) {
      if (location.id == _selectedLocationId) {
        return location;
      }
    }
    return null;
  }
  InventoryProvider? get selectedProvider =>
      _selectedProviderFrom(selectedLocation?.providers ?? const []);
  bool get canGoBack => _step != InventoryStep.locations;

  String get title => switch (_step) {
        InventoryStep.locations => 'Inventario',
        InventoryStep.providers => selectedLocation?.name ?? 'Proveedores',
        InventoryStep.products => selectedProvider?.name ?? 'Productos',
      };

  String get subtitle => switch (_step) {
        InventoryStep.locations =>
          'Heladeras y muebles disponibles.',
        InventoryStep.providers =>
          'Proveedores dentro de ${selectedLocation?.name ?? 'la ubicación'}.',
        InventoryStep.products =>
          'Productos del proveedor ${selectedProvider?.name ?? ''}.',
      };

  void updateLocations(List<InventoryLocation> locations) {
    final nextLocations = List<InventoryLocation>.unmodifiable(locations);
    _locations = nextLocations;
    final locationExists = _locations.any((location) => location.id == _selectedLocationId);
    if (!locationExists) {
      _selectedLocationId = null;
      _selectedProviderId = null;
      _step = InventoryStep.locations;
      notifyListeners();
      return;
    }

    final providerExists = selectedLocation?.providers.any((provider) => provider.id == _selectedProviderId) ?? false;
    if (!providerExists) {
      _selectedProviderId = null;
      if (_step == InventoryStep.products) {
        _step = InventoryStep.providers;
      }
    }
    notifyListeners();
  }

  void enterLocation(InventoryLocation location) {
    _selectedLocationId = location.id;
    _selectedProviderId = null;
    _step = InventoryStep.providers;
    notifyListeners();
  }

  void enterProvider(InventoryProvider provider) {
    _selectedProviderId = provider.id;
    _step = InventoryStep.products;
    notifyListeners();
  }

  void goBack() {
    if (_step == InventoryStep.products) {
      _step = InventoryStep.providers;
      _selectedProviderId = null;
      notifyListeners();
      return;
    }

    if (_step == InventoryStep.providers) {
      _step = InventoryStep.locations;
      _selectedLocationId = null;
      _selectedProviderId = null;
      notifyListeners();
    }
  }

  InventoryProvider? _selectedProviderFrom(List<InventoryProvider> providers) {
    for (final provider in providers) {
      if (provider.id == _selectedProviderId) {
        return provider;
      }
    }
    return null;
  }
}
