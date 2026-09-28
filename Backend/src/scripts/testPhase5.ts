import http from 'http';
import mongoose from 'mongoose';

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
  await mongoose.connect('mongodb://127.0.0.1:27017/rishta_db');
  await mongoose.connection.collection('users').updateOne(
    { email: 'testuser@gmail.com' },
    { $set: { emailVerified: true } }
  );
  await mongoose.connection.close();

  console.log('--- TEST 1: Login Male User & Female Target ---');
  const user = await login('testuser@gmail.com', 'Password123!');
  const target = await login('ayesha.khan@gmail.com', 'Password123!');
  console.log(`Male User ID: ${user.userId}`);
  console.log(`Female Target ID: ${target.userId}`);

  console.log('\n--- TEST 2: Send Interest ---');
  const sendRes = await request('/api/v1/interests', 'POST', { targetUserId: target.userId }, user.token);
  console.log('Send Interest Response:', JSON.stringify(sendRes, null, 2));

  const interestId = sendRes.data.data._id;

  console.log('\n--- TEST 3: Accept Interest (by Female User) ---');
  const acceptRes = await request(`/api/v1/interests/${interestId}/accept`, 'PUT', null, target.token);
  console.log('Accept Interest Response:', JSON.stringify(acceptRes, null, 2));

  console.log('\n--- TEST 4: Get Accepted Interests List ---');
  const listRes = await request('/api/v1/interests?type=accepted', 'GET', null, user.token);
  console.log('Accepted List Response:', JSON.stringify(listRes, null, 2));

  console.log('\n--- TEST 5: Add to Shortlist ---');
  const shortlistRes = await request('/api/v1/shortlist', 'POST', { targetUserId: target.userId }, user.token);
  console.log('Shortlist Response:', JSON.stringify(shortlistRes, null, 2));

  console.log('\n--- TEST 6: Report User ---');
  const reportRes = await request(
    '/api/v1/safety/report',
    'POST',
    {
      targetUserId: target.userId,
      reason: 'spam',
      details: 'Automated test report for verification.',
    },
    user.token
  );
  console.log('Report Response:', JSON.stringify(reportRes, null, 2));

  process.exit(0);
}

run().catch(console.error);
