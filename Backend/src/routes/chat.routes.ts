import { Router } from 'express';
import { getConversations, getMessages, markMessagesRead } from '../controllers/chat.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.get('/conversations', getConversations);
router.get('/conversations/:conversationId/messages', getMessages);
router.put('/conversations/:conversationId/read', markMessagesRead);

export default router;
