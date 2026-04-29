part of 'api_service.dart';

class ApiCookies {
  ApiCookies() {
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
        logger.e(
          'Failed to load cookies: $e',
        );
        _cookies = <String, Map<String, String>>{};
      }
    }
  }

  void updateCookies(Uri uri, http.Response response) {
    final setCookieHeaders = response.headers['set-cookie'];
    if (setCookieHeaders != null) {
      final cookies = _splitSetCookieHeader(setCookieHeaders);
      final domain = uri.host;

      _cookies[domain] ??= {};
      for (final cookie in cookies) {
        try {
          final parsed = Cookie.fromSetCookieValue(cookie);
          _cookies[domain]![parsed.name] = parsed.value;
        } catch (_) {
          final parts = cookie.split(';');
          final nameValue = parts.first.split('=');
          if (nameValue.length >= 2) {
            final name = nameValue[0].trim();
            final value = nameValue.sublist(1).join('=').trim();
            _cookies[domain]![name] = value;
          }
        }
      }
      _saveCookies();
    }
  }

  Future<void> _saveCookies() async {
    final sharePref = await SharedPreferences.getInstance();
    try {
      final cookieString = jsonEncode(_cookies);
      await sharePref.setString('cookies', cookieString);
    } catch (e) {
      logger.e('Failed to save cookies: $e');
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
        await sharePref.setString('cookies', jsonEncode(_cookies));
      } else {
        await sharePref.remove('cookies');
      }
      logger.i(
        'Cookies cleared successfully${domain != null ? ' for $domain' : ''}',
      );
    } catch (e) {
      logger.e('Failed to clear cookies from storage: $e');
    }
  }

  String? getCookieHeader(Uri uri) {
    final domainCookies = _cookies[uri.host];
    if (domainCookies == null || domainCookies.isEmpty) return null;
    return domainCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  List<String> _splitSetCookieHeader(String header) {
    final parts = <String>[];
    var start = 0;
    for (var index = 0; index < header.length; index++) {
      if (header[index] != ',') {
        continue;
      }

      final next = header.substring(index + 1).trimLeft();
      if (RegExp(r"^[!#$%&'*+\-.^_`|~0-9A-Za-z]+=").hasMatch(next)) {
        parts.add(header.substring(start, index).trim());
        start = index + 1;
      }
    }

    parts.add(header.substring(start).trim());
    return parts.where((part) => part.isNotEmpty).toList(growable: false);
  }
}
