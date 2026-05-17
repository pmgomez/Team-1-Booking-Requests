/// Role constants matching backend
class Roles {
  static const String parishioner = 'parishioner';
  static const String parishStaff = 'parish_staff';
  static const String priest = 'priest';
  static const String dioceseStaff = 'diocese_staff';
  static const String parishAdmin = 'parish_admin';
  static const String dioceseAdmin = 'diocese_admin';
  
  static const List<String> allRoles = [
    parishioner,
    parishStaff,
    priest,
    parishAdmin,
    dioceseStaff,
    dioceseAdmin,
  ];
  
  /// Check if role is admin level (can manage bookings)
  static bool isAdmin(String role) {
    return [parishAdmin, parishStaff, dioceseStaff, dioceseAdmin].contains(role);
  }
  
  /// Check if role is diocese level (can manage all parishes)
  static bool isDioceseLevel(String role) {
    return [dioceseStaff, dioceseAdmin].contains(role);
  }

  /// Check if role is priest
  static bool isPriest(String role) {
    return role == priest;
  }
  
  /// Check if role is parish level (restricted to one parish)
  static bool isParishLevel(String role) {
    return [parishStaff, parishAdmin].contains(role);
  }
  
  /// Check if user can approve/decline bookings
  static bool canApproveBookings(String role) {
    return [parishStaff, parishAdmin, dioceseStaff, dioceseAdmin].contains(role);
  }
  
  /// Check if user can manage other users
  static bool canManageUsers(String role) {
    return [dioceseStaff, dioceseAdmin].contains(role);
  }
  
  /// Check if user can manage parishes
  static bool canManageParishes(String role) {
    return [dioceseStaff, dioceseAdmin].contains(role);
  }
  
  /// Check if user can view dashboard
  static bool canViewDashboard(String role) {
    return [parishStaff, parishAdmin, dioceseStaff, dioceseAdmin].contains(role);
  }
  
  /// Check if user can manage sacramental records
  static bool canManageSacramentalRecords(String role) {
    return [parishStaff, parishAdmin, dioceseStaff, dioceseAdmin].contains(role);
  }
  
  /// Check if user can do bulk upload (diocese admin only)
  static bool canBulkUploadRecords(String role) {
    return role == dioceseAdmin;
  }
  
  /// Get human-readable role name
  static String getRoleDisplayName(String role) {
    switch (role) {
      case parishioner:
        return 'Parishioner';
      case parishStaff:
        return 'Parish Staff';
      case priest:
        return 'Priest';
      case parishAdmin:
        return 'Parish Administrator';
      case dioceseStaff:
        return 'Diocese Staff';
      case dioceseAdmin:
        return 'Diocese Administrator';
      default:
        return role;
    }
  }
  
  /// Role hierarchy level (for comparison)
  static int getRoleLevel(String role) {
    switch (role) {
      case parishioner:
        return 1;
      case parishStaff:
        return 2;
      case priest:
        return 3;
      case parishAdmin:
        return 4;
      case dioceseStaff:
        return 5;
      case dioceseAdmin:
        return 6;
      default:
        return 0;
    }
  }
  
  /// Check if managerRole can manage targetRole
  static bool canManageRole(String managerRole, String targetRole) {
    return getRoleLevel(managerRole) > getRoleLevel(targetRole);
  }

  /// Get available roles that a user with the given role can assign
  static List<String> getAvailableRolesForUserManagement(String currentUserRole) {
    // diocese_admin can assign all roles
    if (currentUserRole == dioceseAdmin) {
      return allRoles;
    }
    // diocese_staff can only assign roles lower than their own
    return allRoles.where((role) => getRoleLevel(role) < getRoleLevel(currentUserRole)).toList();
  }

  /// Check if a user can view another user
  static bool canViewUser(String viewerRole, String targetRole) {
    // diocese_admin can view all users
    if (viewerRole == dioceseAdmin) return true;
    // diocese_staff cannot view diocese_staff or diocese_admin
    if (viewerRole == dioceseStaff && [dioceseStaff, dioceseAdmin].contains(targetRole)) {
      return false;
    }
    // All other admin roles can view each other
    return true;
  }
  
  /// Check if a role should have parish selection (diocese-level roles don't belong to a parish)
  static bool shouldShowParishSelection(String role) {
    return !isDioceseLevel(role);
  }
}
