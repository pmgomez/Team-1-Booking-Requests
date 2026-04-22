const nodemailer = require('nodemailer').default || require('nodemailer');

class EmailService {
  constructor() {
    // Only initialize transporter if email is configured
    if (process.env.EMAIL_USER && process.env.EMAIL_PASSWORD) {
      this.transporter = nodemailer.createTransport({
        host: process.env.EMAIL_HOST,
        port: parseInt(process.env.EMAIL_PORT) || 587,
        secure: process.env.EMAIL_SECURE === 'true',
        auth: {
          user: process.env.EMAIL_USER,
          pass: process.env.EMAIL_PASSWORD,
        },
      });
      this.configured = true;
    } else {
      this.transporter = null;
      this.configured = false;
      console.log('⚠️  Email not configured. Email notifications will be skipped.');
    }

    this.from = process.env.EMAIL_FROM || '"Diocese of Kalookan" <noreply@diocese-kalookan.com>';
  }

  /**
   * Sends a welcome email to a new user with their login credentials
   */
  async sendWelcomeEmail(user, temporaryPassword = null) {
    if (!this.configured) return { skipped: true, reason: 'Email not configured' };

    const passwordSection = temporaryPassword
      ? `
        <div style="background-color: #f0f7ff; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <h3 style="margin-top: 0; color: #1976d2;">Your Login Credentials</h3>
          <p><strong>Email:</strong> ${user.email}</p>
          <p><strong>Temporary Password:</strong> <code style="background-color: #e3f2fd; padding: 5px 10px; font-size: 16px;">${temporaryPassword}</code></p>
          <p style="color: #d32f2f; font-weight: bold;">⚠️ Please change your password for your own security.</p>
        </div>
      `
      : `
        <p>You can now log in to your account using your email address and the password you set during registration.</p>
      `;

    const mailOptions = {
      from: this.from,
      to: user.email,
      subject: temporaryPassword 
        ? 'Welcome to Diocese of Kalookan - Your Account Credentials'
        : 'Welcome to Diocese of Kalookan',
      html: `
        <h2>Welcome to Diocese of Kalookan, ${user.firstName}!</h2>
        <p>Dear ${user.firstName} ${user.lastName},</p>
        ${temporaryPassword 
          ? `<p>An account has been created for you by our administration team.</p>`
          : `<p>Thank you for registering with our Diocese of Kalookan application. Your account has been successfully created.</p>`
        }
        ${passwordSection}
        <p>Once logged in, you can access our sacramental services and manage your bookings.</p>
        <br>
        <p>Best regards,<br>
        The Diocese of Kalookan Team</p>
      `,
    };

    try {
      const result = await this.transporter.sendMail(mailOptions);
      console.log('Welcome email sent successfully:', result.messageId);
      return result;
    } catch (error) {
      console.error('Error sending welcome email:', error);
      throw new Error(`Failed to send welcome email: ${error.message}`);
    }
  }

  /**
   * Sends a booking confirmation email
   */
  async sendBookingConfirmation(user, booking) {
    if (!this.configured) return { skipped: true, reason: 'Email not configured' };

    const mailOptions = {
      from: this.from,
      to: user.email,
      subject: 'Booking Confirmation - Diocese of Kalookan',
      html: `
        <h2>Booking Confirmation</h2>
        <p>Dear ${user.firstName} ${user.lastName},</p>
        <p>Your booking has been successfully submitted and is currently under review.</p>
        <p><strong>Booking Details:</strong></p>
        <ul>
          <li>Type: ${booking.bookingType}</li>
          <li>Requested Date: ${new Date(booking.requestedDate).toLocaleDateString()}</li>
          <li>Status: ${booking.status}</li>
          <li>Reference Number: ${booking.id}</li>
        </ul>
        <p>We will notify you once your booking has been confirmed by our staff.</p>
        <br>
        <p>Best regards,<br>
        The Diocese of Kalookan Team</p>
      `,
    };

    try {
      const result = await this.transporter.sendMail(mailOptions);
      console.log('Booking confirmation email sent successfully:', result.messageId);
      return result;
    } catch (error) {
      console.error('Error sending booking confirmation email:', error);
      throw new Error(`Failed to send booking confirmation email: ${error.message}`);
    }
  }

  /**
   * Sends a password change notification
   */
  async sendPasswordChangeNotification(user) {
    if (!this.configured) return { skipped: true, reason: 'Email not configured' };

    const mailOptions = {
      from: this.from,
      to: user.email,
      subject: 'Password Changed - Diocese of Kalookan',
      html: `
        <h2>Password Change Notification</h2>
        <p>Dear ${user.firstName} ${user.lastName},</p>
        <p>Your password has been successfully changed on ${new Date().toLocaleString()}.</p>
        <p>If you did not initiate this change, please contact our support immediately.</p>
        <br>
        <p>Best regards,<br>
        The Diocese of Kalookan Team</p>
      `,
    };

    try {
      const result = await this.transporter.sendMail(mailOptions);
      console.log('Password change notification email sent successfully:', result.messageId);
      return result;
    } catch (error) {
      console.error('Error sending password change notification email:', error);
      throw new Error(`Failed to send password change notification email: ${error.message}`);
    }
  }

  /**
   * Sends a password reset email with a 6-digit reset code
   */
  async sendPasswordResetCodeEmail(user, resetCode) {
    if (!this.configured) return { skipped: true, reason: 'Email not configured' };

    const mailOptions = {
      from: this.from,
      to: user.email,
      subject: 'Your Password Reset Code - Diocese of Kalookan',
      html: `
        <h2>Password Reset Request</h2>
        <p>Dear ${user.firstName} ${user.lastName},</p>
        <p>We received a request to reset your password for your Diocese of Kalookan account.</p>
        <p style="text-align: center; margin: 30px 0;">
          <span style="background-color: #f5f5f5; padding: 16px 32px; font-size: 32px; font-weight: bold; letter-spacing: 8px; border-radius: 8px; display: inline-block; border: 2px solid #1976d2; color: #1976d2;">${resetCode}</span>
        </p>
        <p>Enter this code in the app to reset your password.</p>
        <p><strong>This code will expire in 1 hour.</strong></p>
        <p>If you did not request a password reset, please ignore this email. Your password will remain unchanged.</p>
        <br>
        <p>Best regards,<br>
        The Diocese of Kalookan Team</p>
      `,
    };

    try {
      const result = await this.transporter.sendMail(mailOptions);
      console.log('Password reset code email sent successfully:', result.messageId);
      return result;
    } catch (error) {
      console.error('Error sending password reset code email:', error);
      throw new Error(`Failed to send password reset code email: ${error.message}`);
    }
  }

  /**
   * Sends a password reset email with reset link (deprecated - kept for backward compatibility)
   */
  async sendPasswordResetEmail(user, resetUrl) {
    if (!this.configured) return { skipped: true, reason: 'Email not configured' };

    const mailOptions = {
      from: this.from,
      to: user.email,
      subject: 'Password Reset Request - Diocese of Kalookan',
      html: `
        <h2>Password Reset Request</h2>
        <p>Dear ${user.firstName} ${user.lastName},</p>
        <p>We received a request to reset your password for your Diocese of Kalookan account.</p>
        <p style="text-align: center; margin: 30px 0;">
          <a href="${resetUrl}"
             style="background-color: #1976d2; color: white; padding: 14px 28px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">
            Reset My Password
          </a>
        </p>
        <p>Or copy and paste this link into your browser:</p>
        <p style="background-color: #f5f5f5; padding: 10px; word-break: break-all; border-radius: 5px;">${resetUrl}</p>
        <p><strong>This link will expire in 1 hour.</strong></p>
        <p>If you did not request a password reset, please ignore this email. Your password will remain unchanged.</p>
        <br>
        <p>Best regards,<br>
        The Diocese of Kalookan Team</p>
      `,
    };

    try {
      const result = await this.transporter.sendMail(mailOptions);
      console.log('Password reset email sent successfully:', result.messageId);
      return result;
    } catch (error) {
      console.error('Error sending password reset email:', error);
      throw new Error(`Failed to send password reset email: ${error.message}`);
    }
  }

  /**
   * Sends a general notification email
   */
  async sendNotification(to, subject, message) {
    if (!this.configured) {
      console.log(`📧 Email notification skipped (not configured): ${subject}`);
      return { skipped: true, reason: 'Email not configured' };
    }

    const mailOptions = {
      from: this.from,
      to,
      subject,
      html: message,
    };

    try {
      const result = await this.transporter.sendMail(mailOptions);
      console.log('Notification email sent successfully:', result.messageId);
      return result;
    } catch (error) {
      console.error('Error sending notification email:', error);
      // Don't throw error - just log it so booking can still proceed
      return { error: error.message };
    }
  }

  /**
   * Verifies the email configuration
   */
  async verifyConnection() {
    if (!this.configured) {
      console.log('Email not configured, skipping verification');
      return false;
    }

    try {
      await this.transporter.verify();
      console.log('Email server configuration verified successfully');
      return true;
    } catch (error) {
      console.error('Email server configuration verification failed:', error);
      return false;
    }
  }
}

module.exports = new EmailService();
