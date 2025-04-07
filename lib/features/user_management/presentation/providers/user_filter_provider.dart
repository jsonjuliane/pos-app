import 'package:flutter_riverpod/flutter_riverpod.dart';

final userSearchQueryProvider = StateProvider<String>((ref) => '');
final userRoleFilterProvider = StateProvider<String>((ref) => 'all');
final userBranchFilterProvider = StateProvider<String>((ref) => 'all');
