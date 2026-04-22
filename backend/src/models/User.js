const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');
const bcrypt = require('bcrypt');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  email: {
    type: DataTypes.STRING(255),
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true,
    },
  },
  password: {
    type: DataTypes.STRING(255),
    allowNull: true, // Null for OAuth users
  },
  firstName: {
    type: DataTypes.STRING(100),
    allowNull: false,
  },
  lastName: {
    type: DataTypes.STRING(100),
    allowNull: false,
  },
  phone: {
    type: DataTypes.STRING(20),
  },
  middleName: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },
  role: {
    type: DataTypes.ENUM('parishioner', 'parish_staff', 'priest', 'diocese_staff', 'parish_admin', 'diocese_admin'),
    defaultValue: 'parishioner',
    allowNull: false,
  },
  assignedParishId: {
    type: DataTypes.INTEGER,
    references: {
      model: 'parishes',
      key: 'id',
    },
    allowNull: true,
  },
  preferredParishId: {
    type: DataTypes.INTEGER,
    references: {
      model: 'parishes',
      key: 'id',
    },
    allowNull: true,
  },
  googleId: {
    type: DataTypes.STRING(255),
    unique: true,
    allowNull: true,
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  mustChangePassword: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  lastLoginAt: {
    type: DataTypes.DATE,
  },
  // Password reset fields
  resetPasswordToken: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  resetPasswordExpires: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'users',
  timestamps: true,
  underscored: true,
  indexes: [
    { fields: ['email'] },
    { fields: ['google_id'] },
    { fields: ['role'] },
    { fields: ['assigned_parish_id'] },
    { fields: ['preferred_parish_id'] },
  ],
});

// Hash password before creating user
User.beforeCreate(async (user) => {
  if (user.password) {
    const salt = await bcrypt.genSalt(12);
    user.password = await bcrypt.hash(user.password, salt);
  }
});

// Hash password before updating if changed
User.beforeUpdate(async (user) => {
  if (user.changed('password') && user.password) {
    const salt = await bcrypt.genSalt(12);
    user.password = await bcrypt.hash(user.password, salt);
  }
});

// Instance method to verify password
User.prototype.verifyPassword = async function(password) {
  if (!this.password) return false;
  return await bcrypt.compare(password, this.password);
};

// Instance method to get safe user object (without password)
User.prototype.toSafeObject = function() {
  return {
    id: this.id,
    email: this.email,
    firstName: this.firstName,
    lastName: this.lastName,
    middleName: this.middleName,
    phone: this.phone,
    role: this.role,
    assignedParishId: this.assignedParishId,
    preferredParishId: this.preferredParishId,
    isActive: this.isActive,
    mustChangePassword: this.mustChangePassword,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

module.exports = User;