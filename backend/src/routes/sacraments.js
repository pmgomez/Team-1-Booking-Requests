const express = require('express');
const router = express.Router();
const sacramentController = require('../controllers/sacramentController');
const { authenticateJWT, authorizeRoles } = require('../middleware/auth');
const { upload } = require('../middleware/upload');

// All routes require authentication
router.use(authenticateJWT);

// Helper to create routes for each sacrament type
const createSacramentRoutes = (sacramentType) => {
  // Create controller bindings for this sacrament type
  const createBooking = sacramentController.createSacramentBooking(sacramentType);
  const getBookings = sacramentController.getSacramentBookings(sacramentType);
  const getBooking = sacramentController.getSacramentBooking(sacramentType);
  const updateBooking = sacramentController.updateSacramentBooking(sacramentType);
  const deleteBooking = sacramentController.deleteSacramentBooking(sacramentType);
  const approveBooking = sacramentController.approveSacramentBooking(sacramentType);
  const getAvailableSlots = sacramentController.getAvailableTimeSlots(sacramentType);
  const attachDocument = sacramentController.attachDocument(sacramentType);
  const deleteDocument = sacramentController.deleteDocument(sacramentType);

  return (prefix) => {
    // Public routes for parishioners
    router.post(`/${prefix}`, createBooking);
    router.get(`/${prefix}`, getBookings);
    router.get(`/${prefix}/available-slots`, getAvailableSlots);

    // Attach document to booking (must be before /:id route)
    router.post(`/${prefix}/:id/document`, upload.single('document'), attachDocument);

    // Delete document from booking
    router.delete(`/${prefix}/:bookingId/document/:documentId`, deleteDocument);

    // Get single booking
    router.get(`/${prefix}/:id`, getBooking);

    // Update booking
    router.put(`/${prefix}/:id`, updateBooking);

    // Delete/cancel booking
    router.delete(`/${prefix}/:id`, deleteBooking);

    // Admin-only approval
    router.patch(`/${prefix}/:id/status`, authorizeRoles('parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'),
      approveBooking);
  };
};

// Create routes for each sacrament type
createSacramentRoutes('wedding')('weddings');
createSacramentRoutes('confirmation')('confirmations');
createSacramentRoutes('eucharist')('eucharist');
createSacramentRoutes('reconciliation')('reconciliations');
createSacramentRoutes('anointing_sick')('anointing-sick');
createSacramentRoutes('funeral_mass')('funeral-mass');

module.exports = router;
