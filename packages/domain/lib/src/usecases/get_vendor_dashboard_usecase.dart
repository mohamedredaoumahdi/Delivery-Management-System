import '../entities/vendor_dashboard.dart';
import '../repositories/vendor_repository.dart';

/// Use case for getting vendor dashboard data
class GetVendorDashboardUseCase {
  final VendorRepository repository;

  GetVendorDashboardUseCase(this.repository);

  /// Execute the use case to get dashboard data for a vendor
  Future<VendorDashboard> call(String vendorId) async {
    return await repository.getDashboardData(vendorId);
  }
} 