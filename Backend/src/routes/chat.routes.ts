import { Router } from 'express';
import { getConversations, getMessages, markMessagesRead, sendMessage, getOrCreateConversation } from '../controllers/chat.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.get('/conversations', getConversations);
router.post('/conversations/start', getOrCreateConversation);
router.get('/conversations/:conversationId/messages', getMessages);
router.put('/conversations/:conversationId/read', markMessagesRead);
router.post('/conversations/:conversationId/messages', sendMessage);

export default router;
