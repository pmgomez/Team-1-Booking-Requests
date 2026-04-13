/**
 * Database Migration Script
 * Creates all necessary tables for the Diocese sacramental booking application
 */

require('dotenv').config({
  path: `.env.${process.env.NODE_ENV || 'development'}`
});

const { sequelize } = require('../config/database');
const {
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
} = require('../models');

async function runMigrations() {
  console.log('🚀 Starting database migration...');

  try {
    // Test database connection
    await sequelize.authenticate();
    console.log('✅ Database connection established successfully.');

    // Synchronize all models
    // Note: force: false means it won't drop existing tables
    // Set force: true only in development to reset the database
    await sequelize.sync({
      force: false, // Change to true only in development if you want to reset
      alter: true   // This allows modifying existing tables
    });

    console.log('✅ Database synchronized successfully.');
    console.log('📋 Tables created/updated:');
    console.log('   - users');
    console.log('   - parishes');
    console.log('   - bookings');
    console.log('   - mass_intentions');
    console.log('   - mass_schedules');
    console.log('   - baptism_bookings');
    console.log('   - wedding_bookings');
    console.log('   - confirmation_bookings');
    console.log('   - eucharist_bookings');
    console.log('   - reconciliation_bookings');
    console.log('   - anointing_sick_bookings');
    console.log('   - funeral_mass_bookings');
    console.log('   - parish_slot_settings');
    console.log('   - blackout_dates');
    console.log('   - godparents');
    console.log('   - booking_documents');
    console.log('   - payments');
    console.log('   - sacramental_records');

    // Create default admin user if none exists
    const adminUser = await User.findOne({
      where: { email: process.env.SUPER_ADMIN_EMAIL || 'admin@diocese-kalookan.com' }
    });

    if (!adminUser) {
      await User.create({
        email: process.env.SUPER_ADMIN_EMAIL || 'admin@diocese-kalookan.com',
        password: process.env.SUPER_ADMIN_PASSWORD || 'AdminPass123!',
        firstName: process.env.SUPER_ADMIN_FIRST_NAME || 'System',
        lastName: process.env.SUPER_ADMIN_LAST_NAME || 'Administrator',
        phone: '+639123456789',
        role: 'diocese_admin',
        isActive: true
      });

      console.log('✅ Default diocese_admin (super admin) user created.');
      console.log(`   Email: ${process.env.SUPER_ADMIN_EMAIL || 'admin@diocese-kalookan.com'}`);
      console.log('   ⚠️  IMPORTANT: Change this password after first login!');
    } else {
      console.log('ℹ️  Super admin user already exists.');
    }

    // Create sample parish if none exists
    const sampleParish = await Parish.findOne({
      where: { name: 'Our Lady of Peace Parish' }
    });

    if (!sampleParish) {
      await Parish.create({
        name: 'Our Lady of Peace Parish',
        address: '123 Main Street, Kalookan City',
        contactEmail: 'info@olpparish.org',
        contactPhone: '+639123456789',
        contactPerson: 'Parish Secretary',
        servicesOffered: ['baptism', 'wedding', 'confirmation', 'eucharist', 'reconciliation', 'anointing_sick', 'funeral_mass', 'mass_intention'],
        sacramentSettings: {
          baptism: { maxGodparents: 4 },
          wedding: { maxGodparents: 8 },
          confirmation: { maxGodparents: 2 }
        },
        bookingSettings: {
          autoApprove: false,
          emailNotifications: true
        },
        isActive: true
      });

      console.log('✅ Sample parish created.');
    } else {
      console.log('ℹ️  Sample parish already exists.');
    }

    console.log('\n🎉 Database migration completed successfully!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📋 Next steps:');
    console.log('   - Run `npm run seed` to populate sample data (optional)');
    console.log('   - Run `npm run dev` to start the server');
    console.log('   - Access the API at http://localhost:3000');
    console.log('   - Access Swagger docs at http://localhost:3000/api-docs');
    console.log('   - Use the /health endpoint to verify everything is working');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    console.error('Stack trace:', error.stack);
    process.exit(1);
  }
}

// Run the migration
runMigrations();