const express = require('express');
const { body } = require('express-validator');
const { authenticateJWT, authorizeRoles } = require('../middleware/auth');
const massIntentionController = require('../controllers/massIntentionController');
const { upload } = require('../middleware/upload');

const router = express.Router();

// All mass intention routes require authentication
router.use(authenticateJWT);

// Attach document to mass intention (must be before /:id route)
router.post('/:id/document', upload.single('document'), massIntentionController.attachDocument);

// Create a new mass intention
router.post('/', [
  body('type')
    .isIn(['For the Dead', 'Thanksgiving', 'Special Intention'])
    .withMessage('Type must be one of: For the Dead, Thanksgiving, Special Intention'),
  body('intentionDetails')
    .trim()
    .notEmpty()
    .withMessage('Intention details are required'),
  body('donorName')
    .trim()
    .notEmpty()
    .withMessage('Donor name is required'),
  body('parishId')
    .isInt({ min: 1 })
    .withMessage('Valid parish ID is required'),
  body('massSchedule')
    .isISO8601()
    .withMessage('Valid mass schedule date and time is required'),
  body('preferredPriest')
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage('Preferred priest name is too long'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 1000 })
    .withMessage('Notes are too long'),
], massIntentionController.createMassIntention);

// Get all mass intentions (with pagination and filtering)
router.get('/', massIntentionController.getAllMassIntentions);

// Get a specific mass intention by ID
router.get('/:id', massIntentionController.getMassIntentionById);

// Update a mass intention
router.put('/:id', [
  body('type')
    .optional()
    .isIn(['For the Dead', 'Thanksgiving', 'Special Intention'])
    .withMessage('Type must be one of: For the Dead, Thanksgiving, Special Intention'),
  body('intentionDetails')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Intention details are required'),
  body('donorName')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Donor name is required'),
  body('parishId')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Valid parish ID is required'),
  body('massSchedule')
    .optional()
    .isISO8601()
    .withMessage('Valid mass schedule date and time is required'),
  body('preferredPriest')
    .optional()
    .trim()
    .isLength({ max: 255 })
    .withMessage('Preferred priest name is too long'),
  body('notes')
    .optional()
    .isArray()
    .withMessage('Notes must be an array'),
  body('notes.*.author')
    .optional()
    .isIn(['parishioner', 'admin'])
    .withMessage('Note author must be parishioner or admin'),
  body('notes.*.content')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Note content cannot be empty'),
  body('notes.*.authorId')
    .optional()
    .isInt()
    .withMessage('Note authorId must be an integer'),
  body('status')
    .optional()
    .isIn(['pending', 'approved', 'declined', 'completed'])
    .withMessage('Status must be one of: pending, approved, declined, completed'),
], massIntentionController.updateMassIntention);

// Delete a mass intention
router.delete('/:id', massIntentionController.deleteMassIntention);

// Update mass intention status (parish_admin/parish_staff/diocese_staff/diocese_admin only)
router.patch('/:id/status',
  authorizeRoles('parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'),
  massIntentionController.updateMassIntentionStatus
);

// Approve a mass intention (parish_staff/priest/diocese_staff/diocese_admin only)
router.patch('/:id/approve',
  authorizeRoles('parish_staff', 'priest', 'diocese_staff', 'diocese_admin'),
  massIntentionController.approveMassIntention
);

// Decline a mass intention (parish_staff/priest/diocese_staff/diocese_admin only)
router.patch('/:id/decline',
  authorizeRoles('parish_staff', 'priest', 'diocese_staff', 'diocese_admin'),
  massIntentionController.declineMassIntention
);

module.exports = router;