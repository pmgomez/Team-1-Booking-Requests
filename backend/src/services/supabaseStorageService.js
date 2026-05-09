const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');
const { v4: uuidv4 } = require('uuid');

class SupabaseStorageService {
  constructor() {
    this.supabaseUrl = process.env.SUPABASE_URL;
    this.supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
    this.bucketName = process.env.SUPABASE_STORAGE_BUCKET || 'documents';
    this.maxFileSize = parseInt(process.env.MAX_FILE_SIZE) || 5 * 1024 * 1024;
    this.allowedTypes = process.env.ALLOWED_FILE_TYPES?.split(',') || [
      'image/jpeg',
      'image/png',
      'application/pdf'
    ];
    this.allowedExtensions = new Set(['.jpg', '.jpeg', '.png', '.pdf']);

    if (!this.supabaseUrl || !this.supabaseServiceKey) {
      console.warn('⚠️ Supabase configuration missing. Set SUPABASE_URL and SUPABASE_SERVICE_KEY in .env');
      console.warn('   Current values:', {
        supabaseUrl: this.supabaseUrl ? 'set' : 'MISSING',
        supabaseServiceKey: this.supabaseServiceKey ? 'set' : 'MISSING',
        bucketName: this.bucketName
      });
    } else {
      console.log('✅ Supabase configured:', {
        url: this.supabaseUrl,
        bucket: this.bucketName,
        keyPrefix: this.supabaseServiceKey.substring(0, 10) + '...'
      });
    }

    this.supabase = this.supabaseUrl && this.supabaseServiceKey
      ? createClient(this.supabaseUrl, this.supabaseServiceKey, {
          auth: {
            autoRefreshToken: false,
            persistSession: false,
          },
        })
      : null;
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

    // Check file type
    const ext = path.extname(file.originalname).toLowerCase();
    const mimeValid = this.allowedTypes.includes(file.mimetype);
    const extValid = this.allowedExtensions.has(ext);

    if (!mimeValid && !extValid) {
      throw new Error(`Invalid file type. Only JPEG, PNG, and PDF files are allowed.`);
    }

    return true;
  }

  /**
   * Uploads a file to Supabase Storage
   */
  async uploadFile(file, userId, category = 'general', bookingType = null, bookingId = null, documentType = 'other') {
    try {
      if (!this.supabase) {
        throw new Error('Supabase client not initialized. Check SUPABASE_URL and SUPABASE_SERVICE_KEY');
      }

      this.validateFile(file);

      // Generate unique filename with path structure: userId/category/uuid.ext
      const fileExtension = path.extname(file.originalname);
      const fileName = `${category}-${uuidv4()}${fileExtension}`;
      const storagePath = `${userId}/${category}/${fileName}`;

      // Read file from temp location as Buffer (tested and works)
      let fileBuffer;
      try {
        fileBuffer = fs.readFileSync(file.path);
        console.log(`📖 Read file from ${file.path}: ${fileBuffer.length} bytes`);
      } catch (readErr) {
        console.error('❌ Error reading file:', readErr);
        throw new Error(`Failed to read uploaded file: ${readErr.message}`);
      }

      console.log(`☁️ Uploading to Supabase:`);
      console.log(`   Bucket: ${this.bucketName}, Path: ${storagePath}`);
      console.log(`   File size: ${fileBuffer.length} bytes, Content-Type: ${file.mimetype}`);
      
      // Upload to Supabase Storage using Buffer (proven to work)
      const { error: uploadError } = await this.supabase.storage
        .from(this.bucketName)
        .upload(storagePath, fileBuffer, {
          contentType: file.mimetype,
          upsert: false,
          cacheControl: '3600',
        });

      if (uploadError) {
        // Log all error properties for debugging
        const errorDetails = {
          message: uploadError.message,
          name: uploadError.name,
          statusCode: uploadError.statusCode,
          statusText: uploadError.statusText,
          bucket: this.bucketName,
          path: storagePath,
          supabaseUrl: this.supabaseUrl,
        };
        for (const key of Object.keys(uploadError)) {
          if (!errorDetails[key]) {
            errorDetails[key] = uploadError[key];
          }
        }
        console.error('❌ Supabase upload error details:', errorDetails);
        throw new Error(`Supabase upload failed: ${uploadError.message}`);
      }

      console.log(`✅ Supabase upload successful: ${storagePath}`);

      // Get public URL
      const { data: urlData } = this.supabase.storage
        .from(this.bucketName)
        .getPublicUrl(storagePath);

      const fileUrl = urlData?.publicUrl || `${this.supabaseUrl}/storage/v1/object/public/${this.bucketName}/${storagePath}`;
      console.log(`🔗 File URL: ${fileUrl}`);

      // Clean up temp file after successful upload
      if (file.path && fs.existsSync(file.path)) {
        try {
          fs.unlinkSync(file.path);
          console.log(`🗑️  Cleaned up temp file: ${file.path}`);
        } catch (e) {
          console.warn('⚠️  Could not delete temp file:', e.message);
        }
      }

      return {
        filename: fileName,
        path: storagePath,
        url: fileUrl,
        bucket: this.bucketName,
        size: fileBuffer.length,
        mimeType: file.mimetype,
        uploadedBy: userId,
        category,
        bookingType,
        bookingId,
        documentType,
      };
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

  async deleteFile(filePath) {
    try {
      if (!this.supabase) {
        throw new Error('Supabase client not initialized');
      }

      const { error } = await this.supabase.storage
        .from(this.bucketName)
        .remove([filePath]);

      if (error) {
        throw new Error(`Failed to delete file: ${error.message}`);
      }

      return true;
    } catch (error) {
      throw new Error(`Failed to delete file: ${error.message}`);
    }
  }

  async getUserFiles(userId, category = 'general') {
    try {
      if (!this.supabase) {
        throw new Error('Supabase client not initialized');
      }

      const prefix = `${userId}/${category}/`;
      const { data: files, error } = await this.supabase.storage
        .from(this.bucketName)
        .list(prefix, {
          limit: 100,
          offset: 0,
          sortBy: { column: 'created_at', order: 'desc' },
        });

      if (error) {
        throw new Error(`Failed to list files: ${error.message}`);
      }

      return files.map(file => ({
        filename: file.name,
        path: `${prefix}${file.name}`,
        size: file.metadata?.size || file.metadata?.sizeBytes || 0,
        createdAt: file.created_at,
        updatedAt: file.last_modified,
        url: this.supabase.storage.from(this.bucketName).getPublicUrl(`${prefix}${file.name}`).publicUrl,
      }));
    } catch (error) {
      throw new Error(`Failed to get user files: ${error.message}`);
    }
  }

  createSecurePath(userId, category, filename) {
    const normalizedPath = path.normalize(path.join(userId.toString(), category, filename));
    
    if (normalizedPath.includes('..') || normalizedPath.startsWith('/')) {
      throw new Error('Invalid file path');
    }
    
    return `${userId}/${category}/${filename}`;
  }
}

module.exports = new SupabaseStorageService();
