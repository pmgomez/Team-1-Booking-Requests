/**
 * Use Case: Update Mass Intention
 * Single responsibility: Handle updating mass intention with role-based permissions
 */
const MassIntentionDTO = require('../../dto/MassIntentionDTO');

class UpdateMassIntentionUseCase {
  /**
   * @param {IMassIntentionRepository} massIntentionRepository
   */
  constructor(massIntentionRepository) {
    this.massIntentionRepository = massIntentionRepository;
  }

  /**
   * Executes the use case
   * @param {number} id - The mass intention ID
   * @param {MassIntentionDTO} dto - The update data
   * @param {Object} user - The authenticated user
   * @returns {Promise<MassIntentionDTO>}
   */
   async execute(id, dto, user) {
    // Get existing intention
    const existingIntention = await this.massIntentionRepository.findById(id);
    if (!existingIntention) {
      throw new Error('Mass intention not found');
    }

    // Get allowed fields based on user role (pass full user object for parish check)
    const allowedFields = this._getAllowedFields(user.role, existingIntention, user);

    // Prepare update data with only allowed fields
    const updateData = dto.getAllowedUpdates(allowedFields);

    // Perform update
    return await this.massIntentionRepository.update(id, updateData);
  }

  /**
   * Gets allowed update fields based on user role
   * @param {string} role - User role
   * @param {Object} intention - Existing mass intention
   * @param {Object} user - Full user object (for parish_admin checks)
   */
  _getAllowedFields(role, intention, user) {
    switch (role) {
      case 'diocese_staff':
      case 'diocese_admin':
        // Can update everything
        return ['type', 'intentionDetails', 'donorName', 'parishId', 'massSchedule', 'preferredTime', 'preferredPriest', 'notes', 'status'];

      case 'parish_admin':
        // Parish admin can only manage their assigned parish's intentions
        if (intention.parishId !== user.assignedParishId) {
          throw new Error('Access denied: You can only manage mass intentions in your assigned parish');
        }
        // Can update most fields except parishId and submittedBy
        return ['type', 'intentionDetails', 'donorName', 'massSchedule', 'preferredTime', 'preferredPriest', 'notes', 'status'];

      case 'parish_staff':
      case 'priest':
        // Can update status and notes only (parish-level restriction handled separately if needed)
        return ['status', 'notes'];

      case 'parishioner':
        // Can only update their own pending intentions
        if (intention.submittedBy !== user.userId) {
          throw new Error('Access denied: You can only update your own mass intentions');
        }
        if (intention.status !== 'pending') {
          throw new Error('Cannot update mass intention once it is no longer pending');
        }
        return ['intentionDetails', 'donorName', 'parishId', 'massSchedule', 'preferredPriest', 'notes'];

      default:
        throw new Error('Insufficient permissions');
    }
  }
}

module.exports = UpdateMassIntentionUseCase;
