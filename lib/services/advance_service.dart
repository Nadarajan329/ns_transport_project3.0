import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ns_transport/models/advance_history_model.dart';
import 'package:ns_transport/core/errors/failure.dart';
import 'package:ns_transport/services/supabase_service.dart';

class AdvanceService {
  final SupabaseClient _supabase = SupabaseService.client;

  Future<List<AdvanceHistoryModel>> getAdvanceHistory(String driverId) async {
    try {
      final response = await _supabase
          .from('advance_history')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);
      
      return response.map((json) => AdvanceHistoryModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerFailure(message: 'Failed to get advance history: $e');
    }
  }

  Future<AdvanceHistoryModel> giveAdvance(String driverId, double amount, String description) async {
    try {
      // 1. Insert into advance_history
      final historyResponse = await _supabase
          .from('advance_history')
          .insert({
            'driver_id': driverId,
            'amount': amount,
            'type': 'given_by_owner',
            'description': description,
          })
          .select()
          .single();
          
      // 2. Update advance_balance in users table (this is better handled via a Postgres function
      // but since we don't have an RPC for this specific action yet, we can do it directly.
      // Wait, there's no atomic increment in standard REST without RPC.
      // We will fetch current user, and update it.
      final userRes = await _supabase.from('users').select('advance_balance').eq('id', driverId).single();
      double currentBalance = (userRes['advance_balance'] as num?)?.toDouble() ?? 0.0;
      
      await _supabase
          .from('users')
          .update({'advance_balance': currentBalance + amount})
          .eq('id', driverId);

      return AdvanceHistoryModel.fromJson(historyResponse);
    } catch (e) {
      throw ServerFailure(message: 'Failed to give advance: $e');
    }
  }

  Future<AdvanceHistoryModel> deductAdvance(String driverId, double amount, String description) async {
    try {
      // 1. Insert into advance_history as a deduction
      final historyResponse = await _supabase
          .from('advance_history')
          .insert({
            'driver_id': driverId,
            'amount': amount,
            'type': 'expense_adjustment', // Changed from deducted_for_salary to satisfy DB check constraint
            'description': description,
          })
          .select()
          .single();
          
      // 2. Update advance_balance in users table
      final userRes = await _supabase.from('users').select('advance_balance').eq('id', driverId).single();
      double currentBalance = (userRes['advance_balance'] as num?)?.toDouble() ?? 0.0;
      
      await _supabase
          .from('users')
          .update({'advance_balance': currentBalance - amount})
          .eq('id', driverId);

      return AdvanceHistoryModel.fromJson(historyResponse);
    } catch (e) {
      throw ServerFailure(message: 'Failed to deduct advance: $e');
    }
  }

  Future<AdvanceHistoryModel> updateAdvance(String id, String driverId, double oldAmount, double newAmount, String description, String type) async {
    try {
      // 1. Update the advance_history row
      final response = await _supabase
          .from('advance_history')
          .update({
            'amount': newAmount,
            'description': description,
          })
          .eq('id', id)
          .select()
          .single();

      // 2. Adjust advance_balance in users table
      final userRes = await _supabase.from('users').select('advance_balance').eq('id', driverId).single();
      double currentBalance = (userRes['advance_balance'] as num?)?.toDouble() ?? 0.0;
      
      double diff = newAmount - oldAmount;
      if (type == 'given_by_owner') {
        // If given_by_owner: increasing amount means more advance given
        await _supabase.from('users').update({'advance_balance': currentBalance + diff}).eq('id', driverId);
      } else {
        // If expense_adjustment/deduction: increasing amount means more deducted
        await _supabase.from('users').update({'advance_balance': currentBalance - diff}).eq('id', driverId);
      }

      return AdvanceHistoryModel.fromJson(response);
    } catch (e) {
      throw ServerFailure(message: 'Failed to update advance: $e');
    }
  }

  Future<void> deleteAdvance(String id, String driverId, double amount, String type) async {
    try {
      // 1. Delete the advance_history row
      await _supabase
          .from('advance_history')
          .delete()
          .eq('id', id);

      // 2. Reverse the advance_balance change in users table
      final userRes = await _supabase.from('users').select('advance_balance').eq('id', driverId).single();
      double currentBalance = (userRes['advance_balance'] as num?)?.toDouble() ?? 0.0;
      
      if (type == 'given_by_owner') {
        // Reverse: subtract what was given
        await _supabase.from('users').update({'advance_balance': currentBalance - amount}).eq('id', driverId);
      } else {
        // Reverse: add back what was deducted
        await _supabase.from('users').update({'advance_balance': currentBalance + amount}).eq('id', driverId);
      }
    } catch (e) {
      throw ServerFailure(message: 'Failed to delete advance: $e');
    }
  }
}
