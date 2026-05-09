const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const ConfirmationBooking = sequelize.define('ConfirmationBooking', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  parishId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'parishes',
      key: 'id',
    },
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
  },
  // Confirmand's information
  confirmandName: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  fatherName: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  motherName: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  // Contact information
  contactEmail: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  contactPhone: {
    type: DataTypes.STRING(20),
    allowNull: true,
  },
  // Preferred schedule
  preferredDate: {
    type: DataTypes.DATEONLY,
    allowNull: true,
  },
  preferredTimeSlot: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },
  // Optional priest assignment
  priestId: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'users',
      key: 'id',
    },
  },
  // Status tracking
  status: {
    type: DataTypes.ENUM('pending', 'approved', 'declined', 'completed', 'rescheduled', 'cancelled'),
    defaultValue: 'pending',
    allowNull: false,
  },
  // Notes as JSONB array for conversation history
  notes: {
    type: DataTypes.JSONB,
    allowNull: true,
    defaultValue: [],
  },
  approvedBy: {
    type: DataTypes.INTEGER,
    references: {
      model: 'users',
      key: 'id',
    },
    allowNull: true,
  },
  approvedAt: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'confirmation_bookings',
  timestamps: true,
  underscored: true,
  indexes: [
    { fields: ['parish_id'] },
    { fields: ['user_id'] },
    { fields: ['preferred_date'] },
    { fields: ['status'] },
    { fields: ['confirmand_name'] },
  ],
});

module.exports = ConfirmationBooking;
