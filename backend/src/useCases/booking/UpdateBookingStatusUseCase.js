/**
 * Use Case: Update booking status
 */
class UpdateBookingStatusUseCase {
  constructor(bookingRepository) {
    this.bookingRepository = bookingRepository;
  }

  async execute(id, status, notes, user) {
    // Check role permission
    const allowedRoles = ['diocese_staff', 'diocese_admin', 'parish_admin', 'parish_staff', 'priest'];
    if (!allowedRoles.includes(user.role)) {
      throw new Error('Access denied: Only authorized personnel can update booking status');
    }

    // Validate status
    const validStatuses = ['pending', 'confirmed', 'cancelled', 'completed'];
    if (status && !validStatuses.includes(status)) {
      throw new Error(`Invalid status. Must be one of: ${validStatuses.join(', ')}`);
    }

    // Get booking
    const booking = await this.bookingRepository.findById(id);
    if (!booking) {
      throw new Error('Booking not found');
    }

    // Prepare update data
    const updateData = {};
    if (status) updateData.status = status;

    // Handle notes - append if provided
    if (notes !== undefined && notes !== null) {
      const existingNotes = booking.notes || [];
      // If notes is a string (legacy), convert to array with single entry
      // If notes is an array, append it
      const newNotesArray = Array.isArray(notes) ? notes : [{
        author: 'admin',
        content: notes,
        authorId: user.userId,
        timestamp: new Date().toISOString(),
      }];
      // Append new notes to existing notes
      updateData.notes = [...existingNotes, ...newNotesArray];
    }

    return await this.bookingRepository.update(id, updateData);
  }
}

module.exports = UpdateBookingStatusUseCase;
