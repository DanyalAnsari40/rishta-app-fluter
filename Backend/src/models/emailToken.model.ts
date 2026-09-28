import mongoose, { Schema, Document } from 'mongoose';

export type TokenType = 'verify_email' | 'reset_password';

export interface IEmailToken extends Document {
  userId: mongoose.Types.ObjectId;
  token: string;
  type: TokenType;
  expiresAt: Date;
  createdAt: Date;
}

const emailTokenSchema = new Schema<IEmailToken>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    token: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    type: {
      type: String,
      enum: ['verify_email', 'reset_password'],
      required: true,
    },
    expiresAt: {
      type: Date,
      required: true,
      expires: 0, // Mongoose TTL index automatically deletes expired documents
    },
  },
  {
    timestamps: true,
  }
);

export const EmailToken = mongoose.model<IEmailToken>('EmailToken', emailTokenSchema);
