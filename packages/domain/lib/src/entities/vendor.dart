import 'package:equatable/equatable.dart';

/// Vendor status types
enum VendorStatus {
  /// Vendor account is pending approval
  pending,
  
  /// Vendor account is active and operational
  active,
  
  /// Vendor account is suspended
  suspended,
  
  /// Vendor account is under review
  underReview,
  
  /// Vendor account is inactive
  inactive,
}

/// Vendor entity representing a business vendor in the system
/// This is the business-side representation, separate from Shop (customer-facing)
class Vendor extends Equatable {
  /// Unique identifier for the vendor
  final String id;
  
  /// Business name
  final String businessName;
  
  /// Business owner name
  final String ownerName;
  
  /// Business address
  final String businessAddress;
  
  /// Business phone number
  final String businessPhone;
  
  /// Business email
  final String businessEmail;
  
  /// Business license number
  final String? businessLicense;
  
  /// Tax ID or business registration number
  final String? taxId;
  
  /// Current status of the vendor
  final VendorStatus status;
  
  /// Overall rating (1-5)
  final double rating;
  
  /// Number of ratings
  final int ratingCount;
  
  /// Categories this vendor operates in
  final List<String> categories;
  
  /// Associated shop ID (customer-facing representation)
  final String? shopId;
  
  /// Bank account details for payments
  final String? bankAccount;
  
  /// Commission rate percentage
  final double commissionRate;
  
  /// Whether vendor is verified
  final bool isVerified;
  
  /// Profile picture URL
  final String? profileImageUrl;
  
  /// Business documents URLs
  final List<String> documents;
  
  /// Date when vendor was registered
  final DateTime createdAt;
  
  /// Date when vendor was last updated
  final DateTime updatedAt;
  
  /// Date when vendor was last verified
  final DateTime? verifiedAt;

  /// Creates a vendor entity
  const Vendor({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.businessAddress,
    required this.businessPhone,
    required this.businessEmail,
    this.businessLicense,
    this.taxId,
    required this.status,
    required this.rating,
    required this.ratingCount,
    required this.categories,
    this.shopId,
    this.bankAccount,
    required this.commissionRate,
    required this.isVerified,
    this.profileImageUrl,
    required this.documents,
    required this.createdAt,
    required this.updatedAt,
    this.verifiedAt,
  });

  /// Creates a copy of this vendor with the given fields replaced
  Vendor copyWith({
    String? id,
    String? businessName,
    String? ownerName,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    String? Function()? businessLicense,
    String? Function()? taxId,
    VendorStatus? status,
    double? rating,
    int? ratingCount,
    List<String>? categories,
    String? Function()? shopId,
    String? Function()? bankAccount,
    double? commissionRate,
    bool? isVerified,
    String? Function()? profileImageUrl,
    List<String>? documents,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? Function()? verifiedAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      businessLicense: businessLicense != null ? businessLicense() : this.businessLicense,
      taxId: taxId != null ? taxId() : this.taxId,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      categories: categories ?? this.categories,
      shopId: shopId != null ? shopId() : this.shopId,
      bankAccount: bankAccount != null ? bankAccount() : this.bankAccount,
      commissionRate: commissionRate ?? this.commissionRate,
      isVerified: isVerified ?? this.isVerified,
      profileImageUrl: profileImageUrl != null ? profileImageUrl() : this.profileImageUrl,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verifiedAt: verifiedAt != null ? verifiedAt() : this.verifiedAt,
    );
  }
  
  /// Empty vendor instance
  factory Vendor.empty() {
    return Vendor(
      id: '',
      businessName: '',
      ownerName: '',
      businessAddress: '',
      businessPhone: '',
      businessEmail: '',
      status: VendorStatus.pending,
      rating: 0,
      ratingCount: 0,
      categories: [],
      commissionRate: 0,
      isVerified: false,
      documents: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Creates a vendor from JSON
  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as String,
      businessName: json['businessName'] as String,
      ownerName: json['ownerName'] as String,
      businessAddress: json['businessAddress'] as String,
      businessPhone: json['businessPhone'] as String,
      businessEmail: json['businessEmail'] as String,
      businessLicense: json['businessLicense'] as String?,
      taxId: json['taxId'] as String?,
      status: _parseVendorStatus(json['status'] as String),
      rating: (json['rating'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      categories: List<String>.from(json['categories'] as List),
      shopId: json['shopId'] as String?,
      bankAccount: json['bankAccount'] as String?,
      commissionRate: (json['commissionRate'] as num).toDouble(),
      isVerified: json['isVerified'] as bool,
      profileImageUrl: json['profileImageUrl'] as String?,
      documents: List<String>.from(json['documents'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      verifiedAt: json['verifiedAt'] != null 
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
    );
  }

  /// Parse vendor status from string
  static VendorStatus _parseVendorStatus(String statusString) {
    switch (statusString.toUpperCase()) {
      case 'PENDING':
        return VendorStatus.pending;
      case 'ACTIVE':
        return VendorStatus.active;
      case 'SUSPENDED':
        return VendorStatus.suspended;
      case 'UNDER_REVIEW':
        return VendorStatus.underReview;
      case 'INACTIVE':
        return VendorStatus.inactive;
      default:
        return VendorStatus.pending;
    }
  }

  /// Converts the vendor to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': businessName,
      'ownerName': ownerName,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'businessEmail': businessEmail,
      'businessLicense': businessLicense,
      'taxId': taxId,
      'status': status.toString().split('.').last,
      'rating': rating,
      'ratingCount': ratingCount,
      'categories': categories,
      'shopId': shopId,
      'bankAccount': bankAccount,
      'commissionRate': commissionRate,
      'isVerified': isVerified,
      'profileImageUrl': profileImageUrl,
      'documents': documents,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }
  
  @override
  List<Object?> get props => [
    id, businessName, ownerName, businessAddress, businessPhone,
    businessEmail, businessLicense, taxId, status, rating, ratingCount,
    categories, shopId, bankAccount, commissionRate, isVerified,
    profileImageUrl, documents, createdAt, updatedAt, verifiedAt,
  ];
} 