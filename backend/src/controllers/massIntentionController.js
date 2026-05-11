const { validationResult } = require('express-validator');
const container = require('../container');
const { User, BookingDocument } = require('../models');
const MassIntentionDTO = require('../dto/MassIntentionDTO');

// Attach document to mass intention
exports.attachDocument = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { documentType } = req.body;

    // Get mass intention use case
    const useCase = container.get('getMassIntentionByIdUseCase');
    const booking = await useCase.execute(id, req.user);

    if (!booking) {
      return res.status(404).json({ error: 'Mass intention not found' });
    }

    // Check permissions - only owner or admin can add documents
    const isOwner = booking.userId === req.user.userId;
    const isAdmin = ['parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'].includes(
      req.user.role
    );

    if (!isOwner && !isAdmin) {
      return res.status(403).json({ error: 'Not authorized to add documents to this mass intention' });
    }

    // Handle file upload if present
    if (req.file) {
      const fileService = require('../services/fileService');
      
      // Save file to permanent location
      const fileData = await fileService.saveFile(
        req.file,
        req.user.userId,
        `mass-intention-${id}`
      );

      // Create BookingDocument record in database
      const bookingDocument = await BookingDocument.create({
        bookingType: 'mass_intention',
        bookingId: parseInt(id),
        documentType: documentType || 'other',
        fileName: fileData.filename,
        filePath: fileData.path,
        fileUrl: fileData.url,
        fileSize: fileData.size,
        mimeType: fileData.mimeType,
        uploadedBy: req.user.userId,
      });

      console.log(`Document attached to mass intention ${id}:`, bookingDocument.id);

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
        bookingType: 'mass_intention',
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
    console.error('Error attaching document to mass intention:', error);
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

// Create a new mass intention
exports.createMassIntention = async (req, res, next) => {
  try {
    console.log('[createMassIntention] FULL req.body:', JSON.stringify(req.body));
    // Validate request
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    // Fetch full user object for email
    const user = await User.findByPk(req.user.userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Create DTO from request
    const dto = MassIntentionDTO.fromRequest(req.body);

    // Execute use case
    const useCase = container.get('createMassIntentionUseCase');
    const result = await useCase.execute(dto, user);

    res.status(201).json({
      message: 'Mass intention created successfully',
      massIntention: result.toObject()
    });
  } catch (error) {
    next(error);
  }
};

// Get all mass intentions (with pagination and filtering)
exports.getAllMassIntentions = async (req, res, next) => {
  try {
    const useCase = container.get('getAllMassIntentionsUseCase');
    const result = await useCase.execute(req.query, req.user);

    res.json({
      massIntentions: result.data,
      pagination: result.pagination
    });
  } catch (error) {
    next(error);
  }
};

// Get a specific mass intention by ID
exports.getMassIntentionById = async (req, res, next) => {
  try {
    const { id } = req.params;
    console.log(`[getMassIntentionById] Fetching ID: ${id}, User: ${req.user.userId}`);
    const useCase = container.get('getMassIntentionByIdUseCase');
    const result = await useCase.execute(id, req.user);
    console.log('[getMassIntentionById] Result:', JSON.stringify(result.toObject(), null, 2));

    res.json({
      massIntention: result.toObject()
    });
  } catch (error) {
    console.error('[getMassIntentionById] Error:', error.message);
    next(error);
  }
};

// Update a mass intention
exports.updateMassIntention = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validate request
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const dto = MassIntentionDTO.fromRequest(req.body);
    const useCase = container.get('updateMassIntentionUseCase');
    const result = await useCase.execute(id, dto, req.user);

    res.json({
      message: 'Mass intention updated successfully',
      massIntention: result.toObject()
    });
  } catch (error) {
    next(error);
  }
};

// Delete a mass intention
exports.deleteMassIntention = async (req, res, next) => {
  try {
    const { id } = req.params;
    const useCase = container.get('deleteMassIntentionUseCase');
    await useCase.execute(id, req.user);

    res.json({
      message: 'Mass intention deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Update mass intention status
exports.updateMassIntentionStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status || !['pending', 'approved', 'declined', 'completed'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status value' });
    }

    console.log(`[updateMassIntentionStatus] ID: ${id}, Status: ${status}, User: ${req.user.userId}`);
    const useCase = container.get('updateMassIntentionStatusUseCase');
    const result = await useCase.execute(id, status, req.user);
    console.log('[updateMassIntentionStatus] Success:', result.toObject());

    res.json({
      message: `Mass intention ${status} successfully`,
      massIntention: result.toObject()
    });
  } catch (error) {
    console.error('[updateMassIntentionStatus] Error:', error.message);
    next(error);
  }
};

// Approve a mass intention
exports.approveMassIntention = async (req, res, next) => {
  try {
    const { id } = req.params;
    console.log(`[approveMassIntention] ID: ${id}, User: ${req.user.userId}, Role: ${req.user.role}`);
    const useCase = container.get('approveMassIntentionUseCase');
    const result = await useCase.execute(id, req.user);
    console.log('[approveMassIntention] Success:', result.toObject());

    res.json({
      message: 'Mass intention approved successfully',
      massIntention: result.toObject()
    });
  } catch (error) {
    console.error('[approveMassIntention] Error:', error.message);
    next(error);
  }
};

// Decline a mass intention
exports.declineMassIntention = async (req, res, next) => {
  try {
    const { id } = req.params;
    console.log(`[declineMassIntention] ID: ${id}, User: ${req.user.userId}, Role: ${req.user.role}`);
    const useCase = container.get('declineMassIntentionUseCase');
    const result = await useCase.execute(id, req.user);
    console.log('[declineMassIntention] Success:', result.toObject());

    res.json({
      message: 'Mass intention declined successfully',
      massIntention: result.toObject()
    });
  } catch (error) {
    console.error('[declineMassIntention] Error:', error.message);
    next(error);
  }
};