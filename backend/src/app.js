const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
require('dotenv').config({ 
  path: `.env.${process.env.NODE_ENV || 'development'}` 
});

// Import routes
const authRoutes = require('./routes/auth');
const bookingRoutes = require('./routes/bookings');
const intentionRoutes = require('./routes/intentions');
const massIntentionRoutes = require('./routes/massIntentions');
const massScheduleRoutes = require('./routes/massSchedules');
const userRoutes = require('./routes/users');
const fileRoutes = require('./routes/files');
const parishRoutes = require('./routes/parishes');
const adminRoutes = require('./routes/admin');
const apiDocsRoutes = require('./routes/apiDocs');

// New sacrament booking routes
const baptismRoutes = require('./routes/baptisms');
const baptismDocumentRoutes = require('./routes/baptismDocuments');
const sacramentRoutes = require('./routes/sacraments');
const parishSettingsRoutes = require('./routes/parishSettings');
const sacramentalRecordsRoutes = require('./routes/sacramentalRecords');
const paymentRoutes = require('./routes/payments');

// Import middleware
const errorHandler = require('./middleware/errorHandler');
const { apiLimiter } = require('./middleware/rateLimiter');

const app = express();

// Security middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" },
}));

// CORS configuration for Flutter app
const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [
  'http://localhost:8080', // Flutter web
  'http://10.0.2.2:3000',  // Android emulator
  'http://127.0.0.1:3000', // iOS simulator
];

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, Postman)
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware (development only)
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Serve static files (uploaded documents)
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Rate limiting for API routes
app.use('/api/', apiLimiter);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
    service: 'Diocese API for Flutter',
  });
});

// API version info
app.get('/api', (req, res) => {
  res.json({
    name: 'Diocese of Kalookan API',
    version: '1.0.0',
    description: 'Backend API for sacramental booking and management system',
    endpoints: {
      auth: '/api/auth',
      bookings: '/api/bookings',
      intentions: '/api/intentions',
      'mass-intentions': '/api/mass-intentions',
      users: '/api/users',
      files: '/api/files',
      parishes: '/api/parishes',
      baptisms: '/api/baptisms',
      sacraments: '/api/sacraments (weddings, confirmations, eucharist, reconciliations, anointing-sick, funeral-mass)',
      'parish-settings': '/api/parish-settings',
      'sacramental-records': '/api/sacramental-records',
      payments: '/api/payments',
    },
  });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/intentions', intentionRoutes);
app.use('/api/mass-intentions', massIntentionRoutes);
app.use('/api/mass-schedules', massScheduleRoutes);
app.use('/api/users', userRoutes);
app.use('/api/files', fileRoutes);
app.use('/api/parishes', parishRoutes);

// Admin routes (must be before sacraments to avoid conflicts)
app.use('/api/admin', adminRoutes);

// New sacrament booking routes
app.use('/api/baptisms', baptismRoutes);
app.use('/api/baptism-documents', baptismDocumentRoutes);
app.use('/api/sacraments', sacramentRoutes);
app.use('/api/parish-settings', parishSettingsRoutes);
app.use('/api/sacramental-records', sacramentalRecordsRoutes);
app.use('/api/payments', paymentRoutes);

app.use('/api-docs', apiDocsRoutes);

// Cleanup expired tokens from blacklist daily
if (process.env.NODE_ENV !== 'test') {
  const { TokenBlacklist } = require('./models');
  setInterval(async () => {
    try {
      const deletedCount = await TokenBlacklist.cleanupExpired();
      if (deletedCount > 0) {
        console.log(`🗑️  Cleaned up ${deletedCount} expired tokens from blacklist`);
      }
    } catch (error) {
      console.error('Error cleaning up token blacklist:', error);
    }
  }, 24 * 60 * 60 * 1000); // Run every 24 hours
}

// 404 handler
app.use((req, res) => {
  res.status(404).json({ 
    error: 'Endpoint not found',
    path: req.path,
    method: req.method,
  });
});

// Global error handling middleware
app.use(errorHandler);

module.exports = app;