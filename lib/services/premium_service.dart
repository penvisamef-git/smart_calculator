import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/constants.dart';

enum PurchaseUiState {
  idle,
  buying,
  restoring,
  success,
  failed,
  nothingToRestore,
  storeUnavailable,
}

/// The one-time $0.99 Premium unlock (non-consumable in-app purchase).
///
/// Premium removes ads, keeps history forever and allows unlimited sharing.
/// The result is saved on the phone; "Restore purchase" gets it back after a
/// reinstall or on a new phone with the same store account.
class PremiumService extends ChangeNotifier {
  PremiumService(this._box) {
    _isPremium = _box.get('isPremium', defaultValue: false) as bool;
  }

  final Box _box;
  // Lazy: the store connection starts only when init() runs.
  InAppPurchase get _iap => InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  late bool _isPremium;
  ProductDetails? _product;
  PurchaseUiState _state = PurchaseUiState.idle;
  bool _storeAvailable = false;

  bool get isPremium => _isPremium;
  PurchaseUiState get state => _state;

  /// Price from the store in the user's currency, e.g. "$0.99" or "4,000 ៛".
  String get price => _product?.price ?? r'$0.99';

  Future<void> init() async {
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        debugPrint('Purchase stream error: $e');
      },
    );
    _storeAvailable = await _iap.isAvailable();
    if (!_storeAvailable) return;

    final resp = await _iap.queryProductDetails({AppConfig.premiumProductId});
    if (resp.productDetails.isNotEmpty) {
      _product = resp.productDetails.first;
      notifyListeners();
    } else {
      debugPrint(
        'Product "${AppConfig.premiumProductId}" not found in the store yet. '
        'Create it in Play Console / App Store Connect.',
      );
    }

    // Android restores silently, so we can re-check on every start.
    // (On iOS this could ask for the Apple ID password, so we only do it
    // when the user taps "Restore purchase".)
    if (!_isPremium && Platform.isAndroid) {
      await _iap.restorePurchases();
    }
  }

  Future<void> buy() async {
    if (!_storeAvailable || _product == null) {
      _setState(PurchaseUiState.storeUnavailable);
      return;
    }
    _setState(PurchaseUiState.buying);
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: _product!),
      );
    } catch (e) {
      debugPrint('buy error: $e');
      _setState(PurchaseUiState.failed);
    }
  }

  Future<void> restore() async {
    if (!_storeAvailable) {
      _setState(PurchaseUiState.storeUnavailable);
      return;
    }
    _setState(PurchaseUiState.restoring);
    await _iap.restorePurchases();
    // If the store returns nothing, no event arrives. Give it a few seconds.
    Future.delayed(const Duration(seconds: 6), () {
      if (_state == PurchaseUiState.restoring) {
        _setState(PurchaseUiState.nothingToRestore);
      }
    });
  }

  void clearState() => _setState(PurchaseUiState.idle);

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != AppConfig.premiumProductId) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // For a $0.99 unlock we trust the store result on the device.
          // For extra safety you can verify `p.verificationData` on a server.
          await _unlock();
          break;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          if (_state == PurchaseUiState.buying) {
            _setState(PurchaseUiState.failed);
          }
          break;
        case PurchaseStatus.pending:
          break;
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  Future<void> _unlock() async {
    final wasUserAction =
        _state == PurchaseUiState.buying || _state == PurchaseUiState.restoring;
    _isPremium = true;
    await _box.put('isPremium', true);
    _state = wasUserAction ? PurchaseUiState.success : _state;
    notifyListeners();
  }

  void _setState(PurchaseUiState s) {
    _state = s;
    notifyListeners();
  }

  /// For testing on a debug build only.
  @visibleForTesting
  Future<void> debugSetPremium(bool v) async {
    _isPremium = v;
    await _box.put('isPremium', v);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
