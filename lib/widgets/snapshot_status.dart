import 'package:flutter/material.dart';

/// Build a widget that depends on the current status of a [FutureBuilder]. If the future has completed and the data is
/// ready, then null is returned. Example:
/// ```dart
/// var futureStatus = buildFutureStatus(snapshot, loadingText: 'Loading Data');
/// if (futureStatus != null) return futureStatus;
/// // Process snapshot.data
/// ```
///
/// [snapshot] snapshot provided by the [FutureBuilder]
///
/// [loadingText] text that displays while the future is processing
///
/// [errorPrefix] text that will come before an error message, if an error occurred
///
/// [noDataText] text that displays if no data is available after the future completes; do not provide this if the
///   future is not intended to return data
///
/// returns a [Widget] if there is a status to report, or null if the future is complete and the data is ready
Widget? buildFutureStatus(AsyncSnapshot snapshot, { String? loadingText, String? errorPrefix, String? noDataText }) {
  if (snapshot.connectionState == ConnectionState.waiting) return Text(loadingText ?? 'Loading...');
  if (snapshot.hasError) return Text('${errorPrefix ?? 'Error'}: ${snapshot.error}');
  if (!snapshot.hasData && noDataText != null) return Text(noDataText);
  return null;
}