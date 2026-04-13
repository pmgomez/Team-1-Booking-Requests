const { validationResult } = require('express-validator');
const authService = require('../services/authService');
const { TokenBlacklist } = require('../models');
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
    
    const updatedUser = await authService.updateUserProfile(userId, profileData);
    
    res.json({
      message: 'Profile updated successfully',
      user: updatedUser,
    });
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