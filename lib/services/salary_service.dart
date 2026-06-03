import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ns_transport/models/salary_model.dart';
import 'package:ns_transport/core/errors/failure.dart';
import 'package:ns_transport/services/supabase_service.dart';

class SalaryService {
  final SupabaseClient _supabase = SupabaseService.client;

  Future<List<SalaryModel>> getDriverSalaries(String driverId) async {
    try {
      final response = await _supabase
          .from('salaries')
          .select()
          .eq('driver_id', driverId)
          .order('year', ascending: false)
          .order('month', ascending: false)
          .order('created_at', ascending: false);
      
      return response.map((json) => SalaryModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerFailure(message: 'Failed to get driver salaries: $e');
    }
  }

  Future<List<SalaryModel>> getAllSalaries() async {
    try {
      final response = await _supabase
          .from('salaries')
          .select()
          .order('year', ascending: false)
          .order('month', ascending: false)
          .order('created_at', ascending: false);
      
      return response.map((json) => SalaryModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerFailure(message: 'Failed to get all salaries: $e');
    }
  }

  Future<SalaryModel?> getSalaryByMonthYear(String driverId, int month, int year) async {
    try {
      final response = await _supabase
          .from('salaries')
          .select()
          .eq('driver_id', driverId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();
      
      if (response == null) return null;
      
      return SalaryModel.fromJson(response);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get salary by month and year: $e');
    }
  }

  Future<SalaryModel> upsertSalary(SalaryModel salary) async {
    try {
      final response = await _supabase
          .from('salaries')
          .upsert(salary.toJson())
          .select()
          .single();
      
      return SalaryModel.fromJson(response);
    } catch (e) {
      throw ServerFailure(message: 'Failed to upsert salary: $e');
    }
  }

  Future<SalaryModel> updateSalary(String id, double paidAmount, double advanceAmount) async {
    try {
      final response = await _supabase
          .from('salaries')
          .update({
            'paid_amount': paidAmount,
            'advance_amount': advanceAmount,
          })
          .eq('id', id)
          .select()
          .single();
      
      return SalaryModel.fromJson(response);
    } catch (e) {
      throw ServerFailure(message: 'Failed to update salary: $e');
    }
  }

  Future<void> deleteSalary(String id) async {
    try {
      await _supabase
          .from('salaries')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw ServerFailure(message: 'Failed to delete salary: $e');
    }
  }
}
