part of 'api_service.dart';

class ApiCookies {
  ApiCookies() {
    // Domain -> Cookie Name -> Value
    _cookies = <String, Map<String, String>>{};
  }
  late Map<String, Map<String, String>> _cookies;

  Future<void> initCookies() async {
    final sharePref = await SharedPreferences.getInstance();
    final cookieString = sharePref.getString('cookies');
    if (cookieString != null) {
      try {
        final decoded = jsonDecode(cookieString) as Map<String, dynamic>;
        _cookies = decoded.map(
          (key, value) => MapEntry(key, (value as Map).cast<String, String>()),
        );
      } catch (e) {
        developer.log('Failed to load cookies: $e', level: 1000);
        _cookies = <String, Map<String, String>>{}; // Reset on error
      }
    }
  }

  void updateCookies(Uri uri, http.Response response) {
    final setCookieHeaders = response.headers['set-cookie'];
    if (setCookieHeaders != null) {
      final cookies = setCookieHeaders.split(',').map((str) => str.trim()).toList();
      final domain = uri.host;

      _cookies[domain] ??= {};
      for (final cookie in cookies) {
        final parts = cookie.split(';');
        final nameValue = parts[0].split('=');
        if (nameValue.length >= 2) {
          final name = nameValue[0].trim();
          final value = nameValue[1].trim();
          _cookies[domain]![name] = value;
        }
      }
      _saveCookies(); // Persist cookies after updating
    }
  }

  // Save cookies to SharedPreferences
  Future<void> _saveCookies() async {
    final sharePref = await SharedPreferences.getInstance();
    try {
      final cookieString = jsonEncode(_cookies);
      await sharePref.setString('cookies', cookieString);
    } catch (e) {
      developer.log('Failed to save cookies: $e', level: 1000);
    }
  }

  Future<void> clearCookies({String? domain}) async {
    if (domain != null) {
      _cookies.remove(domain);
    } else {
      _cookies.clear();
    }
    final sharePref = await SharedPreferences.getInstance();
    try {
      if (domain != null && _cookies.isNotEmpty) {
        await sharePref.setString('cookies', jsonEncode(_cookies)); // Update remaining cookies
      } else {
        await sharePref.remove('cookies'); // Clear all
      }
      developer.log('Cookies cleared successfully${domain != null ? ' for $domain' : ''}');
    } catch (e) {
      developer.log('Failed to clear cookies from storage: $e', level: 1000);
    }
  }

  // Helper to manage cookies
  String? getCookieHeader(Uri uri) {
    final domainCookies = _cookies[uri.host];
    if (domainCookies == null || domainCookies.isEmpty) return null;
    return domainCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }
}
