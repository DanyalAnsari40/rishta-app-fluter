import app from '../src/app';
import { connectDB } from '../src/config/db';
import { initCloudinary } from '../src/config/cloudinary';
import { initFirebase } from '../src/config/firebase';

// Initialize DB and integrations for the serverless function
// In serverless, this might be called per-request or container cold-start
let isInitialized = false;

if (!isInitialized) {
  connectDB();
  initCloudinary();
  initFirebase();
  isInitialized = true;
}

export default app;
