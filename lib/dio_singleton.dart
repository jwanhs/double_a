import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

class DioSingleton {
  DioSingleton._internal() {
    final CookieJar cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(cookieJar));
  }

  static final DioSingleton _instance = DioSingleton._internal();

  factory DioSingleton() {
    return _instance;
  }

  final Dio dio = Dio(
    BaseOptions(
      headers: {
        'Content-Type': "application/x-www-form-urlencoded",
      },
    ),
  );

  static Dio get instance => _instance.dio;
}
