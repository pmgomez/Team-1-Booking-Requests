const express = require('express');
const { authenticateJWT, authorizeRoles } = require('../middleware/auth');
const { Booking, BaptismBooking, WeddingBooking, ConfirmationBooking, EucharistBooking, ReconciliationBooking, AnointingSickBooking, FuneralMassBooking, MassIntention } = require('../models');
const { Op } = require('sequelize');

const router = express.Router();

// All booking routes require authentication
router.use(authenticateJWT);

// Get current user's bookings
// Parishioners see only their own; admins can also use but will see all if they pass their own userId
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 20, status, sacramentType } = req.query;
    const userId = req.user.userId;
    const offset = (page - 1) * limit;

    // Build where clause
    const whereClause = { userId };
    if (status) whereClause.status = status;
    
    const sacramentModels = {
      baptism: BaptismBooking,
      wedding: WeddingBooking,
      confirmation: ConfirmationBooking,
      eucharist: EucharistBooking,
      reconciliation: ReconciliationBooking,
      anointing_sick: AnointingSickBooking,
      funeral_mass: FuneralMassBooking,
      mass_intention: MassIntention,
    };

    let results = [];
    let total = 0;

    if (sacramentType) {
      const Model = sacramentModels[sacramentType];
      if (!Model) {
        return res.status(400).json({ error: 'Invalid sacrament type' });
      }
      const { count, rows } = await Model.findAndCountAll({
        where: whereClause,
        limit: parseInt(limit),
        offset: parseInt(offset),
        order: [['createdAt', 'DESC']],
      });
      total = count;
      results = rows.map((booking) => ({
        ...booking.toJSON(),
        sacramentType,
      }));
    } else {
      const modelsWithUserId = [BaptismBooking, WeddingBooking, ConfirmationBooking, EucharistBooking, ReconciliationBooking, AnointingSickBooking, FuneralMassBooking];
      const allResults = await Promise.all([
        ...modelsWithUserId.map(async (Model) => {
          const rows = await Model.findAll({ where: whereClause });
          return rows.map((b) => ({ ...b.toJSON(), sacramentType: Object.entries(sacramentModels).find(([, M]) => M === Model)[0] }));
        }),
        MassIntention.findAll({ where: { submittedBy: userId } }).then((rows) =>
          rows.map((b) => ({ ...b.toJSON(), sacramentType: 'mass_intention' }))
        ),
      ]);
      let combined = allResults.flat();
      
      // Sort by created date descending
      combined.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
      
      // Apply pagination manually
      total = combined.length;
      const start = (page - 1) * limit;
      const end = start + parseInt(limit);
      results = combined.slice(start, end);
    }

    res.json({
      success: true,
      data: results,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (error) {
    console.error('Error fetching user bookings:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch bookings',
      message: error.message,
    });
  }
});

// Get single booking by ID (user can only access their own)
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    
    // Try to find booking across all sacrament types
    const sacramentModels = [
      { type: 'baptism', model: BaptismBooking },
      { type: 'wedding', model: WeddingBooking },
      { type: 'confirmation', model: ConfirmationBooking },
      { type: 'eucharist', model: EucharistBooking },
      { type: 'reconciliation', model: ReconciliationBooking },
      { type: 'anointing_sick', model: AnointingSickBooking },
      { type: 'funeral_mass', model: FuneralMassBooking },
      { type: 'mass_intention', model: MassIntention },
    ];

    for (const { type, model } of sacramentModels) {
      const booking = await model.findByPk(id, {
        include: [{ model: Booking, as: 'booking' }],
      });
      
      if (booking) {
        const ownerId = type === 'mass_intention' ? booking.submittedBy : booking.userId;
        if (ownerId !== userId) {
          return res.status(403).json({ 
            success: false, 
            error: 'Not authorized to view this booking' 
          });
        }
        
        return res.json({
          success: true,
          data: { ...booking.toJSON(), sacramentType: type },
        });
      }
    }

    res.status(404).json({ success: false, error: 'Booking not found' });
  } catch (error) {
    console.error('Error fetching booking:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch booking',
      message: error.message,
    });
  }
});

// Update own booking (only if not approved)
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    const { status, notes, ...updateData } = req.body;

    // Find booking across all types
    const sacramentModels = [
      { type: 'baptism', model: BaptismBooking },
      { type: 'wedding', model: WeddingBooking },
      { type: 'confirmation', model: ConfirmationBooking },
      { type: 'eucharist', model: EucharistBooking },
      { type: 'reconciliation', model: ReconciliationBooking },
      { type: 'anointing_sick', model: AnointingSickBooking },
      { type: 'funeral_mass', model: FuneralMassBooking },
      { type: 'mass_intention', model: MassIntention },
    ];

    let foundBooking = null;
    let bookingType = null;

    for (const { type, model } of sacramentModels) {
      const booking = await model.findByPk(id);
      if (booking) {
        foundBooking = booking;
        bookingType = type;
        break;
      }
    }

    if (!foundBooking) {
      return res.status(404).json({ success: false, error: 'Booking not found' });
    }

    // Check ownership
    const ownerId = bookingType === 'mass_intention' ? foundBooking.submittedBy : foundBooking.userId;
    if (ownerId !== userId) {
      return res.status(403).json({
        success: false,
        error: 'Not authorized to modify this booking'
      });
    }

    // Check if booking is approved - cannot modify
    if (foundBooking.status === 'approved') {
      return res.status(400).json({
        success: false,
        error: 'Cannot modify an approved booking. Please contact the parish office for changes.'
      });
    }

    // If status is being updated, parishioners can only set back to 'pending' (resubmit after decline)
    if (status && !['pending', 'declined'].includes(status)) {
      return res.status(403).json({
        success: false,
        error: 'You cannot set this status'
      });
    }

    // Handle notes as append-only
    let finalUpdateData = { ...updateData };
    if (status) finalUpdateData.status = status;

    if (notes && Array.isArray(notes) && notes.length > 0) {
      // Get existing notes
      const existingNotes = foundBooking.notes || [];
      // Append new notes with author info from the user
      const newNotes = notes.map(note => ({
        author: req.user.role === 'parishioner' ? 'parishioner' : 'admin',
        content: note.content || note,
        authorId: req.user.userId,
        timestamp: new Date().toISOString(),
      }));
      // Combine
      finalUpdateData.notes = [...existingNotes, ...newNotes];
    }

    // Update booking
    await foundBooking.update(finalUpdateData);

    res.json({
      success: true,
      message: 'Booking updated successfully',
      data: { ...foundBooking.toJSON(), sacramentType: bookingType },
    });
  } catch (error) {
    console.error('Error updating booking:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update booking',
      message: error.message,
    });
  }
});

// Delete own booking (only if not approved)
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { sacramentType } = req.query;
    const userId = req.user.userId;

    // If sacramentType is provided, only search that specific model
    if (sacramentType) {
      console.log(`[DELETE /bookings/${id}] Using sacramentType: ${sacramentType}`);
      const modelMap = {
        baptism: BaptismBooking,
        wedding: WeddingBooking,
        confirmation: ConfirmationBooking,
        eucharist: EucharistBooking,
        reconciliation: ReconciliationBooking,
        anointing_sick: AnointingSickBooking,
        funeral_mass: FuneralMassBooking,
        mass_intention: MassIntention,
      };
      const Model = modelMap[sacramentType];
      console.log(`[DELETE] Model found: ${Model ? Model.name : 'undefined'}`);
      if (!Model) {
        return res.status(400).json({ success: false, error: 'Invalid sacrament type' });
      }

      const booking = await Model.findByPk(id);
      console.log(`[DELETE] Booking from DB:`, booking ? booking.id : null, booking ? `submittedBy: ${booking.submittedBy}, userId: ${booking.userId}` : '');
      if (!booking) {
        return res.status(404).json({ success: false, error: 'Booking not found' });
      }

      const ownerId = sacramentType === 'mass_intention' ? booking.submittedBy : booking.userId;
      console.log(`[DELETE] ownerId: ${ownerId} === userId: ${userId} ? ${ownerId === userId}`);
      if (ownerId !== userId) {
        return res.status(403).json({ success: false, error: 'Not authorized to delete this booking' });
      }

      if (booking.status === 'approved') {
        return res.status(400).json({ success: false, error: 'Cannot delete an approved booking. Please contact the parish office.' });
      }

      if (sacramentType !== 'mass_intention') {
        await booking.setDocuments([]);
      }
      await booking.destroy();

      return res.json({ success: true, message: 'Booking deleted successfully' });
    }

    // Find booking across all types
    const sacramentModels = [
      { type: 'baptism', model: BaptismBooking },
      { type: 'wedding', model: WeddingBooking },
      { type: 'confirmation', model: ConfirmationBooking },
      { type: 'eucharist', model: EucharistBooking },
      { type: 'reconciliation', model: ReconciliationBooking },
      { type: 'anointing_sick', model: AnointingSickBooking },
      { type: 'funeral_mass', model: FuneralMassBooking },
      { type: 'mass_intention', model: MassIntention },
    ];

    let foundBooking = null;
    let bookingType = null;
    let bookingModel = null;

    for (const { type, model } of sacramentModels) {
      const booking = await model.findByPk(id);
      if (booking) {
        foundBooking = booking;
        bookingType = type;
        bookingModel = model;
        break;
      }
    }

    if (!foundBooking) {
      return res.status(404).json({ success: false, error: 'Booking not found' });
    }

    // Check ownership
    const ownerId = bookingType === 'mass_intention' ? foundBooking.submittedBy : foundBooking.userId;
    if (ownerId !== userId) {
      return res.status(403).json({ 
        success: false, 
        error: 'Not authorized to delete this booking' 
      });
    }

    // Check if approved
    if (foundBooking.status === 'approved') {
      return res.status(400).json({ 
        success: false, 
        error: 'Cannot delete an approved booking. Please contact the parish office.' 
      });
    }

    // Delete associated documents (only for booking types that have documents relationship)
    if (bookingType !== 'mass_intention') {
      await foundBooking.setDocuments([]);
    }
    
    // Delete the booking
    await foundBooking.destroy();

    res.json({
      success: true,
      message: 'Booking deleted successfully',
    });
  } catch (error) {
    console.error('Error deleting booking:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete booking',
      message: error.message,
    });
  }
});

module.exports = router;
