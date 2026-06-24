const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { User, Parish } = require('../models');
const { Op } = require('sequelize');

class AuthService {
  constructor() {
    this.jwtSecret = process.env.JWT_SECRET;
    this.refreshSecret = process.env.REFRESH_SECRET;
    this.jwtExpiry = process.env.JWT_EXPIRES_IN;
    this.refreshExpiry = process.env.REFRESH_EXPIRES_IN;
  }

  /**
   * Generates JWT access and refresh tokens
   */
  generateTokens(user) {
    const accessToken = jwt.sign(
      {
        userId: user.id,
        role: user.role,
        email: user.email,
        assignedParishId: user.assignedParishId || null,
      },
      this.jwtSecret,
      { expiresIn: this.jwtExpiry }
    );
    
    const refreshToken = jwt.sign(
      { userId: user.id },
      this.refreshSecret,
      { expiresIn: this.refreshExpiry }
    );
    
    return { accessToken, refreshToken };
  }

  /**
   * Verifies access token
   */
  verifyAccessToken(token) {
    try {
      return jwt.verify(token, this.jwtSecret);
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        throw new Error('Access token expired');
      } else if (error.name === 'JsonWebTokenError') {
        throw new Error('Invalid access token');
      }
      throw error;
    }
  }

  /**
   * Verifies refresh token
   */
  verifyRefreshToken(token) {
    try {
      return jwt.verify(token, this.refreshSecret);
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        throw new Error('Refresh token expired');
      } else if (error.name === 'JsonWebTokenError') {
        throw new Error('Invalid refresh token');
      }
      throw error;
    }
  }

  /**
   * Registers a new user
   */
  async register(userData) {
    const { email, password, firstName, lastName, phone, role = 'parishioner', preferredParishId } = userData;

    // Check if user already exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      throw new Error('Email already registered');
    }

    // Validate preferredParishId if provided (for non-diocese roles)
    const isDioceseLevel = ['diocese_staff', 'diocese_admin'].includes(role);
    let finalPreferredParishId = isDioceseLevel ? null : preferredParishId;
    let finalAssignedParishId = isDioceseLevel ? null : undefined;
    
    if (!isDioceseLevel && preferredParishId != null) {
      if (!Number.isInteger(preferredParishId) || preferredParishId <= 0) {
        throw new Error('Invalid parish selected');
      }
      const parish = await Parish.findByPk(preferredParishId);
      if (!parish) {
        throw new Error('Invalid parish selected');
      }
      finalAssignedParishId = preferredParishId;
    }

    // Create new user
    const user = await User.create({
      email,
      password,
      firstName,
      lastName,
      phone,
      role,
      preferredParishId: finalPreferredParishId,
      assignedParishId: finalAssignedParishId,
    });

    // Generate tokens
    const tokens = this.generateTokens(user);

    return {
      user: user.toSafeObject(),
      ...tokens,
    };
  }

  /**
   * Authenticates user login
   */
  async login(email, password) {
    // Find user by email
    const user = await User.findOne({ where: { email } });
    if (!user) {
      throw new Error('Invalid credentials');
    }

    // Verify password
    const isValidPassword = await user.verifyPassword(password);
    if (!isValidPassword) {
      throw new Error('Invalid credentials');
    }

    // Check if user is active
    if (!user.isActive) {
      throw new Error('Account disabled');
    }

    // Update last login
    await user.update({ lastLoginAt: new Date() });

    // Generate tokens
    const tokens = this.generateTokens(user);
    
    return {
      user: user.toSafeObject(),
      mustChangePassword: user.mustChangePassword || false,
      ...tokens,
    };
  }

  /**
   * Refreshes access token
   */
  async refreshToken(refreshToken) {
    // Verify refresh token
    const decoded = this.verifyRefreshToken(refreshToken);

    // Find user
    const user = await User.findByPk(decoded.userId);
    if (!user || !user.isActive) {
      throw new Error('Invalid refresh token');
    }

    // Generate new access token
    const accessToken = jwt.sign(
      { 
        userId: user.id, 
        role: user.role,
        email: user.email,
        assignedParishId: user.assignedParishId || null,
      },
      this.jwtSecret,
      { expiresIn: this.jwtExpiry }
    );

    return {
      accessToken,
    };
  }

  /**
   * Updates user password
   */
  async updatePassword(userId, oldPassword, newPassword) {
    const user = await User.findByPk(userId);
    if (!user) {
      throw new Error('User not found');
    }

    // Verify old password
    const isValidPassword = await user.verifyPassword(oldPassword);
    if (!isValidPassword) {
      throw new Error('Current password is incorrect');
    }

    // Update password
    await user.update({ password: newPassword });

    return { message: 'Password updated successfully' };
  }

  /**
   * Changes user password (admin or password reset)
   */
  async changePassword(userId, newPassword) {
    const user = await User.findByPk(userId);
    if (!user) {
      throw new Error('User not found');
    }

    await user.update({ password: newPassword });
    return { message: 'Password changed successfully' };
  }

  /**
   * Deactivates a user account
   */
  async deactivateUser(userId, requestingUserId) {
    const user = await User.findByPk(userId);
    if (!user) {
      throw new Error('User not found');
    }

    // Don't allow deactivation of own account
    if (userId === requestingUserId) {
      throw new Error('Cannot deactivate your own account');
    }

    await user.update({ isActive: false });
    return { message: 'User deactivated successfully' };
  }

  /**
   * Activates a user account
   */
  async activateUser(userId) {
    const user = await User.findByPk(userId);
    if (!user) {
      throw new Error('User not found');
    }

    await user.update({ isActive: true });
    return { message: 'User activated successfully' };
  }

  /**
   * Gets user by ID
   */
  async getUserById(userId) {
    const user = await User.findByPk(userId);
    if (!user) {
      throw new Error('User not found');
    }

    return user.toSafeObject();
  }

  /**
   * Searches users by email or name
   */
  async searchUsers(searchTerm, page = 1, limit = 10) {
    const offset = (page - 1) * limit;
    
    const { count, rows } = await User.findAndCountAll({
      where: {
        [Op.or]: [
          { email: { [Op.iLike]: `%${searchTerm}%` } },
          { firstName: { [Op.iLike]: `%${searchTerm}%` } },
          { lastName: { [Op.iLike]: `%${searchTerm}%` } },
        ],
        isActive: true,
      },
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['createdAt', 'DESC']],
    });

    return {
      users: rows.map(user => user.toSafeObject()),
      total: count,
      page: parseInt(page),
      totalPages: Math.ceil(count / limit),
    };
  }

  /**
   * Updates user profile
   */
  async updateUserProfile(userId, profileData) {
    const user = await User.findByPk(userId);
    if (!user) {
      throw new Error('User not found');
    }

    // Update allowed fields
    const allowedFields = ['firstName', 'lastName', 'phone', 'address'];
    const updateData = {};
    
    for (const field of allowedFields) {
      if (profileData[field] !== undefined) {
        updateData[field] = profileData[field];
      }
    }

    if (updateData.phone && !/^(\+63|0)9\d{9}$/.test(updateData.phone)) {
      throw new Error('Invalid Philippine phone number');
    }

    await user.update(updateData);
    return user.toSafeObject();
  }
}

module.exports = new AuthService();