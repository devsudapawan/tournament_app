// // lib/core/network/network_info.dart
// //
// // Checks internet connectivity before making network calls.
// // Usage: inject NetworkInfo and call isConnected before any remote call.
//
// import 'dart:io';
//
// abstract class NetworkInfo {
//   Future<bool> get isConnected;
// }
//
// class NetworkInfoImpl implements NetworkInfo {
//   @override
//   Future<bool> get isConnected async {
//     try {
//       final result = await InternetAddress.lookup('google.com')
//           .timeout(const Duration(seconds: 5));
//       return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//     } catch (_) {
//       return false;
//     }
//   }
// }
