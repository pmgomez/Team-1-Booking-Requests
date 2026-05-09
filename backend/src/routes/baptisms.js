const express = require('express');
const router = express.Router();
const baptismController = require('../controllers/baptismController');
const { authenticateJWT, authorizeRoles } = require('../middleware/auth');
const { upload } = require('../middleware/upload');

// All routes require authentication
router.use(authenticateJWT);

// Public routes for parishioners
router.post('/', baptismController.createBaptismBooking);
router.get('/', baptismController.getBaptismBookings);
router.get('/available-slots', baptismController.getAvailableTimeSlots);

// Attach document to booking (must be before /:id route)
router.post('/:id/document', upload.single('document'), baptismController.attachDocument);

// Delete document from booking
router.delete('/:id/document/:documentId', baptismController.deleteDocument);

// Get single booking (owner or admin)
router.get('/:id', baptismController.getBaptismBooking);

// Update booking (owner or admin)
router.put('/:id', baptismController.updateBaptismBooking);

// Delete/cancel booking (owner or admin)
router.delete('/:id', baptismController.deleteBaptismBooking);

// Admin-only routes for approval
router.patch('/:id/status', authorizeRoles('parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'),
  baptismController.approveBaptismBooking);

module.exports = router;
