const { Parish } = require('../models');
const { Op } = require('sequelize');

// Get all parishes (with optional filtering for active/inactive)
exports.getAllParishes = async (req, res, next) => {
  try {
    const { active } = req.query;
    let whereCondition = {};

    // If active parameter is provided, filter accordingly
    if (active !== undefined) {
      whereCondition.isActive = active === 'true';
    } else {
      // By default, only return active parishes
      whereCondition.isActive = true;
    }

    const parishes = await Parish.findAll({
      where: whereCondition,
      attributes: ['id', 'name', 'address', 'contactEmail', 'contactPhone', 'schedule', 'servicesOffered', 'isActive', 'createdAt', 'updatedAt'],
    });

    res.json({
      success: true,
      data: parishes,
      message: 'Parishes retrieved successfully',
    });
  } catch (error) {
    // Log connection errors for debugging
    if (error.name === 'SequelizeConnectionError' || error.original) {
      console.error('Database connection error in getAllParishes:', {
        message: error.message,
        original: error.original?.message,
        code: error.original?.code,
      });
    }
    next(error);
  }
};

// Get parish by ID
exports.getParishById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const parish = await Parish.findByPk(id, {
      attributes: ['id', 'name', 'address', 'contactEmail', 'contactPhone', 'schedule', 'servicesOffered', 'isActive', 'createdAt', 'updatedAt'],
    });

    if (!parish) {
      return res.status(404).json({
        success: false,
        message: 'Parish not found',
      });
    }

    res.json({
      success: true,
      data: parish,
      message: 'Parish retrieved successfully',
    });
  } catch (error) {
    next(error);
  }
};

// Create a new parish
exports.createParish = async (req, res, next) => {
  try {
    // Only diocese staff can create parishes
    if (!['diocese_staff', 'diocese_admin'].includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Only diocese staff can create parishes',
      });
    }

    const { name, address, contactEmail, contactPhone, schedule, servicesOffered } = req.body;

    // Check if parish with same name already exists
    const existingParish = await Parish.findOne({
      where: { name: { [Op.iLike]: name.trim() } }
    });

    if (existingParish) {
      return res.status(409).json({
        success: false,
        message: 'A parish with this name already exists',
      });
    }

    const newParish = await Parish.create({
      name,
      address,
      contactEmail,
      contactPhone,
      schedule: schedule || {},
      servicesOffered: servicesOffered || [],
    });

    res.status(201).json({
      success: true,
      data: newParish,
      message: 'Parish created successfully',
    });
  } catch (error) {
    next(error);
  }
};

// Update a parish
exports.updateParish = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, address, contactEmail, contactPhone, schedule, servicesOffered, isActive } = req.body;

    const parish = await Parish.findByPk(id);

    if (!parish) {
      return res.status(404).json({
        success: false,
        message: 'Parish not found',
      });
    }

    // Check if user has permission to update this parish
    if (!['diocese_staff', 'diocese_admin'].includes(req.user.role)) {
      // Parish admins can only update their assigned parish
      if (req.user.role !== 'parish_admin' || req.user.assignedParishId !== id) {
        return res.status(403).json({
          success: false,
          message: 'You do not have permission to update this parish',
        });
      }
    }

    // Check if another parish with the same name exists (excluding current parish)
    if (name) {
      const existingParish = await Parish.findOne({
        where: { 
          name: { [Op.iLike]: name.trim() },
          id: { [Op.ne]: id } // Exclude current parish
        }
      });

      if (existingParish) {
        return res.status(409).json({
          success: false,
          message: 'A parish with this name already exists',
        });
      }
    }

    await parish.update({
      name: name || parish.name,
      address: address || parish.address,
      contactEmail: contactEmail || parish.contactEmail,
      contactPhone: contactPhone || parish.contactPhone,
      schedule: schedule !== undefined ? schedule : parish.schedule,
      servicesOffered: servicesOffered !== undefined ? servicesOffered : parish.servicesOffered,
      isActive: isActive !== undefined ? isActive : parish.isActive,
    });

    res.json({
      success: true,
      data: parish,
      message: 'Parish updated successfully',
    });
  } catch (error) {
    next(error);
  }
};

// Delete a parish (soft delete by setting isActive to false)
exports.deleteParish = async (req, res, next) => {
  try {
    const { id } = req.params;

    const parish = await Parish.findByPk(id);

    if (!parish) {
      return res.status(404).json({
        success: false,
        message: 'Parish not found',
      });
    }

    // Check if user has permission to delete this parish
    if (!['diocese_staff', 'diocese_admin'].includes(req.user.role)) {
      // Parish admins cannot delete parishes
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to delete parishes',
      });
    }

    // Soft delete by setting isActive to false
    await parish.update({ isActive: false });

    res.json({
      success: true,
      message: 'Parish deactivated successfully',
    });
  } catch (error) {
    next(error);
  }
};

// Hard delete a parish (only for diocese admin use)
exports.hardDeleteParish = async (req, res, next) => {
  try {
    const { id } = req.params;

    const parish = await Parish.findByPk(id);

    if (!parish) {
      return res.status(404).json({
        success: false,
        message: 'Parish not found',
      });
    }

    // Only diocese staff can hard delete parishes
    if (!['diocese_staff', 'diocese_admin'].includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Only diocese staff can hard delete parishes',
      });
    }

    await parish.destroy();

    res.json({
      success: true,
      message: 'Parish deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

// Search parishes by name or location
exports.searchParishes = async (req, res, next) => {
  try {
    const { query, services } = req.query;
    const conditions = { isActive: true };

    if (query) {
      conditions[Op.or] = [
        { name: { [Op.iLike]: `%${query}%` } },
        { address: { [Op.iLike]: `%${query}%` } },
      ];
    }

    if (services) {
      const serviceList = Array.isArray(services) ? services : [services];
      conditions.servicesOffered = { [Op.contains]: serviceList };
    }

    const parishes = await Parish.findAll({
      where: conditions,
      attributes: ['id', 'name', 'address', 'contactEmail', 'contactPhone', 'schedule', 'servicesOffered', 'isActive', 'createdAt', 'updatedAt'],
    });

    res.json({
      success: true,
      data: parishes,
      message: 'Parishes retrieved successfully',
    });
  } catch (error) {
    next(error);
  }
};

// Get parishes by services offered
exports.getParishesByService = async (req, res, next) => {
  try {
    const { service } = req.params;

    const parishes = await Parish.findAll({
      where: {
        isActive: true,
        servicesOffered: { [Op.contains]: [service] },
      },
      attributes: ['id', 'name', 'address', 'contactEmail', 'contactPhone', 'schedule', 'servicesOffered', 'isActive', 'createdAt', 'updatedAt'],
    });

    res.json({
      success: true,
      data: parishes,
      message: 'Parishes retrieved successfully',
    });
  } catch (error) {
    next(error);
  }
};