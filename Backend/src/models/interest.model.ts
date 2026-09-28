import mongoose, { Schema, Document } from 'mongoose';

export type InterestStatus = 'pending' | 'accepted' | 'declined' | 'withdrawn';

export interface IInterest extends Document {
  senderId: mongoose.Types.ObjectId;
  receiverId: mongoose.Types.ObjectId;
  status: InterestStatus;
  createdAt: Date;
  updatedAt: Date;
}

const interestSchema = new Schema<IInterest>(
  {
    senderId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    receiverId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'declined', 'withdrawn'],
      default: 'pending',
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

// Compound unique index to prevent duplicate interests between the same two users
interestSchema.index({ senderId: 1, receiverId: 1 }, { unique: true });

export const Interest = mongoose.model<IInterest>('Interest', interestSchema);
