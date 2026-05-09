const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env.development') });
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
const bucketName = process.env.SUPABASE_STORAGE_BUCKET || 'documents';

console.log('Supabase Config:', {
  url: supabaseUrl ? 'set' : 'MISSING',
  bucket: bucketName,
  keyPrefix: supabaseServiceKey ? supabaseServiceKey.substring(0, 15) + '...' : 'MISSING'
});

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('ERROR: Missing Supabase credentials');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: { autoRefreshToken: false, persistSession: false }
});

// Create a test file
const testFilePath = path.join(__dirname, 'uploads', 'temp', 'test-upload.txt');
fs.writeFileSync(testFilePath, 'Test content for upload');
const fileBuffer = fs.readFileSync(testFilePath);

console.log('\nTest file created:', testFilePath);
console.log('File size:', fileBuffer.length, 'bytes');

// Test upload
const testPath = `test-user/test-category/test-${Date.now()}.txt`;
console.log('\nAttempting upload to:', `${bucketName}/${testPath}`);

supabase.storage
  .from(bucketName)
  .upload(testPath, fileBuffer, {
    contentType: 'text/plain',
    upsert: false,
    cacheControl: '3600',
  })
  .then(({ data, error }) => {
    if (error) {
      console.error('\n❌ Upload failed:');
      console.error('   Message:', error.message);
      console.error('   Name:', error.name);
      console.error('   Status:', error.statusCode, error.statusText);
      console.error('   Full error:', JSON.stringify(error, null, 2));
    } else {
      console.log('\n✅ Upload successful:', data);
    }
    
    // Cleanup
    fs.unlinkSync(testFilePath);
    console.log('\nTest file cleaned up');
  })
  .catch(err => {
    console.error('\n❌ Unexpected error:', err);
    fs.unlinkSync(testFilePath);
  });
