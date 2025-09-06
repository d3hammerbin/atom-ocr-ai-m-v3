part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const SPLASH = _Paths.SPLASH;
  static const INITIAL = _Paths.INITIAL;
  static const HOME = _Paths.HOME;
  static const OCR = _Paths.OCR;
  static const CAMERA = _Paths.CAMERA;
  static const CREDENTIALS_LIST = _Paths.CREDENTIALS_LIST;
  static const PROCESSING = _Paths.PROCESSING;
  static const LOCAL_PROCESS = _Paths.LOCAL_PROCESS;
  static const CAPTURE_SELECTION = _Paths.CAPTURE_SELECTION;
}

abstract class _Paths {
  _Paths._();
  static const SPLASH = '/splash';
  static const INITIAL = '/initial';
  static const HOME = '/home';
  static const OCR = '/ocr';
  static const CAMERA = '/camera';
  static const CREDENTIALS_LIST = '/credentials-list';
  static const PROCESSING = '/processing';
  static const LOCAL_PROCESS = '/local-process';
  static const CAPTURE_SELECTION = '/capture-selection';
}