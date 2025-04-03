import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/user_management/data/domain/repositories/branch_repository.dart';
import '../models/branch.dart';

final allBranchesProvider = StreamProvider.autoDispose<List<Branch>>((ref) {
  final branchRepository = ref.read(branchRepositoryProvider); // Get the branch repository instance
  return branchRepository.getAllBranches(); // Use the repository to fetch branches in real-time
});

final branchNamesProvider = StreamProvider.autoDispose<Map<String, String>>((ref) {
  final branchRepository = ref.read(branchRepositoryProvider); // Get the branch repository instance
  return branchRepository.getBranchNames(); // Use the repository to fetch branch names in real-time
});

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  return BranchRepository();
});
