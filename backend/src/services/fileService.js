const fs = require('fs');
const path = require('path');
const supabaseStorageService = require('./supabaseStorageService');

class FileService {
  constructor() {
    this.uploadDir = process.env.UPLOAD_PATH || './uploads/documents';
    this.tempDir = './uploads/temp';
    this.maxFileSize = parseInt(process.env.MAX_FILE_SIZE) || 5 * 1024 * 1024;
    this.allowedTypes = process.env.ALLOWED_FILE_TYPES?.split(',') || [
      'image/jpeg',
      'image/png',
      'application/pdf'
    ];
    this.allowedExtensions = new Set(['.jpg', '.jpeg', '.png', '.pdf']);
  }

  /**
   * Validates file before processing
   */
  validateFile(file) {
    if (!file) {
      throw new Error('No file provided');
    }

    // Check file size
    if (file.size > this.maxFileSize) {
      const maxSizeMB = this.maxFileSize / (1024 * 1024);
      throw new Error(`File too large. Maximum size is ${maxSizeMB}MB`);
    }

    // Check file type - accept by MIME type OR by file extension
    const ext = path.extname(file.originalname).toLowerCase();
    const mimeValid = this.allowedTypes.includes(file.mimetype);
    const extValid = this.allowedExtensions.has(ext);

    if (!mimeValid && !extValid) {
      throw new Error(
        `Invalid file type. Only JPEG, PNG, and PDF files are allowed.`
      );
    }

    return true;
  }

  /**
   * Uploads file to Supabase Storage
   */
  async saveFile(file, userId, category = 'general', bookingType = null, bookingId = null, documentType = 'other') {
    try {
      this.validateFile(file);

      // Upload to Supabase Storage
      const fileData = await supabaseStorageService.uploadFile(
        file,
        userId,
        category,
        bookingType,
        bookingId,
        documentType
      );

      return fileData;
    } catch (error) {
      // Clean up temp file if error occurs
      if (file && file.path && fs.existsSync(file.path)) {
        try {
          fs.unlinkSync(file.path);
        } catch (cleanupError) {
          // Ignore cleanup errors
        }
      }
      throw error;
    }
  }

  /**
      return await supabaseStorageService.getFileStats(filePath);
    } catch (error) {
      throw new Error(`Failed to get file stats: ${error.message}`);
    }
  }

  /**
   * Checks if file exists in Supabase Storage
   */
  async fileExists(filePath) {
    try {
      return await supabaseStorageService.fileExists(filePath);
    } catch (error) {
      return false;
    }
  }

  /**
   * Gets user's files from Supabase Storage
   */
  async getUserFiles(userId, category = 'general') {
    try {
      return await supabaseStorageService.getUserFiles(userId, category);
    } catch (error) {
      throw new Error(`Failed to get user files: ${error.message}`);
    }
  }

  /**
   * Creates a secure file path
   */
  createSecurePath(userId, category, filename) {
    return supabaseStorageService.createSecurePath(userId, category, filename);
  }
}

module.exports = new FileService();
