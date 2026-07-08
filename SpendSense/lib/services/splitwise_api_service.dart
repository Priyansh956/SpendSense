import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'splitwise_service.dart';

class SplitwiseApiService {
  static Map<String, dynamic> _serializeExpense(SplitExpense expense) {
    return {
      'title': expense.title,
      'totalAmount': expense.totalAmount,
      'category': expense.category,
      'paidByUid': expense.paidByUid,
      'paidByEmail': expense.paidByEmail,
      'paidByName': expense.paidByName,
      'participants': expense.participants.map((p) => p.toMap()).toList(),
      'date': expense.date.toIso8601String(),
      if (expense.note != null) 'note': expense.note,
      'isSettled': expense.isSettled,
      'involvedUids': [
        expense.paidByUid,
        ...expense.participants.map((p) => p.uid).toSet(),
      ],
    };
  }

  static Map<String, dynamic> _decode(http.Response res) {
    if (res.body.isEmpty) return {};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createSplitExpense(
    SplitExpense expense,
  ) async {
    final res = await http.post(
      Uri.parse('${ApiService.baseUrl}/splitwise/expenses'),
      headers: await ApiService.authHeaders(),
      body: jsonEncode(_serializeExpense(expense)),
    );

    final body = _decode(res);
    if (res.statusCode != 201) {
      throw ApiException(
        body['message'] ?? 'Failed to create split expense',
        res.statusCode,
      );
    }

    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  static Future<List<SplitExpense>> getSplitExpenses() async {
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}/splitwise/expenses'),
      headers: await ApiService.authHeaders(),
    );

    final body = _decode(res);
    if (res.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Failed to fetch split expenses',
        res.statusCode,
      );
    }

    final data = List<dynamic>.from(body['data'] as List<dynamic>);
    return data.map((item) {
      final json = Map<String, dynamic>.from(item as Map<String, dynamic>);
      final id = json['id']?.toString() ?? json['_id']?.toString() ?? '';
      return SplitExpense.fromMap(json, id);
    }).toList();
  }

  static Future<void> markParticipantPaid(
    String expenseId,
    String participantUid,
  ) async {
    final res = await http.patch(
      Uri.parse(
        '${ApiService.baseUrl}/splitwise/expenses/$expenseId/participants/$participantUid/paid',
      ),
      headers: await ApiService.authHeaders(),
    );

    final body = _decode(res);
    if (res.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Failed to mark participant paid',
        res.statusCode,
      );
    }
  }

  static Future<void> settleExpense(String expenseId) async {
    final res = await http.patch(
      Uri.parse('${ApiService.baseUrl}/splitwise/expenses/$expenseId/settle'),
      headers: await ApiService.authHeaders(),
    );

    final body = _decode(res);
    if (res.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Failed to settle split expense',
        res.statusCode,
      );
    }
  }

  static Future<void> deleteSplitExpense(String expenseId) async {
    final res = await http.delete(
      Uri.parse('${ApiService.baseUrl}/splitwise/expenses/$expenseId'),
      headers: await ApiService.authHeaders(),
    );

    final body = _decode(res);
    if (res.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Failed to delete split expense',
        res.statusCode,
      );
    }
  }
}
