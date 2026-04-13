/**
 * Data Transfer Object for User
 * Encapsulates user data and provides validation
 */
class UserDTO {
  constructor({
    id,
    email,
    password,
    firstName,
    lastName,
    phone,
    role,
    assignedParishId,
    preferredParishId,
    googleId,
    isActive,
    lastLoginAt,
    createdAt,
    updatedAt,
  }) {
    this.id = id;
    this.email = email;
    this.password = password;
    this.firstName = firstName;
    this.lastName = lastName;
    this.phone = phone;
    this.role = role;
    this.assignedParishId = assignedParishId;
    this.preferredParishId = preferredParishId;
    this.googleId = googleId;
    this.isActive = isActive;
    this.lastLoginAt = lastLoginAt;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  /**
   * Creates DTO from request body (for registration)
   */
  static fromRegisterRequest(body) {
    return new this({
      email: body.email,
      password: body.password,
      firstName: body.firstName,
      lastName: body.lastName,
      phone: body.phone,
      role: body.role || 'parishioner',
    });
  }

  /**
   * Creates DTO from request body (for login)
   */
  static fromLoginRequest(body) {
    return new this({
      email: body.email,
      password: body.password,
    });
  }

  /**
   * Creates DTO from request body (for profile update)
   */
  static fromProfileUpdateRequest(body) {
    return new this({
      firstName: body.firstName,
      lastName: body.lastName,
      phone: body.phone,
      address: body.address,
    });
  }

  /**
   * Creates DTO from database entity
   */
  static fromEntity(entity) {
    if (!entity) return null;
    return new this({
      id: entity.id,
      email: entity.email,
      firstName: entity.firstName,
      lastName: entity.lastName,
      phone: entity.phone,
      role: entity.role,
      assignedParishId: entity.assignedParishId,
      preferredParishId: entity.preferredParishId,
      googleId: entity.googleId,
      isActive: entity.isActive,
      lastLoginAt: entity.lastLoginAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    });
  }

  /**
   * Creates DTOs from database entities
   */
  static fromEntities(entities) {
    return entities.map(entity => this.fromEntity(entity));
  }

  /**
   * Validates registration data
   */
  validateForRegistration() {
    const errors = [];

    if (!this.email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.email)) {
      errors.push('Valid email is required');
    }

    if (!this.password || this.password.length < 8) {
      errors.push('Password must be at least 8 characters');
    }

    if (!this.firstName || typeof this.firstName !== 'string') {
      errors.push('First name is required');
    }

    if (!this.lastName || typeof this.lastName !== 'string') {
      errors.push('Last name is required');
    }

    const validRoles = ['parishioner', 'parish_staff', 'priest', 'diocese_staff', 'parish_admin', 'diocese_admin'];
    if (this.role && !validRoles.includes(this.role)) {
      errors.push('Invalid role');
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  /**
   * Validates login data
   */
  validateForLogin() {
    const errors = [];

    if (!this.email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.email)) {
      errors.push('Valid email is required');
    }

    if (!this.password) {
      errors.push('Password is required');
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  /**
   * Validates profile update data
   */
  validateForProfileUpdate() {
    const errors = [];

    if (this.firstName && typeof this.firstName !== 'string') {
      errors.push('First name must be a string');
    }

    if (this.lastName && typeof this.lastName !== 'string') {
      errors.push('Last name must be a string');
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  /**
   * Returns only allowed update fields
   */
  getAllowedUpdates(allowedFields) {
    const updateData = {};
    for (const field of allowedFields) {
      if (this[field] !== undefined) {
        updateData[field] = this[field];
      }
    }
    return updateData;
  }

  /**
   * Converts to plain object (without sensitive data)
   */
  toSafeObject() {
    return {
      id: this.id,
      email: this.email,
      firstName: this.firstName,
      lastName: this.lastName,
      phone: this.phone,
      role: this.role,
      assignedParishId: this.assignedParishId,
      preferredParishId: this.preferredParishId,
      isActive: this.isActive,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }

  /**
   * Converts to plain object (full)
   */
  toObject() {
    return {
      id: this.id,
      email: this.email,
      firstName: this.firstName,
      lastName: this.lastName,
      phone: this.phone,
      role: this.role,
      assignedParishId: this.assignedParishId,
      preferredParishId: this.preferredParishId,
      googleId: this.googleId,
      isActive: this.isActive,
      lastLoginAt: this.lastLoginAt,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }
}

module.exports = UserDTO;
