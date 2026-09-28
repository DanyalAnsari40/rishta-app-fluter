import mongoose, { Schema, Document } from 'mongoose';

export type VerificationStatus = 'pending' | 'approved' | 'rejected';

export interface IVerificationRequest extends Document {
  userId: mongoose.Types.ObjectId;
  selfieUrl: string;
  idCardUrl: string;
  status: VerificationStatus;
  rejectionReason?: string;
  reviewedBy?: mongoose.Types.ObjectId;
  reviewedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const verificationRequestSchema = new Schema<IVerificationRequest>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    selfieUrl: {
      type: String,
      required: true,
    },
    idCardUrl: {
      type: String,
      required: true,
    },
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
      default: 'pending',
      index: true,
    },
    rejectionReason: {
      type: String,
    },
    reviewedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
    },
    reviewedAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

export const VerificationRequest = mongoose.model<IVerificationRequest>(
  'VerificationRequest',
  verificationRequestSchema
);
