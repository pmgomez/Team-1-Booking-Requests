const {
  BaptismBooking,
  Godparent,
  BookingDocument,
  Parish,
  ParishSlotSetting,
  BlackoutDate,
  Payment,
  User,
} = require('../models');
const { Op } = require('sequelize');
const emailService = require('../services/emailService');

// Helper function to check if date is within booking window
const checkBookingWindow = async (parishId, serviceType, preferredDate) => {
  const settings = await ParishSlotSetting.findOne({
    where: { parishId, serviceType, isActive: true },
  });

  if (!settings) return { valid: true }; // No restrictions set

  const today = new Date();
  const requestedDate = new Date(preferredDate);
  const minDate = new Date(today);
  minDate.setDate(minDate.getDate() + (settings.minAdvanceDays || 1));
  const maxDate = new Date(today);
  maxDate.setDate(maxDate.getDate() + (settings.maxAdvanceDays || 90));

  if (requestedDate < minDate) {
    return {
      valid: false,
      error: `Booking must be made at least ${settings.minAdvanceDays} days in advance`,
    };
  }

  if (requestedDate > maxDate) {
    return {
      valid: false,
      error: `Booking can only be made up to ${settings.maxAdvanceDays} days in advance`,
    };
  }

  return { valid: true };
};

// Helper function to check blackout dates
const checkBlackoutDates = async (parishId, serviceType, date) => {
  const blackoutDates = await BlackoutDate.findAll({
    where: {
      parishId,
      date,
      [Op.or]: [{ serviceType: null }, { serviceType }],
    },
  });

  if (blackoutDates.length > 0) {
    return {
      available: false,
      reason: blackoutDates[0].reason || 'Date is not available',
    };
  }

  return { available: true };
};

// Helper function to check daily limit
const checkDailyLimit = async (parishId, serviceType, date) => {
  const settings = await ParishSlotSetting.findOne({
    where: { parishId, serviceType, isActive: true },
  });

  if (!settings || !settings.dailyLimit) return { withinLimit: true };

  const startOfDay = new Date(date);
  startOfDay.setHours(0, 0, 0, 0);
  const endOfDay = new Date(date);
  endOfDay.setHours(23, 59, 59, 999);

  const bookingCount = await BaptismBooking.count({
    where: {
      parishId,
      preferredDate: {
        [Op.gte]: startOfDay,
        [Op.lte]: endOfDay,
      },
      status: { [Op.notIn]: ['declined', 'cancelled'] },
    },
  });

  if (bookingCount >= settings.dailyLimit) {
    return {
      withinLimit: false,
      error: `Daily limit of ${settings.dailyLimit} bookings has been reached`,
    };
  }

  return { withinLimit: true, remaining: settings.dailyLimit - bookingCount };
};

// Create Baptism Booking
exports.createBaptismBooking = async (req, res) => {
  try {
    const {
      childFullName,
      dateOfBirth,
      fatherName,
      motherName,
      contactEmail,
      contactPhone,
      preferredDate,
      preferredTimeSlot,
      preferredPriest,
      additionalNotes,
      parishId,
      godparents = [],
      uploadedFile,
      filePath,
      fileUrl,
      fileSize,
      mimeType,
      documentType = 'birth_certificate',
    } = req.body;

    // Validate parish exists
    const parish = await Parish.findByPk(parishId);
    if (!parish) {
      return res.status(404).json({ error: 'Parish not found' });
    }

    // Check booking window
    const windowCheck = await checkBookingWindow(parishId, 'baptism', preferredDate);
    if (!windowCheck.valid) {
      return res.status(400).json({ error: windowCheck.error });
    }

    // Check blackout dates
    const blackoutCheck = await checkBlackoutDates(parishId, 'baptism', preferredDate);
    if (!blackoutCheck.available) {
      return res.status(400).json({ error: blackoutCheck.reason });
    }

    // Check daily limit
    const limitCheck = await checkDailyLimit(parishId, 'baptism', preferredDate);
    if (!limitCheck.withinLimit) {
      return res.status(400).json({ error: limitCheck.error });
    }

    // Create booking
    const booking = await BaptismBooking.create({
      parishId,
      userId: req.user.userId,
      childFullName,
      dateOfBirth,
      fatherName,
      motherName,
      contactEmail,
      contactPhone,
      preferredDate,
      preferredTimeSlot,
      preferredPriest,
      additionalNotes,
      status: 'pending',
    });

    // Add godparents
    if (godparents.length > 0) {
      const godparentRecords = godparents.map((gp) => ({
        bookingType: 'baptism',
        bookingId: booking.id,
        fullName: gp.fullName || gp.name || 'Unknown',
        contactEmail: gp.contactEmail || null,
        contactPhone: gp.contactPhone || null,
        address: gp.address || null,
        parishAffiliation: gp.parishAffiliation || null,
        confirmationCertificateNumber: gp.confirmationCertificateNumber || null,
        notes: gp.notes || null,
      }));
      await Godparent.bulkCreate(godparentRecords);
    }

    // Link uploaded file to booking if provided
    if (uploadedFile && filePath && fileUrl && fileSize && mimeType) {
      // Create BookingDocument record using file details from upload
      await BookingDocument.create({
        bookingType: 'baptism',
        bookingId: booking.id,
        documentType: documentType,
        fileName: uploadedFile,
        filePath,
        fileUrl,
        fileSize,
        mimeType,
        uploadedBy: req.user.userId,
      });
      console.log(`Created booking document for file ${uploadedFile} linked to baptism booking ${booking.id}`);
    } else if (uploadedFile) {
      console.log(`File ${uploadedFile} uploaded but missing file details in request body`);
    }

    // Send confirmation email
    try {
      await emailService.sendNotification(
        contactEmail,
        'Baptism Booking Request Received',
        `
          <h2>Baptism Booking Request Received</h2>
          <p>Dear Parent/Guardian,</p>
          <p>Your baptism booking request for <strong>${childFullName}</strong> has been successfully submitted.</p>
          <p><strong>Booking Details:</strong></p>
          <ul>
            <li>Reference Number: ${booking.id}</li>
            <li>Preferred Date: ${new Date(preferredDate).toLocaleDateString()}</li>
            <li>Preferred Time Slot: ${preferredTimeSlot}</li>
            <li>Parish: ${parish.name}</li>
          </ul>
          <p>Your request is currently under review. We will notify you once it has been confirmed by our parish staff.</p>
          ${preferredPriest ? '<p><em>Note: Your preferred priest has been noted. Subject to availability. Parish will confirm.</em></p>' : ''}
          <br>
          <p>Best regards,<br>The Parish Team</p>
        `
      );
    } catch (emailError) {
      console.error('Failed to send confirmation email:', emailError);
    }

    res.status(201).json({
      message: 'Baptism booking request submitted successfully',
      booking: {
        id: booking.id,
        childFullName: booking.childFullName,
        preferredDate: booking.preferredDate,
        preferredTimeSlot: booking.preferredTimeSlot,
        status: booking.status,
        note: preferredPriest
          ? 'Preferred priest noted. Subject to availability. Parish will confirm.'
          : undefined,
      },
    });
  } catch (error) {
    console.error('Error creating baptism booking:', error);
    console.error('Request body:', req.body);
    console.error('User:', req.user);
    res.status(500).json({ error: 'Failed to create baptism booking', details: error.message });
  }
};

// Get all Baptism Bookings (with filters)
exports.getBaptismBookings = async (req, res) => {
  try {
    const { page = 1, limit = 10, status, parishId, startDate, endDate } = req.query;
    const offset = (page - 1) * limit;

    const where = {};

    if (status) where.status = status;
    if (parishId) where.parishId = parseInt(parishId);

    // Filter by user's parish if not admin
    if (req.user.role === 'parish_admin' || req.user.role === 'parish_staff') {
      const user = await User.findByPk(req.user.userId);
      if (user && user.assignedParishId) {
        where.parishId = user.assignedParishId;
      }
    }

    if (startDate || endDate) {
      where.preferredDate = {};
      if (startDate) where.preferredDate[Op.gte] = startDate;
      if (endDate) where.preferredDate[Op.lte] = endDate;
    }

    const { count, rows } = await BaptismBooking.findAndCountAll({
      where,
      include: [
        { model: Parish, as: 'parish', attributes: ['id', 'name', 'address'] },
        {
          model: Godparent,
          as: 'godparents',
          attributes: ['id', 'fullName', 'contactEmail', 'contactPhone'],
        },
        {
          model: BookingDocument,
          as: 'documents',
          attributes: ['id', 'documentType', 'fileName', 'fileUrl', 'isVerified'],
        },
      ],
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['createdAt', 'DESC']],
    });

    res.json({
      bookings: rows,
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    console.error('Error fetching baptism bookings:', error);
    res.status(500).json({ error: 'Failed to fetch baptism bookings' });
  }
};

// Get single Baptism Booking
exports.getBaptismBooking = async (req, res) => {
  try {
    const { id } = req.params;

    const booking = await BaptismBooking.findByPk(id, {
      include: [
        { model: Parish, as: 'parish' },
        { model: Godparent, as: 'godparents' },
        { model: BookingDocument, as: 'documents' },
        { model: Payment, as: 'payment' },
      ],
    });

    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    res.json({ booking });
  } catch (error) {
    console.error('Error fetching baptism booking:', error);
    res.status(500).json({ error: 'Failed to fetch baptism booking' });
  }
};

// Update Baptism Booking
exports.updateBaptismBooking = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    console.log('=== UPDATE BAPTISM BOOKING ===');
    console.log('ID:', id);
    console.log('Request body:', JSON.stringify(req.body, null, 2));
    console.log('User:', req.user);

    const booking = await BaptismBooking.findByPk(id);
    if (!booking) {
      console.log('Booking not found with ID:', id);
      return res.status(404).json({ error: 'Booking not found' });
    }

    // Check permissions
    const isOwner = booking.userId === req.user.userId;
    const isAdmin = ['parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'].includes(
      req.user.role
    );

    console.log('Is Owner:', isOwner);
    console.log('Is Admin:', isAdmin);

    if (!isOwner && !isAdmin) {
      console.log('Not authorized - user does not own booking and is not admin');
      return res.status(403).json({ error: 'Not authorized to update this booking' });
    }

    // Admins can update status, users can only update notes
    if (!isAdmin) {
      delete updateData.status;
      delete updateData.preferredDate;
      delete updateData.preferredTimeSlot;
    }

    console.log('Updating with data:', JSON.stringify(updateData, null, 2));
    
    await booking.update(updateData);

    console.log('Booking updated successfully!');
    res.json({
      message: 'Baptism booking updated successfully',
      booking,
    });
  } catch (error) {
    console.error('Error updating baptism booking:', error);
    console.error('Stack trace:', error.stack);
    res.status(500).json({ error: 'Failed to update baptism booking', details: error.message });
  }
};

// Approve/Decline/Complete Baptism Booking (Admin only)
exports.approveBaptismBooking = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, adminNotes } = req.body;

    if (!['approved', 'declined', 'completed'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status. Must be "approved", "declined", or "completed"' });
    }

    const booking = await BaptismBooking.findByPk(id);
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    await booking.update({
      status,
      adminNotes,
      approvedBy: req.user.userId,
      approvedAt: new Date(),
    });

    // Send email notification
    try {
      const user = await User.findByPk(booking.userId);
      await emailService.sendNotification(
        booking.contactEmail,
        `Baptism Booking ${status === 'approved' ? 'Approved' : 'Declined'}`,
        `
          <h2>Baptism Booking Update</h2>
          <p>Dear Parent/Guardian,</p>
          <p>Your baptism booking request for <strong>${booking.childFullName}</strong> has been ${status}.</p>
          ${adminNotes ? `<p><strong>Admin Notes:</strong> ${adminNotes}</p>` : ''}
          <p><strong>Booking Details:</strong></p>
          <ul>
            <li>Reference Number: ${booking.id}</li>
            <li>Status: ${status}</li>
          </ul>
          <br>
          <p>Best regards,<br>The Parish Team</p>
        `
      );
    } catch (emailError) {
      console.error('Failed to send status update email:', emailError);
    }

    res.json({
      message: `Baptism booking ${status} successfully`,
      booking,
    });
  } catch (error) {
    console.error('Error approving baptism booking:', error);
    res.status(500).json({ error: 'Failed to process approval' });
  }
};

// Delete Baptism Booking
exports.deleteBaptismBooking = async (req, res) => {
  try {
    const { id } = req.params;

    const booking = await BaptismBooking.findByPk(id);
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    // Check permissions
    const isOwner = booking.userId === req.user.userId;
    const isAdmin = ['parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'].includes(
      req.user.role
    );

    if (!isOwner && !isAdmin) {
      return res.status(403).json({ error: 'Not authorized to delete this booking' });
    }

    // Soft delete by setting status to cancelled
    await booking.update({ status: 'cancelled' });

    res.json({ message: 'Baptism booking cancelled successfully' });
  } catch (error) {
    console.error('Error deleting baptism booking:', error);
    res.status(500).json({ error: 'Failed to delete baptism booking' });
  }
};

// Attach document to baptism booking
exports.attachDocument = async (req, res) => {
  try {
    const { id } = req.params;
    const { documentType } = req.body;

    // Validate booking exists
    const booking = await BaptismBooking.findByPk(id);
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    // Check permissions - only owner or admin can add documents
    const isOwner = booking.userId === req.user.userId;
    const isAdmin = ['parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'].includes(
      req.user.role
    );

    if (!isOwner && !isAdmin) {
      return res.status(403).json({ error: 'Not authorized to add documents to this booking' });
    }

    // Handle file upload if present
    if (req.file) {
      const fileService = require('../services/fileService');
      
      // Save file to permanent location
      const fileData = await fileService.saveFile(
        req.file,
        req.user.userId,
        `baptism-${id}`,
        'baptism',
        parseInt(id),
        documentType || 'birth_certificate'
      );

      // Create BookingDocument record in database
      const bookingDocument = await BookingDocument.create({
        bookingType: 'baptism',
        bookingId: parseInt(id),
        documentType: documentType || 'birth_certificate',
        fileName: fileData.filename,
        filePath: fileData.path,
        fileUrl: fileData.url,
        fileSize: fileData.size,
        mimeType: fileData.mimetype,
        uploadedBy: req.user.userId,
      });

      console.log(`Document attached to baptism booking ${id}:`, bookingDocument.id);

      return res.status(201).json({
        message: 'Document attached successfully',
        document: {
          id: bookingDocument.id,
          documentType: bookingDocument.documentType,
          fileName: bookingDocument.fileName,
          fileUrl: bookingDocument.fileUrl,
          isVerified: bookingDocument.isVerified,
          createdAt: bookingDocument.createdAt,
        },
      });
    }

    // If no file, check if it's a URL-based document reference
    const { fileUrl, fileName: reqFileName, fileSize, mimeType } = req.body;
    if (fileUrl && reqFileName) {
      const bookingDocument = await BookingDocument.create({
        bookingType: 'baptism',
        bookingId: parseInt(id),
        documentType: documentType || 'other',
        fileName: reqFileName,
        filePath: '',
        fileUrl: fileUrl,
        fileSize: parseInt(fileSize) || 0,
        mimeType: mimeType || 'application/octet-stream',
        uploadedBy: req.user.userId,
      });

      return res.status(201).json({
        message: 'Document reference added successfully',
        document: {
          id: bookingDocument.id,
          documentType: bookingDocument.documentType,
          fileName: bookingDocument.fileName,
          fileUrl: bookingDocument.fileUrl,
          isVerified: bookingDocument.isVerified,
        },
      });
    }

    return res.status(400).json({ error: 'No file provided' });
  } catch (error) {
    console.error('Error attaching document to baptism booking:', error);
    // Clean up uploaded file if there was an error
    if (req.file && req.file.path) {
      try {
        require('fs').unlinkSync(req.file.path);
      } catch (cleanupError) {
        // Ignore cleanup errors
      }
    }
    res.status(500).json({ error: 'Failed to attach document', details: error.message });
  }
};

// Get available time slots for a date
exports.getAvailableTimeSlots = async (req, res) => {
  try {
    const { parishId, date } = req.query;

    if (!parishId || !date) {
      return res.status(400).json({ error: 'Parish IDand date are required' });
    }

    // Get slot settings
    const settings = await ParishSlotSetting.findOne({
      where: { parishId, serviceType: 'baptism', isActive: true },
    });

    if (!settings || !settings.timeSlots) {
      // Return default time slots if none configured
      return res.json({
        timeSlots: [
          { start: '09:00', end: '10:00', available: true },
          { start: '10:00', end: '11:00', available: true },
          { start: '13:00', end: '14:00', available: true },
          { start: '14:00', end: '15:00', available: true },
        ],
      });
    }

    // Check blackout dates
    const blackoutCheck = await checkBlackoutDates(parishId, 'baptism', date);
    if (!blackoutCheck.available) {
      return res.json({ timeSlots: [], blackoutReason: blackoutCheck.reason });
    }

    // Get bookings for this date
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    const existingBookings = await BaptismBooking.findAll({
      where: {
        parishId,
        preferredDate: {
          [Op.gte]: startOfDay,
          [Op.lte]: endOfDay,
        },
        status: { [Op.notIn]: ['declined', 'cancelled'] },
      },
      attributes: ['preferredTimeSlot'],
    });

    const bookedSlots = new Set(existingBookings.map((b) => b.preferredTimeSlot));

    // Calculate availability for each time slot
    const availableSlots = settings.timeSlots.map((slot) => ({
      ...slot,
      available: !bookedSlots.has(slot.start) && slot.capacity > bookedSlots.size,
    }));

    res.json({ timeSlots: availableSlots });
  } catch (error) {
    console.error('Error fetching time slots:', error);
    res.status(500).json({ error: 'Failed to fetch available time slots' });
  }
};
