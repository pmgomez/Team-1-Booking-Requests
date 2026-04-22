const jwt = require('jsonwebtoken');
const { User, TokenBlacklist } = require('../models');

// Verify JWT token from Flutter app
const authenticateJWT = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Access token required',
        message: 'Please provide a valid JWT token in Authorization header'
      });
    }

    const token = authHeader.split(' ')[1];

    // Check if token is blacklisted
    const isBlacklisted = await TokenBlacklist.isBlacklisted(token);
    if (isBlacklisted) {
      return res.status(401).json({
        error: 'Token blacklisted',
        message: 'You have been logged out. Please login again.'
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Attach user info to request
    req.user = {
      userId: decoded.userId,
      role: decoded.role,
      email: decoded.email,
      assignedParishId: decoded.assignedParishId || null,
    };

    next();
  } catch (error) {
    console.error('Auth middleware error:', error.message);
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Token expired',
        message: 'Your session has expired. Please refresh your token.'
      });
    }
    if (error.name === 'JsonWebTokenError') {
      return res.status(403).json({
        error: 'Invalid token',
        message: 'The provided token is invalid or malformed.'
      });
    }
    return res.status(500).json({ error: 'Authentication failed', details: error.message });
  }
};

// Middleware to check if user must change password
// Should be used after authenticateJWT on routes that require password change
const requirePasswordChange = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.user.userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (user.mustChangePassword) {
      return res.status(403).json({
        error: 'Password change required',
        message: 'You must change your temporary password before continuing.',
        mustChangePassword: true,
      });
    }

    next();
  } catch (error) {
    console.error('Password check error:', error);
    return res.status(500).json({ error: 'Failed to verify password status' });
  }
};

// Authorize based on user roles
const authorizeRoles = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ 
        error: 'Authentication required' 
      });
    }
    
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ 
        error: 'Access denied',
        message: `This action requires one of these roles: ${allowedRoles.join(', ')}` 
      });
    }
    
    next();
  };
};

module.exports = { authenticateJWT, authorizeRoles, requirePasswordChange };