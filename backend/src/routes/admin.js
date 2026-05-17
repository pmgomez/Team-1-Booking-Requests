const express = require('express');
const { authenticateJWT, authorizeRoles } = require('../middleware/auth');
const adminController = require('../controllers/adminController');

const router = express.Router();

// All admin routes require authentication and admin roles
router.use(authenticateJWT);

// Note: requirePasswordChange middleware removed
// Users can now access admin screens while seeing a modal reminder to change password

// ==================== DASHBOARD ====================
// Get dashboard statistics
router.get(
  '/dashboard',
  authorizeRoles('diocese_admin', 'diocese_staff', 'parish_admin', 'parish_staff'),
  adminController.getDashboardStats
);

// ==================== USER MANAGEMENT ====================
// Get all users (with filtering and pagination)
router.get(
  '/users',
  authorizeRoles('diocese_admin', 'diocese_staff', 'parish_admin', 'parish_staff'),
  adminController.getAllUsers
);

// Get single user by ID
router.get(
  '/users/:id',
  authorizeRoles('diocese_admin', 'diocese_staff', 'parish_admin', 'parish_staff'),
  adminController.getUserById
);

// Create new user
router.post(
  '/users',
  authorizeRoles('diocese_admin', 'diocese_staff', 'parish_admin', 'parish_staff'),
  adminController.createUser
);

// Update user
router.put(
  '/users/:id',
  authorizeRoles('diocese_admin', 'diocese_staff', 'parish_admin'),
  adminController.updateUser
);

// Delete user (soft delete)
router.delete(
  '/users/:id',
  authorizeRoles('diocese_admin', 'parish_admin', 'parish_staff'),
  adminController.deleteUser
);

// ==================== PARISH MANAGEMENT ====================
// Get all parishes
router.get(
  '/parishes',
  authorizeRoles('diocese_admin', 'diocese_staff', 'parish_admin'),
  adminController.getAllParishes
);

// Get single parish by ID
router.get(
  '/parishes/:id',
  authorizeRoles('diocese_admin', 'diocese_staff', 'parish_admin'),
  adminController.getParishById
);

// Create new parish
router.post(
  '/parishes',
  authorizeRoles('diocese_admin'),
  adminController.createParish
);

// Update parish
router.put(
  '/parishes/:id',
  authorizeRoles('diocese_admin', 'parish_admin'),
  adminController.updateParish
);

// Delete parish (soft delete)
router.delete(
  '/parishes/:id',
  authorizeRoles('diocese_admin'),
  adminController.deleteParish
);

// ==================== SYSTEM CONFIGURATION MANAGEMENT ====================
// Get configurations for a parish
router.get(
  '/parishes/:parishId/configurations',
  authorizeRoles('diocese_admin', 'parish_admin', 'parish_staff'),
  adminController.getParishConfigurations
);

// Create or update configuration
router.put(
  '/parishes/:parishId/configurations/:configType',
  authorizeRoles('diocese_admin', 'parish_admin'),
  adminController.upsertConfiguration
);

// Delete configuration (soft delete)
router.delete(
  '/configurations/:id',
  authorizeRoles('diocese_admin', 'parish_admin'),
  adminController.deleteConfiguration
);

// ==================== BOOKING MANAGEMENT ====================
// Get all bookings (admin view with filtering)
router.get(
  '/bookings',
  authorizeRoles('diocese_admin', 'diocese_staff', 'parish_admin', 'parish_staff'),
  adminController.getAllBookings
);

// Get single booking by ID
router.get(
  '/bookings/:id',
  authorizeRoles('diocese_admin', 'diocese_staff', 'parish_admin', 'parish_staff'),
  adminController.getBookingById
);

// Update booking status (approve/reject/reschedule)
router.put(
  '/bookings/:id/status',
  authorizeRoles('diocese_admin', 'diocese_staff', 'parish_admin', 'parish_staff'),
  adminController.updateBookingStatus
);

// Delete booking
router.delete(
  '/bookings/:id',
  authorizeRoles('diocese_admin', 'parish_admin'),
  adminController.deleteBooking
);

// ==================== PRIEST MANAGEMENT ====================
// Get priests by parish ID
router.get(
  '/priests',
  authorizeRoles('diocese_admin', 'diocese_staff', 'parish_admin', 'parish_staff', 'priest', 'parishioner'),
  adminController.getPriestsByParish
);

// Get priest's schedule (bookings assigned to the priest)
router.get(
  '/priest-schedule',
  authorizeRoles('priest'),
  adminController.getPriestSchedule
);

// ==================== MASS INTENTION MANAGEMENT ====================
// Get all mass intentions (admin view)
router.get(
  '/mass-intentions',
  authorizeRoles('diocese_admin', 'diocese_staff', 'parish_admin', 'parish_staff'),
  adminController.getAllMassIntentions
);

// Update mass intention status
router.put(
  '/mass-intentions/:id/status',
  authorizeRoles('diocese_admin', 'diocese_staff', 'parish_admin', 'parish_staff'),
  adminController.updateMassIntentionStatus
);

module.exports = router;
