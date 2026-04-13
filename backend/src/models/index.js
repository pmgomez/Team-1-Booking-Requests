const { sequelize } = require('../config/database');
const User = require('./User');
const Parish = require('./Parish');
const Booking = require('./Booking');
const MassIntention = require('./MassIntention');
const MassSchedule = require('./MassSchedule');
const SystemConfiguration = require('./SystemConfiguration');
const BaptismBooking = require('./BaptismBooking');
const WeddingBooking = require('./WeddingBooking');
const ConfirmationBooking = require('./ConfirmationBooking');
const EucharistBooking = require('./EucharistBooking');
const ReconciliationBooking = require('./ReconciliationBooking');
const AnointingSickBooking = require('./AnointingSickBooking');
const FuneralMassBooking = require('./FuneralMassBooking');
const TokenBlacklist = require('./TokenBlacklist');

// Supporting models
const ParishSlotSetting = require('./ParishSlotSetting');
const BlackoutDate = require('./BlackoutDate');
const Godparent = require('./Godparent');
const BookingDocument = require('./BookingDocument');
const Payment = require('./Payment');
const SacramentalRecord = require('./SacramentalRecord');

// ============ USER ASSOCIATIONS ============
User.hasMany(Booking, {
  foreignKey: 'userId',
  as: 'bookings',
  onDelete: 'CASCADE',
});
Booking.belongsTo(User, {
  foreignKey: 'userId',
  as: 'user',
});

User.hasMany(MassIntention, {
  foreignKey: 'submittedBy',
  as: 'intentions',
  onDelete: 'CASCADE',
});
MassIntention.belongsTo(User, {
  foreignKey: 'submittedBy',
  as: 'submitter',
});

User.hasMany(MassSchedule, {
  foreignKey: 'priestId',
  as: 'assignedMassSchedules',
});
MassSchedule.belongsTo(User, {
  foreignKey: 'priestId',
  as: 'assignedPriest',
});

User.hasMany(BaptismBooking, {
  foreignKey: 'userId',
  as: 'baptismBookings',
  onDelete: 'CASCADE',
});
BaptismBooking.belongsTo(User, {
  foreignKey: 'userId',
  as: 'user',
});

User.hasMany(WeddingBooking, {
  foreignKey: 'userId',
  as: 'weddingBookings',
  onDelete: 'CASCADE',
});
WeddingBooking.belongsTo(User, {
  foreignKey: 'userId',
  as: 'user',
});

User.hasMany(ConfirmationBooking, {
  foreignKey: 'userId',
  as: 'confirmationBookings',
  onDelete: 'CASCADE',
});
ConfirmationBooking.belongsTo(User, {
  foreignKey: 'userId',
  as: 'user',
});

User.hasMany(EucharistBooking, {
  foreignKey: 'userId',
  as: 'eucharistBookings',
  onDelete: 'CASCADE',
});
EucharistBooking.belongsTo(User, {
  foreignKey: 'userId',
  as: 'user',
});

User.hasMany(ReconciliationBooking, {
  foreignKey: 'userId',
  as: 'reconciliationBookings',
  onDelete: 'CASCADE',
});
ReconciliationBooking.belongsTo(User, {
  foreignKey: 'userId',
  as: 'user',
});

User.hasMany(AnointingSickBooking, {
  foreignKey: 'userId',
  as: 'anointingSickBookings',
  onDelete: 'CASCADE',
});
AnointingSickBooking.belongsTo(User, {
  foreignKey: 'userId',
  as: 'user',
});

User.hasMany(FuneralMassBooking, {
  foreignKey: 'userId',
  as: 'funeralMassBookings',
  onDelete: 'CASCADE',
});
FuneralMassBooking.belongsTo(User, {
  foreignKey: 'userId',
  as: 'user',
});

User.hasMany(BookingDocument, {
  foreignKey: 'uploadedBy',
  as: 'uploadedDocuments',
  onDelete: 'CASCADE',
});
BookingDocument.belongsTo(User, {
  foreignKey: 'uploadedBy',
  as: 'uploader',
});

User.hasMany(SacramentalRecord, {
  foreignKey: 'digitizedBy',
  as: 'digitizedRecords',
});
SacramentalRecord.belongsTo(User, {
  foreignKey: 'digitizedBy',
  as: 'digitizer',
});

User.hasMany(BlackoutDate, {
  foreignKey: 'createdBy',
  as: 'createdBlackoutDates',
});
BlackoutDate.belongsTo(User, {
  foreignKey: 'createdBy',
  as: 'creator',
});

// Association for parish admins
User.belongsTo(Parish, {
  foreignKey: 'assignedParishId',
  as: 'assignedParish',
});
Parish.hasMany(User, {
  foreignKey: 'assignedParishId',
  as: 'staffMembers',
});

// Association for user's preferred parish
User.belongsTo(Parish, {
  foreignKey: 'preferredParishId',
  as: 'preferredParish',
});
Parish.hasMany(User, {
  foreignKey: 'preferredParishId',
  as: 'parishioners',
});

// ============ PARISH ASSOCIATIONS ============
Parish.hasMany(Booking, {
  foreignKey: 'parishId',
  as: 'bookings',
});
Booking.belongsTo(Parish, {
  foreignKey: 'parishId',
  as: 'parish',
});

Parish.hasMany(MassIntention, {
  foreignKey: 'parishId',
  as: 'intentions',
});
MassIntention.belongsTo(Parish, {
  foreignKey: 'parishId',
  as: 'parish',
});

Parish.hasMany(MassSchedule, {
  foreignKey: 'parishId',
  as: 'massSchedules',
});
MassSchedule.belongsTo(Parish, {
  foreignKey: 'parishId',
  as: 'parish',
});

Parish.hasMany(BaptismBooking, {
  foreignKey: 'parishId',
  as: 'baptismBookings',
});
BaptismBooking.belongsTo(Parish, {
  foreignKey: 'parishId',
  as: 'parish',
});

Parish.hasMany(WeddingBooking, {
  foreignKey: 'parishId',
  as: 'weddingBookings',
});
WeddingBooking.belongsTo(Parish, {
  foreignKey: 'parishId',
  as: 'parish',
});

Parish.hasMany(ConfirmationBooking, {
  foreignKey: 'parishId',
  as: 'confirmationBookings',
});
ConfirmationBooking.belongsTo(Parish, {
  foreignKey: 'parishId',
  as: 'parish',
});

Parish.hasMany(EucharistBooking, {
  foreignKey: 'parishId',
  as: 'eucharistBookings',
});
EucharistBooking.belongsTo(Parish, {
  foreignKey: 'parishId',
  as: 'parish',
});

Parish.hasMany(ReconciliationBooking, {
  foreignKey: 'parishId',
  as: 'reconciliationBookings',
});
ReconciliationBooking.belongsTo(Parish, {
  foreignKey: 'parishId',
  as: 'parish',
});

Parish.hasMany(AnointingSickBooking, {
  foreignKey: 'parishId',
  as: 'anointingSickBookings',
});
AnointingSickBooking.belongsTo(Parish, {
  foreignKey: 'parishId',
  as: 'parish',
});

Parish.hasMany(FuneralMassBooking, {
  foreignKey: 'parishId',
  as: 'funeralMassBookings',
});
FuneralMassBooking.belongsTo(Parish, {
  foreignKey: 'parishId',
  as: 'parish',
});

Parish.hasMany(ParishSlotSetting, {
  foreignKey: 'parishId',
  as: 'slotSettings',
});
ParishSlotSetting.belongsTo(Parish, {
  foreignKey: 'parishId',
  as: 'parish',
});

Parish.hasMany(BlackoutDate, {
  foreignKey: 'parishId',
  as: 'blackoutDates',
});
BlackoutDate.belongsTo(Parish, {
  foreignKey: 'parishId',
  as: 'parish',
});

Parish.hasMany(SacramentalRecord, {
  foreignKey: 'parishId',
  as: 'sacramentalRecords',
});
SacramentalRecord.belongsTo(Parish, {
  foreignKey: 'parishId',
  as: 'parish',
});

Parish.hasMany(Payment, {
  foreignKey: 'parishId',
  as: 'payments',
});
Payment.belongsTo(Parish, {
  foreignKey: 'parishId',
  as: 'parish',
});

// ============ MASS INTENTION ASSOCIATIONS ============
// Already defined above

// ============ MASS SCHEDULE ASSOCIATIONS ============
// Already defined above

// ============ BAPTISM BOOKING ASSOCIATIONS ============
BaptismBooking.hasMany(Godparent, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'baptism' },
  as: 'godparents',
});
BaptismBooking.hasMany(BookingDocument, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'baptism' },
  as: 'documents',
});
BaptismBooking.hasOne(Payment, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'baptism' },
  as: 'payment',
});

// ============ WEDDING BOOKING ASSOCIATIONS ============
WeddingBooking.hasMany(Godparent, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'wedding' },
  as: 'godparents',
});
WeddingBooking.hasMany(BookingDocument, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'wedding' },
  as: 'documents',
});
WeddingBooking.hasOne(Payment, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'wedding' },
  as: 'payment',
});

// ============ CONFIRMATION BOOKING ASSOCIATIONS ============
ConfirmationBooking.hasMany(Godparent, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'confirmation' },
  as: 'godparents',
});
ConfirmationBooking.hasMany(BookingDocument, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'confirmation' },
  as: 'documents',
});
ConfirmationBooking.hasOne(Payment, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'confirmation' },
  as: 'payment',
});

// ============ EUCHARIST BOOKING ASSOCIATIONS ============
EucharistBooking.hasMany(BookingDocument, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'eucharist' },
  as: 'documents',
});
EucharistBooking.hasOne(Payment, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'eucharist' },
  as: 'payment',
});

// ============ RECONCILIATION BOOKING ASSOCIATIONS ============
ReconciliationBooking.hasMany(BookingDocument, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'reconciliation' },
  as: 'documents',
});
ReconciliationBooking.hasOne(Payment, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'reconciliation' },
  as: 'payment',
});

// ============ ANOINTING SICK BOOKING ASSOCIATIONS ============
AnointingSickBooking.hasMany(BookingDocument, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'anointing_sick' },
  as: 'documents',
});
AnointingSickBooking.hasOne(Payment, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'anointing_sick' },
  as: 'payment',
});

// ============ FUNERAL MASS BOOKING ASSOCIATIONS ============
FuneralMassBooking.hasMany(BookingDocument, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'funeral_mass' },
  as: 'documents',
});
FuneralMassBooking.hasOne(Payment, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'funeral_mass' },
  as: 'payment',
});

// ============ MASS INTENTION PAYMENT ASSOCIATIONS ============
MassIntention.hasOne(Payment, {
  foreignKey: 'bookingId',
  constraints: false,
  scope: { bookingType: 'mass_intention' },
  as: 'payment',
});

// ============ GODPARENT POLYMORPHIC ASSOCIATIONS ============
// Godparent belongs to different booking types (polymorphic)
// Handled via bookingType and bookingId fields

// ============ BOOKING DOCUMENT POLYMORPHIC ASSOCIATIONS ============
// BookingDocument belongs to different booking types (polymorphic)
// Handled via bookingType and bookingId fields

// ============ PAYMENT POLYMORPHIC ASSOCIATIONS ============
// Payment belongs to different booking types (polymorphic)
// Handled via bookingType and bookingId fields

// Sync database
const syncDatabase = async (options = {}) => {
  try {
    // Set force: true to drop and recreate tables (DANGER: deletes all data)
    // Set alter: true to modify tables to match models
    await sequelize.sync(options);
    console.log('✅ Database models synchronized successfully.');

    if (options.force) {
      console.log('⚠️  WARNING: All tables were dropped and recreated!');
    }
  } catch (error) {
    console.error('❌ Database sync failed:', error);
    throw error;
  }
};

module.exports = {
  sequelize,
  User,
  Parish,
  Booking,
  MassIntention,
  MassSchedule,
  BaptismBooking,
  WeddingBooking,
  ConfirmationBooking,
  EucharistBooking,
  ReconciliationBooking,
  AnointingSickBooking,
  FuneralMassBooking,
  ParishSlotSetting,
  BlackoutDate,
  Godparent,
  BookingDocument,
  Payment,
  SacramentalRecord,
  TokenBlacklist,
  syncDatabase,
};
