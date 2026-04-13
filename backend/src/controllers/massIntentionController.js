const { validationResult } = require('express-validator');
const container = require('../container');
const { User } = require('../models');
const MassIntentionDTO = require('../dto/MassIntentionDTO');

// Create a new mass intention
exports.createMassIntention = async (req, res, next) => {
  try {
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
    const useCase = container.get('getMassIntentionByIdUseCase');
    const result = await useCase.execute(id, req.user);

    res.json({
      massIntention: result.toObject()
    });
  } catch (error) {
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

// Approve a mass intention
exports.approveMassIntention = async (req, res, next) => {
  try {
    const { id } = req.params;
    const useCase = container.get('approveMassIntentionUseCase');
    const result = await useCase.execute(id, req.user);

    res.json({
      message: 'Mass intention approved successfully',
      massIntention: result.toObject()
    });
  } catch (error) {
    next(error);
  }
};

// Decline a mass intention
exports.declineMassIntention = async (req, res, next) => {
  try {
    const { id } = req.params;
    const useCase = container.get('declineMassIntentionUseCase');
    const result = await useCase.execute(id, req.user);

    res.json({
      message: 'Mass intention declined successfully',
      massIntention: result.toObject()
    });
  } catch (error) {
    next(error);
  }
};