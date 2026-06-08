const {
  User,
  Parish,
  Booking,
  MassIntention,
  SystemConfiguration,
  BaptismBooking,
  WeddingBooking,
  ConfirmationBooking,
  EucharistBooking,
  ReconciliationBooking,
  AnointingSickBooking,
  FuneralMassBooking,
} = require('../models');
const { sequelize } = require('../config/database');
const { Op } = require('sequelize');
const { generateRandomPassword } = require('../utils/passwordUtils');
const emailService = require('../services/emailService');

// Helper to get sacrament name from model
const _getSacramentName = (modelName) => {
  const nameMap = {
    'BaptismBooking': 'Baptism',
    'WeddingBooking': 'Wedding',
    'ConfirmationBooking': 'Confirmation',
    'EucharistBooking': 'Eucharist',
    'ReconciliationBooking': 'Reconciliation',
    'AnointingSickBooking': 'Anointing of the Sick',
    'FuneralMassBooking': 'Funeral Mass',
    'MassIntention': 'Mass Intention',
  };
  return nameMap[modelName] || 'Sacrament';
};

// Get dashboard statistics
const getDashboardStats = async (req, res) => {
  try {
    const { parishId } = req.query;
    const user = req.user;

    // Build where clause based on user role
    let parishWhereClause = {};
    let bookingWhereClause = {};
    let userWhereClause = {};

    // Parish-level users: restrict to their assigned parish
    if (user.role === 'parish_admin' || user.role === 'parish_staff') {
      if (user.assignedParishId) {
        parishWhereClause = { id: user.assignedParishId };
        bookingWhereClause = { parishId: user.assignedParishId };
        userWhereClause = { assignedParishId: user.assignedParishId };
      }
    }

    // Diocese-level users: can filter by specific parish or see all
    if (user.role === 'diocese_admin' || user.role === 'diocese_staff') {
      if (parishId) {
        parishWhereClause = { id: parishId };
        bookingWhereClause = { parishId };
        userWhereClause = { assignedParishId: parishId };
      }
      // If no parishId, clauses remain empty = all parishes/bookings/users
    }

    // Get counts from ALL booking tables
    const bookingTables = [
      { model: BaptismBooking, type: 'baptism' },
      { model: WeddingBooking, type: 'wedding' },
      { model: ConfirmationBooking, type: 'confirmation' },
      { model: EucharistBooking, type: 'eucharist' },
      { model: ReconciliationBooking, type: 'reconciliation' },
      { model: AnointingSickBooking, type: 'anointing_sick' },
      { model: FuneralMassBooking, type: 'funeral_mass' },
    ];

    let totalBookings = 0;
    let pendingBookings = 0;
    let approvedBookings = 0;
    let thisMonthBookings = 0;

    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const endOfMonth = new Date();
    endOfMonth.setMonth(endOfMonth.getMonth() + 1);
    endOfMonth.setDate(1);
    endOfMonth.setHours(0, 0, 0, 0);

    for (const { model } of bookingTables) {
      const total = await model.count({ where: bookingWhereClause });
      const pending = await model.count({
        where: { ...bookingWhereClause, status: 'pending' },
      });
      const approved = await model.count({
        where: { ...bookingWhereClause, status: 'approved' },
      });
      const thisMonth = await model.count({
        where: {
          ...bookingWhereClause,
          preferredDate: {
            [Op.gte]: startOfMonth,
            [Op.lt]: endOfMonth,
          },
        },
      });

      totalBookings += total;
      pendingBookings += pending;
      approvedBookings += approved;
      thisMonthBookings += thisMonth;
    }

    // Also count mass intentions
    const massIntentionTotal = await MassIntention.count({ where: bookingWhereClause });
    const massIntentionPending = await MassIntention.count({
      where: { ...bookingWhereClause, status: 'pending' },
    });
    const massIntentionApproved = await MassIntention.count({
      where: { ...bookingWhereClause, status: 'approved' },
    });
    const massIntentionThisMonth = await MassIntention.count({
      where: {
        ...bookingWhereClause,
        massSchedule: {
          [Op.gte]: startOfMonth,
          [Op.lt]: endOfMonth,
        },
      },
    });

    totalBookings += massIntentionTotal;
    pendingBookings += massIntentionPending;
    approvedBookings += massIntentionApproved;
    thisMonthBookings += massIntentionThisMonth;

    // Get parish and user counts
    const totalParishes = await Parish.count({ where: parishWhereClause });
    const totalUsers = await User.count({ where: userWhereClause });

    // Debug logging
    console.log('Dashboard stats - User role:', user.role);
    console.log('Dashboard stats - Parish where clause:', parishWhereClause);
    console.log('Dashboard stats - Total parishes:', totalParishes);
    console.log('Dashboard stats - Total users:', totalUsers);

    // Return dashboard stats
    res.json({
      totalParishes,
      totalUsers,
      totalBookings,
      pendingBookings,
      approvedBookings,
      thisMonthBookings,
    });
  } catch (error) {
    console.error('Error getting dashboard stats:', error);
    res.status(500).json({ error: 'Failed to get dashboard statistics' });
  }
};

// ==================== USER MANAGEMENT ====================

// Role hierarchy levels for user management
const ROLE_HIERARCHY = {
  parishioner: 1,
  parish_staff: 2,
  priest: 3,
  parish_admin: 4,
  diocese_staff: 5,
  diocese_admin: 6,
};

// Helper to check if a user can manage a target role
const canManageRole = (requestingUserRole, targetRole) => {
  return ROLE_HIERARCHY[requestingUserRole] > ROLE_HIERARCHY[targetRole];
};

// Get all users (with filtering and pagination)
const getAllUsers = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      role,
      parishId,
      search,
      isActive,
    } = req.query;

    const requestingUser = req.user;
    const offset = (page - 1) * limit;
    const whereClause = {};

    // Apply parish-level restrictions based on user role
    if (requestingUser.role === 'parish_admin') {
      // Parish admins can only view users in their assigned parish
      whereClause.assignedParishId = requestingUser.assignedParishId;
      // They can only view parish_staff, priest, and parishioner roles
      whereClause.role = { [Op.in]: ['parish_staff', 'priest', 'parishioner'] };
    } else if (requestingUser.role === 'parish_staff') {
      // Parish staff can only view users in their assigned parish
      whereClause.assignedParishId = requestingUser.assignedParishId;
      // They can only view parishioner roles
      whereClause.role = { [Op.in]: ['parishioner'] };
    } else if (requestingUser.role === 'diocese_staff') {
      // diocese_staff cannot view diocese_staff or diocese_admin users
      whereClause.role = { [Op.notIn]: ['diocese_staff', 'diocese_admin'] };
    }

    // Apply additional filters if provided
    if (role) {
      // Validate role permissions based on user role
      if (requestingUser.role === 'parish_admin') {
        if (!['parish_staff', 'priest', 'parishioner'].includes(role)) {
          return res.status(403).json({
            error: 'Insufficient permissions',
            message: 'Parish administrators can only view parish staff, priests, and parishioners.',
          });
        }
      } else if (requestingUser.role === 'parish_staff') {
        if (!['priest', 'parishioner'].includes(role)) {
          return res.status(403).json({
            error: 'Insufficient permissions',
            message: 'Parish staff can only view priests and parishioners.',
          });
        }
      } else if (requestingUser.role === 'diocese_staff') {
        if (['diocese_staff', 'diocese_admin'].includes(role)) {
          return res.status(403).json({
            error: 'Insufficient permissions',
            message: 'You do not have permission to view users with this role.',
          });
        }
      }
      whereClause.role = role;
    }
    
    // Parish-level users cannot override parish filter
    if (requestingUser.role === 'parish_admin' || requestingUser.role === 'parish_staff') {
      // Ensure they can only see their own parish
      whereClause.assignedParishId = requestingUser.assignedParishId;
    } else if (parishId) {
      // Diocese-level users can filter by specific parish
      whereClause.assignedParishId = parishId;
    }
    
    if (isActive !== undefined) whereClause.isActive = isActive === 'true';

    if (search) {
      whereClause[Op.or] = [
        { firstName: { [Op.iLike]: `%${search}%` } },
        { lastName: { [Op.iLike]: `%${search}%` } },
        { email: { [Op.iLike]: `%${search}%` } },
      ];
    }

    const { count, rows } = await User.findAndCountAll({
      where: whereClause,
      include: [
        {
          model: Parish,
          as: 'assignedParish',
          attributes: ['id', 'name'],
        },
      ],
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['createdAt', 'DESC']],
    });

    res.json({
      users: rows.map((user) => user.toSafeObject()),
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    console.error('Error getting users:', error);
    res.status(500).json({ error: 'Failed to get users' });
  }
};

// Get single user by ID
const getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    const requestingUser = req.user;

    const user = await User.findByPk(id, {
      include: [
        {
          model: Parish,
          as: 'assignedParish',
          attributes: ['id', 'name'],
        },
      ],
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Apply parish-level restrictions
    if (requestingUser.role === 'parish_admin') {
      // Parish admins can only view users in their assigned parish
      if (user.assignedParishId !== requestingUser.assignedParishId) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'You can only view users in your assigned parish.',
        });
      }
      // They can only view parish_staff, priest, and parishioner roles
      if (!['parish_staff', 'priest', 'parishioner'].includes(user.role)) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Parish administrators can only view parish staff, priests, and parishioners.',
        });
      }
    } else if (requestingUser.role === 'parish_staff') {
      // Parish staff can only view users in their assigned parish
      if (user.assignedParishId !== requestingUser.assignedParishId) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'You can only view users in your assigned parish.',
        });
      }
      // They can only view priest and parishioner roles
      if (!['priest', 'parishioner'].includes(user.role)) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Parish staff can only view priests and parishioners.',
        });
      }
    } else if (requestingUser.role === 'diocese_staff') {
      // diocese_staff cannot view diocese_staff or diocese_admin users
      if (['diocese_staff', 'diocese_admin'].includes(user.role)) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'You do not have permission to view this user.',
        });
      }
    }

    res.json(user.toSafeObject());
  } catch (error) {
    console.error('Error getting user:', error);
    res.status(500).json({ error: 'Failed to get user' });
  }
};

// Create new user
const createUser = async (req, res) => {
  try {
    const {
      email,
      firstName,
      lastName,
      phone,
      role,
      assignedParishId,
    } = req.body;

    // Validate required fields
    if (!email || !firstName || !lastName || !role) {
      return res.status(400).json({
        error: 'Missing required fields',
        message: 'Email, firstName, lastName, and role are required',
      });
    }

    // Role-based user creation permissions:
    // - diocese_admin can create all users
    // - diocese_staff can create all except diocese_admin
    // - parish_admin can create all except diocese_admin and diocese_staff
    // - parish_staff can only create priest (same parish) and parishioner (same parish)
    // - priests and parishioners cannot create users
    
    const requestingUser = req.user;
    
    // Check if the requesting user can create the target role
    if (requestingUser.role === 'diocese_admin') {
      // diocese_admin can create any role
    } else if (requestingUser.role === 'diocese_staff') {
      // diocese_staff can create all roles except diocese_admin
      if (role === 'diocese_admin') {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Diocese staff cannot create diocese administrators.',
        });
      }
    } else if (requestingUser.role === 'parish_admin') {
      // parish_admin can only create parish_staff, priest, and parishioner (same parish only)
      if (!['parish_staff', 'priest', 'parishioner'].includes(role)) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Parish administrators can only create parish staff, priests, and parishioners.',
        });
      }
      
      // Verify the assignedParishId matches the admin's assigned parish
      if (assignedParishId !== requestingUser.assignedParishId) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Parish administrators can only create users for their assigned parish.',
        });
      }
    } else if (requestingUser.role === 'parish_staff') {
      // parish_staff can only create parishioner of the same parish
      if (role !== 'parishioner') {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Parish staff can only create parishioners.',
        });
      }
      
      // Verify the assignedParishId matches the staff's assigned parish
      if (assignedParishId !== requestingUser.assignedParishId) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Parish staff can only create users for their assigned parish.',
        });
      }
    } else {
      // Only allow admin roles to create users
      return res.status(403).json({
        error: 'Insufficient permissions',
        message: 'You do not have permission to create users.',
      });
    }

    // For diocese-level roles, set parish fields to null
    // since diocese personnel don't belong to a specific parish
    const isDioceseLevel = ['diocese_staff', 'diocese_admin'].includes(role);
    let finalAssignedParishId = assignedParishId;
    
    if (isDioceseLevel) {
      finalAssignedParishId = null;
    } else if (requestingUser.role === 'parish_staff' && ['priest', 'parishioner'].includes(role)) {
      // parish_staff can only create users for their assigned parish
      finalAssignedParishId = requestingUser.assignedParishId;
    } else if (!isDioceseLevel && !finalAssignedParishId) {
      // Non-diocese roles require a parish assignment
      return res.status(400).json({
        error: 'Missing parish assignment',
        message: 'Non-diocese level roles must be assigned to a parish.',
      });
    } else if (!isDioceseLevel && finalAssignedParishId) {
      // Validate that the parish exists
      const parish = await Parish.findByPk(finalAssignedParishId);
      if (!parish) {
        return res.status(400).json({
          error: 'Invalid parish',
          message: 'The specified parish does not exist.',
        });
      }
    }

    // Check if user already exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    // Generate random password
    const tempPassword = generateRandomPassword(12);

    const user = await User.create({
      email,
      password: tempPassword,
      firstName,
      lastName,
      phone,
      role,
      assignedParishId: finalAssignedParishId,
      mustChangePassword: true, // Force password change on first login
    });

    // Send email with credentials
    try {
      await emailService.sendWelcomeEmail(user, tempPassword);
    } catch (emailError) {
      console.error('Failed to send welcome email:', emailError);
      // Don't fail the request if email fails
    }

    res.status(201).json({
      message: 'User created successfully. An email with login credentials has been sent to the user.',
      user: user.toSafeObject(),
    });
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ error: 'Failed to create user' });
  }
};

// Update user
const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      email,
      firstName,
      lastName,
      phone,
      role,
      assignedParishId,
      isActive,
    } = req.body;

    const user = await User.findByPk(id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const requestingUser = req.user;

    // Apply parish-level restrictions for viewing/editing users
    if (requestingUser.role === 'parish_admin') {
      // Parish admins can only edit users in their assigned parish
      if (user.assignedParishId !== requestingUser.assignedParishId) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'You can only edit users in your assigned parish.',
        });
      }
      // They can only edit parish_staff, priest, and parishioner roles
      if (!['parish_staff', 'priest', 'parishioner'].includes(user.role)) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Parish administrators can only edit parish staff, priests, and parishioners.',
        });
      }
      // They cannot change the role to anything outside their allowed roles
      if (role && !['parish_staff', 'priest', 'parishioner'].includes(role)) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Parish administrators can only assign parish staff, priest, or parishioner roles.',
        });
      }
    } else if (requestingUser.role === 'parish_staff') {
      // Parish staff can only edit users in their assigned parish
      if (user.assignedParishId !== requestingUser.assignedParishId) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'You can only edit users in your assigned parish.',
        });
      }
      // They can only edit priest and parishioner roles
      if (!['priest', 'parishioner'].includes(user.role)) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Parish staff can only edit priests and parishioners.',
        });
      }
      // They cannot change the role at all
      if (role) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Parish staff cannot change user roles.',
        });
      }
    } else if (requestingUser.role === 'diocese_staff') {
      // diocese_staff cannot edit diocese_staff or diocese_admin users
      if (['diocese_staff', 'diocese_admin'].includes(user.role)) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Diocese staff cannot edit users with equal or higher roles.',
        });
      }
      // Additional validation: diocese_staff cannot promote to diocese_staff or diocese_admin
      if (role && ['diocese_staff', 'diocese_admin'].includes(role)) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Diocese staff cannot assign roles equal to or higher than their own.',
        });
      }
    }

    // Check email uniqueness if changing email
    if (email && email !== user.email) {
      const existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        return res.status(400).json({ error: 'Email already registered' });
      }
    }

    // Determine the final role (if changing)
    const finalRole = role || user.role;

    // For diocese-level roles, set parish fields to null
    // since diocese personnel don't belong to a specific parish
    const isDioceseLevel = ['diocese_staff', 'diocese_admin'].includes(finalRole);
    const finalAssignedParishId = isDioceseLevel ? null : (assignedParishId !== undefined ? assignedParishId : user.assignedParishId);

    await user.update({
      email: email || user.email,
      firstName: firstName || user.firstName,
      lastName: lastName || user.lastName,
      phone: phone || user.phone,
      role: finalRole,
      assignedParishId: finalAssignedParishId,
      isActive: isActive !== undefined ? isActive : user.isActive,
    });

    res.json({
      message: 'User updated successfully',
      user: user.toSafeObject(),
    });
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ error: 'Failed to update user' });
  }
};

// Delete user (soft delete by deactivating)
const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;
    const requestingUser = req.user;

    const user = await User.findByPk(id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Prevent self-deletion
    if (parseInt(id) === req.user.userId) {
      return res.status(400).json({ error: 'Cannot delete your own account' });
    }

    // Apply parish-level restrictions for deleting users
    if (requestingUser.role === 'parish_admin') {
      // Parish admins can only delete users in their assigned parish
      if (user.assignedParishId !== requestingUser.assignedParishId) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'You can only delete users in your assigned parish.',
        });
      }
      // They can only delete parish_staff, priest, and parishioner roles
      if (!['parish_staff', 'priest', 'parishioner'].includes(user.role)) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Parish administrators can only delete parish staff, priests, and parishioners.',
        });
      }
    } else if (requestingUser.role === 'parish_staff') {
      // Parish staff can only delete users in their assigned parish
      if (user.assignedParishId !== requestingUser.assignedParishId) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'You can only delete users in your assigned parish.',
        });
      }
      // They can only delete priest and parishioner roles
      if (!['priest', 'parishioner'].includes(user.role)) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Parish staff can only delete priests and parishioners.',
        });
      }
    } else if (requestingUser.role === 'diocese_staff') {
      // diocese_staff cannot delete diocese_staff or diocese_admin users
      if (['diocese_staff', 'diocese_admin'].includes(user.role)) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'Diocese staff cannot delete users with equal or higher roles.',
        });
      }
    }

    // Check if user is a parishioner with pending bookings
    if (user.role === 'parishioner') {
      const bookingTables = [
        BaptismBooking,
        WeddingBooking,
        ConfirmationBooking,
        EucharistBooking,
        ReconciliationBooking,
        AnointingSickBooking,
        FuneralMassBooking,
        MassIntention,
      ];

      let pendingBookingsCount = 0;

      for (const model of bookingTables) {
        const count = await model.count({
          where: {
            userId: id,
            status: 'pending',
          },
        });
        pendingBookingsCount += count;
      }

      if (pendingBookingsCount > 0) {
        return res.status(400).json({
          error: 'Cannot delete user with pending bookings',
          message: `This user has ${pendingBookingsCount} pending booking(s). Please approve or decline them first.`,
          pendingBookingsCount,
        });
      }
    }

    await User.update({ isActive: false }, { where: { id } });

    res.json({ message: 'User deactivated successfully' });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ error: 'Failed to delete user' });
  }
};

// ==================== PARISH MANAGEMENT ====================

// Get all parishes
const getAllParishes = async (req, res) => {
  try {
    const { page = 1, limit = 20, isActive, search } = req.query;
    const offset = (page - 1) * limit;
    const whereClause = {};

    if (isActive !== undefined) whereClause.isActive = isActive === 'true';
    if (search) {
      whereClause.name = { [Op.iLike]: `%${search}%` };
    }

    const { count, rows } = await Parish.findAndCountAll({
      where: whereClause,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['name', 'ASC']],
    });

    res.json({
      parishes: rows,
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    console.error('Error getting parishes:', error);
    res.status(500).json({ error: 'Failed to get parishes' });
  }
};

// Get single parish by ID
const getParishById = async (req, res) => {
  try {
    const { id } = req.params;

    const parish = await Parish.findByPk(id, {
      include: [
        {
          model: SystemConfiguration,
          as: 'configurations',
          where: { isActive: true },
          required: false,
        },
      ],
    });

    if (!parish) {
      return res.status(404).json({ error: 'Parish not found' });
    }

    res.json(parish);
  } catch (error) {
    console.error('Error getting parish:', error);
    res.status(500).json({ error: 'Failed to get parish' });
  }
};

// Create new parish
const createParish = async (req, res) => {
  try {
    const {
      name,
      address,
      contactEmail,
      contactPhone,
      schedule,
      servicesOffered,
    } = req.body;

    if (!name || !address) {
      return res.status(400).json({
        error: 'Missing required fields',
        message: 'Name and address are required',
      });
    }

    const parish = await Parish.create({
      name,
      address,
      contactEmail,
      contactPhone,
      schedule,
      servicesOffered,
    });

    res.status(201).json({
      success: true,
      data: { parishes: [parish] },
      message: 'Parish created successfully',
    });
  } catch (error) {
    console.error('Error creating parish:', error);
    res.status(500).json({ success: false, message: 'Failed to create parish' });
  }
};

// Update parish
const updateParish = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      address,
      contactEmail,
      contactPhone,
      schedule,
      servicesOffered,
      isActive,
    } = req.body;

    const parish = await Parish.findByPk(id);
    if (!parish) {
      return res.status(404).json({ error: 'Parish not found' });
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
      data: { parishes: [parish] },
      message: 'Parish updated successfully',
    });
  } catch (error) {
    console.error('Error updating parish:', error);
    res.status(500).json({ success: false, message: 'Failed to update parish' });
  }
};

// Delete parish (soft delete)
const deleteParish = async (req, res) => {
  try {
    const { id } = req.params;

    const parish = await Parish.findByPk(id);
    if (!parish) {
      return res.status(404).json({ error: 'Parish not found' });
    }

    await parish.update({ isActive: false });

    res.json({ success: true, message: 'Parish deactivated successfully' });
  } catch (error) {
    console.error('Error deleting parish:', error);
    res.status(500).json({ success: false, message: 'Failed to deactivate parish' });
  }
};

// ==================== SYSTEM CONFIGURATION MANAGEMENT ====================

// Get configurations for a parish
const getParishConfigurations = async (req, res) => {
  try {
    const { parishId } = req.params;
    const { configType } = req.query;

    const whereClause = { parishId, isActive: true };
    if (configType) {
      whereClause.configType = configType;
    }

    const configurations = await SystemConfiguration.findAll({
      where: whereClause,
      order: [['configType', 'ASC']],
    });

    res.json(configurations);
  } catch (error) {
    console.error('Error getting configurations:', error);
    res.status(500).json({ error: 'Failed to get configurations' });
  }
};

// Create or update configuration
const upsertConfiguration = async (req, res) => {
  try {
    const { parishId, configType } = req.params;
    const configData = req.body;

    // Find existing configuration
    let configuration = await SystemConfiguration.findOne({
      where: { parishId, configType },
    });

    if (configuration) {
      // Update existing
      await configuration.update(configData);
      res.json({
        message: 'Configuration updated successfully',
        configuration,
      });
    } else {
      // Create new
      configuration = await SystemConfiguration.create({
        parishId,
        configType,
        ...configData,
      });
      res.status(201).json({
        message: 'Configuration created successfully',
        configuration,
      });
    }
  } catch (error) {
    console.error('Error upserting configuration:', error);
    res.status(500).json({ error: 'Failed to save configuration' });
  }
};

// Delete configuration
const deleteConfiguration = async (req, res) => {
  try {
    const { id } = req.params;

    const configuration = await SystemConfiguration.findByPk(id);
    if (!configuration) {
      return res.status(404).json({ error: 'Configuration not found' });
    }

    await configuration.update({ isActive: false });

    res.json({ message: 'Configuration deactivated successfully' });
  } catch (error) {
    console.error('Error deleting configuration:', error);
    res.status(500).json({ error: 'Failed to delete configuration' });
  }
};

// ==================== BOOKING MANAGEMENT ====================

// Get all bookings (admin view) - queries ALL booking tables
const getAllBookings = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      status,
      parishId,
      sacramentType,
      userId,
      startDate,
      endDate,
    } = req.query;

    const user = req.user;
    const offset = (page - 1) * limit;

    // Build where clause based on user role
    let bookingWhereClause = {};

    if (status) bookingWhereClause.status = status;
    if (parishId) bookingWhereClause.parishId = parseInt(parishId);
    if (userId) bookingWhereClause.userId = parseInt(userId);

    // Filter by date range
    if (startDate || endDate) {
      bookingWhereClause.preferredDate = {};
      if (startDate) bookingWhereClause.preferredDate[Op.gte] = startDate;
      if (endDate) bookingWhereClause.preferredDate[Op.lte] = endDate;
    }

    // Restrict parish-level users to their parish
    if (user.role === 'parish_admin' || user.role === 'parish_staff') {
      if (user.assignedParishId) {
        bookingWhereClause.parishId = user.assignedParishId;
      }
    }

    // Query all booking tables
    const allBookings = [];

    const bookingTables = [
      { model: BaptismBooking, type: 'baptism', include: ['godparents', 'documents'] },
      { model: WeddingBooking, type: 'wedding', include: ['documents'] },
      { model: ConfirmationBooking, type: 'confirmation', include: ['documents'] },
      { model: EucharistBooking, type: 'eucharist', include: ['documents'] },
      { model: ReconciliationBooking, type: 'reconciliation', include: ['documents'] },
      { model: AnointingSickBooking, type: 'anointing_sick', include: ['documents'] },
      { model: FuneralMassBooking, type: 'funeral_mass', include: ['documents'] },
      { model: MassIntention, type: 'mass_intention', include: [] },
    ];

    for (const { model, type, include } of bookingTables) {
      // Skip if sacramentType filter is set and doesn't match
      if (sacramentType && sacramentType !== type) continue;

      try {
        const bookings = await model.findAll({
          where: bookingWhereClause,
          include: include,
          limit: parseInt(limit),
          offset: parseInt(offset),
          order: [['createdAt', 'DESC']],
        });

        // Add bookingType to each booking
        const bookingsWithType = bookings.map(booking => ({
          ...booking.toJSON(),
          bookingType: type,
          sacramentType: type,
        }));

        allBookings.push(...bookingsWithType);
      } catch (err) {
        console.error(`Error querying ${type} bookings:`, err);
        // Continue with other tables even if one fails
      }
    }

    // Sort all bookings by createdAt
    allBookings.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    // Get total count for pagination
    let totalCount = 0;
    for (const { model, type } of bookingTables) {
      if (sacramentType && sacramentType !== type) continue;
      const count = await model.count({ where: bookingWhereClause });
      totalCount += count;
    }

    res.json({
      bookings: allBookings,
      pagination: {
        total: totalCount,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(totalCount / limit),
      },
    });
  } catch (error) {
    console.error('Error getting bookings:', error);
    res.status(500).json({ error: 'Failed to get bookings' });
  }
};

// Helper function to find booking across all tables
const findBookingById = async (id) => {
  const bookingTables = [
    { model: BaptismBooking, include: ['godparents', 'documents', 'parish', 'payment'] },
    { model: WeddingBooking, include: ['documents', 'parish'] },
    { model: ConfirmationBooking, include: ['documents', 'parish'] },
    { model: EucharistBooking, include: ['documents', 'parish'] },
    { model: ReconciliationBooking, include: ['documents', 'parish'] },
    { model: AnointingSickBooking, include: ['documents', 'parish'] },
    { model: FuneralMassBooking, include: ['documents', 'parish'] },
    { model: MassIntention, include: ['parish'] },
  ];

  for (const { model, include } of bookingTables) {
    try {
      const booking = await model.findByPk(id, { include });
      if (booking) {
        return {
          ...booking.toJSON(),
          bookingType: model.name.replace('Booking', '').toLowerCase(),
        };
      }
    } catch (err) {
      console.error(`Error querying ${model.name}:`, err);
    }
  }

  return null;
};

// Get single booking by ID
const getBookingById = async (req, res) => {
  try {
    const { id } = req.params;
    const requestingUser = req.user;

    const booking = await findBookingById(id);

    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    // Apply parish-level restrictions
    if (requestingUser.role === 'parish_admin' || requestingUser.role === 'parish_staff') {
      // Parish-level users can only view bookings in their assigned parish
      if (booking.parishId !== requestingUser.assignedParishId) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'You can only view bookings in your assigned parish.',
        });
      }
    }

    res.json({ booking });
  } catch (error) {
    console.error('Error getting booking:', error);
    res.status(500).json({ error: 'Failed to get booking' });
  }
};

// Update booking status (approve/reject/reschedule) and add notes
const updateBookingStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    const requestingUser = req.user;

    const bookingTables = [
      BaptismBooking,
      WeddingBooking,
      ConfirmationBooking,
      EucharistBooking,
      ReconciliationBooking,
      AnointingSickBooking,
      FuneralMassBooking,
      MassIntention,
    ];

    let booking = null;
    let bookingModel = null;

    // Find the booking in all tables
    for (const model of bookingTables) {
      const found = await model.findByPk(id);
      if (found) {
        booking = found;
        bookingModel = model;
        break;
      }
    }

    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    // Apply parish-level restrictions
    if (requestingUser.role === 'parish_admin' || requestingUser.role === 'parish_staff') {
      // Parish-level users can only manage bookings in their assigned parish
      if (booking.parishId !== requestingUser.assignedParishId) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'You can only manage bookings in your assigned parish.',
        });
      }
    }

    const validStatuses = ['pending', 'approved', 'declined', 'completed', 'rescheduled'];
    if (status && !validStatuses.includes(status)) {
      return res.status(400).json({
        error: 'Invalid status',
        message: `Status must be one of: ${validStatuses.join(', ')}`,
      });
    }

    const updateData = {
      status: status || booking.status,
    };

    // Handle notes as append-only
    if (notes && Array.isArray(notes) && notes.length > 0) {
      const existingNotes = booking.notes || [];
      const newNotes = notes.map(note => ({
        author: 'admin',
        content: note.content || note,
        authorId: req.user.userId,
        timestamp: new Date().toISOString(),
      }));
      updateData.notes = [...existingNotes, ...newNotes];
    }

    // Add approval metadata
    if (status === 'approved' || status === 'declined') {
      updateData.approvedBy = req.user.userId;
      updateData.approvedAt = new Date();
    }

    await booking.update(updateData);

    // Send email notification for approved/declined status
    if (status === 'approved' || status === 'declined') {
      try {
        const user = await User.findByPk(booking.userId);
        const contactEmail = booking.contactEmail || booking.email || user?.email;
        const isDeclined = status === 'declined';
        
        const sacramentName = _getSacramentName(bookingModel?.name || booking.constructor?.name || 'Booking');
        
        await emailService.sendNotification(
          contactEmail,
          `${sacramentName} Booking ${isDeclined ? 'Requires Attention' : (status === 'approved' ? 'Approved' : 'Update')}`,
          `
            <h2>${sacramentName} Booking ${isDeclined ? 'Update' : 'Notification'}</h2>
            <p>Dear Applicant,</p>
            <p>Your ${sacramentName.toLowerCase()} booking request has been ${isDeclined ? '<span style="color: red;">declined</span>' : status}.</p>
            ${isDeclined && notes ? `
              <div style="background-color: #fff3cd; padding: 16px; border-radius: 8px; margin: 16px 0;">
                <h3 style="margin-top: 0; color: #856404;">⚠️ Your booking requires attention</h3>
                <p><strong>Reason for decline:</strong></p>
                ${notes.map(n => n.content || n).join('<br>')}
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
              <li>Preferred Date: ${booking.preferredDate || booking.massSchedule ? new Date(booking.preferredDate || booking.massSchedule).toLocaleDateString() : 'Not specified'}</li>
              <li>Preferred Time Slot: ${booking.preferredTimeSlot || booking.massTime || 'Not specified'}</li>
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
    }

    res.json({
      message: `Booking ${status ? status + 'ed' : 'updated'} successfully`,
      booking,
    });
  } catch (error) {
    console.error('Error updating booking status:', error);
    res.status(500).json({ error: 'Failed to update booking status' });
  }
};

// Delete booking
const deleteBooking = async (req, res) => {
  try {
    const { id } = req.params;
    const { sacramentType } = req.query;
    const requestingUser = req.user;

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

    let booking = null;
    let bookingType = sacramentType;

    if (sacramentType && modelMap[sacramentType]) {
      booking = await modelMap[sacramentType].findByPk(id);
    } else {
      // Fallback: search all tables (less reliable due to overlapping IDs)
      for (const [type, model] of Object.entries(modelMap)) {
        const found = await model.findByPk(id);
        if (found) {
          booking = found;
          bookingType = type;
          break;
        }
      }
    }

    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    // Apply parish-level restrictions
    if (requestingUser.role === 'parish_admin' || requestingUser.role === 'parish_staff') {
      if (booking.parishId !== requestingUser.assignedParishId) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'You can only delete bookings in your assigned parish.',
        });
      }
    }

    // Delete associated documents
    const { BookingDocument } = require('../models');
    await BookingDocument.destroy({ where: { bookingId: parseInt(id), bookingType } });
    
    // Hard delete the booking
    await booking.destroy();

    res.json({ message: 'Booking deleted successfully' });
  } catch (error) {
    console.error('Error deleting booking:', error);
    res.status(500).json({ error: 'Failed to delete booking' });
  }
};

// ==================== MASS INTENTION MANAGEMENT ====================

// Get all mass intentions (admin view)
const getAllMassIntentions = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      status,
      parishId,
      intentionType,
      startDate,
      endDate,
      massTime,
    } = req.query;

    const requestingUser = req.user;
    const offset = (page - 1) * limit;
    const whereClause = {};

    // Apply parish-level restrictions
    if (requestingUser.role === 'parish_admin' || requestingUser.role === 'parish_staff') {
      // Parish-level users can only view mass intentions in their assigned parish
      whereClause.parishId = requestingUser.assignedParishId;
    } else if (parishId) {
      // Diocese-level users can filter by specific parish
      whereClause.parishId = parishId;
    }

    if (status) whereClause.status = status;
    if (intentionType) whereClause.type = intentionType;
    if (massTime) whereClause.preferredTime = massTime;

    if (startDate || endDate) {
      if (startDate && endDate && startDate === endDate) {
        whereClause.massSchedule = sequelize.where(
          sequelize.fn('DATE', sequelize.col('MassIntention.mass_schedule')),
          Op.eq,
          startDate
        );
      } else {
        whereClause.massSchedule = {};
        if (startDate) {
          whereClause.massSchedule[Op.gte] = `${startDate}T00:00:00.000Z`;
        }
        if (endDate) {
          whereClause.massSchedule[Op.lte] = `${endDate}T23:59:59.999Z`;
        }
      }
    }

    console.log('[adminController.getMassIntentions] whereClause:', JSON.stringify(whereClause, null, 2));
    console.log('[adminController.getMassIntentions] user role:', requestingUser.role, 'assignedParishId:', requestingUser.assignedParishId);

    const { count, rows } = await MassIntention.findAndCountAll({
      where: whereClause,
      include: [
        {
          model: User,
          as: 'submitter',
          attributes: ['id', 'firstName', 'lastName', 'email'],
        },
        {
          model: Parish,
          as: 'parish',
          attributes: ['id', 'name'],
        },
      ],
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['massSchedule', 'DESC']],
    });

    res.json({
      massIntentions: rows,
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    console.error('Error getting mass intentions:', error);
    res.status(500).json({ error: 'Failed to get mass intentions' });
  }
};

// Update mass intention status and add notes
const updateMassIntentionStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    const requestingUser = req.user;

    const intention = await MassIntention.findByPk(id);
    if (!intention) {
      return res.status(404).json({ error: 'Mass intention not found' });
    }

    // Apply parish-level restrictions
    if (requestingUser.role === 'parish_admin' || requestingUser.role === 'parish_staff') {
      // Parish-level users can only manage mass intentions in their assigned parish
      if (intention.parishId !== requestingUser.assignedParishId) {
        return res.status(403).json({
          error: 'Insufficient permissions',
          message: 'You can only manage mass intentions in your assigned parish.',
        });
      }
    }

    const validStatuses = ['pending', 'confirmed', 'completed', 'cancelled'];
    if (status && !validStatuses.includes(status)) {
      return res.status(400).json({
        error: 'Invalid status',
        message: `Status must be one of: ${validStatuses.join(', ')}`,
      });
    }

    // Handle notes as append-only
    let updateData = { status: status || intention.status };
    if (notes && Array.isArray(notes) && notes.length > 0) {
      const existingNotes = intention.notes || [];
      const newNotes = notes.map(note => {
        let noteContent = note;
        if (typeof note === 'object' && note !== null) {
          noteContent = note.content || JSON.stringify(note);
        }
        return {
          author: 'admin',
          content: noteContent,
          authorId: req.user.userId,
          timestamp: new Date().toISOString(),
        };
      });
      updateData.notes = [...existingNotes, ...newNotes];
    }

    await intention.update(updateData);

    res.json({
      message: 'Mass intention updated successfully',
      intention,
    });
  } catch (error) {
    console.error('Error updating mass intention:', error);
    res.status(500).json({ error: 'Failed to update mass intention' });
  }
};

// Get priests by parish ID
const getPriestsByParish = async (req, res) => {
  try {
    const { parishId } = req.query;
    const requestingUser = req.user;

    // If no parishId provided, use the user's preferred parish
    let targetParishId = parishId ? parseInt(parishId) : null;
    
    // If still no parishId, try to get from user's preferred parish
    if (!targetParishId && requestingUser.preferredParishId) {
      targetParishId = requestingUser.preferredParishId;
    }

    if (!targetParishId) {
      return res.status(400).json({
        error: 'Missing parish ID',
        message: 'Please select a parish first',
      });
    }

    // Apply parish-level restrictions
    // Parish-level users can only see priests from their own parish
    if (requestingUser.role === 'parish_admin' || requestingUser.role === 'parish_staff' || requestingUser.role === 'priest') {
      if (requestingUser.assignedParishId !== targetParishId) {
        // Check if the user is viewing their own parish
        if (requestingUser.assignedParishId !== targetParishId) {
          return res.status(403).json({
            error: 'Insufficient permissions',
            message: 'You can only view priests from your assigned parish.',
          });
        }
      }
    }

    // Get priests assigned to this parish
    const priests = await User.findAll({
      where: {
        role: 'priest',
        assignedParishId: targetParishId,
        isActive: true,
      },
      attributes: ['id', 'firstName', 'lastName', 'email'],
      order: [['lastName', 'ASC'], ['firstName', 'ASC']],
    });

    res.json({
      message: 'Priests retrieved successfully',
      priests: priests.map(priest => priest.toSafeObject()),
    });
  } catch (error) {
    console.error('Error getting priests:', error);
    res.status(500).json({ error: 'Failed to get priests' });
  }
};

// Get priest's schedule (bookings assigned to the priest)
const getPriestSchedule = async (req, res) => {
  try {
    const { month, year, status } = req.query;
    const priestId = req.user.userId;
    
    // Calculate date range for the month
    const targetMonth = month ? parseInt(month) : new Date().getMonth() + 1;
    const targetYear = year ? parseInt(year) : new Date().getFullYear();
    
    const startDate = new Date(targetYear, targetMonth - 1, 1);
    const endDate = new Date(targetYear, targetMonth, 0, 23, 59, 59); // Last day of month

    const bookingTables = [
      { model: BaptismBooking, type: 'baptism' },
      { model: WeddingBooking, type: 'wedding' },
      { model: ConfirmationBooking, type: 'confirmation' },
      { model: EucharistBooking, type: 'eucharist' },
      { model: ReconciliationBooking, type: 'reconciliation' },
      { model: AnointingSickBooking, type: 'anointing_sick' },
      { model: FuneralMassBooking, type: 'funeral_mass' },
    ];

    let allBookings = [];
    const whereClause = { priestId };

    // Filter by status if provided
    if (status) {
      whereClause.status = status;
    } else {
      // Default: show pending and approved bookings
      whereClause.status = { [Op.in]: ['pending', 'approved'] };
    }

    for (const { model, type } of bookingTables) {
      try {
        const bookings = await model.findAll({
          where: {
            ...whereClause,
            preferredDate: {
              [Op.gte]: startDate.toISOString().split('T')[0],
              [Op.lte]: endDate.toISOString().split('T')[0],
            },
          },
          include: [
            { model: Parish, as: 'parish', attributes: ['id', 'name'] },
          ],
          order: [['preferredDate', 'ASC'], ['preferredTimeSlot', 'ASC']],
        });

        const bookingsWithType = bookings.map(booking => ({
          ...booking.toJSON(),
          bookingType: type,
          sacramentType: type,
        }));

        allBookings.push(...bookingsWithType);
      } catch (err) {
        console.error(`Error querying ${type} bookings for priest schedule:`, err);
      }
    }

    // Sort all bookings by date
    allBookings.sort((a, b) => new Date(a.preferredDate) - new Date(b.preferredDate));

    res.json({
      success: true,
      bookings: allBookings,
      month: targetMonth,
      year: targetYear,
    });
  } catch (error) {
    console.error('Error getting priest schedule:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to get priest schedule',
      message: error.message 
    });
  }
};

module.exports = {
  getDashboardStats,
  getAllUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
  getAllParishes,
  getParishById,
  createParish,
  updateParish,
  deleteParish,
  getParishConfigurations,
  upsertConfiguration,
  deleteConfiguration,
  getAllBookings,
  getBookingById,
  updateBookingStatus,
  deleteBooking,
  getAllMassIntentions,
  updateMassIntentionStatus,
  getPriestsByParish,
  getPriestSchedule,
};
