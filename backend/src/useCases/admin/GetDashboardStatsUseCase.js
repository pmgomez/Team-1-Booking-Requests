/**
 * Use Case: Get dashboard statistics
 */
class GetDashboardStatsUseCase {
  constructor(bookingRepository, parishRepository, userRepository, massIntentionRepository) {
    this.bookingRepository = bookingRepository;
    this.parishRepository = parishRepository;
    this.userRepository = userRepository;
    this.massIntentionRepository = massIntentionRepository;
  }

  async execute(user, filters = {}) {
    // Build where clause based on user role
    const parishWhereClause = this._getParishWhereClause(user, filters);
    const bookingWhereClause = this._getBookingWhereClause(user, filters);
    const userWhereClause = this._getUserWhereClause(user, filters);

    // Get counts
    const totalParishes = await this.parishRepository.count(parishWhereClause);
    const totalUsers = await this.userRepository.count(userWhereClause);
    const totalBookings = await this.bookingRepository.count(bookingWhereClause);
    const pendingBookings = await this.bookingRepository.count({ ...bookingWhereClause, status: 'pending' });
    const confirmedBookings = await this.bookingRepository.count({ ...bookingWhereClause, status: 'confirmed' });

    // Get bookings by status and type
    const bookingsByStatus = await this.bookingRepository.countByStatus(bookingWhereClause);
    const bookingsByType = await this.bookingRepository.countByType(bookingWhereClause);

    return {
      summary: {
        totalParishes,
        totalUsers,
        totalBookings,
        pendingBookings,
        confirmedBookings,
      },
      bookingsByStatus,
      bookingsByType,
    };
  }

  _getParishWhereClause(user, filters) {
    // Parish-level users: restrict to their assigned parish
    if (user.role === 'parish_admin' || user.role === 'parish_staff') {
      return { id: user.assignedParishId };
    }
    // Diocese-level users: can filter by specific parish or see all
    if (filters.parishId && (user.role === 'diocese_admin' || user.role === 'diocese_staff')) {
      return { id: filters.parishId };
    }
    return {};
  }

  _getBookingWhereClause(user, filters) {
    // Parish-level users: restrict to their assigned parish
    if (user.role === 'parish_admin' || user.role === 'parish_staff') {
      return { parishId: user.assignedParishId };
    }
    // Diocese-level users: can filter by specific parish or see all
    if (filters.parishId && (user.role === 'diocese_admin' || user.role === 'diocese_staff')) {
      return { parishId: filters.parishId };
    }
    return {};
  }

  _getUserWhereClause(user, filters) {
    // Parish-level users: restrict to their assigned parish
    if (user.role === 'parish_admin' || user.role === 'parish_staff') {
      return { assignedParishId: user.assignedParishId };
    }
    // Diocese-level users: can filter by specific parish or see all
    if (filters.parishId && (user.role === 'diocese_admin' || user.role === 'diocese_staff')) {
      return { assignedParishId: filters.parishId };
    }
    return {};
  }
}

module.exports = GetDashboardStatsUseCase;
