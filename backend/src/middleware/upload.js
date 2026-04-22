const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure upload directories exist
const uploadDir = process.env.UPLOAD_PATH || './uploads';
const documentsDir = path.join(uploadDir, 'documents');
const tempDir = path.join(uploadDir, 'temp');

// Create directories if they don't exist
[uploadDir, documentsDir, tempDir].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// Configure multer storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    // Use temporary directory for initial upload
    cb(null, tempDir);
  },
  filename: function (req, file, cb) {
    // Generate unique filename with timestamp
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, file.fieldname + '-' + uniqueSuffix + ext);
  }
});

// File extensions mapping for fallback validation
const extToMimetype = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.pdf': 'application/pdf',
};

// File filter to allow specific types
const fileFilter = (req, file, cb) => {
  const allowedTypes = process.env.ALLOWED_FILE_TYPES?.split(',') || [
    'image/jpeg',
    'image/png',
    'application/pdf'
  ];

  const ext = path.extname(file.originalname).toLowerCase();
  const inferredMimetype = extToMimetype[ext];

  console.log('📁 File upload attempt:', {
    originalName: file.originalname,
    mimetype: file.mimetype,
    fieldname: file.fieldname,
    extension: ext,
  });

  // Accept if MIME type matches OR if we can infer from extension
  const mimeMatches = allowedTypes.includes(file.mimetype);
  const extValid = inferredMimetype && allowedTypes.includes(inferredMimetype);

  if (mimeMatches || extValid) {
    console.log(`✅ File type accepted (mimetype: ${mimeMatches}, extension: ${extValid})`);
    cb(null, true);
  } else {
    console.log(`❌ File type rejected. mimetype="${file.mimetype}", ext="${ext}"`, '\n   Allowed types:', allowedTypes);
    cb(new Error(`Invalid file type. Only JPEG, PNG, and PDF files are allowed.`), false);
  }
};

// Get max file size from environment or default to 5MB
const maxSize = parseInt(process.env.MAX_FILE_SIZE) || 5 * 1024 * 1024; // 5MB default

const upload = multer({
  storage: storage,
  limits: {
    fileSize: maxSize
  },
  fileFilter: fileFilter
});

module.exports = {
  upload,
  documentsDir,
  tempDir
};