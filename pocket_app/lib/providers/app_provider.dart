import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService api = ApiService();

  Map<String, dynamic>? user;
  Map<String, dynamic>? homeStats;
  bool loading = false;
  String? error;
  List<dynamic> notifications = [];
  List<dynamic> transactions = [];
  List<dynamic> giftCards = [];
  List<dynamic> pointsHistory = [];
  Map<String, dynamic>? vivaLine;
  List<dynamic> insights = [];
  Map<String, dynamic>? mascota;

  bool get isLoggedIn => api.token != null;
  bool get easyMode => user?['easy_mode'] == true;
  int get kycLevel => (user?['kyc_level'] as num?)?.toInt() ?? 0;
  bool isNewUser = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      api.setToken(token);
      await refreshProfile();
    }
  }

  Future<void> _saveToken(String token) async {
    api.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  void _applyUser(Map<String, dynamic>? data) {
    if (data != null) user = Map<String, dynamic>.from(data);
  }

  Future<void> logout() async {
    api.setToken(null);
    user = null;
    homeStats = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  Future<Map<String, dynamic>?> vivaPrefill(String phone) async {
    return await api.get('/api/auth/viva-prefill/$phone') as Map<String, dynamic>?;
  }

  Future<bool> register({
    required String phone,
    required String pin,
    String? fullName,
    String? ci,
    bool vivaLinked = false,
    bool vivaLineActive = false,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await api.post('/api/auth/register', {
        'phone': phone,
        'pin': pin,
        'full_name': fullName,
        'ci': ci,
        'viva_linked': vivaLinked || vivaLineActive,
      });
      await _saveToken(res['token']);
      _applyUser(res['user']);
      isNewUser = true; // marca para mostrar el tour
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String phone, String pin) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await api.post('/api/auth/login', {'phone': phone, 'pin': pin});
      await _saveToken(res['token']);
      _applyUser(res['user']);
      loading = false;
      await refreshProfile();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final res = await api.get('/api/me/home');
      _applyUser(res);
      homeStats = {
        'proximo_premio': res['proximo_premio'],
        'stats_mes': res['stats_mes'],
      };
      await loadInsights();
      await loadMascota();
      notifyListeners();
    } catch (_) {
      try {
        _applyUser(Map<String, dynamic>.from(await api.get('/api/auth/me')));
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> loadInsights() async {
    try {
      final res = await api.get('/api/insights');
      insights = res['insights'] as List<dynamic>? ?? [];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadMascota() async {
    try {
      mascota = Map<String, dynamic>.from(await api.get('/api/mascota'));
      notifyListeners();
    } catch (_) {}
  }

  Future<String?> tataChat(String message) async {
    final res = await api.post('/api/tata/chat', {'message': message});
    return res['reply'] as String?;
  }

  Future<void> tataReset() async {
    try {
      await api.post('/api/tata/reset', {});
    } catch (_) {}
  }

  /// Cash-in QR: el usuario paga Bs y recibe $VIVA al tipo de cambio demo.
  Future<bool> walletDeposit(double amount) async {
    try {
      final res = await api.post('/api/wallet/deposit', {'monto': amount});
      _applyUser(res['user']);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> upgradeKyc(int level) async {
    try {
      final res = await api.post('/api/auth/upgrade-kyc', {'level': level});
      _applyUser(res['user']);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> kycUpgrade() async {
    try {
      final res = await api.post('/api/me/kyc-upgrade', {});
      _applyUser(res['user']);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> activateCard() async {
    try {
      final res = await api.post('/api/card/activate');
      _applyUser(res['user']);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> pay({
    required double amount,
    required String type,
    String? merchant,
  }) async {
    try {
      final res = await api.post('/api/transactions/pay', {
        'amount': amount,
        'type': type,
        'merchant': merchant,
      });
      _applyUser(res['user']);
      await loadTransactions();
      if (res['notification'] != null) {
        notifications.insert(0, res['notification']);
      }
      await loadInsights();
      await loadMascota();
      notifyListeners();
      return Map<String, dynamic>.from(res);
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> loadCardFromWallet(double amount) async {
    try {
      final res = await api.post('/api/card/load', {'monto': amount});
      _applyUser(res['user']);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> loadTransactions() async {
    final res = await api.get('/api/transactions/history');
    transactions = res is Map ? (res['items'] as List<dynamic>? ?? []) : res as List<dynamic>;
    notifyListeners();
  }

  Future<void> loadGiftCards() async {
    giftCards = await api.get('/api/points/gift-cards/catalog') as List<dynamic>;
    notifyListeners();
  }

  Future<void> loadPointsHistory() async {
    pointsHistory = await api.get('/api/points/log') as List<dynamic>;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> redeemGiftCard(String id) async {
    try {
      final res = await api.post('/api/points/gift-cards/redeem', {'gift_card_id': id});
      _applyUser(res['user']);
      await loadPointsHistory();
      return Map<String, dynamic>.from(res);
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> linkViva(String phone) async {
    try {
      final res = await api.post('/api/me/vincular-viva', {'numero_linea': phone});
      _applyUser(res['user']);
      await loadVivaLine();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> loadVivaLine() async {
    vivaLine = Map<String, dynamic>.from(await api.get('/api/viva/line'));
    notifyListeners();
  }

  Future<Map<String, dynamic>?> convertAlvaPoints(int cantidadAlva) async {
    try {
      final res = await api.post('/api/points/convert-alva', {'cantidad_alva': cantidadAlva});
      _applyUser(res['user']);
      await loadVivaLine();
      return Map<String, dynamic>.from(res);
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<void> toggleEasyMode(bool enabled) async {
    await api.patch('/api/me/modo-facil', {'enabled': enabled});
    await refreshProfile();
  }

  Future<bool> feedMascota() async {
    try {
      await api.post('/api/mascota/feed');
      await loadMascota();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> playWithMascota() async {
    try {
      await api.post('/api/mascota/play');
      await loadMascota();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── EARN ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> earnStatus() async {
    try {
      return Map<String, dynamic>.from(await api.get('/api/earn/status'));
    } catch (_) {
      return null;
    }
  }

  Future<bool> earnActivate() async {
    try {
      final res = await api.post('/api/earn/activate');
      _applyUser(res['user']);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> earnAcreditar() async {
    try {
      final res = await api.post('/api/earn/acreditar');
      _applyUser(res['user']);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── SWAP ──────────────────────────────────────────────────────────

  Future<bool> swapVivaToUsdt(double amount) async {
    try {
      final res = await api.post('/api/swap/viva-usdt', {'monto_viva': amount});
      _applyUser(res['user']);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> swapUsdtToViva(double amount) async {
    try {
      final res = await api.post('/api/swap/usdt-viva', {'monto_usdt': amount});
      _applyUser(res['user']);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
