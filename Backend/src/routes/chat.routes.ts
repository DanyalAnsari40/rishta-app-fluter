import { Router } from 'express';
import { getConversations, getMessages, markMessagesRead, sendMessage } from '../controllers/chat.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.get('/conversations', getConversations);
router.get('/conversations/:conversationId/messages', getMessages);
router.put('/conversations/:conversationId/read', markMessagesRead);
router.post('/conversations/:conversationId/messages', sendMessage);

export default router;
