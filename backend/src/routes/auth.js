const express = require('express');
const { body } = require('express-validator');
const authController = require('../controllers/authController');
const { authLimiter } = require('../middleware/rateLimiter');
const { authenticateJWT } = require('../middleware/auth');

const router = express.Router();

// Register new user
router.post(
  '/register',
  [
    body('email')
      .isEmail()
      .normalizeEmail()
      .withMessage('Invalid email address'),
    body('password')
      .isLength({ min: 8 })
      .withMessage('Password must be at least 8 characters'),
    body('firstName')
      .trim()
      .notEmpty()
      .withMessage('First name is required'),
    body('lastName')
      .trim()
      .notEmpty()
      .withMessage('Last name is required'),
  ],
  authController.register
);

// Login
router.post(
  '/login',
  authLimiter,
  [
    body('email')
      .isEmail()
      .normalizeEmail()
      .withMessage('Invalid email address'),
    body('password')
      .notEmpty()
      .withMessage('Password is required'),
  ],
  authController.login
);

// Refresh access token
router.post('/refresh', authController.refreshToken);

// Google OAuth (for future implementation)
router.post('/google', authController.googleAuth);

// Get current user profile (protected route - no longer blocks on mustChangePassword)
router.get('/me', authenticateJWT, authController.getCurrentUser);

// Update user profile (protected route - no longer blocks on mustChangePassword)
router.put('/me', authenticateJWT, authController.updateProfile);

// Change password (protected route, allows password change even if mustChangePassword)
router.patch('/change-password', authenticateJWT, [
  body('oldPassword')
    .notEmpty()
    .withMessage('Old password is required'),
  body('newPassword')
    .isLength({ min: 8 })
    .withMessage('New password must be at least 8 characters'),
], authController.changePassword);

// Force password change on first login (protected route, does NOT require password change - this IS the password change)
router.post('/force-password-change', authenticateJWT, [
  body('newPassword')
    .isLength({ min: 8 })
    .withMessage('New password must be at least 8 characters'),
], authController.forcePasswordChange);

// Logout (protected route, does NOT require password change)
router.post('/logout', authenticateJWT, authController.logout);

// Forgot password - request reset (public, rate limited)
router.post(
  '/forgot-password',
  authLimiter,
  [
    body('email')
      .isEmail()
      .normalizeEmail()
      .withMessage('Valid email address is required'),
  ],
  authController.forgotPassword
);

// Reset password with code (public, rate limited)
router.post(
  '/reset-password',
  authLimiter,
  [
    body('resetCode')
      .notEmpty()
      .withMessage('Reset code is required'),
    body('newPassword')
      .isLength({ min: 8 })
      .withMessage('New password must be at least 8 characters'),
  ],
  authController.resetPassword
);

// Verify reset code (public)
router.get(
  '/verify-reset-code/:resetCode',
  authController.verifyResetCode
);

module.exports = router;