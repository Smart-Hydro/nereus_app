import 'package:dio/dio.dart';
import 'package:nereus_app/core/json_util.dart';
import 'package:nereus_app/core/network/api_error.dart';

/// Cliente Dio de `/api/operations/`. El interceptor ya pone Token y X-Branch-ID.
class OpsHttp {
  OpsHttp(this.dio);

  final Dio dio;

  Future<List<T>> getList<T>(
    String path,
    T Function(Map<String, dynamic> json) parse, {
    Map<String, dynamic>? query,
  }) {
    return _guard(() async {
      final response = await dio.get<dynamic>(
        path,
        queryParameters: {
          'page_size': 100,
          ...?_clean(query),
        },
      );
      return _rows(response.data).map(parse).toList();
    });
  }

  Future<T> getOne<T>(
    String path,
    T Function(Map<String, dynamic> json) parse, {
    Map<String, dynamic>? query,
  }) {
    return _guard(() async {
      final response = await dio.get<dynamic>(path, queryParameters: _clean(query));
      return parse(asMap(response.data));
    });
  }

  Future<T> send<T>(
    String path, {
    String method = 'POST',
    Object? data,
    required T Function(Map<String, dynamic> json) parse,
  }) {
    return _guard(() async {
      final response = await dio.request<dynamic>(
        path,
        data: data,
        options: Options(method: method),
      );
      return parse(asMap(response.data));
    });
  }

  Future<List<T>> sendList<T>(
    String path,
    T Function(Map<String, dynamic> json) parse, {
    String method = 'POST',
    Object? data,
  }) {
    return _guard(() async {
      final response = await dio.request<dynamic>(
        path,
        data: data,
        options: Options(method: method),
      );
      return _rows(response.data).map(parse).toList();
    });
  }

  Future<void> sendEmpty(
    String path, {
    String method = 'POST',
    Object? data,
  }) {
    return _guard(() async {
      await dio.request<dynamic>(
        path,
        data: data,
        options: Options(method: method),
      );
    });
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stack) {
      throw ApiError.fromAny(error, stack);
    }
  }

  List<Map<String, dynamic>> _rows(dynamic data) {
    if (data is List) return asMapList(data);
    return asResults(data);
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return null;
    final out = <String, dynamic>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      out[entry.key] = value;
    }
    return out.isEmpty ? null : out;
  }
}
