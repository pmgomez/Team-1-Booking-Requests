const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const BookingDocument = sequelize.define('BookingDocument', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  // Polymorphic association - can belong to different booking types
  bookingType: {
    type: DataTypes.ENUM(
      'baptism',
      'wedding',
      'confirmation',
      'eucharist',
      'reconciliation',
      'anointing_sick',
      'funeral_mass',
      'mass_intention'
    ),
    allowNull: false,
  },
  bookingId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  // Document information
  documentType: {
    type: DataTypes.ENUM(
      'birth_certificate',
      'baptismal_certificate',
      'confirmation_certificate',
      'cenomar',
      'death_certificate',
      'id_card',
      'proof_of_payment',
      'other'
    ),
    allowNull: false,
  },
  fileName: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  filePath: {
    type: DataTypes.STRING(500),
    allowNull: false,
  },
  fileUrl: {
    type: DataTypes.STRING(500),
    allowNull: false,
  },
  fileSize: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  mimeType: {
    type: DataTypes.STRING(100),
    allowNull: false,
  },
  // Upload information
  uploadedBy: {
    type: DataTypes.INTEGER,
    references: {
      model: 'users',
      key: 'id',
    },
    allowNull: false,
  },
  // Verification status
  isVerified: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  verifiedBy: {
    type: DataTypes.INTEGER,
    references: {
      model: 'users',
      key: 'id',
    },
    allowNull: true,
  },
  verifiedAt: {
    type: DataTypes.DATE,
    allowNull: true,
  },
   rejectionReason: {
     type: DataTypes.TEXT,
     allowNull: true,
   },
}, {
  tableName: 'booking_documents',
  timestamps: true,
  underscored: true,
  indexes: [
    { fields: ['booking_type'] },
    { fields: ['booking_id'] },
    { fields: ['document_type'] },
    { fields: ['uploaded_by'] },
    { fields: ['is_verified'] },
    {
      name: 'booking_documents_lookup',
      fields: ['booking_type', 'booking_id'],
    },
  ],
});

module.exports = BookingDocument;
