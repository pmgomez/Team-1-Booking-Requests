/**
 * Data Transfer Object for Mass Intention
 * Encapsulates request/response data and provides validation
 */
class MassIntentionDTO {
  constructor({
    id,
    type,
    intentionDetails,
    donorName,
    parishId,
    parishName,
    massSchedule,
    preferredTime,
    preferredPriest,
    notes = [],
    dateRequested,
    status,
    submittedBy,
    createdAt,
    updatedAt,
  }) {
    this.id = id;
    this.type = type;
    this.intentionDetails = intentionDetails;
    this.donorName = donorName;
    this.parishId = parishId;
    this.parishName = parishName;
    this.massSchedule = massSchedule;
    this.preferredTime = preferredTime;
    this.preferredPriest = preferredPriest;
    this.notes = Array.isArray(notes) ? notes : [];
    this.dateRequested = dateRequested;
    this.status = status;
    this.submittedBy = submittedBy;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  /**
   * Creates DTO from request body
   */
  static fromRequest(body) {
    console.log('[MassIntentionDTO.fromRequest] RECEIVED body.notes:', JSON.stringify(body.notes), 'type:', typeof body.notes);
    let notes = [];
    
    if (body.notes) {
      console.log('[MassIntentionDTO.fromRequest] body.notes type:', typeof body.notes, 'value:', JSON.stringify(body.notes));
      if (typeof body.notes === 'string') {
        try {
          notes = JSON.parse(body.notes);
        } catch (e) {
          notes = [];
        }
      } else if (Array.isArray(body.notes)) {
        notes = body.notes;
      }
    }
    console.log('[MassIntentionDTO.fromRequest] final notes:', JSON.stringify(notes));

    return new this({
      type: body.type,
      intentionDetails: body.intentionDetails,
      donorName: body.donorName,
      parishId: parseInt(body.parishId),
      massSchedule: new Date(body.massSchedule),
      preferredTime: body.preferredTime,
      preferredPriest: body.preferredPriest,
      notes: notes,
    });
  }

  /**
   * Creates DTO from database entity
   */
  static fromEntity(entity) {
    if (!entity) return null;
    let notes = [];
    if (entity.notes) {
      try {
        const parsed = typeof entity.notes === 'string' ? JSON.parse(entity.notes) : entity.notes;
        notes = Array.isArray(parsed) ? parsed : [];
      } catch (e) {
        notes = [];
      }
    }
    return new this({
      id: entity.id,
      type: entity.type,
      intentionDetails: entity.intentionDetails,
      donorName: entity.donorName,
      parishId: entity.parishId,
      parishName: entity.parish?.name, // from included association
      massSchedule: entity.massSchedule,
      preferredTime: entity.preferredTime,
      preferredPriest: entity.preferredPriest,
      notes: notes,
      dateRequested: entity.dateRequested,
      status: entity.status,
      submittedBy: entity.submittedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    });
  }

  /**
   * Creates DTOs from database entities
   */
  static fromEntities(entities) {
    return entities.map(entity => this.fromEntity(entity));
  }

  /**
   * Validates the DTO data
   */
  validate() {
    const errors = [];

    if (!this.type || !['For the Dead', 'Thanksgiving', 'Special Intention'].includes(this.type)) {
      errors.push('Invalid or missing intention type');
    }

    if (!this.intentionDetails || typeof this.intentionDetails !== 'string') {
      errors.push('Intention details are required');
    }

    if (!this.donorName || typeof this.donorName !== 'string') {
      errors.push('Donor name is required');
    }

    if (!this.parishId || typeof this.parishId !== 'number') {
      errors.push('Valid parish ID is required');
    }

    if (!this.massSchedule || !(this.massSchedule instanceof Date) || isNaN(this.massSchedule.getTime())) {
      errors.push('Valid mass schedule date is required');
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  /**
   * Returns only allowed update fields
   */
  getAllowedUpdates(allowedFields) {
    const updateData = {};
    for (const field of allowedFields) {
      if (this[field] !== undefined) {
        updateData[field] = this[field];
      }
    }
    return updateData;
  }

  /**
   * Converts to plain object
   */
  toObject() {
    return {
      id: this.id,
      type: this.type,
      intentionDetails: this.intentionDetails,
      donorName: this.donorName,
      parishId: this.parishId,
      parishName: this.parishName,
      massSchedule: this.massSchedule,
      preferredTime: this.preferredTime,
      preferredPriest: this.preferredPriest,
      notes: this.notes,
      dateRequested: this.dateRequested,
      status: this.status,
      submittedBy: this.submittedBy,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }

  /**
   * Adds a note to the notes array
   * @param {string} author - 'parishioner' or 'admin'
   * @param {string} content - Note content
   * @param {number} authorId - User ID of the author
   */
  addNote(author, content, authorId) {
    if (!this.notes) this.notes = [];
    this.notes.push({
      author,
      content,
      authorId,
      timestamp: new Date().toISOString(),
    });
  }
}

module.exports = MassIntentionDTO;
