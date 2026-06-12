import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class ApiService {
  final String token;
  ApiService(this.token);

  Map<String, String> get _json => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
  Map<String, String> get _auth => {'Authorization': 'Bearer $token'};

  dynamic _parse(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return <String, dynamic>{};
      return jsonDecode(r.body);
    }
    String msg = 'HTTP ${r.statusCode}';
    try {
      final d = jsonDecode(r.body);
      if (d is Map && d['detail'] != null) msg = d['detail'].toString();
    } catch (_) {}
    throw ApiException(msg, r.statusCode);
  }

  Future<dynamic> _get(String path, [Map<String, String>? q]) async {
    var uri = Uri.parse('${AppConfig.baseUrl}$path');
    if (q != null && q.isNotEmpty) uri = uri.replace(queryParameters: q);
    return _parse(await http.get(uri, headers: _json));
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async =>
      _parse(await http.post(Uri.parse('${AppConfig.baseUrl}$path'),
          headers: _json, body: jsonEncode(body)));

  Future<dynamic> _put(String path, Map<String, dynamic> body) async =>
      _parse(await http.put(Uri.parse('${AppConfig.baseUrl}$path'),
          headers: _json, body: jsonEncode(body)));

  Future<dynamic> _patch(String path, Map<String, dynamic> body) async =>
      _parse(await http.patch(Uri.parse('${AppConfig.baseUrl}$path'),
          headers: _json, body: jsonEncode(body)));

  Future<dynamic> _delete(String path) async =>
      _parse(await http.delete(Uri.parse('${AppConfig.baseUrl}$path'), headers: _json));

  Future<dynamic> _multipart(
      String path,
      Uint8List bytes,
      String filename,
      String contentType, {
        Map<String, String>? fields,
      }) async {
    final req = http.MultipartRequest('POST', Uri.parse('${AppConfig.baseUrl}$path'));
    req.headers.addAll(_auth);
    req.files.add(http.MultipartFile.fromBytes('file', bytes,
        filename: filename, contentType: MediaType.parse(contentType)));
    if (fields != null) req.fields.addAll(fields);
    return _parse(await http.Response.fromStream(await req.send()));
  }

  // ── AUTH ─────────────────────────────────────────────────────────────────
  Future<Map> getMe() async => await _get('/auth/me') as Map;

  // ── BRANCHES ─────────────────────────────────────────────────────────────
  Future<List> getBranches() async => await _get('/api/branches/') as List;

  Future<Map> createBranch(Map<String, dynamic> data) async =>
      await _post('/api/branches/', data) as Map;

  Future<void> replaceBranch(String id, Map<String, dynamic> data) async =>
      await _put('/api/branches/$id', data);

  Future<void> patchBranch(String id, Map<String, dynamic> data) async =>
      await _patch('/api/branches/$id', data);

  Future<void> deleteBranch(String id) async => await _delete('/api/branches/$id');

  Future<Map> uploadBranchImage(
      String id, Uint8List bytes, String filename, String ct, {
        String altEl = '', String altEn = '',
      }) async =>
      await _multipart('/api/branches/$id/image', bytes, filename, ct,
          fields: {'alt_el': altEl, 'alt_en': altEn}) as Map;

  // ── STAFF ────────────────────────────────────────────────────────────────
  Future<List> getStaff() async => await _get('/api/staff/') as List;

  Future<Map> createStaff(Map<String, dynamic> data) async =>
      await _post('/api/staff/', data) as Map;

  Future<void> replaceStaff(String id, Map<String, dynamic> data) async =>
      await _put('/api/staff/$id', data);

  Future<void> patchStaff(String id, Map<String, dynamic> data) async =>
      await _patch('/api/staff/$id', data);

  Future<void> deleteStaff(String id) async => await _delete('/api/staff/$id');

  Future<Map> uploadStaffImage(
      String id, Uint8List bytes, String filename, String ct, {
        String altEl = '', String altEn = '',
      }) async =>
      await _multipart('/api/staff/$id/image', bytes, filename, ct,
          fields: {'alt_el': altEl, 'alt_en': altEn}) as Map;

  // ── ANNOUNCEMENTS ────────────────────────────────────────────────────────
  Future<Map> getAnnouncements({
    bool visibleOnly = false,
    int limit = 50,
    int skip = 0,
  }) async =>
      await _get('/api/announcements/', {
        'visible_only': visibleOnly.toString(),
        'limit': limit.toString(),
        'skip': skip.toString(),
      }) as Map;

  Future<Map> createAnnouncement(Map<String, dynamic> data) async =>
      await _post('/api/announcements/', data) as Map;

  Future<void> replaceAnnouncement(String id, Map<String, dynamic> data) async =>
      await _put('/api/announcements/$id', data);

  Future<void> patchAnnouncement(String id, Map<String, dynamic> data) async =>
      await _patch('/api/announcements/$id', data);

  Future<void> deleteAnnouncement(String id) async =>
      await _delete('/api/announcements/$id');

  Future<Map> uploadAnnouncementImage(
      String id, Uint8List bytes, String filename, String ct, {
        String altEl = '', String altEn = '',
      }) async =>
      await _multipart('/api/announcements/$id/image', bytes, filename, ct,
          fields: {'alt_el': altEl, 'alt_en': altEn}) as Map;

  Future<Map> uploadAnnouncementFile(
      String id, Uint8List bytes, String filename, String ct) async =>
      await _multipart('/api/announcements/$id/file', bytes, filename, ct) as Map;

  // ── SERVICES ─────────────────────────────────────────────────────────────
  Future<List> getServices({String? section, bool visibleOnly = false}) async {
    final q = <String, String>{'visible_only': visibleOnly.toString()};
    if (section != null) q['section'] = section;
    return await _get('/api/services/', q) as List;
  }

  Future<Map> createService(Map<String, dynamic> data) async =>
      await _post('/api/services/', data) as Map;

  Future<void> replaceService(String id, Map<String, dynamic> data) async =>
      await _put('/api/services/$id', data);

  Future<void> patchService(String id, Map<String, dynamic> data) async =>
      await _patch('/api/services/$id', data);

  Future<void> deleteService(String id) async => await _delete('/api/services/$id');

  Future<Map> uploadServiceImage(
      String id, Uint8List bytes, String filename, String ct, {
        String altEl = '', String altEn = '',
      }) async =>
      await _multipart('/api/services/$id/image', bytes, filename, ct,
          fields: {'alt_el': altEl, 'alt_en': altEn}) as Map;

  // ── STATISTICS ───────────────────────────────────────────────────────────
  Future<List> getStatistics() async => await _get('/api/statistics') as List;

  Future<Map> createStat(Map<String, dynamic> data) async =>
      await _post('/api/statistics', data) as Map;

  Future<void> replaceStat(String id, Map<String, dynamic> data) async =>
      await _put('/api/statistics/$id', data);

  Future<void> patchStat(String id, Map<String, dynamic> data) async =>
      await _patch('/api/statistics/$id', data);

  Future<void> deleteStat(String id) async => await _delete('/api/statistics/$id');

  // ── GUIDES ───────────────────────────────────────────────────────────────
  Future<List> getGuides() async => await _get('/api/guides') as List;

  Future<Map> createGuide(Map<String, dynamic> data) async =>
      await _post('/api/guides', data) as Map;

  Future<void> replaceGuide(String id, Map<String, dynamic> data) async =>
      await _put('/api/guides/$id', data);

  Future<void> patchGuide(String id, Map<String, dynamic> data) async =>
      await _patch('/api/guides/$id', data);

  Future<void> deleteGuide(String id) async => await _delete('/api/guides/$id');

  Future<Map> uploadGuideFile(
      String id, Uint8List bytes, String filename, String ct) async =>
      await _multipart('/api/guides/$id/file', bytes, filename, ct) as Map;

  // ── USEFUL LINKS ─────────────────────────────────────────────────────────
  Future<List> getUsefulLinks() async => await _get('/api/useful-links') as List;

  Future<Map> createUsefulLink(Map<String, dynamic> data) async =>
      await _post('/api/useful-links', data) as Map;

  Future<void> replaceUsefulLink(String id, Map<String, dynamic> data) async =>
      await _put('/api/useful-links/$id', data);

  Future<void> deleteUsefulLink(String id) async =>
      await _delete('/api/useful-links/$id');

  Future<Map> uploadUsefulLinkImage(
      String id, Uint8List bytes, String filename, String ct, {
        String altEl = '', String altEn = '',
      }) async =>
      await _multipart('/api/useful-links/$id/image', bytes, filename, ct,
          fields: {'alt_el': altEl, 'alt_en': altEn}) as Map;

  // ── QUICK LINKS ──────────────────────────────────────────────────────────
  Future<List> getQuickLinks() async => await _get('/api/quick-links') as List;

  Future<Map> createQuickLink(Map<String, dynamic> data) async =>
      await _post('/api/quick-links', data) as Map;

  Future<void> replaceQuickLink(String id, Map<String, dynamic> data) async =>
      await _put('/api/quick-links/$id', data);

  Future<void> deleteQuickLink(String id) async =>
      await _delete('/api/quick-links/$id');

  Future<Map> uploadQuickLinkImage(
      String id, Uint8List bytes, String filename, String ct, {
        String altEl = '', String altEn = '',
      }) async =>
      await _multipart('/api/quick-links/$id/image', bytes, filename, ct,
          fields: {'alt_el': altEl, 'alt_en': altEn}) as Map;

  // ── COLLECTIONS ──────────────────────────────────────────────────────────
  Future<List> getCollections() async => await _get('/api/collections') as List;

  Future<Map> createCollection(Map<String, dynamic> data) async =>
      await _post('/api/collections', data) as Map;

  Future<void> replaceCollection(String id, Map<String, dynamic> data) async =>
      await _put('/api/collections/$id', data);

  Future<void> patchCollection(String id, Map<String, dynamic> data) async =>
      await _patch('/api/collections/$id', data);

  Future<void> deleteCollection(String id) async =>
      await _delete('/api/collections/$id');

  Future<Map> uploadCollectionImage(
      String id, Uint8List bytes, String filename, String ct, {
        String altEl = '', String altEn = '',
      }) async =>
      await _multipart('/api/collections/$id/image', bytes, filename, ct,
          fields: {'alt_el': altEl, 'alt_en': altEn}) as Map;

  // ── PAGE CONTENT ─────────────────────────────────────────────────────────
  Future<List> getPageContent({String? page}) async {
    final q = <String, String>{};
    if (page != null) q['page'] = page;
    return await _get('/api/page-content', q) as List;
  }

  Future<Map> upsertPageContent(Map<String, dynamic> data) async =>
      await _post('/api/page-content', data) as Map;

  Future<void> patchPageContent(String id, Map<String, dynamic> data) async =>
      await _patch('/api/page-content/$id', data);

  Future<void> deletePageContent(String id) async =>
      await _delete('/api/page-content/$id');

  Future<Map> uploadPageContentImage(
      String id, Uint8List bytes, String filename, String ct, {
        String altEl = '', String altEn = '',
      }) async =>
      await _multipart('/api/page-content/$id/image', bytes, filename, ct,
          fields: {'alt_el': altEl, 'alt_en': altEn}) as Map;

  // ── FORMS / SUBMISSIONS ──────────────────────────────────────────────────
  Future<Map> getSubmissions({
    String? formType,
    bool unreadOnly = false,
    int limit = 20,
    int skip = 0,
  }) async {
    final q = <String, String>{
      'unread_only': unreadOnly.toString(),
      'limit': limit.toString(),
      'skip': skip.toString(),
    };
    if (formType != null) q['form_type'] = formType;
    return await _get('/api/forms/submissions', q) as Map;
  }

  Future<Map> getSubmission(String id) async =>
      await _get('/api/forms/submissions/$id') as Map;

  Future<void> markRead(String id, {bool read = true}) async =>
      await _patch('/api/forms/submissions/$id/read', {'read': read});

  Future<void> deleteSubmission(String id) async =>
      await _delete('/api/forms/submissions/$id');

  // ── MEDIA ────────────────────────────────────────────────────────────────
  Future<Map> getMedia({String? folder, int limit = 50, int skip = 0}) async {
    final q = <String, String>{
      'limit': limit.toString(),
      'skip': skip.toString(),
    };
    if (folder != null) q['folder'] = folder;
    return await _get('/api/media', q) as Map;
  }

  Future<Map> uploadMedia(
      Uint8List bytes,
      String filename,
      String ct, {
        String folder = 'misc',
        String refCollection = '',
        String refId = '',
      }) async {
    final req = http.MultipartRequest(
        'POST', Uri.parse('${AppConfig.baseUrl}/api/media/upload'));
    req.headers.addAll(_auth);
    req.files.add(http.MultipartFile.fromBytes('file', bytes,
        filename: filename, contentType: MediaType.parse(ct)));
    req.fields['folder'] = folder;
    req.fields['ref_collection'] = refCollection;
    req.fields['ref_id'] = refId;
    return _parse(await http.Response.fromStream(await req.send())) as Map;
  }

  Future<void> deleteMedia(String id) async => await _delete('/api/media/$id');

  /// Σκανάρει όλα τα αρχεία από όλες τις collections του server
  Future<Map> scanAllMedia() async =>
      await _get('/api/media/scan') as Map;

  // ── CHAT ─────────────────────────────────────────────────────────────────
  Future<List> getChatSessions({bool closed = false}) async =>
      await _get('/api/chat/sessions', {'closed': closed.toString()}) as List;

  Future<List> getChatMessages(String sessionId) async =>
      await _get('/api/chat/sessions/$sessionId/messages') as List;

  Future<void> closeChatSession(String sessionId) async =>
      await _post('/api/chat/sessions/$sessionId/close', {});

  Future<void> deleteChatSession(String sessionId) async =>
      await _delete('/api/chat/sessions/$sessionId');

  // ── SERVICE CATEGORIES ───────────────────────────────────────────────────
  Future<List> getServiceCategories({bool visibleOnly = false}) async =>
      await _get('/api/service-categories/',
          {'visible_only': visibleOnly.toString()}) as List;

  Future<Map> createServiceCategory(Map<String, dynamic> data) async =>
      await _post('/api/service-categories/', data) as Map;

  Future<void> replaceServiceCategory(String id, Map<String, dynamic> data) async =>
      await _put('/api/service-categories/$id', data);

  Future<void> patchServiceCategory(String id, Map<String, dynamic> data) async =>
      await _patch('/api/service-categories/$id', data);

  Future<void> deleteServiceCategory(String id) async =>
      await _delete('/api/service-categories/$id');
}