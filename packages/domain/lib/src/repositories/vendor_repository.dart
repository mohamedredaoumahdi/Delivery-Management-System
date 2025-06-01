import '../entities/vendor.dart';
import '../entities/vendor_dashboard.dart';

/// Repository interface for vendor-related operations
abstract class VendorRepository {
  /// Get vendor profile by ID
  Future<Vendor> getVendorById(String vendorId);
  
  /// Get current authenticated vendor
  Future<Vendor> getCurrentVendor();
  
  /// Update vendor profile
  Future<Vendor> updateVendor(Vendor vendor);
  
  /// Get vendor dashboard data
  Future<VendorDashboard> getDashboardData(String vendorId);
  
  /// Update vendor status
  Future<Vendor> updateVendorStatus(String vendorId, VendorStatus status);
  
  /// Upload vendor document
  Future<String> uploadDocument(String vendorId, String filePath, String documentType);
  
  /// Update vendor banking information
  Future<Vendor> updateBankingInfo(String vendorId, String bankAccount);
  
  /// Get vendor analytics data for date range
  Future<Map<String, dynamic>> getAnalytics(String vendorId, DateTime startDate, DateTime endDate);
  
  /// Toggle vendor shop status (open/closed)
  Future<bool> toggleShopStatus(String vendorId, bool isOpen);
  
  /// Get vendor verification status
  Future<Map<String, dynamic>> getVerificationStatus(String vendorId);
  
  /// Submit vendor for verification
  Future<void> submitForVerification(String vendorId);
} 