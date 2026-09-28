import bcrypt from 'bcryptjs';
import { connectDB } from '../config/db';
import { User } from '../models/user.model';
import { env } from '../config/env';
import { logger } from '../utils/logger';
import mongoose from 'mongoose';

const seedAdmin = async () => {
  try {
    await connectDB();

    const adminEmail = env.ADMIN_EMAIL;
    const adminPassword = env.ADMIN_PASSWORD;
    const isResetMode = process.argv.includes('--reset');

    if (!adminEmail || !adminPassword) {
      logger.error('❌ ADMIN_EMAIL and ADMIN_PASSWORD must be configured in .env before seeding.');
      process.exit(1);
    }

    const existingAdmin = await User.findOne({ email: adminEmail.toLowerCase() });

    if (existingAdmin) {
      if (isResetMode) {
        logger.info(`🔄 --reset flag detected. Updating password for admin: ${adminEmail}`);
        const hashedPassword = await bcrypt.hash(adminPassword, 12);
        existingAdmin.password = hashedPassword;
        existingAdmin.role = 'admin';
        existingAdmin.emailVerified = true;
        existingAdmin.status = 'active';
        existingAdmin.mustChangePassword = true;
        await existingAdmin.save();
        logger.info(`✅ Admin password successfully updated for ${adminEmail}`);
      } else {
        logger.info(`ℹ️ Admin user (${adminEmail}) already exists. Skipping seeding. Use --reset to reset credentials.`);
      }
    } else {
      const hashedPassword = await bcrypt.hash(adminPassword, 12);
      await User.create({
        email: adminEmail.toLowerCase(),
        password: hashedPassword,
        role: 'admin',
        emailVerified: true,
        status: 'active',
        mustChangePassword: true,
        profileCreatedFor: 'self',
      });

      logger.info(`🎉 Admin account successfully created!`);
      logger.info(`   Email: ${adminEmail}`);
      logger.info(`   Role: admin`);
      logger.info(`   Email Verified: true`);
      logger.info(`   Must Change Password: true`);
    }

    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    logger.error('❌ Error seeding admin user:', error);
    process.exit(1);
  }
};

seedAdmin();
