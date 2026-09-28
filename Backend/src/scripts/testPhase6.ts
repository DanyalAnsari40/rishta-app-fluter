import http from 'http';
import { io as ioClient } from 'socket.io-client';

function request(path: string, method: string, data: any, token?: string): Promise<any> {
  return new Promise((resolve, reject) => {
    const payload = data ? JSON.stringify(data) : '';
    const headers: any = {
      'Content-Type': 'application/json',
    };
    if (payload) {
      headers['Content-Length'] = Buffer.byteLength(payload);
    }
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(
      {
        hostname: 'localhost',
        port: 5000,
        path,
        method,
        headers,
      },
      (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          try {
            resolve({ status: res.statusCode, data: JSON.parse(body) });
          } catch (e) {
            resolve({ status: res.statusCode, body });
          }
        });
      }
    );
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

async function login(email: string, password: string) {
  const res = await request('/api/v1/auth/login', 'POST', { email, password });
  return {
    token: res.data.data.accessToken,
    userId: res.data.data.user.id,
  };
}

async function run() {
  console.log('--- TEST 1: Login Male User & Female Target ---');
  const user = await login('testuser@gmail.com', 'Password123!');
  const target = await login('ayesha.khan@gmail.com', 'Password123!');

  console.log('--- TEST 2: GET /api/v1/chat/conversations ---');
  const convRes = await request('/api/v1/chat/conversations', 'GET', null, user.token);
  console.log('Conversations Response:', JSON.stringify(convRes, null, 2));

  console.log('\n--- TEST 3: Realtime Socket.IO Chat Connection & Message Emission ---');
  const socketUser = ioClient('http://localhost:5000', {
    auth: { token: user.token },
    transports: ['websocket', 'polling'],
  });

  const socketTarget = ioClient('http://localhost:5000', {
    auth: { token: target.token },
    transports: ['websocket', 'polling'],
  });

  await new Promise((resolve) => setTimeout(resolve, 1000));

  socketTarget.on('message:new', (msg) => {
    console.log('🎯 Target received realtime message via Socket.IO:', msg);
  });

  socketUser.emit(
    'message:send',
    {
      receiverId: target.userId,
      text: 'Assalamu Alaikum! Nice to connect with you.',
    },
    (ack: any) => {
      console.log('Message send acknowledgment:', ack);
    }
  );

  await new Promise((resolve) => setTimeout(resolve, 2000));

  socketUser.disconnect();
  socketTarget.disconnect();

  console.log('\n--- TEST 4: GET Notifications List ---');
  const notifRes = await request('/api/v1/notifications', 'GET', null, target.token);
  console.log('Notifications Response:', JSON.stringify(notifRes, null, 2));

  process.exit(0);
}

run().catch(console.error);
