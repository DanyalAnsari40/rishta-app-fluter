import app from '../src/app';
import { connectDB } from '../src/config/db';
import { initCloudinary } from '../src/config/cloudinary';
import { initFirebase } from '../src/config/firebase';
import { Request, Response } from 'express';

// Cache the initialization promise so it only runs once per container
let initPromise: Promise<void> | null = null;

function initialize(): Promise<void> {
  if (!initPromise) {
    initPromise = (async () => {
      await connectDB();
      initCloudinary();
      initFirebase();
    })();
  }
  return initPromise;
}

// Wrap the Express app to ensure DB is connected before handling requests
export default async function handler(req: Request, res: Response) {
  await initialize();
  return app(req, res);
}
