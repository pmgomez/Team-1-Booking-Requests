/**
 * Use Case: Create a new Mass Intention
 * Single responsibility: Handle the business logic for creating mass intentions
 */
const MassIntentionDTO = require('../../dto/MassIntentionDTO');

class CreateMassIntentionUseCase {
  /**
   * @param {IMassIntentionRepository} massIntentionRepository
   * @param {IParishRepository} parishRepository
   * @param {IEmailService} emailService
   */
  constructor(massIntentionRepository, parishRepository, emailService) {
    this.massIntentionRepository = massIntentionRepository;
    this.parishRepository = parishRepository;
    this.emailService = emailService;
  }

  /**
   * Executes the use case
   * @param {MassIntentionDTO} dto - The mass intention data
   * @param {Object} user - The authenticated user
   * @returns {Promise<MassIntentionDTO>}
   */
  async execute(dto, user) {
    // Validate input
    const validation = dto.validate();
    if (!validation.isValid) {
      throw new Error(validation.errors.join(', '));
    }

    // Verify parish exists
    const parish = await this.parishRepository.findById(dto.parishId);
    if (!parish) {
      throw new Error('Parish not found');
    }

    // Set additional fields
    dto.submittedBy = user.id; // Use user.id from Sequelize model
    dto.dateRequested = new Date().toISOString().split('T')[0];
    dto.status = 'pending';

    // Create the mass intention
    const createdIntention = await this.massIntentionRepository.create(dto);

    // Send confirmation email (non-blocking)
    this._sendConfirmationEmail(user, createdIntention).catch(err => {
      console.error('Failed to send confirmation email:', err);
    });

    return createdIntention;
  }

  /**
   * Sends confirmation email
   */
  async _sendConfirmationEmail(user, intention) {
    if (!this.emailService) return;
    
    await this.emailService.sendNotification(
      user.email,
      'Mass Intention Submitted',
      `
        <h2>Mass Intention Submitted</h2>
        <p>Dear ${user.firstName || 'User'},</p>
        <p>Your mass intention has been successfully submitted.</p>
        <p><strong>Details:</strong></p>
        <ul>
          <li>Type: ${intention.type}</li>
          <li>Reference Number: ${intention.id}</li>
          <li>Status: ${intention.status}</li>
        </ul>
        <p>We will notify you once your intention has been reviewed.</p>
        <br>
        <p>Best regards,<br>The Diocese of Kalookan Team</p>
      `
    );
  }
}

module.exports = CreateMassIntentionUseCase;
