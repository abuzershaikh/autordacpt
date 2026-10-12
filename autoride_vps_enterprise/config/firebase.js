import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { config } from './env.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let firebaseApp = null;
let firestoreDb = null;
let authInstance = null;
let isFirebaseReady = false;

export function initFirebase() {
  if (firebaseApp) return { app: firebaseApp, db: firestoreDb };

  try {
    const keyPath = path.isAbsolute(config.firebase.serviceAccountPath)
      ? config.firebase.serviceAccountPath
      : path.resolve(__dirname, 'serviceAccountKey.json');

    if (!fs.existsSync(keyPath)) {
      console.warn(`[Firebase] Service account file not found at: ${keyPath}`);
      return { app: null, db: null };
    }

    const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));

    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id || 'autoride-accept',
    });

    firestoreDb = admin.firestore();
    authInstance = admin.auth();
    isFirebaseReady = true;
    console.log(`✅ [Firebase Admin] Initialized with project ID: ${serviceAccount.project_id}`);
    return { app: firebaseApp, db: firestoreDb };
  } catch (error) {
    console.error('⚠️ [Firebase Admin] Initialization warning:', error.message);
    return { app: null, db: null };
  }
}

export function getFirestore() {
  if (!firestoreDb) {
    initFirebase();
  }
  return firestoreDb;
}

// Auto-init on load if file exists
initFirebase();

export const db = firestoreDb;
export const auth = authInstance;
export const firebaseReady = isFirebaseReady;
export { admin };
export default admin;
