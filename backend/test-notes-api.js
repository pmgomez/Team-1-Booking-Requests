const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';
let authToken = null;

async function testAuth() {
  try {
    const response = await axios.post(`${BASE_URL}/auth/login`, {
      email: 'admin@diocese-kalookan.com',
      password: 'SuperAdmin2026!Secure'
    });
    authToken = response.data.accessToken;
    console.log('✅ Login successful');
    return authToken;
  } catch (error) {
    console.error('❌ Login failed:', error.response?.data || error.message);
    process.exit(1);
  }
}

async function testCreateReconciliationWithNotes(token) {
  try {
    // Use a date far in the future that's not a holiday
    const notes = [
      {
        author: 'parishioner',
        content: 'Test note from parishioner',
        authorId: 1,
        timestamp: new Date().toISOString()
      }
    ];

    const response = await axios.post(
      `${BASE_URL}/sacraments/reconciliations`,
      {
        parishId: 1,
        penitentName: 'Test Penitent',
        contactEmail: 'test@example.com',
        contactPhone: '1234567890',
        preferredDate: '2026-01-15',
        preferredTimeSlot: '10:00',
        notes: notes
      },
      {
        headers: { Authorization: `Bearer ${token}` }
      }
    );

    console.log('✅ Create reconciliation with notes successful');
    console.log('   Booking ID:', response.data.booking.id);
    console.log('   Notes:', JSON.stringify(response.data.booking.notes, null, 2));
    return response.data.booking.id;
  } catch (error) {
    console.error('❌ Create reconciliation failed:', error.response?.data || error.message);
    throw error;
  }
}

async function testUpdateReconciliationWithNotes(token, bookingId) {
  try {
    const newNotes = [
      {
        author: 'admin',
        content: 'Admin note added during update',
        authorId: 1,
        timestamp: new Date().toISOString()
      }
    ];

    const response = await axios.put(
      `${BASE_URL}/sacraments/reconciliations/${bookingId}`,
      {
        penitentName: 'Updated Penitent Name',
        contactEmail: 'updated@example.com',
        contactPhone: '0987654321',
        preferredDate: '2026-01-16',
        preferredTimeSlot: '14:00',
        notes: newNotes
      },
      {
        headers: { Authorization: `Bearer ${token}` }
      }
    );

    console.log('✅ Update reconciliation with notes successful');
    console.log('   Notes:', JSON.stringify(response.data.booking.notes, null, 2));
  } catch (error) {
    console.error('❌ Update reconciliation failed:', error.response?.data || error.message);
    throw error;
  }
}

async function testGetReconciliation(token, bookingId) {
  try {
    const response = await axios.get(
      `${BASE_URL}/sacraments/reconciliations/${bookingId}`,
      {
        headers: { Authorization: `Bearer ${token}` }
      }
    );

    console.log('✅ Get reconciliation successful');
    console.log('   Notes from GET:', JSON.stringify(response.data.booking.notes, null, 2));
  } catch (error) {
    console.error('❌ Get reconciliation failed:', error.response?.data || error.message);
  }
}

async function runTests() {
  console.log('🚀 Starting API tests for notes migration...\n');

  try {
    const token = await testAuth();
    console.log('');

    const bookingId = await testCreateReconciliationWithNotes(token);
    console.log('');

    await testUpdateReconciliationWithNotes(token, bookingId);
    console.log('');

    await testGetReconciliation(token, bookingId);
    console.log('');

    console.log('🎉 All API tests passed!');
  } catch (error) {
    console.error('❌ Tests failed:', error.message);
    process.exit(1);
  }
}

runTests();
