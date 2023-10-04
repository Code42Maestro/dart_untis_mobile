// This is a private part of the dart_untis_mobile library
// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth.dart';
import 'objects.dart';
import 'util.dart';

abstract class UntisRequest {
  late final Uri apiEndpoint;
  final String _id = '-1';
  final String _jsonrpc = '2.0';

  abstract final String _method;
  Map<String, dynamic> _params = <String, dynamic>{};
  final UntisAuthentication? auth;

  UntisRequest(String apiEndpoint, {this.auth}) {
    this.apiEndpoint = Uri.parse(apiEndpoint.replaceAll('%METHOD%', _method));
  }

  Future<Object?> _request() async {
    _params['auth'] = auth;
    final String request = jsonEncode(<String, dynamic>{
      'id': _id,
      'jsonrpc': _jsonrpc,
      'method': _method,
      'params': <Map<String, dynamic>>[_params]
    });
    final http.Response response = await http.post(apiEndpoint,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: request);
    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    if (response.statusCode != 200 || jsonResponse.containsKey('error')) {
      final int untisErrorCode =
          (jsonResponse['error'] as Map<String, dynamic>)['code'];
      final String untisErrorText = untisErrorCode == -8520
          ? '\nYou need to authenticate with .login() first.'
          : '';
      throw HttpException(
          'An exception occurred while communicating with the WebUntis API: '
          "${jsonResponse["error"]}$untisErrorText");
    }
    return jsonResponse['result'];
  }

  Future<dynamic> request();
}

class AppSharedSecretRequest extends UntisRequest {
  @override
  final String _method = 'getAppSharedSecret';

  AppSharedSecretRequest(super.apiEndpoint, String username, String password) {
    super._params = <String, dynamic>{
      'userName': username,
      'password': password
    };
  }

  @override
  Future<String?> request() async {
    return (await super._request()) as String?;
  }
}

class UserDataRequest extends UntisRequest {
  @override
  final String _method = 'getUserData2017';

  UserDataRequest(super.apiEndpoint, UntisAuthentication auth)
      : super(auth: auth) {
    super._params = <String, dynamic>{'deviceOs': '', 'elementId': 0};
  }

  @override
  Future<Map<String, dynamic>?> request() async {
    final Map<String, dynamic>? json =
        (await super._request()) as Map<String, dynamic>?;
    return json;
  }
}

class AbsencesRequest extends UntisRequest {
  @override
  final String _method = 'getStudentAbsences2017';

  /// If startDate lies more in the Future than endDate,
  /// endDate will be startDate + 356days
  AbsencesRequest(
      super.apiEndpoint,
      UntisAuthentication auth,
      DateTime startDate,
      DateTime endDate,
      bool includeExcused,
      bool includeUnExcused)
      : super(auth: auth) {
    final Duration dateDiff = startDate.difference(endDate);
    if (dateDiff.isNegative) endDate = startDate.add(const Duration(days: 356));
    super._params = <String, dynamic>{
      'startDate': dateTimeToUntisDate(startDate),
      'endDate': dateTimeToUntisDate(endDate),
      'includeExcused': includeExcused,
      'includeUnExcused': includeUnExcused
    };
  }

  @override
  Future<Map<String, dynamic>?> request() async {
    final Map<String, dynamic>? json =
        (await super._request()) as Map<String, dynamic>?;
    return json;
  }
}

class ExamsRequest extends UntisRequest {
  @override
  final String _method = 'getExams2017';

  /// If startDate lies more in the Future than endDate,
  /// endDate will be startDate + 7days
  ExamsRequest(super.apiEndpoint, UntisAuthentication auth,
      UntisElementDescriptor id, DateTime startDate, DateTime endDate)
      : super(auth: auth) {
    final Duration dateDiff = startDate.difference(endDate);
    if (dateDiff.isNegative) endDate = startDate.add(const Duration(days: 7));
    super._params = <String, dynamic>{
      'id': id.id,
      'type': id.type.name,
      'startDate': dateTimeToUntisDate(startDate),
      'endDate': dateTimeToUntisDate(endDate)
    };
  }

  @override
  Future<Map<String, dynamic>?> request() async {
    final Map<String, dynamic>? json =
        (await super._request()) as Map<String, dynamic>?;
    return json;
  }
}

class HomeworkRequest extends UntisRequest {
  @override
  final String _method = 'getHomeWork2017';

  /// If startDate lies more in the Future than endDate,
  /// endDate will be startDate + 7days
  HomeworkRequest(super.apiEndpoint, UntisAuthentication auth,
      UntisElementDescriptor id, DateTime startDate, DateTime endDate)
      : super(auth: auth) {
    final Duration dateDiff = startDate.difference(endDate);
    if (dateDiff.isNegative) endDate = startDate.add(const Duration(days: 7));
    super._params = <String, dynamic>{
      'id': id.id,
      'type': id.type.name,
      'startDate': dateTimeToUntisDate(startDate),
      'endDate': dateTimeToUntisDate(endDate)
    };
  }

  @override
  Future<Map<String, dynamic>?> request() async {
    final Map<String, dynamic>? json =
        (await super._request()) as Map<String, dynamic>?;
    return json;
  }
}

class TimetableRequest extends UntisRequest {
  @override
  final String _method = 'getTimetable2017';

  /// masterDataTimestamp will tell the Untis API if current masterData is
  /// up to date, if not it will send an update
  /// If startDate lies more in the Future than endDate,
  /// endDate will be startDate + 7days
  TimetableRequest(
      super.apiEndpoint,
      UntisAuthentication auth,
      UntisElementDescriptor id,
      int masterDataTimestamp,
      DateTime startDate,
      DateTime endDate)
      : super(auth: auth) {
    final Duration dateDiff = startDate.difference(endDate);
    if (dateDiff.isNegative) endDate = startDate.add(const Duration(days: 7));

    super._params = <String, dynamic>{
      'id': id.id,
      'type': id.type.name,
      'startDate': dateTimeToUntisDate(startDate),
      'endDate': dateTimeToUntisDate(endDate),
      'masterDataTimestamp': masterDataTimestamp,
      'timetableTimestamp': 0,
      'timetableTimestamps': <int>[for (int i = 0; i < dateDiff.inDays; i++) 0]
    };
  }

  @override
  Future<Map<String, dynamic>?> request() async {
    final Map<String, dynamic>? json =
        (await super._request()) as Map<String, dynamic>?;
    return json;
  }
}
