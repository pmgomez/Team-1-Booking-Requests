const express = require('express');
const router = express.Router();
const { upload, tempDir } = require('../middleware/upload');
const fileService = require('../services/fileService');

// Upload a file
router.post('/upload', require('../middleware/auth').authenticateJWT, upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        error: 'No file provided',
        message: 'Please select a file to upload'
      });
    }

    // Save file to permanent location
    const fileData = await fileService.saveFile(
      req.file,
      req.user.userId,
      req.body.category || 'general',
      req.body.bookingType || req.body.category, // Use category as bookingType if not specified
      req.body.bookingId,
      req.body.documentType || 'other'
    );

    res.status(201).json({
      message: 'File uploaded successfully',
      file: fileData
    });
  } catch (error) {
    // Clean up temp file if error occurs
    if (req.file && req.file.path) {
      try {
        require('fs').unlinkSync(req.file.path);
      } catch (cleanupError) {
        // Ignore cleanup errors (file may already be moved/deleted)
      }
    }

    next(error);
  }
});

// Get user's files
router.get('/', require('../middleware/auth').authenticateJWT, async (req, res, next) => {
  try {
    const category = req.query.category || 'general';
    const userId = req.user.userId;
    
    const files = await fileService.getUserFiles(userId, category);
    
    res.json({
      message: 'Files retrieved successfully',
      files,
      category
    });
  } catch (error) {
    next(error);
  }
});

// Get specific file info
router.get('/:filename', require('../middleware/auth').authenticateJWT, async (req, res, next) => {
  try {
    const { filename } = req.params;
    const category = req.query.category || 'general';
    const userId = req.user.userId;
    
    const filePath = fileService.createSecurePath(userId, category, filename);
    
    if (!fileService.fileExists(filePath)) {
      return res.status(404).json({
        error: 'File not found',
        message: 'The requested file does not exist'
      });
    }
    
    const stats = fileService.getFileStats(filePath);
    
    res.json({
      message: 'File info retrieved successfully',
      file: {
        filename,
        path: filePath,
        size: stats.size,
        createdAt: stats.createdAt,
        url: `/uploads/documents/${userId}/${category}/${filename}`
      }
    });
  } catch (error) {
    next(error);
  }
});

// Delete a file
router.delete('/:filename', require('../middleware/auth').authenticateJWT, async (req, res, next) => {
  try {
    const { filename } = req.params;
    const category = req.query.category || 'general';
    const userId = req.user.userId;
    
    const filePath = fileService.createSecurePath(userId, category, filename);
    
    if (!fileService.fileExists(filePath)) {
      return res.status(404).json({
        error: 'File not found',
        message: 'The requested file does not exist'
      });
    }
    
    const deleted = await fileService.deleteFile(filePath);
    
    if (deleted) {
      res.json({
        message: 'File deleted successfully'
      });
    } else {
      res.status(500).json({
        error: 'Failed to delete file',
        message: 'Could not delete the file'
      });
    }
  } catch (error) {
    next(error);
  }
});

module.exports = router;