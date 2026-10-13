
import { PrismaClient, User } from '@prisma/client';
import bcrypt from 'bcrypt';
import crypto from 'crypto';
import jwt, { JwtPayload, SignOptions } from 'jsonwebtoken';
import { StringValue } from 'ms';

import { RegisterInput } from '../validators/auth.validator';

import {
    sendVerificationEmail,
    sendPasswordResetEmail
} from './email.service';

const prisma = new PrismaClient();


// ====================== ROLE PREFIXES ======================

const ROLE_PREFIX: Record<string, string> = {
    recipient: 'R',
    donor: 'D',
    'volunteer delivery partner': 'V',
    'ngo coordinator': 'N'
};


// ====================== JWT UTILITIES ======================

const getJwtSecret = (): string => {
    const jwtSecret = process.env.JWT_SECRET;

    if (!jwtSecret) {
        throw new Error('JWT secret is not configured');
    }

    return jwtSecret;
};


const isJwtExpiryFormat = (value: string): value is StringValue => {
    return /^(\d+)(ms|s|m|h|d|w|y)?$/.test(value);
};


const getJwtExpiresIn = (): SignOptions['expiresIn'] => {
    const jwtExpiresIn = process.env.JWT_EXPIRES_IN;

    if (!jwtExpiresIn) {
        return '1h';
    }

    const asNumber = Number(jwtExpiresIn);

    if (Number.isInteger(asNumber) && asNumber > 0) {
        return asNumber;
    }

    if (isJwtExpiryFormat(jwtExpiresIn)) {
        return jwtExpiresIn;
    }

    throw new Error(
        'JWT_EXPIRES_IN is invalid. Use values like "1h", "30m", or a positive number.'
    );
};


// ====================== GENERATE CUSTOM USER ID ======================

const generateSequentialCustomUserId = async (
    rolePrefix: string
): Promise<string> => {

    const lastUser = await prisma.user.findFirst({
        where: {
            roleCode: rolePrefix
        },
        orderBy: {
            customUserId: 'desc'
        }
    });

    let nextNumber = 1;

    if (lastUser) {
        const lastId = lastUser.customUserId;
        const lastNumber = parseInt(lastId.slice(1), 10);

        nextNumber = lastNumber + 1;
    }

    return `${rolePrefix}${nextNumber}`;
};


// ====================== VERIFICATION CODE UTILITIES ======================

const hashVerificationCode = (code: string): string => {
    return crypto
        .createHash('sha256')
        .update(code)
        .digest('hex');
};


const generateVerificationCode = (): string => {
    return crypto.randomInt(100000, 1000000).toString();
};


const issueVerificationCode = async (
    email: string
): Promise<User> => {

    const verificationCode = generateVerificationCode();

    const verificationCodeHash =
        hashVerificationCode(verificationCode);

    const emailVerificationExpiresAt =
        new Date(Date.now() + 15 * 60 * 1000);

    const user = await prisma.user.update({
        where: {
            email
        },
        data: {
            emailVerificationCodeHash: verificationCodeHash,
            emailVerificationExpiresAt
        }
    });

    await sendVerificationEmail(
        email,
        verificationCode
    );

    return user;
};


// ====================== REGISTER ======================

export const registerUser = async (
    userData: Required<RegisterInput>
): Promise<User> => {

    const {
        email,
        password,
        role
    } = userData;

    const normalizedRole =
        String(role).trim().toLowerCase();

    const existingUser =
        await prisma.user.findUnique({
            where: {
                email
            }
        });

    if (existingUser) {
        throw new Error('Email is already registered');
    }

    const rolePrefix =
        ROLE_PREFIX[normalizedRole];

    if (!rolePrefix) {
        throw new Error(
            `Unsupported role: ${role}`
        );
    }

    const customUserId =
        await generateSequentialCustomUserId(
            rolePrefix
        );

    const hashedPassword =
        await bcrypt.hash(password, 10);

    const user = await prisma.user.create({
        data: {
            customUserId,
            email,
            password: hashedPassword,
            roleCode: rolePrefix,
            isEmailVerified: false
        }
    });

    try {
        await issueVerificationCode(email);
    } catch (error) {
        await prisma.user.delete({
            where: {
                email
            }
        });

        throw error;
    }

    return user;
};


// ====================== LOGIN ======================

export interface LoginResult {
    user: User;
    token: string;
    profileCompleted: boolean;
}


interface AuthTokenPayload extends JwtPayload {
    customUserId?: string;
    email?: string;
    roleCode?: string;
}


export const loginUser = async (
    email: string,
    password: string
): Promise<LoginResult> => {

    const user = await prisma.user.findUnique({
        where: {
            email
        }
    });

    if (!user) {
        throw new Error(
            'Invalid email or password'
        );
    }

    const isPasswordValid =
        await bcrypt.compare(
            password,
            user.password
        );

    if (!isPasswordValid) {
        throw new Error(
            'Invalid email or password'
        );
    }

    if (!user.isEmailVerified) {
        throw new Error(
            'Please verify your email first'
        );
    }

    // Keep the existing behavior for NGO and volunteer users.
    // Check whether the user's profile is completed.
    
    // Keep the existing behavior for NGO and volunteer users.
    let profileCompleted = true;

    if (user.roleCode === 'D') {
        const donorProfile = await prisma.donor.findUnique({
        where: {
            customUserId: user.customUserId,
        },
        });

        profileCompleted = donorProfile !== null;
    } else if (user.roleCode === 'R') {
        const recipientProfile = await prisma.recipient.findUnique({
        where: {
            customUserId: user.customUserId,
        },
        });

        profileCompleted = recipientProfile !== null;
    }

    const token = jwt.sign(
        {
            sub: user.id,
            customUserId: user.customUserId,
            email: user.email,
            roleCode: user.roleCode
        },
        getJwtSecret(),
        {
            expiresIn: getJwtExpiresIn()
        }
    );

    return {
        user,
        token,
        profileCompleted
    };
};


// ====================== EMAIL VERIFICATION ======================

export const verifyEmail = async (
    email: string,
    code: string
): Promise<User> => {

    const user = await prisma.user.findUnique({
        where: {
            email
        }
    });

    if (!user) {
        throw new Error('User not found');
    }

    if (user.isEmailVerified) {
        throw new Error(
            'Email is already verified'
        );
    }

    if (
        !user.emailVerificationCodeHash ||
        !user.emailVerificationExpiresAt
    ) {
        throw new Error(
            'Verification code is not available'
        );
    }

    if (
        user.emailVerificationExpiresAt.getTime() <
        Date.now()
    ) {
        throw new Error(
            'Verification code has expired'
        );
    }

    const codeHash =
        hashVerificationCode(code);

    if (
        codeHash !==
        user.emailVerificationCodeHash
    ) {
        throw new Error(
            'Invalid verification code'
        );
    }

    return prisma.user.update({
        where: {
            email
        },
        data: {
            isEmailVerified: true,
            emailVerificationCodeHash: null,
            emailVerificationExpiresAt: null
        }
    });
};


// ====================== RESEND VERIFICATION ======================

export const resendVerificationEmail = async (
    email: string
): Promise<User> => {

    const user = await prisma.user.findUnique({
        where: {
            email
        }
    });

    if (!user) {
        throw new Error('User not found');
    }

    if (user.isEmailVerified) {
        throw new Error(
            'Email is already verified'
        );
    }

    return issueVerificationCode(email);
};


// ====================== PASSWORD RESET ======================

export const requestPasswordReset = async (
    email: string
): Promise<void> => {

    const user = await prisma.user.findUnique({
        where: {
            email
        }
    });

    if (!user) {
        // Do not reveal whether the email exists.
        return;
    }

    if (!user.isEmailVerified) {
        throw new Error(
            'Please verify your email first'
        );
    }

    const resetCode =
        generateVerificationCode();

    const resetCodeHash =
        hashVerificationCode(resetCode);

    const passwordResetExpiresAt =
        new Date(Date.now() + 15 * 60 * 1000);

    await prisma.user.update({
        where: {
            email
        },
        data: {
            passwordResetCodeHash: resetCodeHash,
            passwordResetExpiresAt
        }
    });

    await sendPasswordResetEmail(
        email,
        resetCode
    );
};


export const resetPassword = async (
    email: string,
    code: string,
    newPassword: string
): Promise<User> => {

    const user = await prisma.user.findUnique({
        where: {
            email
        }
    });

    if (!user) {
        throw new Error('User not found');
    }

    if (
        !user.passwordResetCodeHash ||
        !user.passwordResetExpiresAt
    ) {
        throw new Error(
            'Password reset code is not available'
        );
    }

    if (
        user.passwordResetExpiresAt.getTime() <
        Date.now()
    ) {
        throw new Error(
            'Password reset code has expired'
        );
    }

    const codeHash =
        hashVerificationCode(code);

    if (
        codeHash !==
        user.passwordResetCodeHash
    ) {
        throw new Error(
            'Invalid password reset code'
        );
    }

    const hashedPassword =
        await bcrypt.hash(
            newPassword,
            10
        );

    return prisma.user.update({
        where: {
            email
        },
        data: {
            password: hashedPassword,
            passwordResetCodeHash: null,
            passwordResetExpiresAt: null
        }
    });
};


// ====================== CHANGE PASSWORD ======================

export const changePassword = async (
    userId: string,
    oldPassword: string,
    newPassword: string
): Promise<User> => {

    const user =
        await prisma.user.findUnique({
            where: {
                id: userId
            }
        });

    if (!user) {
        throw new Error('User not found');
    }

    const isOldPasswordValid =
        await bcrypt.compare(
            oldPassword,
            user.password
        );

    if (!isOldPasswordValid) {
        throw new Error(
            'Current password is incorrect'
        );
    }

    if (oldPassword === newPassword) {
        throw new Error(
            'New password must be different from the current password'
        );
    }

    const hashedPassword =
        await bcrypt.hash(
            newPassword,
            10
        );

    return prisma.user.update({
        where: {
            id: userId
        },
        data: {
            password: hashedPassword
        }
    });
};


// ====================== CURRENT USER ======================

export interface CurrentUserResult {
    user: Pick<
        User,
        | 'id'
        | 'customUserId'
        | 'email'
        | 'roleCode'
        | 'createdAt'
        | 'updatedAt'
    >;
}


export const getCurrentUserFromToken = async (
    token: string
): Promise<CurrentUserResult> => {

    const decoded = jwt.verify(
        token,
        getJwtSecret()
    );

    if (typeof decoded === 'string') {
        throw new Error(
            'Invalid token'
        );
    }

    const payload =
        decoded as AuthTokenPayload;

    const userId =
        payload.sub;

    if (
        typeof userId !== 'string' ||
        userId.length === 0
    ) {
        throw new Error(
            'Invalid token payload'
        );
    }

    const user =
        await prisma.user.findUnique({
            where: {
                id: userId
            }
        });

    if (!user) {
        throw new Error(
            'User not found'
        );
    }

    return {
        user: {
            id: user.id,
            customUserId: user.customUserId,
            email: user.email,
            roleCode: user.roleCode,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt
        }
    };
};
