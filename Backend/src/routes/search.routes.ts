import { Router } from 'express';
import { getHomeFeed, searchProfiles } from '../controllers/search.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.get('/feed', getHomeFeed);
router.get('/', searchProfiles);

export default router;
