import { Router } from 'express';
import {
  sendInterest,
  acceptInterest,
  declineInterest,
  withdrawInterest,
  getInterests,
} from '../controllers/interest.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.post('/', sendInterest);
router.get('/', getInterests);
router.put('/:interestId/accept', acceptInterest);
router.put('/:interestId/decline', declineInterest);
router.delete('/:interestId/withdraw', withdrawInterest);

export default router;
