part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const HOME = _Paths.HOME;
  static const OCR = _Paths.OCR;
  static const CAMERA = _Paths.CAMERA;
  static const CREDENTIALS_LIST = _Paths.CREDENTIALS_LIST;
}

abstract class _Paths {
  _Paths._();
  static const HOME = '/home';
  static const OCR = '/ocr';
  static const CAMERA = '/camera';
  static const CREDENTIALS_LIST = '/credentials-list';
}