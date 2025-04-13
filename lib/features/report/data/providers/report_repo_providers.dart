import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repository/report_repository.dart';

final reportRepoProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});
