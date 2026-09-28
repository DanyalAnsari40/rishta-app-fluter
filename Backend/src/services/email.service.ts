import nodemailer from 'nodemailer';
import { env } from '../config/env';
import { logger } from '../utils/logger';

export class EmailService {
  private static transporter = nodemailer.createTransport({
    host: env.SMTP_HOST || 'smtp.mailtrap.io',
    port: env.SMTP_PORT || 2525,
    secure: env.SMTP_PORT === 465,
    auth:
      env.SMTP_USER && env.SMTP_PASS
        ? {
            user: env.SMTP_USER,
            pass: env.SMTP_PASS,
          }
        : undefined,
  });

  /**
   * Sends an email verification link to the user.
   */
  static async sendVerificationEmail(email: string, token: string): Promise<boolean> {
    const verifyUrl = `${env.CLIENT_URL}/api/v1/auth/verify-email?token=${token}`;
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
        <h2 style="color: #F2457B; text-align: center;">Welcome to Rishta App!</h2>
        <p>Assalamu Alaikum / Hello,</p>
        <p>Thank you for signing up. Please verify your email address to activate your profile and start searching for compatible life partners.</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${verifyUrl}" style="background-color: #F2457B; color: #ffffff; padding: 12px 30px; text-decoration: none; border-radius: 25px; font-weight: bold; display: inline-block;">Verify Email Address</a>
        </div>
        <p>Or copy and paste this link into your browser:</p>
        <p style="word-break: break-all; color: #555555;">${verifyUrl}</p>
        <p style="color: #888888; font-size: 12px; margin-top: 30px; text-align: center;">If you did not create an account on Rishta App, please ignore this email.</p>
      </div>
    `;

    return this.sendMail(email, 'Verify your email address - Rishta App', html);
  }

  /**
   * Sends a password reset link to the user.
   */
  static async sendPasswordResetEmail(email: string, token: string): Promise<boolean> {
    const resetUrl = `${env.CLIENT_URL}/reset-password?token=${token}`;
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
        <h2 style="color: #F2457B; text-align: center;">Reset Your Password</h2>
        <p>Assalamu Alaikum / Hello,</p>
        <p>We received a request to reset your password for your Rishta App account. Click the button below to set a new password:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${resetUrl}" style="background-color: #F2457B; color: #ffffff; padding: 12px 30px; text-decoration: none; border-radius: 25px; font-weight: bold; display: inline-block;">Reset Password</a>
        </div>
        <p>Or copy and paste this link into your browser:</p>
        <p style="word-break: break-all; color: #555555;">${resetUrl}</p>
        <p style="color: #888888; font-size: 12px; margin-top: 30px; text-align: center;">This link will expire in 1 hour. If you didn't request a password reset, you can safely ignore this email.</p>
      </div>
    `;

    return this.sendMail(email, 'Reset your password - Rishta App', html);
  }

  private static async sendMail(to: string, subject: string, html: string): Promise<boolean> {
    try {
      if (!env.SMTP_USER) {
        logger.info(`[MOCK EMAIL LOG] To: ${to} | Subject: ${subject}`);
        logger.info(`[MOCK EMAIL CONTENT]\n${html}`);
        return true;
      }

      await this.transporter.sendMail({
        from: `"${env.FROM_NAME}" <${env.FROM_EMAIL}>`,
        to,
        subject,
        html,
      });

      logger.info(`📧 Email sent successfully to ${to}`);
      return true;
    } catch (error) {
      logger.error(`❌ Failed to send email to ${to}:`, error);
      return false;
    }
  }
}
