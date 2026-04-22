const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { BookingDocument } = require('../models');

class FileService {
  constructor() {
    this.uploadDir = process.env.UPLOAD_PATH || './uploads/documents';
    this.tempDir = './uploads/temp';
    this.maxFileSize = parseInt(process.env.MAX_FILE_SIZE) || 5 * 1024 * 1024; // 5MB default
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
    // Extension check covers cases where the client sends a generic mimetype (e.g., application/octet-stream)
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
   * Moves file from temp to permanent location
   */
  async saveFile(file, userId, category = 'general', bookingType = null, bookingId = null, documentType = 'other') {
    try {
      this.validateFile(file);

      // Create user-specific directory
      const userDir = path.join(this.uploadDir, userId.toString());
      const categoryDir = path.join(userDir, category);
      
      if (!fs.existsSync(categoryDir)) {
        fs.mkdirSync(categoryDir, { recursive: true });
      }

      // Generate unique filename
      const fileExtension = path.extname(file.originalname);
      const fileName = `${category}-${uuidv4()}${fileExtension}`;
      const filePath = path.join(categoryDir, fileName);
      const fileUrl = `/uploads/documents/${userId}/${category}/${fileName}`;

      // Move file from temp to permanent location
      const tempFilePath = file.path;
      fs.renameSync(tempFilePath, filePath);

      // Note: BookingDocument record will be created when booking is created,
      // using the file details returned here.

      return {
        filename: fileName,
        path: filePath,
        originalName: file.originalname,
        size: file.size,
        mimetype: file.mimetype,
        url: fileUrl
      };
    } catch (error) {
      // Clean up temp file if validation fails
      if (file && fs.existsSync(file.path)) {
        fs.unlinkSync(file.path);
      }
      throw error;
    }
  }

  /**
   * Deletes a file
   */
  async deleteFile(filePath) {
    try {
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        return true;
      }
      return false;
    } catch (error) {
      throw new Error(`Failed to delete file: ${error.message}`);
    }
  }

  /**
   * Gets file information
   */
  getFileStats(filePath) {
    try {
      if (!fs.existsSync(filePath)) {
        throw new Error('File does not exist');
      }
      
      const stats = fs.statSync(filePath);
      return {
        size: stats.size,
        createdAt: stats.birthtime,
        updatedAt: stats.mtime,
        isFile: stats.isFile()
      };
    } catch (error) {
      throw new Error(`Failed to get file stats: ${error.message}`);
    }
  }

  /**
   * Checks if file exists
   */
  fileExists(filePath) {
    return fs.existsSync(filePath);
  }

  /**
   * Gets user's files by category
   */
  getUserFiles(userId, category = 'general') {
    try {
      const userDir = path.join(this.uploadDir, userId.toString(), category);
      
      if (!fs.existsSync(userDir)) {
        return [];
      }

      const files = fs.readdirSync(userDir);
      return files.map(filename => {
        const filePath = path.join(userDir, filename);
        const stats = fs.statSync(filePath);
        
        return {
          filename,
          path: filePath,
          size: stats.size,
          createdAt: stats.birthtime,
          url: `/uploads/documents/${userId}/${category}/${filename}`
        };
      });
    } catch (error) {
      throw new Error(`Failed to get user files: ${error.message}`);
    }
  }

  /**
   * Creates a secure file path
   */
  createSecurePath(userId, category, filename) {
    // Prevent directory traversal attacks
    const normalizedPath = path.normalize(path.join(this.uploadDir, userId.toString(), category, filename));
    
    if (!normalizedPath.startsWith(this.uploadDir)) {
      throw new Error('Invalid file path');
    }
    
    return normalizedPath;
  }
}

module.exports = new FileService();