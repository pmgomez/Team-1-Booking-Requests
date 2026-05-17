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
  
      console.log('[UpdateMassIntentionUseCase] DTO preferredTime:', dto.preferredTime);
      console.log('[UpdateMassIntentionUseCase] DTO all:', JSON.stringify(dto));
  
      // Get allowed fields based on user role (pass full user object for parish check)
      const allowedFields = this._getAllowedFields(user.role, existingIntention, user, dto);
 
// Prepare update data with only allowed fields (excluding notes which are handled separately)
      console.log('[UpdateMassIntentionUseCase] allowedFields:', allowedFields);
      const updateData = dto.getAllowedUpdates(allowedFields.filter(f => f !== 'notes'));
      console.log('[UpdateMassIntentionUseCase] updateData after getAllowedUpdates:', JSON.stringify(updateData));
 
      // Handle notes separately - append only
      if (dto.notes && dto.notes.length > 0 && allowedFields.includes('notes')) {
        const existingNotes = existingIntention.notes || [];
        const newNotes = dto.notes.map(note => {
          let noteContent = note;
          if (typeof note === 'object' && note !== null) {
            noteContent = note.content || JSON.stringify(note);
          }
          return {
            author: user.role === 'parishioner' ? 'parishioner' : 'admin',
            content: noteContent,
            authorId: user.userId,
            timestamp: new Date().toISOString(),
          };
        });
        updateData.notes = [...existingNotes, ...newNotes];
      }
 
     // Perform update
     return await this.massIntentionRepository.update(id, updateData);
   }

/**
    * Gets allowed update fields based on user role
    * @param {string} role - User role
    * @param {Object} intention - Existing mass intention
    * @param {Object} user - Full user object (for parish_admin checks)
    * @param {MassIntentionDTO} dto - The update data
    */
   _getAllowedFields(role, intention, user, dto) {
    switch (role) {
      case 'diocese_staff':
      case 'diocese_admin':
        // Can update everything including notes
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
        // Can update all fields like parish_admin
        return ['type', 'intentionDetails', 'donorName', 'massSchedule', 'preferredTime', 'preferredPriest', 'notes', 'status'];

      case 'parishioner':
        // Can only update their own intentions
        if (intention.submittedBy !== user.userId) {
          throw new Error('Access denied: You can only update your own mass intentions');
        }
        // Allow resubmit: change status from 'declined' back to 'pending'
        if (intention.status === 'declined') {
          // If no status in request, allow regular update (keep declined)
          if (!dto.status) {
            return ['intentionDetails', 'donorName', 'parishId', 'massSchedule', 'preferredTime', 'preferredPriest', 'notes'];
          }
          // If status is 'pending', allow resubmit
          if (dto.status === 'pending') {
            return ['intentionDetails', 'donorName', 'parishId', 'massSchedule', 'preferredTime', 'preferredPriest', 'notes', 'status'];
          }
          // Any other status is not allowed
          throw new Error('Cannot update a declined mass intention unless resubmitting');
        }
        if (intention.status !== 'pending') {
          throw new Error('Cannot update mass intention once it is no longer pending');
        }
        return ['intentionDetails', 'donorName', 'parishId', 'massSchedule', 'preferredTime', 'preferredPriest', 'notes'];

      default:
        throw new Error('Insufficient permissions');
    }
  }
}

module.exports = UpdateMassIntentionUseCase;
