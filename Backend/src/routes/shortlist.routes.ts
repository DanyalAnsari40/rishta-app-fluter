import { Router } from 'express';
import { addShortlist, removeShortlist, getShortlist } from '../controllers/shortlist.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.post('/', addShortlist);
router.get('/', getShortlist);
router.delete('/:targetUserId', removeShortlist);

export default router;
