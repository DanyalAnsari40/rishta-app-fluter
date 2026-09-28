import mongoose, { Schema, Document } from 'mongoose';

export interface IShortlist extends Document {
  userId: mongoose.Types.ObjectId;
  targetUserId: mongoose.Types.ObjectId;
  createdAt: Date;
}

const shortlistSchema = new Schema<IShortlist>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    targetUserId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
  }
);

shortlistSchema.index({ userId: 1, targetUserId: 1 }, { unique: true });

export const Shortlist = mongoose.model<IShortlist>('Shortlist', shortlistSchema);
