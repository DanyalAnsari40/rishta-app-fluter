import mongoose, { Schema, Document } from 'mongoose';

export type UserRole = 'user' | 'admin';
export type UserStatus = 'active' | 'suspended' | 'deleted';
export type ProfileCreatedFor = 'self' | 'son' | 'daughter' | 'brother' | 'sister' | 'relative' | 'friend';

export interface IUser extends Document {
  email: string;
  password?: string;
  googleId?: string;
  phone?: string;
  profileCreatedFor: ProfileCreatedFor;
  role: UserRole;
  status: UserStatus;
  emailVerified: boolean;
  mustChangePassword?: boolean;
  lastActiveAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

const userSchema = new Schema<IUser>(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    password: {
      type: String,
      select: false,
    },
    googleId: {
      type: String,
      unique: true,
      sparse: true,
    },
    phone: {
      type: String,
      select: false, // Phone number is private and never exposed directly in public user queries
    },
    profileCreatedFor: {
      type: String,
      enum: ['self', 'son', 'daughter', 'brother', 'sister', 'relative', 'friend'],
      default: 'self',
    },
    role: {
      type: String,
      enum: ['user', 'admin'],
      default: 'user',
      index: true,
    },
    status: {
      type: String,
      enum: ['active', 'suspended', 'deleted'],
      default: 'active',
      index: true,
    },
    emailVerified: {
      type: Boolean,
      default: false,
    },
    mustChangePassword: {
      type: Boolean,
      default: false,
    },
    lastActiveAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform(doc, ret: any) {
        delete ret.password;
        delete ret.phone;
        delete ret.__v;
        return ret;
      },
    },
  }
);

export const User = mongoose.model<IUser>('User', userSchema);
