# Supabase Storage Setup Guide

This document provides instructions for setting up Supabase Storage for file uploads.

## Prerequisites

- A Supabase project (already in use for database)
- Access to Supabase dashboard with admin privileges

## Configuration Steps

### 1. Create a Storage Bucket

1. Go to your Supabase project dashboard: https://app.supabase.com
2. Navigate to **Storage** in the left sidebar
3. Click **Create a new bucket**
4. Configure the bucket:
   - **Name**: `documents` (or your preferred name, must match `SUPABASE_STORAGE_BUCKET` in .env)
   - **Public bucket**: Toggle **ON** (allows public read access to uploaded files)
   - **File size limit**: Set to your maximum (e.g., 5MB)
   - **Allowed MIME types**: Add `image/jpeg`, `image/png`, `application/pdf`
5. Click **Create bucket**

### 2. Set Up Storage Policies (if bucket is private)

If you prefer to keep the bucket private, you'll need to set up Row Level Security (RLS) policies:

```sql
-- Allow authenticated uploads
CREATE POLICY "Allow authenticated uploads" ON storage.objects
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow public read access
CREATE POLICY "Allow public read access" ON storage.objects
FOR SELECT USING (true);
```

However, for simplicity, making the bucket public is recommended for this use case.

### 3. Get Supabase Credentials

1. In Supabase dashboard, go to **Project Settings** (gear icon) → **API**
2. You'll find:
   - **Project URL**: e.g., `https://[your-project-ref].supabase.co`
   - **service_role key** (NOT the anon key) - this has admin privileges for server-side uploads

   > **Important**: Use the `service_role` key for server-side operations. Keep it secret!

3. Copy these values.

### 4. Update Backend .env File

Open `backend/.env.development` and update the Supabase configuration:

```bash
# Supabase Storage Configuration
SUPABASE_URL=https://your-actual-project-ref.supabase.co
SUPABASE_SERVICE_KEY=your-actual-service-role-key-here
SUPABASE_STORAGE_BUCKET=documents
```

Replace the placeholder values with your actual Supabase URL and service key.

### 5. Install Dependencies (Already Done)

The `@supabase/supabase-js` package has been installed. If you need to reinstall:

```bash
cd backend
npm install @supabase/supabase-js
```

### 6. Restart the Backend Server

After configuration changes, restart your backend:

```bash
cd backend
npm run dev
```

### 7. Test File Upload

1. Start the Flutter app (web or mobile)
2. Navigate to any booking form with file upload (e.g., Baptism booking)
3. Select a file (PDF, JPG, PNG)
4. Click upload
5. Verify:
   - Upload succeeds without errors
   - File appears in Supabase Storage bucket
   - Booking creation includes the file URL

## File Structure in Supabase

Files are organized as:
```
{userId}/{category}/{category}-{uuid}.{ext}
```

Example:
```
15/baptism/baptism-a1b2c3d4-e5f6-7890-abcd-ef1234567890.pdf
```

## Troubleshooting

### Error: "Supabase client not initialized"
- Check that `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` are correctly set in `.env`
- Ensure the backend server was restarted after changing `.env`

### Error: "Bucket not found"
- Verify the bucket name in `.env` matches the actual bucket name in Supabase
- Bucket names are case-sensitive

### Upload fails with permission error
- Ensure the bucket is public OR RLS policies are correctly set
- For private buckets, the service_role key should have bypass RLS capability

### Files not showing in frontend
- Check that the returned `url` field is being used correctly
- The URL is a full Supabase public URL, not a relative path

## Migration from Local Filesystem

Previously, files were stored in `backend/uploads/documents/`. With this change:
- New uploads go to Supabase Storage
- Existing local files remain on the server (back them up if needed)
- To migrate existing files to Supabase, you would need to manually upload them

## Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `SUPABASE_URL` | Your Supabase project URL | `https://abc123.supabase.co` |
| `SUPABASE_SERVICE_KEY` | Service role API key (secret) | `eyJhbGciOiJIUzI1NiIs...` |
| `SUPABASE_STORAGE_BUCKET` | Storage bucket name | `documents` |
