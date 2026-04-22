/**
 * Dependency Injection Container
 * Wires together repositories, use cases, and services
 */

// Repositories
const MassIntentionRepository = require('../repositories/implementations/MassIntentionRepository');
const ParishRepository = require('../repositories/implementations/ParishRepository');
const UserRepository = require('../repositories/implementations/UserRepository');
const BookingRepository = require('../repositories/implementations/BookingRepository');
const TokenBlacklistRepository = require('../repositories/implementations/TokenBlacklistRepository');

// Services
const emailService = require('../services/emailService');
const TokenService = require('../services/implementations/TokenService');
const EmailServiceAdapter = require('../services/implementations/EmailServiceAdapter');

// Use Cases - Mass Intention
const CreateMassIntentionUseCase = require('../useCases/massIntention/CreateMassIntentionUseCase');
const GetAllMassIntentionsUseCase = require('../useCases/massIntention/GetAllMassIntentionsUseCase');
const GetMassIntentionByIdUseCase = require('../useCases/massIntention/GetMassIntentionByIdUseCase');
const UpdateMassIntentionUseCase = require('../useCases/massIntention/UpdateMassIntentionUseCase');
const DeleteMassIntentionUseCase = require('../useCases/massIntention/DeleteMassIntentionUseCase');
const ApproveMassIntentionUseCase = require('../useCases/massIntention/ApproveMassIntentionUseCase');
const DeclineMassIntentionUseCase = require('../useCases/massIntention/DeclineMassIntentionUseCase');
const UpdateMassIntentionStatusUseCase = require('../useCases/massIntention/UpdateMassIntentionStatusUseCase');

// Use Cases - Auth
const RegisterUserUseCase = require('../useCases/auth/RegisterUserUseCase');
const LoginUserUseCase = require('../useCases/auth/LoginUserUseCase');
const RefreshTokenUseCase = require('../useCases/auth/RefreshTokenUseCase');
const LogoutUserUseCase = require('../useCases/auth/LogoutUserUseCase');
const UpdateUserProfileUseCase = require('../useCases/auth/UpdateUserProfileUseCase');
const ChangePasswordUseCase = require('../useCases/auth/ChangePasswordUseCase');

// Use Cases - User
const GetAllUsersUseCase = require('../useCases/user/GetAllUsersUseCase');
const GetUserByIdUseCase = require('../useCases/user/GetUserByIdUseCase');
const CreateUserUseCase = require('../useCases/user/CreateUserUseCase');
const UpdateUserUseCase = require('../useCases/user/UpdateUserUseCase');
const DeleteUserUseCase = require('../useCases/user/DeleteUserUseCase');

// Use Cases - Booking
const CreateBookingUseCase = require('../useCases/booking/CreateBookingUseCase');
const GetAllBookingsUseCase = require('../useCases/booking/GetAllBookingsUseCase');
const GetBookingByIdUseCase = require('../useCases/booking/GetBookingByIdUseCase');
const UpdateBookingStatusUseCase = require('../useCases/booking/UpdateBookingStatusUseCase');

// Use Cases - Admin
const GetDashboardStatsUseCase = require('../useCases/admin/GetDashboardStatsUseCase');

/**
 * Container class for dependency injection
 */
class Container {
  constructor() {
    this._instances = {};
    this._initialized = false;
  }

  /**
   * Initializes all dependencies
   */
  initialize() {
    if (this._initialized) {
      return;
    }

    // ========== SERVICES ==========
    this._instances.tokenService = new TokenService();
    this._instances.emailService = new EmailServiceAdapter();

    // ========== REPOSITORIES ==========
    this._instances.massIntentionRepository = new MassIntentionRepository();
    this._instances.parishRepository = new ParishRepository();
    this._instances.userRepository = new UserRepository();
    this._instances.bookingRepository = new BookingRepository();
    this._instances.tokenBlacklistRepository = new TokenBlacklistRepository();

    // ========== USE CASES - MASS INTENTION ==========
    this._instances.createMassIntentionUseCase = new CreateMassIntentionUseCase(
      this._instances.massIntentionRepository,
      this._instances.parishRepository,
      this._instances.emailService
    );

    this._instances.getAllMassIntentionsUseCase = new GetAllMassIntentionsUseCase(
      this._instances.massIntentionRepository
    );

    this._instances.getMassIntentionByIdUseCase = new GetMassIntentionByIdUseCase(
      this._instances.massIntentionRepository
    );

    this._instances.updateMassIntentionUseCase = new UpdateMassIntentionUseCase(
      this._instances.massIntentionRepository
    );

    this._instances.deleteMassIntentionUseCase = new DeleteMassIntentionUseCase(
      this._instances.massIntentionRepository
    );

    this._instances.approveMassIntentionUseCase = new ApproveMassIntentionUseCase(
      this._instances.massIntentionRepository,
      this._instances.emailService
    );

    this._instances.declineMassIntentionUseCase = new DeclineMassIntentionUseCase(
      this._instances.massIntentionRepository,
      this._instances.emailService
    );

    this._instances.updateMassIntentionStatusUseCase = new UpdateMassIntentionStatusUseCase(
      this._instances.massIntentionRepository
    );

    // ========== USE CASES - AUTH ==========
    this._instances.registerUserUseCase = new RegisterUserUseCase(
      this._instances.userRepository,
      this._instances.tokenService,
      this._instances.emailService
    );

    this._instances.loginUserUseCase = new LoginUserUseCase(
      this._instances.userRepository,
      this._instances.tokenService
    );

    this._instances.refreshTokenUseCase = new RefreshTokenUseCase(
      this._instances.userRepository,
      this._instances.tokenService,
      this._instances.tokenBlacklistRepository
    );

    this._instances.logoutUserUseCase = new LogoutUserUseCase(
      this._instances.tokenBlacklistRepository
    );

    this._instances.updateUserProfileUseCase = new UpdateUserProfileUseCase(
      this._instances.userRepository
    );

    this._instances.changePasswordUseCase = new ChangePasswordUseCase(
      this._instances.userRepository,
      this._instances.emailService
    );

    // ========== USE CASES - USER ==========
    this._instances.getAllUsersUseCase = new GetAllUsersUseCase(
      this._instances.userRepository
    );

    this._instances.getUserByIdUseCase = new GetUserByIdUseCase(
      this._instances.userRepository
    );

    this._instances.createUserUseCase = new CreateUserUseCase(
      this._instances.userRepository,
      this._instances.tokenService
    );

    this._instances.updateUserUseCase = new UpdateUserUseCase(
      this._instances.userRepository
    );

    this._instances.deleteUserUseCase = new DeleteUserUseCase(
      this._instances.userRepository
    );

    // ========== USE CASES - BOOKING ==========
    this._instances.createBookingUseCase = new CreateBookingUseCase(
      this._instances.bookingRepository,
      this._instances.parishRepository,
      this._instances.emailService
    );

    this._instances.getAllBookingsUseCase = new GetAllBookingsUseCase(
      this._instances.bookingRepository
    );

    this._instances.getBookingByIdUseCase = new GetBookingByIdUseCase(
      this._instances.bookingRepository
    );

    this._instances.updateBookingStatusUseCase = new UpdateBookingStatusUseCase(
      this._instances.bookingRepository
    );

    // ========== USE CASES - ADMIN ==========
    this._instances.getDashboardStatsUseCase = new GetDashboardStatsUseCase(
      this._instances.bookingRepository,
      this._instances.parishRepository,
      this._instances.userRepository,
      this._instances.massIntentionRepository
    );

    this._initialized = true;
    console.log('✅ Dependency container initialized with', Object.keys(this._instances).length, 'services');
  }

  /**
   * Gets an instance from the container
   */
  get(name) {
    if (!this._initialized) {
      this.initialize();
    }

    if (!this._instances[name]) {
      throw new Error(`Dependency not found: ${name}`);
    }

    return this._instances[name];
  }

  /**
   * Registers a custom instance (for testing)
   */
  register(name, instance) {
    this._instances[name] = instance;
  }

  /**
   * Resets the container (for testing)
   */
  reset() {
    this._instances = {};
    this._initialized = false;
  }

  /**
   * Gets all registered service names
   */
  listServices() {
    if (!this._initialized) {
      this.initialize();
    }
    return Object.keys(this._instances);
  }
}

// Create singleton instance
const container = new Container();

module.exports = container;
