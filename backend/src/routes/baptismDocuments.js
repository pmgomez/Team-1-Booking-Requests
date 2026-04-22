const express = require('express');
const router = express.Router();
const { upload } = require('../middleware/upload');
const BaptismBooking = require('../models').BaptismBooking;
const BookingDocument = require('../models').BookingDocument;
const User = require('../models').User;

// All routes require authentication
router.use(require('../middleware/auth').authenticateJWT);

/**
 * Attach a document (file) to a baptism booking
 */
router.post('/booking/:bookingId/document', upload.single('document'), async (req, res, next) => {
  try {
    const { bookingId } = req.params;
    
    if (!req.file) {
      return res.status(400).json({ error: 'No file provided' });
    }

    // Verify booking exists and user has access
    const booking = await BaptismBooking.findByPk(bookingId);
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    const user = await User.findByPk(req.user.userId);
    const isOwner = booking.userId === req.user.userId;
    const isAdmin = ['parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'].includes(user.role);

    if (!isOwner && !isAdmin) {
      return res.status(403).json({ error: 'Not authorized to add documents to this booking' });
    }

    // Save the file path info to booking_documents table
    const document = await BookingDocument.create({
      bookingType: 'baptism',
      bookingId: booking.id,
      documentType: req.body.documentType || 'birth_certificate',
      fileName: req.file.filename,
      filePath: req.file.path,
      fileSize: req.file.size,
      mimeType: req.file.mimetype,
      fileUrl: `/uploads/documents/${req.user.userId}/baptism/${req.file.filename}`,  // Changed from 'url' to 'fileUrl'
      uploadedBy: req.user.userId,
      isVerified: false,
    });

    res.json({
      message: 'Document attached successfully',
      document,
    });
  } catch (error) {
    console.error('Error attaching document to booking:', error);
    next(error);
  }
});

module.exports = router;
