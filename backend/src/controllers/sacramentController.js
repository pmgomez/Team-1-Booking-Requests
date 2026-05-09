const {
  WeddingBooking,
  ConfirmationBooking,
  EucharistBooking,
  ReconciliationBooking,
  AnointingSickBooking,
  FuneralMassBooking,
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

// Mapping of sacrament types to models and config
const SACRAMENT_CONFIG = {
  wedding: {
    model: WeddingBooking,
    serviceName: 'Wedding',
    emailTemplate: 'weddingConfirmation',
    allowsGodparents: true,
  },
  confirmation: {
    model: ConfirmationBooking,
    serviceName: 'Confirmation',
    emailTemplate: 'confirmationConfirmation',
    allowsGodparents: true,
  },
  eucharist: {
    model: EucharistBooking,
    serviceName: 'First Communion',
    emailTemplate: 'eucharistConfirmation',
    allowsGodparents: false,
  },
  reconciliation: {
    model: ReconciliationBooking,
    serviceName: 'Confession',
    emailTemplate: 'reconciliationConfirmation',
    allowsGodparents: false,
  },
  anointing_sick: {
    model: AnointingSickBooking,
    serviceName: 'Anointing of the Sick',
    emailTemplate: 'anointingSickConfirmation',
    allowsGodparents: false,
  },
  funeral_mass: {
    model: FuneralMassBooking,
    serviceName: 'Funeral Mass',
    emailTemplate: 'funeralMassConfirmation',
    allowsGodparents: false,
  },
};

// Helper function to check if date is within booking window
const checkBookingWindow = async (parishId, serviceType, preferredDate) => {
  const settings = await ParishSlotSetting.findOne({
    where: { parishId, serviceType, isActive: true },
  });

  if (!settings) return { valid: true };

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
const checkDailyLimit = async (parishId, serviceType, date, Model) => {
  const settings = await ParishSlotSetting.findOne({
    where: { parishId, serviceType, isActive: true },
  });

  if (!settings || !settings.dailyLimit) return { withinLimit: true };

  const startOfDay = new Date(date);
  startOfDay.setHours(0, 0, 0, 0);
  const endOfDay = new Date(date);
  endOfDay.setHours(23, 59, 59, 999);

  const bookingCount = await Model.count({
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

// Create Sacrament Booking (generic)
exports.createSacramentBooking = (sacramentType) => async (req, res) => {
  try {
    const config = SACRAMENT_CONFIG[sacramentType];
    if (!config) {
      return res.status(400).json({ error: 'Invalid sacrament type' });
    }

    const {
      parishId,
      preferredDate,
      preferredTimeSlot,
      priestId,
      notes, // New notes array format
      godparents = [],
      uploadedFile,
      filePath,
      fileUrl,
      fileSize,
      mimeType,
      documentType = 'other',
      documents, // Array of document objects for multiple uploads
      ...bookingData
    } = req.body;

    // Validate parish exists
    const parish = await Parish.findByPk(parishId);
    if (!parish) {
      return res.status(404).json({ error: 'Parish not found' });
    }

    // Check booking window
    const windowCheck = await checkBookingWindow(parishId, sacramentType, preferredDate);
    if (!windowCheck.valid) {
      return res.status(400).json({ error: windowCheck.error });
    }

    // Check blackout dates
    const blackoutCheck = await checkBlackoutDates(parishId, sacramentType, preferredDate);
    if (!blackoutCheck.available) {
      return res.status(400).json({ error: blackoutCheck.reason });
    }

    // Check daily limit
    const limitCheck = await checkDailyLimit(parishId, sacramentType, preferredDate, config.model);
    if (!limitCheck.withinLimit) {
      return res.status(400).json({ error: limitCheck.error });
    }

    // Convert notes array to JSONB string if needed, or handle legacy additionalNotes
    let notesArray = [];
    if (notes && Array.isArray(notes) && notes.length > 0) {
      // New format: notes is already an array of {author, content, authorId, timestamp}
      notesArray = notes;
    } else if (additionalNotes) {
      // Legacy format: convert single additionalNotes string to array
      notesArray = [{
        author: 'parishioner',
        content: additionalNotes,
        authorId: req.user.userId,
        timestamp: new Date().toISOString(),
      }];
    }
    // If neither notes nor additionalNotes provided, notesArray remains empty

    // Create booking first (we need the booking ID to link documents)
    const booking = await config.model.create({
      parishId,
      userId: req.user.userId,
      preferredDate,
      preferredTimeSlot,
      priestId,
      notes: notesArray,
      status: 'pending',
      ...bookingData,
    });


    // Add godparents if allowed
    if (config.allowsGodparents && godparents.length > 0) {
      const godparentRecords = godparents.map((gp) => ({
        bookingType: sacramentType,
        bookingId: booking.id,
        fullName: gp.fullName,
        contactEmail: gp.contactEmail,
        contactPhone: gp.contactPhone,
        address: gp.address,
        parishAffiliation: gp.parishAffiliation,
        confirmationCertificateNumber: gp.confirmationCertificateNumber,
        notes: gp.notes,
      }));
      await Godparent.bulkCreate(godparentRecords);
    }

    // Link uploaded documents to booking
    // Handle both single document (legacy) and multiple documents array
    const documentEntries = [];

    // Check if documents array is provided (new format)
    if (Array.isArray(documents) && documents.length > 0) {
      documentEntries.push(...documents);
    } 
    // Otherwise, fallback to single document fields (legacy)
    else if (uploadedFile && filePath && fileUrl && fileSize && mimeType) {
      documentEntries.push({
        uploadedFile,
        filePath,
        fileUrl,
        fileSize,
        mimeType,
        documentType: documentType,
      });
    }

    // Create all document records
    for (const doc of documentEntries) {
      await BookingDocument.create({
        bookingType: sacramentType,
        bookingId: booking.id,
        documentType: doc.documentType || 'other',
        fileName: doc.uploadedFile,
        filePath: doc.filePath,
        fileUrl: doc.fileUrl,
        fileSize: parseInt(doc.fileSize),
        mimeType: doc.mimeType,
        uploadedBy: req.user.userId,
      });
      console.log(`Created booking document for file ${doc.uploadedFile} linked to ${sacramentType} booking ${booking.id}`);
    }

    // Log warnings for incomplete single document data
    if (uploadedFile && !(filePath && fileUrl && fileSize && mimeType)) {
      console.log(`File ${uploadedFile} uploaded but missing file details in request body`);
    }

    // Send confirmation email
    try {
      const contactEmail = bookingData.contactEmail || req.user.email;
      await emailService.sendNotification(
        contactEmail,
        `${config.serviceName} Booking Request Received`,
        `
          <h2>${config.serviceName} Booking Request Received</h2>
          <p>Dear Applicant,</p>
          <p>Your ${config.serviceName.toLowerCase()} booking request has been successfully submitted.</p>
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

    const responseNote = preferredPriest
      ? 'Preferred priest noted. Subject to availability. Parish will confirm.'
      : undefined;

    // Get booking data as plain object, excluding meta fields
    const bookingRecord = booking.get({ plain: true });
    // Add the note field
    bookingRecord.note = responseNote;

    // Log the response for debugging
    const responseBody = {
      message: `${config.serviceName} booking request submitted successfully`,
      booking: bookingRecord,
    };
    console.log('Funeral Mass Booking created. Response:', JSON.stringify(responseBody, null, 2));

    res.status(201).json(responseBody);
  } catch (error) {
    console.error(`Error creating ${sacramentType} booking:`, error);
    res.status(500).json({ error: `Failed to create ${sacramentType} booking` });
  }
};

// Get all Sacrament Bookings (generic)
exports.getSacramentBookings = (sacramentType) => async (req, res) => {
  try {
    const config = SACRAMENT_CONFIG[sacramentType];
    if (!config) {
      return res.status(400).json({ error: 'Invalid sacrament type' });
    }

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

    const includeOptions = [
      { model: Parish, as: 'parish', attributes: ['id', 'name', 'address'] },
    ];

    if (config.allowsGodparents) {
      includeOptions.push({
        model: Godparent,
        as: 'godparents',
        attributes: ['id', 'fullName', 'contactEmail', 'contactPhone'],
      });
    }

    includeOptions.push({
      model: BookingDocument,
      as: 'documents',
      attributes: ['id', 'documentType', 'fileName', 'fileUrl', 'isVerified'],
    });

    const { count, rows } = await config.model.findAndCountAll({
      where,
      include: includeOptions,
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
    console.error(`Error fetching ${sacramentType} bookings:`, error);
    res.status(500).json({ error: `Failed to fetch ${sacramentType} bookings` });
  }
};

// Get single Sacrament Booking (generic)
exports.getSacramentBooking = (sacramentType) => async (req, res) => {
  try {
    const config = SACRAMENT_CONFIG[sacramentType];
    if (!config) {
      return res.status(400).json({ error: 'Invalid sacrament type' });
    }

    const { id } = req.params;

    const includeOptions = [
      { model: Parish, as: 'parish' },
      { model: BookingDocument, as: 'documents' },
      { model: Payment, as: 'payment' },
    ];

    if (config.allowsGodparents) {
      includeOptions.push({ model: Godparent, as: 'godparents' });
    }

    const booking = await config.model.findByPk(id, {
      include: includeOptions,
    });

    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    res.json({ booking });
  } catch (error) {
    console.error(`Error fetching ${sacramentType} booking:`, error);
    res.status(500).json({ error: `Failed to fetch ${sacramentType} booking` });
  }
};

// Update Sacrament Booking (generic)
exports.updateSacramentBooking = (sacramentType) => async (req, res) => {
  try {
    const config = SACRAMENT_CONFIG[sacramentType];
    if (!config) {
      return res.status(400).json({ error: 'Invalid sacrament type' });
    }

    const { id } = req.params;
    const updateData = req.body;

    const booking = await config.model.findByPk(id);
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    // Check permissions
    const isOwner = booking.userId === req.user.userId;
    const isAdmin = ['parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'].includes(
      req.user.role
    );

    if (!isOwner && !isAdmin) {
      return res.status(403).json({ error: 'Not authorized to update this booking' });
    }

    // Admins can update status, users can only update notes and resubmit after decline
    if (!isAdmin) {
      delete updateData.preferredDate;
      delete updateData.preferredTimeSlot;
      
      // Allow parishioners to resubmit: change status from 'declined' back to 'pending'
      if (updateData.status && booking.status === 'declined' && updateData.status === 'pending') {
        // This is allowed - resubmit after decline
      } else if (updateData.status) {
        // Only allow setting back to pending (for resubmit), delete any other status changes
        delete updateData.status;
      }
    }

    // Handle notes: if notes are provided, append to existing notes
    if (updateData.notes !== undefined) {
      const existingNotes = booking.notes || [];
      const newNotes = Array.isArray(updateData.notes) ? updateData.notes : [{
        author: 'parishioner',
        content: updateData.notes,
        authorId: req.user.userId,
        timestamp: new Date().toISOString(),
      }];
      updateData.notes = [...existingNotes, ...newNotes];
    }

    await booking.update(updateData);

    res.json({
      message: `${config.serviceName} booking updated successfully`,
      booking,
    });
  } catch (error) {
    console.error(`Error updating ${sacramentType} booking:`, error);
    res.status(500).json({ error: `Failed to update ${sacramentType} booking` });
  }
};

// Approve/Decline Sacrament Booking (generic - Admin only)
exports.approveSacramentBooking = (sacramentType) => async (req, res) => {
  try {
    const config = SACRAMENT_CONFIG[sacramentType];
    if (!config) {
      return res.status(400).json({ error: 'Invalid sacrament type' });
    }

    const { id } = req.params;
    const { status, notes: adminNotes } = req.body;

    if (!['approved', 'declined', 'completed'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status. Must be "approved", "declined", or "completed"' });
    }

    const booking = await config.model.findByPk(id);
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    // Prepare update data
    const updateData = {
      status,
      approvedBy: req.user.userId,
      approvedAt: new Date(),
    };

    // If adminNotes provided, append to notes array
    if (adminNotes) {
      const existingNotes = booking.notes || [];
      const newNote = {
        author: 'admin',
        content: adminNotes,
        authorId: req.user.userId,
        timestamp: new Date().toISOString(),
      };
      updateData.notes = [...existingNotes, newNote];
    }

    await booking.update(updateData);

    // Send email notification
    try {
      const user = await User.findByPk(booking.userId);
      const contactEmail = booking.contactEmail || user?.email;
      const isDeclined = status === 'declined';
      
      await emailService.sendNotification(
        contactEmail,
        `${config.serviceName} Booking ${isDeclined ? 'Requires Attention' : (status === 'approved' ? 'Approved' : 'Update')}`,
        `
          <h2>${config.serviceName} Booking ${isDeclined ? 'Update' : 'Notification'}</h2>
          <p>Dear Applicant,</p>
          <p>Your ${config.serviceName.toLowerCase()} booking request has been ${isDeclined ? '<span style="color: red;">declined</span>' : status}.</p>
          ${isDeclined ? `
            <div style="background-color: #fff3cd; padding: 16px; border-radius: 8px; margin: 16px 0;">
              <h3 style="margin-top: 0; color: #856404;">⚠️ Your booking requires attention</h3>
              <p><strong>Reason for decline:</strong></p>
              ${adminNotes ? `<p style="margin-left: 16px;">${adminNotes}</p>` : '<p><em>No specific reason provided. Please contact the parish office for details.</em></p>'}
              <p><strong>What to do next:</strong></p>
              <ol style="margin-left: 16px;">
                <li>Review the reason above</li>
                <li>Make the necessary corrections or changes</li>
                <li>Log in to the booking system and click <strong>"Resubmit Booking"</strong> after making your changes</li>
              </ol>
            </div>
          ` : ''}
          <p><strong>Booking Details:</strong></p>
          <ul>
            <li>Reference Number: ${booking.id}</li>
            <li>Preferred Date: ${booking.preferredDate ? new Date(booking.preferredDate).toLocaleDateString() : 'Not specified'}</li>
            <li>Preferred Time Slot: ${booking.preferredTimeSlot || 'Not specified'}</li>
            <li>Status: ${status}</li>
          </ul>
          ${booking.notes && booking.notes.length > 0 ? `
            <p><strong>Previous Notes:</strong></p>
            <ul>
              ${booking.notes.slice(-3).map(note => `<li><em>${note.author === 'admin' ? 'Parish Admin' : 'You'}:</em> ${note.content}</li>`).join('')}
            </ul>
          ` : ''}
          <br>
          <p>Best regards,<br>The Parish Team</p>
        `
      );
    } catch (emailError) {
      console.error('Failed to send status update email:', emailError);
    }

    res.json({
      message: `${config.serviceName} booking ${status} successfully`,
      booking,
    });
  } catch (error) {
    console.error(`Error approving ${sacramentType} booking:`, error);
    res.status(500).json({ error: 'Failed to process approval' });
  }
};

// Delete Sacrament Booking (generic)
exports.deleteSacramentBooking = (sacramentType) => async (req, res) => {
  try {
    const config = SACRAMENT_CONFIG[sacramentType];
    if (!config) {
      return res.status(400).json({ error: 'Invalid sacrament type' });
    }

    const { id } = req.params;

    const booking = await config.model.findByPk(id);
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

    res.json({ message: `${config.serviceName} booking cancelled successfully` });
  } catch (error) {
    console.error(`Error deleting ${sacramentType} booking:`, error);
    res.status(500).json({ error: `Failed to delete ${sacramentType} booking` });
  }
};

// Attach document to sacrament booking (generic)
exports.attachDocument = (sacramentType) => async (req, res) => {
  try {
    const config = SACRAMENT_CONFIG[sacramentType];
    if (!config) {
      return res.status(400).json({ error: 'Invalid sacrament type' });
    }

    const { id } = req.params;
    const { documentType } = req.body;

    // Validate booking exists
    const booking = await config.model.findByPk(id);
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
      
      // Save file to permanent location (upload to Supabase immediately for existing bookings)
      const fileData = await fileService.saveFile(
        req.file,
        req.user.userId,
        `${sacramentType}-${id}`
      );

      // Create BookingDocument record in database
      const bookingDocument = await BookingDocument.create({
        bookingType: sacramentType,
        bookingId: parseInt(id),
        documentType: documentType || 'other',
        fileName: fileData.filename,
        filePath: fileData.path,
        fileUrl: fileData.url,
        fileSize: fileData.size,
        mimeType: fileData.mimeType,
        uploadedBy: req.user.userId,
      });

      console.log(`Document attached to ${sacramentType} booking ${id}:`, bookingDocument.id);

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
        bookingType: sacramentType,
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
    console.error(`Error attaching document to ${sacramentType} booking:`, error);
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

// Delete document from sacrament booking
exports.deleteDocument = (sacramentType) => async (req, res) => {
  try {
    const config = SACRAMENT_CONFIG[sacramentType];
    if (!config) {
      return res.status(400).json({ error: 'Invalid sacrament type' });
    }

    const { bookingId, documentId } = req.params;
    console.log(`=== DELETE DOCUMENT REQUEST (${sacramentType}) ===`);
    console.log('Booking ID:', bookingId);
    console.log('Document ID:', documentId);
    console.log('User ID:', req.user.userId);
    console.log('User Role:', req.user.role);

    // Verify booking exists
    const booking = await config.model.findByPk(bookingId);
    if (!booking) {
      console.log('Booking not found for ID:', bookingId);
      return res.status(404).json({ error: 'Booking not found' });
    }
    console.log('Booking found:', booking.id, 'User ID:', booking.userId);

    // Check permissions - only owner or admin can delete documents
    const isOwner = booking.userId === req.user.userId;
    const isAdmin = ['parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'].includes(req.user.role);
    console.log('Permission check - Is Owner:', isOwner, 'Is Admin:', isAdmin);
    if (!isOwner && !isAdmin) {
      return res.status(403).json({ error: 'Not authorized to delete documents' });
    }

    // Find the document
    console.log('Searching for document with:', { id: documentId, bookingType: sacramentType, bookingId: parseInt(bookingId) });
    const document = await BookingDocument.findOne({
      where: { id: documentId, bookingType: sacramentType, bookingId: parseInt(bookingId) }
    });

    if (!document) {
      console.log('Document not found with criteria:', { id: documentId, bookingType: sacramentType, bookingId: parseInt(bookingId) });
      // Try to find any documents for this booking to help debug
      const allDocs = await BookingDocument.findAll({ where: { bookingId: parseInt(bookingId), bookingType: sacramentType } });
      console.log('All documents for this booking:', allDocs.length);
      return res.status(404).json({ error: 'Document not found' });
    }
    console.log('Document found:', document.id, 'fileName:', document.fileName, 'filePath:', document.filePath);

    // Delete file from storage
    const fileService = require('../services/fileService');
    try {
      console.log('Attempting to delete file from storage:', document.filePath);
      await fileService.deleteFile(document.filePath);
      console.log('File deleted from storage successfully');
    } catch (fileError) {
      console.error('Error deleting file from storage:', fileError);
      // Continue to delete DB record even if file deletion fails
    }

    // Delete document record
    console.log('Deleting document record from database, id:', document.id);
    await document.destroy();
    console.log('Document record deleted successfully');

    res.json({ message: 'Document deleted successfully' });
  } catch (error) {
    console.error(`Error deleting document from ${sacramentType} booking:`, error);
    console.error('Stack trace:', error.stack);
    res.status(500).json({ error: 'Failed to delete document', details: error.message });
  }
};

// Get available time slots (generic)
exports.getAvailableTimeSlots = (sacramentType) => async (req, res) => {
  try {
    const config = SACRAMENT_CONFIG[sacramentType];
    if (!config) {
      return res.status(400).json({ error: 'Invalid sacrament type' });
    }

    const { parishId, date } = req.query;

    if (!parishId || !date) {
      return res.status(400).json({ error: 'Parish ID and date are required' });
    }

    // Get slot settings
    const settings = await ParishSlotSetting.findOne({
      where: { parishId, serviceType: sacramentType, isActive: true },
    });

    // Check blackout dates
    const blackoutCheck = await checkBlackoutDates(parishId, sacramentType, date);
    if (!blackoutCheck.available) {
      return res.json({ timeSlots: [], blackoutReason: blackoutCheck.reason });
    }

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

    // Get bookings for this date
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    const existingBookings = await config.model.findAll({
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
      available: !bookedSlots.has(slot.start) && (!slot.capacity || slot.capacity > bookedSlots.size),
    }));

    res.json({ timeSlots: availableSlots });
  } catch (error) {
    console.error(`Error fetching time slots for ${sacramentType}:`, error);
    res.status(500).json({ error: 'Failed to fetch available time slots' });
  }
};
