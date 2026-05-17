/**
 * Sequelize Implementation of Mass Intention Repository
 */
const { MassIntention, User, Parish } = require('../../models');
const MassIntentionDTO = require('../../dto/MassIntentionDTO');

class MassIntentionRepository {
  /**
   * Creates a new mass intention
   */
  async create(dto) {
    const entity = await MassIntention.create({
      type: dto.type,
      intentionDetails: dto.intentionDetails,
      donorName: dto.donorName,
      parishId: dto.parishId,
      massSchedule: dto.massSchedule,
      preferredTime: dto.preferredTime,
      preferredPriest: dto.preferredPriest,
      notes: dto.notes,
      submittedBy: dto.submittedBy,
      dateRequested: dto.dateRequested,
    });

    return MassIntentionDTO.fromEntity(entity);
  }

  /**
   * Finds a mass intention by ID with optional includes
   */
  async findById(id, includes = []) {
    const entity = await MassIntention.findByPk(id, {
      include: includes.length > 0 ? includes : [
        { model: User, as: 'submitter', attributes: ['id', 'firstName', 'lastName', 'email'] },
        { model: Parish, as: 'parish', attributes: ['id', 'name', 'address'] },
      ],
    });

    return MassIntentionDTO.fromEntity(entity);
  }

  /**
   * Finds all mass intentions with pagination and filtering
   */
  async findAll(options = {}) {
    const {
      page = 1,
      limit = 10,
      filters = {},
      includes = [],
      orderBy = [['createdAt', 'DESC']],
    } = options;

    const offset = (page - 1) * limit;
    const whereClause = this._buildWhereClause(filters);

    const { count, rows } = await MassIntention.findAndCountAll({
      where: whereClause,
      limit,
      offset,
      order: orderBy,
      include: includes.length > 0 ? includes : [
        { model: User, as: 'submitter', attributes: ['id', 'firstName', 'lastName', 'email'] },
        { model: Parish, as: 'parish', attributes: ['id', 'name', 'address'] },
      ],
    });

    return {
      data: MassIntentionDTO.fromEntities(rows),
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(count / limit),
        totalItems: count,
        itemsPerPage: limit,
      },
    };
  }

  /**
   * Updates a mass intention
   */
  async update(id, data) {
    console.log('[MassIntentionRepository] Update data:', JSON.stringify(data));
    const entity = await MassIntention.findByPk(id);
    if (!entity) {
      throw new Error('Mass intention not found');
    }

    await entity.update(data);
    console.log('[MassIntentionRepository] After update, preferredTime:', entity.preferredTime);
    return MassIntentionDTO.fromEntity(entity);
  }

  /**
   * Deletes a mass intention
   */
  async delete(id) {
    const entity = await MassIntention.findByPk(id);
    if (!entity) {
      throw new Error('Mass intention not found');
    }

    await entity.destroy();
    return true;
  }

  /**
   * Updates the status of a mass intention
   */
  async updateStatus(id, status) {
    const entity = await MassIntention.findByPk(id);
    if (!entity) {
      throw new Error('Mass intention not found');
    }

    await entity.update({ status });
    return MassIntentionDTO.fromEntity(entity);
  }

  /**
   * Builds WHERE clause from filters
   */
  _buildWhereClause(filters) {
    const { Op } = require('sequelize');
    const where = {};

    if (filters.type) where.type = filters.type;
    if (filters.status) where.status = filters.status;
    if (filters.parishId) where.parishId = filters.parishId;
    if (filters.submittedBy) where.submittedBy = filters.submittedBy;

    // Date range filtering
    if (filters.startDate || filters.endDate) {
      where.dateRequested = {};
      if (filters.startDate) where.dateRequested[Op.gte] = filters.startDate;
      if (filters.endDate) where.dateRequested[Op.lte] = filters.endDate;
    }

    return where;
  }
}

module.exports = MassIntentionRepository;
