import 'package:get/get.dart';
import 'logs_controller.dart';

class LogsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LogsController>(() => LogsController());
  }
}