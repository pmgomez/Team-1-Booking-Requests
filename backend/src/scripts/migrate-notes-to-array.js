/**
 * Database Migration: Convert notes fields to JSONB array format
 * This script migrates existing note data to the new array-based structure
 */

require('dotenv').config({
  path: `.env.${process.env.NODE_ENV || 'development'}`
});

const { sequelize } = require('../config/database');

async function migrateNotes() {
  console.log('🚀 Starting notes migration...');

  try {
    await sequelize.authenticate();
    console.log('✅ Database connection established.');

    const transaction = await sequelize.transaction();

    try {
      // ==================== MASS INTENTIONS ====================
      console.log('\n📝 Migrating mass_intentions table...');
      
      // MassIntention: Convert single notes TEXT to JSONB array
      // Existing notes are from the parishioner (submittedBy)
      await sequelize.query(`
        ALTER TABLE mass_intentions
        ALTER COLUMN notes TYPE JSONB
        USING CASE
          WHEN notes IS NULL THEN '[]'::JSONB
          ELSE jsonb_build_array(
            jsonb_build_object(
              'author', 'parishioner',
              'content', notes,
              'authorId', submitted_by,
              'timestamp', created_at
            )
          )
        END;
      `, { transaction });
      console.log('   ✅ mass_intentions.notes converted to JSONB array');

      // ==================== BAPTISM BOOKINGS ====================
      console.log('\n📝 Migrating baptism_bookings table...');
      
      // Add new notes column if it doesn't exist
      await sequelize.query(`
        ALTER TABLE baptism_bookings
        ADD COLUMN IF NOT EXISTS notes JSONB DEFAULT '[]';
      `, { transaction });

      // Combine additional_notes (parishioner) and admin_notes (admin) into notes array
      await sequelize.query(`
        UPDATE baptism_bookings
        SET notes = 
          CASE
            WHEN additional_notes IS NOT NULL AND admin_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'parishioner', 'content', additional_notes, 'timestamp', created_at),
                jsonb_build_object('author', 'admin', 'content', admin_notes, 'timestamp', updated_at)
              )
            WHEN additional_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'parishioner', 'content', additional_notes, 'timestamp', created_at)
              )
            WHEN admin_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'admin', 'content', admin_notes, 'timestamp', updated_at)
              )
            ELSE '[]'::JSONB
          END;
      `, { transaction });
      console.log('   ✅ Combined additional_notes and admin_notes into notes array');

      // Drop old columns
      await sequelize.query(`
        ALTER TABLE baptism_bookings
        DROP COLUMN IF EXISTS additional_notes,
        DROP COLUMN IF EXISTS admin_notes;
      `, { transaction });
      console.log('   ✅ Dropped additional_notes and admin_notes columns');

      // ==================== FUNERAL MASS BOOKINGS ====================
      console.log('\n📝 Migrating funeral_mass_bookings table...');
      
      await sequelize.query(`
        ALTER TABLE funeral_mass_bookings
        ADD COLUMN IF NOT EXISTS notes JSONB DEFAULT '[]';
      `, { transaction });

      await sequelize.query(`
        UPDATE funeral_mass_bookings
        SET notes = 
          CASE
            WHEN additional_notes IS NOT NULL AND admin_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'parishioner', 'content', additional_notes, 'timestamp', created_at),
                jsonb_build_object('author', 'admin', 'content', admin_notes, 'timestamp', updated_at)
              )
            WHEN additional_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'parishioner', 'content', additional_notes, 'timestamp', created_at)
              )
            WHEN admin_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'admin', 'content', admin_notes, 'timestamp', updated_at)
              )
            ELSE '[]'::JSONB
          END;
      `, { transaction });
      console.log('   ✅ Combined additional_notes and admin_notes into notes array');

      await sequelize.query(`
        ALTER TABLE funeral_mass_bookings
        DROP COLUMN IF EXISTS additional_notes,
        DROP COLUMN IF EXISTS admin_notes;
      `, { transaction });
      console.log('   ✅ Dropped additional_notes and admin_notes columns');

      // ==================== RECONCILIATION BOOKINGS ====================
      console.log('\n📝 Migrating reconciliation_bookings table...');
      
      await sequelize.query(`
        ALTER TABLE reconciliation_bookings
        ADD COLUMN IF NOT EXISTS notes JSONB DEFAULT '[]';
      `, { transaction });

      await sequelize.query(`
        UPDATE reconciliation_bookings
        SET notes = 
          CASE
            WHEN additional_notes IS NOT NULL AND admin_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'parishioner', 'content', additional_notes, 'timestamp', created_at),
                jsonb_build_object('author', 'admin', 'content', admin_notes, 'timestamp', updated_at)
              )
            WHEN additional_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'parishioner', 'content', additional_notes, 'timestamp', created_at)
              )
            WHEN admin_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'admin', 'content', admin_notes, 'timestamp', updated_at)
              )
            ELSE '[]'::JSONB
          END;
      `, { transaction });
      console.log('   ✅ Combined additional_notes and admin_notes into notes array');

      await sequelize.query(`
        ALTER TABLE reconciliation_bookings
        DROP COLUMN IF EXISTS additional_notes,
        DROP COLUMN IF EXISTS admin_notes;
      `, { transaction });
      console.log('   ✅ Dropped additional_notes and admin_notes columns');

      // ==================== CONFIRMATION BOOKINGS ====================
      console.log('\n📝 Migrating confirmation_bookings table...');
      
      await sequelize.query(`
        ALTER TABLE confirmation_bookings
        ADD COLUMN IF NOT EXISTS notes JSONB DEFAULT '[]';
      `, { transaction });

      await sequelize.query(`
        UPDATE confirmation_bookings
        SET notes = 
          CASE
            WHEN additional_notes IS NOT NULL AND admin_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'parishioner', 'content', additional_notes, 'timestamp', created_at),
                jsonb_build_object('author', 'admin', 'content', admin_notes, 'timestamp', updated_at)
              )
            WHEN additional_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'parishioner', 'content', additional_notes, 'timestamp', created_at)
              )
            WHEN admin_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'admin', 'content', admin_notes, 'timestamp', updated_at)
              )
            ELSE '[]'::JSONB
          END;
      `, { transaction });
      console.log('   ✅ Combined additional_notes and admin_notes into notes array');

      await sequelize.query(`
        ALTER TABLE confirmation_bookings
        DROP COLUMN IF EXISTS additional_notes,
        DROP COLUMN IF EXISTS admin_notes;
      `, { transaction });
      console.log('   ✅ Dropped additional_notes and admin_notes columns');

      // ==================== WEDDING BOOKINGS ====================
      console.log('\n📝 Migrating wedding_bookings table...');
      
      await sequelize.query(`
        ALTER TABLE wedding_bookings
        ADD COLUMN IF NOT EXISTS notes JSONB DEFAULT '[]';
      `, { transaction });

      await sequelize.query(`
        UPDATE wedding_bookings
        SET notes = 
          CASE
            WHEN additional_notes IS NOT NULL AND admin_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'parishioner', 'content', additional_notes, 'timestamp', created_at),
                jsonb_build_object('author', 'admin', 'content', admin_notes, 'timestamp', updated_at)
              )
            WHEN additional_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'parishioner', 'content', additional_notes, 'timestamp', created_at)
              )
            WHEN admin_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'admin', 'content', admin_notes, 'timestamp', updated_at)
              )
            ELSE '[]'::JSONB
          END;
      `, { transaction });
      console.log('   ✅ Combined additional_notes and admin_notes into notes array');

      await sequelize.query(`
        ALTER TABLE wedding_bookings
        DROP COLUMN IF EXISTS additional_notes,
        DROP COLUMN IF EXISTS admin_notes;
      `, { transaction });
      console.log('   ✅ Dropped additional_notes and admin_notes columns');

      // ==================== EUCHARIST BOOKINGS ====================
      console.log('\n📝 Migrating eucharist_bookings table...');
      
      await sequelize.query(`
        ALTER TABLE eucharist_bookings
        ADD COLUMN IF NOT EXISTS notes JSONB DEFAULT '[]';
      `, { transaction });

      await sequelize.query(`
        UPDATE eucharist_bookings
        SET notes = 
          CASE
            WHEN additional_notes IS NOT NULL AND admin_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'parishioner', 'content', additional_notes, 'timestamp', created_at),
                jsonb_build_object('author', 'admin', 'content', admin_notes, 'timestamp', updated_at)
              )
            WHEN additional_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'parishioner', 'content', additional_notes, 'timestamp', created_at)
              )
            WHEN admin_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'admin', 'content', admin_notes, 'timestamp', updated_at)
              )
            ELSE '[]'::JSONB
          END;
      `, { transaction });
      console.log('   ✅ Combined additional_notes and admin_notes into notes array');

      await sequelize.query(`
        ALTER TABLE eucharist_bookings
        DROP COLUMN IF EXISTS additional_notes,
        DROP COLUMN IF EXISTS admin_notes;
      `, { transaction });
      console.log('   ✅ Dropped additional_notes and admin_notes columns');

      // ==================== ANOINTING SICK BOOKINGS ====================
      console.log('\n📝 Migrating anointing_sick_bookings table...');
      
      await sequelize.query(`
        ALTER TABLE anointing_sick_bookings
        ADD COLUMN IF NOT EXISTS notes JSONB DEFAULT '[]';
      `, { transaction });

      await sequelize.query(`
        UPDATE anointing_sick_bookings
        SET notes = 
          CASE
            WHEN additional_notes IS NOT NULL AND admin_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'parishioner', 'content', additional_notes, 'timestamp', created_at),
                jsonb_build_object('author', 'admin', 'content', admin_notes, 'timestamp', updated_at)
              )
            WHEN additional_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'parishioner', 'content', additional_notes, 'timestamp', created_at)
              )
            WHEN admin_notes IS NOT NULL THEN
              jsonb_build_array(
                jsonb_build_object('author', 'admin', 'content', admin_notes, 'timestamp', updated_at)
              )
            ELSE '[]'::JSONB
          END;
      `, { transaction });
      console.log('   ✅ Combined additional_notes and admin_notes into notes array');

      await sequelize.query(`
        ALTER TABLE anointing_sick_bookings
        DROP COLUMN IF EXISTS additional_notes,
        DROP COLUMN IF EXISTS admin_notes;
      `, { transaction });
      console.log('   ✅ Dropped additional_notes and admin_notes columns');

      // Commit transaction
      await transaction.commit();
      console.log('\n🎉 Migration completed successfully!');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log('📋 Summary:');
      console.log('   - mass_intentions: notes converted to JSONB array');
      console.log('   - All other bookings: combined additional_notes + admin_notes into notes array');
      console.log('   - Old columns removed');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      process.exit(0);
    } catch (error) {
      await transaction.rollback();
      console.error('❌ Migration failed, rolling back:', error.message);
      console.error('Stack trace:', error.stack);
      process.exit(1);
    }
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    process.exit(1);
  }
}

// Run migration
migrateNotes();
