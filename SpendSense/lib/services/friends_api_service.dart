import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'splitwise_service.dart';

class FriendsApiService {
  static Future<void> sendFriendRequest(String toEmail) async {
    final res = await http.post(
      Uri.parse('${ApiService.baseUrl}/friends/requests'),
      headers: await ApiService.authHeaders(),
      body: jsonEncode({'email': toEmail}),
    );

    final body = ApiService.decode(res);
    if (res.statusCode != 201) {
      throw ApiException(
        body['message'] ?? 'Failed to send friend request',
        res.statusCode,
      );
    }
  }

  static Future<List<FriendRequest>> getIncomingRequests() async {
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}/friends/requests/incoming'),
      headers: await ApiService.authHeaders(),
    );

    final body = ApiService.decode(res);
    if (res.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Failed to fetch incoming requests',
        res.statusCode,
      );
    }

    final data = body['data'] as List<dynamic>;
    return data
        .map(
          (item) => FriendRequest.fromMap({
            'id': item['id'],
            'fromUid': item['fromUser']?['id'] ?? '',
            'fromEmail': item['fromUser']?['email'] ?? '',
            'toUid': item['toUser']?['id'] ?? '',
            'toEmail': item['toUser']?['email'] ?? '',
            'status': item['status'] ?? 'pending',
            'createdAt': item['createdAt'],
          }, item['id']),
        )
        .toList();
  }

  static Future<List<FriendRequest>> getOutgoingRequests() async {
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}/friends/requests/outgoing'),
      headers: await ApiService.authHeaders(),
    );

    final body = ApiService.decode(res);
    if (res.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Failed to fetch outgoing requests',
        res.statusCode,
      );
    }

    final data = body['data'] as List<dynamic>;
    return data
        .map(
          (item) => FriendRequest.fromMap({
            'id': item['id'],
            'fromUid': item['fromUser']?['id'] ?? '',
            'fromEmail': item['fromUser']?['email'] ?? '',
            'toUid': item['toUser']?['id'] ?? '',
            'toEmail': item['toUser']?['email'] ?? '',
            'status': item['status'] ?? 'pending',
            'createdAt': item['createdAt'],
          }, item['id']),
        )
        .toList();
  }

  static Future<List<Friend>> getFriends() async {
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}/friends/list'),
      headers: await ApiService.authHeaders(),
    );

    final body = ApiService.decode(res);
    if (res.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Failed to fetch friends',
        res.statusCode,
      );
    }

    final data = body['data'] as List<dynamic>;
    return data
        .map(
          (item) => Friend(
            uid: item['id']?.toString() ?? '',
            email: item['email']?.toString() ?? '',
            displayName: item['email']?.toString().split('@')[0] ?? 'User',
          ),
        )
        .toList();
  }

  static Future<void> acceptRequest(String requestId) async {
    final res = await http.post(
      Uri.parse('${ApiService.baseUrl}/friends/requests/$requestId/accept'),
      headers: await ApiService.authHeaders(),
    );

    final body = ApiService.decode(res);
    if (res.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Failed to accept request',
        res.statusCode,
      );
    }
  }

  static Future<void> rejectRequest(String requestId) async {
    final res = await http.post(
      Uri.parse('${ApiService.baseUrl}/friends/requests/$requestId/reject'),
      headers: await ApiService.authHeaders(),
    );

    final body = ApiService.decode(res);
    if (res.statusCode != 200) {
      throw ApiException(
        body['message'] ?? 'Failed to reject request',
        res.statusCode,
      );
    }
  }
}
