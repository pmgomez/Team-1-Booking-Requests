/**
 * Role Permissions Helper
 * Centralizes role-based permission checks across the application
 */

const ROLES = {
  PARISHIONER: 'parishioner',
  PARISH_STAFF: 'parish_staff',
  PRIEST: 'priest',
  DIOCESE_STAFF: 'diocese_staff',
  PARISH_ADMIN: 'parish_admin',
  DIOCESE_ADMIN: 'diocese_admin',
};

// Role hierarchy (higher roles inherit lower role permissions)
const ROLE_HIERARCHY = {
  [ROLES.PARISHIONER]: 1,
  [ROLES.PARISH_STAFF]: 2,
  [ROLES.PRIEST]: 3,
  [ROLES.PARISH_ADMIN]: 4,
  [ROLES.DIOCESE_STAFF]: 5,
  [ROLES.DIOCESE_ADMIN]: 6,
};

// Permission matrix
const PERMISSIONS = {
  // User Management
  CREATE_USER: [ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  UPDATE_USER: [ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  DELETE_USER: [ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  VIEW_ALL_USERS: [ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  
  // Parish Management
  CREATE_PARISH: [ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  UPDATE_PARISH: [ROLES.PARISH_ADMIN, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  DELETE_PARISH: [ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  VIEW_ALL_PARISHES: [ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  
  // Booking Management
  APPROVE_BOOKING: [ROLES.PARISH_STAFF, ROLES.PARISH_ADMIN, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  DECLINE_BOOKING: [ROLES.PARISH_STAFF, ROLES.PARISH_ADMIN, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  VIEW_ALL_BOOKINGS: [ROLES.PARISH_STAFF, ROLES.PARISH_ADMIN, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  UPDATE_BOOKING: [ROLES.PARISH_STAFF, ROLES.PARISH_ADMIN, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  DELETE_BOOKING: [ROLES.PARISH_ADMIN, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  
  // Mass Intentions
  APPROVE_MASS_INTENTION: [ROLES.PARISH_STAFF, ROLES.PRIEST, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  DECLINE_MASS_INTENTION: [ROLES.PARISH_STAFF, ROLES.PRIEST, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  
  // Mass Schedules
  CREATE_MASS_SCHEDULE: [ROLES.PARISH_ADMIN, ROLES.PARISH_STAFF, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  UPDATE_MASS_SCHEDULE: [ROLES.PARISH_ADMIN, ROLES.PARISH_STAFF, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  DELETE_MASS_SCHEDULE: [ROLES.PARISH_ADMIN, ROLES.PARISH_STAFF, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  
  // Payments
  VIEW_PAYMENTS: [ROLES.PARISH_ADMIN, ROLES.PARISH_STAFF, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  UPDATE_PAYMENT: [ROLES.PARISH_ADMIN, ROLES.PARISH_STAFF, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  DELETE_PAYMENT: [ROLES.PARISH_ADMIN, ROLES.PARISH_STAFF, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  
  // Sacramental Records
  CREATE_SACRAMENTAL_RECORD: [ROLES.PARISH_ADMIN, ROLES.PARISH_STAFF, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  UPDATE_SACRAMENTAL_RECORD: [ROLES.PARISH_ADMIN, ROLES.PARISH_STAFF, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  DELETE_SACRAMENTAL_RECORD: [ROLES.PARISH_ADMIN, ROLES.PARISH_STAFF, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  BULK_UPLOAD_SACRAMENTAL_RECORDS: [ROLES.DIOCESE_ADMIN],
  
  // Dashboard
  VIEW_DASHBOARD: [ROLES.PARISH_ADMIN, ROLES.PARISH_STAFF, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  VIEW_DIOCESE_STATS: [ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  
  // Settings
  MANAGE_PARISH_SETTINGS: [ROLES.PARISH_ADMIN, ROLES.PARISH_STAFF, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
  MANAGE_BLACKOUT_DATES: [ROLES.PARISH_ADMIN, ROLES.PARISH_STAFF, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN],
};

class RoleHelper {
  /**
   * Check if a role has a specific permission
   */
  static hasPermission(role, permission) {
    const allowedRoles = PERMISSIONS[permission];
    if (!allowedRoles) return false;
    return allowedRoles.includes(role);
  }

  /**
   * Check if user has any of the required permissions
   */
  static hasAnyPermission(role, permissions) {
    return permissions.some(permission => this.hasPermission(role, permission));
  }

  /**
   * Check if role is admin level (parish or diocese)
   */
  static isAdmin(role) {
    return [ROLES.PARISH_ADMIN, ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN].includes(role);
  }

  /**
   * Check if role is diocese level
   */
  static isDioceseLevel(role) {
    return [ROLES.DIOCESE_STAFF, ROLES.DIOCESE_ADMIN].includes(role);
  }

  /**
   * Check if role is parish level
   */
  static isParishLevel(role) {
    return [ROLES.PARISH_STAFF, ROLES.PARISH_ADMIN].includes(role);
  }

  /**
   * Check if user can manage a specific parish
   */
  static canManageParish(role, parishId, userAssignedParishId) {
    if (this.isDioceseLevel(role)) return true;
    if (this.isParishLevel(role)) return parishId === userAssignedParishId;
    return false;
  }

  /**
   * Get role hierarchy level
   */
  static getRoleLevel(role) {
    return ROLE_HIERARCHY[role] || 0;
  }

  /**
   * Check if role1 can manage role2
   */
  static canManageRole(managerRole, targetRole) {
    return this.getRoleLevel(managerRole) > this.getRoleLevel(targetRole);
  }

  /**
   * Get all permissions for a role
   */
  static getPermissionsForRole(role) {
    const permissions = [];
    for (const [permission, allowedRoles] of Object.entries(PERMISSIONS)) {
      if (allowedRoles.includes(role)) {
        permissions.push(permission);
      }
    }
    return permissions;
  }

  /**
   * Get human-readable role name
   */
  static getRoleDisplayName(role) {
    const names = {
      [ROLES.PARISHIONER]: 'Parishioner',
      [ROLES.PARISH_STAFF]: 'Parish Staff',
      [ROLES.PRIEST]: 'Priest',
      [ROLES.PARISH_ADMIN]: 'Parish Administrator',
      [ROLES.DIOCESE_STAFF]: 'Diocese Staff',
      [ROLES.DIOCESE_ADMIN]: 'Diocese Administrator',
    };
    return names[role] || role;
  }
}

module.exports = { RoleHelper, ROLES, PERMISSIONS };
