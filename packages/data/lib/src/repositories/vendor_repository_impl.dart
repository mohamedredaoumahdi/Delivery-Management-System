import 'package:domain/domain.dart';
import '../datasources/vendor_remote_datasource.dart';

/// Implementation of vendor repository
class VendorRepositoryImpl implements VendorRepository {
  final VendorRemoteDataSource remoteDataSource;

  VendorRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Vendor> getVendorById(String vendorId) async {
    try {
      final data = await remoteDataSource.getVendorById(vendorId);
      return Vendor.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get vendor: $e');
    }
  }

  @override
  Future<Vendor> getCurrentVendor() async {
    try {
      final data = await remoteDataSource.getCurrentVendor();
      return Vendor.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get current vendor: $e');
    }
  }

  @override
  Future<Vendor> updateVendor(Vendor vendor) async {
    try {
      final data = await remoteDataSource.updateVendor(vendor.toJson());
      return Vendor.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update vendor: $e');
    }
  }

  @override
  Future<VendorDashboard> getDashboardData(String vendorId) async {
    try {
      final data = await remoteDataSource.getDashboardData(vendorId);
      return VendorDashboard.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get dashboard data: $e');
    }
  }

  @override
  Future<Vendor> updateVendorStatus(String vendorId, VendorStatus status) async {
    try {
      final statusString = status.toString().split('.').last;
      final data = await remoteDataSource.updateVendorStatus(vendorId, statusString);
      return Vendor.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update vendor status: $e');
    }
  }

  @override
  Future<String> uploadDocument(String vendorId, String filePath, String documentType) async {
    try {
      return await remoteDataSource.uploadDocument(vendorId, filePath, documentType);
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  @override
  Future<Vendor> updateBankingInfo(String vendorId, String bankAccount) async {
    try {
      final data = await remoteDataSource.updateBankingInfo(vendorId, bankAccount);
      return Vendor.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update banking info: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAnalytics(String vendorId, DateTime startDate, DateTime endDate) async {
    try {
      return await remoteDataSource.getAnalytics(
        vendorId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      );
    } catch (e) {
      throw Exception('Failed to get analytics: $e');
    }
  }

  @override
  Future<bool> toggleShopStatus(String vendorId, bool isOpen) async {
    try {
      return await remoteDataSource.toggleShopStatus(vendorId, isOpen);
    } catch (e) {
      throw Exception('Failed to toggle shop status: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getVerificationStatus(String vendorId) async {
    try {
      return await remoteDataSource.getVerificationStatus(vendorId);
    } catch (e) {
      throw Exception('Failed to get verification status: $e');
    }
  }

  @override
  Future<void> submitForVerification(String vendorId) async {
    try {
      await remoteDataSource.submitForVerification(vendorId);
    } catch (e) {
      throw Exception('Failed to submit for verification: $e');
    }
  }
} 