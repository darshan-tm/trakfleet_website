import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void openDeviceOverview(BuildContext context, Map<String, dynamic> device) {
  context.pushNamed(
    'deviceOverview',
    pathParameters: {'imei': device['imei']},
    extra: device,
  );
}

void openDeviceDiagnostics(BuildContext context, Map<String, dynamic> device) {
  context.pushNamed(
    'deviceDiagnostics',
    pathParameters: {'imei': device['imei']},
    extra: device,
  );
}

void openDeviceConfiguration(
  BuildContext context,
  Map<String, dynamic> device,
) {
  context.pushNamed(
    'deviceConfiguration',
    pathParameters: {'imei': device['imei']},
    extra: device,
  );
}
