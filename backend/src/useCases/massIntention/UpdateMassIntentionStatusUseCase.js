/**
 * Use Case: Update Mass Intention Status
 * Single responsibility: Handle generic status updates for mass intentions
 */
class UpdateMassIntentionStatusUseCase {
  /**
   * @param {IMassIntentionRepository} massIntentionRepository
   */
  constructor(massIntentionRepository) {
    this.massIntentionRepository = massIntentionRepository;
  }

  /**
   * Executes the use case
   * @param {number} id - The mass intention ID
   * @param {string} status - The new status
   * @param {Object} user - The authenticated user
   * @returns {Promise<MassIntentionDTO>}
   */
  async execute(id, status, user) {
    // Check role permission (parish_admin and above, excluding priest)
    const allowedRoles = ['parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'];
    if (!allowedRoles.includes(user.role)) {
      throw new Error('Access denied: This action requires one of these roles: parish_admin, parish_staff, diocese_staff, diocese_admin');
    }

    // Validate status
    const validStatuses = ['pending', 'approved', 'declined', 'completed'];
    if (!validStatuses.includes(status)) {
      throw new Error('Invalid status value');
    }

    // Update status
    const updatedIntention = await this.massIntentionRepository.updateStatus(id, status);

    return updatedIntention;
  }
}

module.exports = UpdateMassIntentionStatusUseCase;
