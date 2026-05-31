import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ns_transport/models/salary_model.dart';
import 'package:ns_transport/services/salary_service.dart';
import 'package:ns_transport/providers/auth_provider.dart';

final salaryServiceProvider = Provider((ref) => SalaryService());

class SalaryNotifier extends StateNotifier<AsyncValue<List<SalaryModel>>> {
  final SalaryService _salaryService;
  final Ref _ref;

  SalaryNotifier(this._salaryService, this._ref) : super(const AsyncValue.loading());

  Future<void> loadSalaries() async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(authProvider).value;
      if (user == null) {
        state = const AsyncValue.data([]);
        return;
      }
      List<SalaryModel> salaries;
      if (user.isOwner) {
        salaries = await _salaryService.getAllSalaries();
      } else {
        salaries = await _salaryService.getDriverSalaries(user.id);
      }
      state = AsyncValue.data(salaries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> upsertSalary(SalaryModel salary) async {
    try {
      final updatedSalary = await _salaryService.upsertSalary(salary);
      if (state.hasValue) {
        final existingSalaries = state.value!;
        final index = existingSalaries.indexWhere((s) => s.id == updatedSalary.id);
        
        if (index >= 0) {
          final newList = List<SalaryModel>.from(existingSalaries);
          newList[index] = updatedSalary;
          state = AsyncValue.data(newList);
        } else {
          state = AsyncValue.data([updatedSalary, ...existingSalaries]);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}

final salaryProvider = StateNotifierProvider<SalaryNotifier, AsyncValue<List<SalaryModel>>>((ref) {
  return SalaryNotifier(ref.watch(salaryServiceProvider), ref);
});
