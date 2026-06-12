// Κεντρικός API client.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String kApiBase = 'http://10.19.151.142:8080';

// ── Icon name → IconData ──────────────────────────────────────────────────────
const Map<String, IconData> kIconMap = {
  'menu_book':                  Icons.menu_book,
  'menu_book_rounded':          Icons.menu_book_rounded,
  'laptop_chromebook_rounded':  Icons.laptop_chromebook_rounded,
  'storage_rounded':            Icons.storage_rounded,
  'account_balance':            Icons.account_balance,
  'account_balance_rounded':    Icons.account_balance_rounded,
  'people_outline':             Icons.people_outline,
  'people_rounded':             Icons.people_rounded,
  'link_rounded':               Icons.link_rounded,
  'link':                       Icons.link,
  'public':                     Icons.public,
  'public_outlined':            Icons.public_outlined,
  'import_contacts':            Icons.import_contacts,
  'cloud_outlined':             Icons.cloud_outlined,
  'folder_open':                Icons.folder_open,
  'manage_search':              Icons.manage_search,
  'article_rounded':            Icons.article_rounded,
  'school':                     Icons.school,
  'school_outlined':            Icons.school_outlined,
  'biotech':                    Icons.biotech,
  'description':                Icons.description,
  'swap_horiz_rounded':         Icons.swap_horiz_rounded,
  'folder_special_rounded':     Icons.folder_special_rounded,
  'bar_chart_rounded':          Icons.bar_chart_rounded,
  'person_add_outlined':        Icons.person_add_outlined,
  'manage_search_outlined':     Icons.manage_search_outlined,
  'edit_document':              Icons.edit_document,
  'source_outlined':            Icons.source_outlined,
  'plagiarism_outlined':        Icons.plagiarism_outlined,
  'settings':                   Icons.settings,
  'badge_outlined':             Icons.badge_outlined,
  'workspace_premium_outlined': Icons.workspace_premium_outlined,
  'precision_manufacturing_outlined': Icons.precision_manufacturing_outlined,
  'location_city_outlined':     Icons.location_city_outlined,
  'agriculture_outlined':       Icons.agriculture_outlined,
  'local_hospital_outlined':    Icons.local_hospital_outlined,
  'swap_horiz':                 Icons.swap_horiz,
  'sync_alt_rounded':           Icons.sync_alt_rounded
};

IconData iconFromString(String? name) =>
    kIconMap[name ?? ''] ?? Icons.circle_outlined;

Color colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFFD4A017);
  try {
    return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  } catch (_) {
    return const Color(0xFFD4A017);
  }
}

// ── Bilingual text helper ─────────────────────────────────────────────────────
String bi(Map<String, dynamic>? map, String key, bool isGreek) {
  if (map == null) return '';
  final v = map[key];
  if (v == null) return '';
  if (v is Map) return isGreek ? (v['el'] ?? '') : (v['en'] ?? '');
  return v.toString();
}

// ── HTTP helpers ──────────────────────────────────────────────────────────────
Future<List<Map<String, dynamic>>> apiGetList(String path) async {
  try {
    final res = await http
        .get(Uri.parse('$kApiBase$path'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is List) return List<Map<String, dynamic>>.from(body);
      if (body is Map && body.containsKey('items')) {
        return List<Map<String, dynamic>>.from(body['items']);
      }
    }
  } catch (e) {
    debugPrint('API error $path: $e');
  }
  return [];
}

Future<Map<String, dynamic>> apiGetSingle(String path) async {
  try {
    final res = await http.get(Uri.parse('$kApiBase$path'));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(
          jsonDecode(utf8.decode(res.bodyBytes)));
    }
  } catch (e) {
    debugPrint('API error $path: $e');
  }
  return {};
}

Future<bool> apiSubmitForm(Map<String, dynamic> payload) async {
  try {
    final res = await http
        .post(
          Uri.parse('$kApiBase/api/forms/submit'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));
    return res.statusCode == 200 || res.statusCode == 201;
  } catch (_) {
    return false;
  }
}

// ── Shared UI widgets ─────────────────────────────────────────────────────────
Widget buildLoading({Color color = const Color(0xFFD4A017)}) =>
    Center(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: CircularProgressIndicator(color: color),
    ));

Widget buildApiError(String msg, VoidCallback onRetry) =>
    Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
        const SizedBox(height: 16),
        Text(msg, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Επανάληψη / Retry'),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD4A017))),
        ),
      ]),
    ));
