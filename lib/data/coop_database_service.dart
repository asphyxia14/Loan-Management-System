import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_models.dart';

class CoopDatabaseService {
  String? _apiBaseUrl;
  String? _sessionToken;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<bool> connect(DbConnectionConfig config) async {
    final baseUrl = _normalizeBaseUrl(config.apiBaseUrl);

    final response = await http.post(
      Uri.parse('$baseUrl/connect'),
      headers: _jsonHeaders(includeAuth: false),
      body: jsonEncode(<String, dynamic>{
        'host': config.host,
        'port': config.port,
        'database': config.database,
        'username': config.username,
        'password': config.password,
        'timeoutInSeconds': config.timeoutInSeconds,
      }),
    ).timeout(const Duration(seconds: 15));

    final payload = _decodeJsonResponse(response);
    _ensureSuccess(
      response,
      payload,
      fallbackMessage: 'Backend connection failed.',
    );

    final token = payload['token']?.toString();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Backend did not return a valid session token.');
    }

    _apiBaseUrl = baseUrl;
    _sessionToken = token;
    _isConnected = true;
    return true;
  }

  Future<void> disconnect() async {
    if (!_isConnected || _apiBaseUrl == null || _sessionToken == null) {
      _isConnected = false;
      _apiBaseUrl = null;
      _sessionToken = null;
      return;
    }

    try {
      final response = await http.post(
        _uri('/disconnect'),
        headers: _jsonHeaders(),
      ).timeout(const Duration(seconds: 15));
      final payload = _decodeJsonResponse(response);
      _ensureSuccess(
        response,
        payload,
        fallbackMessage: 'Failed to disconnect session.',
      );
    } finally {
      _isConnected = false;
      _apiBaseUrl = null;
      _sessionToken = null;
    }
  }

  Future<void> initializeSchema() async {
    await _post('/setup');
  }

  Future<List<MemberRecord>> fetchMembers() async {
    final payload = await _get('/members');
    final rows = _rowsFromPayload(payload);
    return rows.map(MemberRecord.fromRow).toList(growable: false);
  }

  Future<int> createMember({
    required String fullName,
    required String phoneNumber,
    required String addressLine,
    DateTime? joinedDate,
  }) async {
    final effectiveDate = joinedDate ?? DateTime.now();
    final payload = await _post(
      '/members',
      body: <String, dynamic>{
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'addressLine': addressLine.trim(),
        'joinedDate': _formatSqlDate(effectiveDate),
      },
    );

    final memberId = _toInt(payload['memberId']);
    if (memberId <= 0) {
      throw StateError('Unable to create member.');
    }
    return memberId;
  }

  Future<void> updateMember({
    required int memberId,
    required String fullName,
    required String phoneNumber,
    required String addressLine,
  }) async {
    await _patch(
      '/members/$memberId',
      body: <String, dynamic>{
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'addressLine': addressLine.trim(),
      },
    );
  }

  Future<void> updateMemberStatus({
    required int memberId,
    required String status,
  }) async {
    await _post(
      '/members/$memberId/status',
      body: <String, dynamic>{'status': status.toUpperCase()},
    );
  }

  Future<void> deleteMember(int memberId) async {
    await _delete('/members/$memberId');
  }

  Future<void> recordSavingsTransaction({
    required int memberId,
    required String transactionType,
    required double amount,
    required DateTime transactionDate,
    String referenceNo = '',
    String remarks = '',
  }) async {
    await _post(
      '/savings-transactions',
      body: <String, dynamic>{
        'memberId': memberId,
        'transactionDate': _formatSqlDate(transactionDate),
        'transactionType': transactionType,
        'amount': amount,
        'referenceNo': referenceNo.trim(),
        'remarks': remarks.trim(),
      },
    );
  }

  Future<List<SavingsTransactionRecord>> fetchSavingsTransactions({
    required int memberId,
    int limit = 100,
  }) async {
    final payload = await _get(
      '/members/$memberId/savings-transactions',
      query: <String, String>{'limit': '$limit'},
    );
    final rows = _rowsFromPayload(payload);
    return rows.map(SavingsTransactionRecord.fromRow).toList(growable: false);
  }

  Future<double> fetchSavingsBalance(int memberId) async {
    final payload = await _get('/members/$memberId/savings-balance');
    return _toDouble(payload['SavingsBalance']);
  }

  Future<int> createLoan({
    required int memberId,
    required double principalAmount,
    required double annualInterestRate,
    required int termMonths,
    String purpose = '',
    String approvedBy = 'Manager',
    DateTime? approvalDate,
  }) async {
    final effectiveDate = approvalDate ?? DateTime.now();
    final payload = await _post(
      '/loans',
      body: <String, dynamic>{
        'memberId': memberId,
        'principalAmount': principalAmount,
        'annualInterestRate': annualInterestRate,
        'termMonths': termMonths,
        'purpose': purpose.trim(),
        'approvedBy': approvedBy.trim(),
        'approvalDate': _formatSqlDate(effectiveDate),
      },
    );

    final loanId = _toInt(payload['loanId']);
    if (loanId <= 0) {
      throw StateError('Unable to create loan.');
    }
    return loanId;
  }

  Future<List<LoanAccountRecord>> fetchLoans() async {
    final payload = await _get('/loans');
    final rows = _rowsFromPayload(payload);
    return rows.map(LoanAccountRecord.fromRow).toList(growable: false);
  }

  Future<void> recordLoanPayment({
    required int loanId,
    required DateTime paymentDate,
    required double principalPaid,
    required double interestPaid,
    required double penaltyPaid,
    String remarks = '',
  }) async {
    await _post(
      '/loan-payments',
      body: <String, dynamic>{
        'loanId': loanId,
        'paymentDate': _formatSqlDate(paymentDate),
        'principalPaid': principalPaid,
        'interestPaid': interestPaid,
        'penaltyPaid': penaltyPaid,
        'remarks': remarks.trim(),
      },
    );
  }

  Future<List<LoanPaymentRecord>> fetchLoanPayments({
    required int loanId,
    int limit = 100,
  }) async {
    final payload = await _get(
      '/loans/$loanId/payments',
      query: <String, String>{'limit': '$limit'},
    );
    final rows = _rowsFromPayload(payload);
    return rows.map(LoanPaymentRecord.fromRow).toList(growable: false);
  }

  Future<DashboardMetrics> fetchDashboardMetrics() async {
    final payload = await _get('/dashboard');
    return DashboardMetrics(
      activeMembers: _toInt(payload['ActiveMembers']),
      totalSavings: _toDouble(payload['TotalSavings']),
      activeLoans: _toInt(payload['ActiveLoans']),
      totalLoanOutstanding: _toDouble(payload['TotalLoanOutstanding']),
    );
  }

  Future<MonthlyFinancialSummary?> fetchMonthlySummary({
    required int year,
    required int month,
  }) async {
    final payload = await _get(
      '/reports/monthly',
      query: <String, String>{'year': '$year', 'month': '$month'},
    );

    final dynamic summary = payload['summary'];
    if (summary == null) {
      return null;
    }
    if (summary is! Map) {
      throw StateError('Unexpected report payload.');
    }

    return MonthlyFinancialSummary.fromRow(Map<String, dynamic>.from(summary));
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? query,
  }) async {
    _requireConnectionState();
    final response = await http
        .get(_uri(path, query), headers: _jsonHeaders())
        .timeout(const Duration(seconds: 15));
    final payload = _decodeJsonResponse(response);
    _ensureSuccess(response, payload, fallbackMessage: 'GET $path failed.');
    return payload;
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    _requireConnectionState();
    final response = await http
        .post(
          _uri(path),
          headers: _jsonHeaders(),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    final payload = _decodeJsonResponse(response);
    _ensureSuccess(response, payload, fallbackMessage: 'POST $path failed.');
    return payload;
  }

  Future<Map<String, dynamic>> _patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    _requireConnectionState();
    final response = await http
        .patch(
          _uri(path),
          headers: _jsonHeaders(),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    final payload = _decodeJsonResponse(response);
    _ensureSuccess(response, payload, fallbackMessage: 'PATCH $path failed.');
    return payload;
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    _requireConnectionState();
    final response = await http
        .delete(_uri(path), headers: _jsonHeaders())
        .timeout(const Duration(seconds: 15));
    final payload = _decodeJsonResponse(response);
    _ensureSuccess(response, payload, fallbackMessage: 'DELETE $path failed.');
    return payload;
  }

  void _requireConnectionState() {
    if (!_isConnected || _apiBaseUrl == null || _sessionToken == null) {
      throw StateError('Not connected. Connect to backend first.');
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final baseUrl = _apiBaseUrl;
    if (baseUrl == null) {
      throw StateError('API base URL is not set.');
    }

    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: query);
  }

  Map<String, String> _jsonHeaders({bool includeAuth = true}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (includeAuth && _sessionToken != null) {
      headers['Authorization'] = 'Bearer $_sessionToken';
    }
    return headers;
  }

  Map<String, dynamic> _decodeJsonResponse(http.Response response) {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      if (response.statusCode >= 400) {
        throw StateError(
          'Server returned an invalid error response (HTTP ${response.statusCode}).',
        );
      }
      throw StateError('Expected JSON response, but received $contentType.');
    }

    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return <String, dynamic>{'rows': decoded};
      }
      return Map<String, dynamic>.from(decoded);
    } on FormatException catch (e) {
      throw StateError(
        'Failed to parse server response as JSON. Error: ${e.message}',
      );
    }
  }

  void _ensureSuccess(
    http.Response response,
    Map<String, dynamic> payload, {
    required String fallbackMessage,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final message = payload['error']?.toString().trim();
    if (message != null && message.isNotEmpty) {
      final lowerMessage = message.toLowerCase();
      if (lowerMessage.contains('login failed for user')) {
        throw StateError(
          '$message Check SQL username/password (Docker MSSQL_SA_PASSWORD) and database name.',
        );
      }
      if (lowerMessage.contains('cannot open database')) {
        throw StateError(
          '$message Database might not exist yet. Use an existing DB (for example master) or create the database first.',
        );
      }
      throw StateError(message);
    }
    throw StateError('$fallbackMessage HTTP ${response.statusCode}.');
  }

  List<Map<String, dynamic>> _rowsFromPayload(Map<String, dynamic> payload) {
    final dynamic rows = payload['rows'];
    if (rows is! List) {
      return const <Map<String, dynamic>>[];
    }

    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  String _normalizeBaseUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) {
      throw StateError('Backend API URL is required.');
    }

    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }

    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }

    return value;
  }

  String _formatSqlDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
