const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const MassIntention = sequelize.define('MassIntention', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  type: {
    type: DataTypes.ENUM('For the Dead', 'Thanksgiving', 'Special Intention'),
    allowNull: false,
  },
  intentionDetails: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  donorName: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  dateRequested: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  parishId: {
    type: DataTypes.INTEGER,
    references: {
      model: 'parishes',
      key: 'id',
    },
    allowNull: false,
  },
  massSchedule: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  preferredTime: {
    type: DataTypes.STRING(10),
    allowNull: true,
  },
  preferredPriest: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  notes: {
    type: DataTypes.JSONB,
    allowNull: true,
    defaultValue: [],
  },
  status: {
    type: DataTypes.ENUM('pending', 'approved', 'declined', 'completed'),
    defaultValue: 'pending',
    allowNull: false,
  },
  submittedBy: {
    type: DataTypes.INTEGER,
    references: {
      model: 'users',
      key: 'id',
    },
    allowNull: false,
  },
}, {
  tableName: 'mass_intentions',
  timestamps: true,
  underscored: true,
  indexes: [
    { fields: ['type'] },
    { fields: ['date_requested'] },
    { fields: ['parish_id'] },
    { fields: ['status'] },
  ],
});

module.exports = MassIntention;