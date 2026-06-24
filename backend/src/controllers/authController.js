const { validationResult } = require('express-validator');
const authService = require('../services/authService');
const { TokenBlacklist, User } = require('../models');
const jwt = require('jsonwebtoken');

// Register new user
exports.register = async (req, res, next) => {
  try {
    // Validate request
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed',
        details: errors.array() 
      });
    }
    
    const { email, password, firstName, lastName, phone, preferredParishId } = req.body;

    try {
      // Register user using auth service
      const result = await authService.register({
        email,
        password,
        firstName,
        lastName,
        phone,
        preferredParishId,
        role: 'parishioner' // Default role
      });
      
      // Return success response
      res.status(201).json({
        message: 'User registered successfully',
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      });
    } catch (error) {
      if (error.message === 'Email already registered') {
        return res.status(409).json({ 
          error: 'Email already registered',
          message: 'An account with this email already exists' 
        });
      } else if (error.message === 'Invalid parish selected') {
        return res.status(400).json({ 
          error: 'Invalid parish',
          message: 'The selected parish does not exist' 
        });
      }
      throw error;
    }
  } catch (error) {
    next(error);
  }
};

// Login user
exports.login = async (req, res, next) => {
  try {
    // Validate request
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { email, password } = req.body;

    try {
      // Authenticate user using auth service
      const result = await authService.login(email, password);

      // Return success response
      res.json({
        message: 'Login successful',
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        mustChangePassword: result.mustChangePassword || false,
      });
    } catch (error) {
      if (error.message === 'Invalid credentials') {
        return res.status(401).json({
          error: 'Invalid credentials',
          message: 'Email or password is incorrect'
        });
      } else if (error.message === 'Account disabled') {
        return res.status(403).json({
          error: 'Account disabled',
          message: 'Your account has been deactivated. Please contact support.'
        });
      }
      throw error;
    }
  } catch (error) {
    next(error);
  }
};

// Refresh access token
exports.refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return res.status(401).json({ 
        error: 'Refresh token required',
        message: 'Please provide a refresh token' 
      });
    }
    
    try {
      // Refresh token using auth service
      const result = await authService.refreshToken(refreshToken);
      
      res.json({
        message: 'Token refreshed successfully',
        accessToken: result.accessToken,
      });
    } catch (error) {
      if (error.message === 'Refresh token expired') {
        return res.status(401).json({ 
          error: 'Refresh token expired',
          message: 'Please login again' 
        });
      } else if (error.message === 'Invalid refresh token' || error.message === 'User not found or account is inactive') {
        return res.status(403).json({ 
          error: 'Invalid refresh token',
          message: error.message 
        });
      }
      throw error;
    }
  } catch (error) {
    next(error);
  }
};

// Google OAuth authentication
exports.googleAuth = async (req, res, next) => {
  try {
    const { idToken } = req.body;
    
    if (!idToken) {
      return res.status(400).json({ 
        error: 'ID token required',
        message: 'Please provide Google ID token' 
      });
    }
    
    const googleAuthService = require('../services/googleAuthService');
    
    let googleUserInfo;
    try {
      googleUserInfo = await googleAuthService.verifyGoogleToken(idToken);
    } catch (verifyError) {
      return res.status(401).json({ 
        error: 'Invalid Google token',
        message: verifyError.message || 'The provided Google token is invalid' 
      });
    }
    
    // Authenticate/create user in the system
    const user = await googleAuthService.authenticateGoogleUser(googleUserInfo);
    
    // Generate JWT tokens using the auth service
    const tokens = authService.generateTokens(user);
    
    res.json({
      message: 'Google authentication successful',
      user: user.toSafeObject(),
      ...tokens,
    });
  } catch (error) {
    console.error('Google OAuth error:', error);
    next(error);
  }
};

// Get current user profile
exports.getCurrentUser = async (req, res, next) => {
  try {
    const user = await authService.getUserById(req.user.userId);
    
    res.json({
      user: user,
    });
  } catch (error) {
    next(error);
  }
};

// Update user profile
exports.updateProfile = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const profileData = req.body;
     
    try {
      const updatedUser = await authService.updateUserProfile(userId, profileData);
      
      res.json({
        message: 'Profile updated successfully',
        user: updatedUser,
      });
    }
    catch (error) {
      if (error.message === 'Invalid Philippine phone number') {
        return res.status(400).json({
          error: 'Invalid Philippine phone number',
          message: error.message
        });
      }
      throw error;
    }
  } catch (error) {
    next(error);
  }
};

// Change password
exports.changePassword = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { oldPassword, newPassword } = req.body;

    // Validate request
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    try {
      const result = await authService.updatePassword(userId, oldPassword, newPassword);

      res.json(result);
    } catch (error) {
      if (error.message === 'Current password is incorrect') {
        return res.status(400).json({
          error: 'Current password is incorrect',
          message: error.message
        });
      } else if (error.message === 'User not found') {
        return res.status(404).json({
          error: 'User not found',
          message: error.message
        });
      }
      throw error;
    }
  } catch (error) {
    next(error);
  }
};

// Force password change on first login
exports.forcePasswordChange = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { newPassword } = req.body;

    if (!newPassword || newPassword.length < 8) {
      return res.status(400).json({
        error: 'Invalid password',
        message: 'Password must be at least 8 characters',
      });
    }

    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Update password and set mustChangePassword to false
    await user.update({
      password: newPassword,
      mustChangePassword: false,
    });

    res.json({
      message: 'Password changed successfully. Please login again with your new password.',
    });
  } catch (error) {
    console.error('Error forcing password change:', error);
    next(error);
  }
};

// Forgot password - request reset
exports.forgotPassword = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { email } = req.body;
    const user = await User.findOne({ where: { email } });

    if (!user) {
      // Don't reveal if user exists or not for security
      return res.json({
        message: 'If an account with that email exists, a password reset code has been sent.',
      });
    }

    // Generate 6-digit reset code
    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
    const resetCodeExpiry = new Date(Date.now() + 3600000); // 1 hour

    await user.update({
      resetPasswordToken: resetCode,
      resetPasswordExpires: resetCodeExpiry,
    });

    // Send reset code via email
    const emailService = require('../services/emailService');

    try {
      await emailService.sendPasswordResetCodeEmail(user, resetCode);
    } catch (emailError) {
      console.error('Failed to send password reset code email:', emailError);
      // Clear the reset code if email fails
      await user.update({
        resetPasswordToken: null,
        resetPasswordExpires: null,
      });
      return res.status(500).json({
        error: 'Failed to send reset code email',
        message: 'There was an error sending the reset code. Please try again later.',
      });
    }

    res.json({
      message: 'If an account with that email exists, a password reset code has been sent.',
    });
  } catch (error) {
    next(error);
  }
};

// Reset password with code
exports.resetPassword = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { resetCode, newPassword } = req.body;

    if (!resetCode || !newPassword) {
      return res.status(400).json({
        error: 'Missing required fields',
        message: 'Reset code and new password are required',
      });
    }

    // Find user with valid reset code
    const user = await User.findOne({
      where: {
        resetPasswordToken: resetCode,
        resetPasswordExpires: { [require('sequelize').Op.gt]: new Date() },
      },
    });

    if (!user) {
      return res.status(400).json({
        error: 'Invalid or expired code',
        message: 'The password reset code is invalid or has expired.',
      });
    }

    // Update password and clear reset code
    await user.update({
      password: newPassword,
      resetPasswordToken: null,
      resetPasswordExpires: null,
      mustChangePassword: false,
    });

    // Send confirmation email
    const emailService = require('../services/emailService');
    try {
      await emailService.sendPasswordChangeNotification(user);
    } catch (emailError) {
      console.error('Failed to send password change confirmation:', emailError);
    }

    res.json({
      message: 'Password has been reset successfully. You can now log in with your new password.',
    });
  } catch (error) {
    next(error);
  }
};

// Verify reset code
exports.verifyResetCode = async (req, res, next) => {
  try {
    const { resetCode } = req.params;

    const user = await User.findOne({
      where: {
        resetPasswordToken: resetCode,
        resetPasswordExpires: { [require('sequelize').Op.gt]: new Date() },
      },
    });

    if (!user) {
      return res.status(400).json({
        valid: false,
        message: 'The password reset code is invalid or has expired.',
      });
    }

    res.json({
      valid: true,
      message: 'Code is valid',
    });
  } catch (error) {
    next(error);
  }
};

// Logout user
exports.logout = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader ? authHeader.split(' ')[1] : null;

    if (token) {
      // Decode token to get expiration time
      const decoded = jwt.decode(token);

      // Calculate when the token expires
      const expiresAt = decoded && decoded.exp
        ? new Date(decoded.exp * 1000)
        : new Date(Date.now() + 24 * 60 * 60 * 1000); // Default 24 hours if can't decode

      // Add token to blacklist
      await TokenBlacklist.blacklist(token, expiresAt, 'logout');

      const userId = req.user ? req.user.userId : null;
      console.log(`User ${userId} logged out at ${new Date().toISOString()} - token blacklisted`);
    }

    res.json({
      message: 'Logout successful',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Logout error:', error);
    next(error);
  }
};