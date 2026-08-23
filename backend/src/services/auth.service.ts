import { PrismaClient, User } from '@prisma/client';
import bcrypt from 'bcrypt';
import jwt, { JwtPayload, SignOptions } from 'jsonwebtoken';
import { StringValue } from 'ms';
import { RegisterInput } from '../validators/auth.validator';

const prisma = new PrismaClient();

// Role prefixes
const ROLE_PREFIX: Record<string, string> = {
    recipient: 'R',
    donor: 'D',
    'volunteer delivery partner': 'V',
    'ngo coordinator': 'N'
};

// Utility functions for JWT
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

// Get JWT expiration time
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

    throw new Error('JWT_EXPIRES_IN is invalid. Use values like "1h", "30m", or a positive number.');
};

// Generate sequential customUserId
const generateSequentialCustomUserId = async (rolePrefix: string): Promise<string> => {
    const lastUser = await prisma.user.findFirst({
        where: { roleCode: rolePrefix },
        orderBy: { customUserId: 'desc' }
    });

    let nextNumber = 1;
    if (lastUser) {
        const lastId = lastUser.customUserId; // e.g. "D25"
        const lastNumber = parseInt(lastId.slice(1), 10);
        nextNumber = lastNumber + 1;
    }

    return `${rolePrefix}${nextNumber}`;
};

// Register function
export const registerUser = async (userData: Required<RegisterInput>): Promise<User> => {
    const { email, password, role } = userData;
    const normalizedRole = String(role).trim().toLowerCase();

    // 1. Check if email already exists
    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
        throw new Error('Email is already registered');
    }

    // 2. Map role to prefix
    const rolePrefix = ROLE_PREFIX[normalizedRole];
    if (!rolePrefix) {
        throw new Error(`Unsupported role: ${role}`);
    }

    // 3. Generate sequential customUserId
    const customUserId = await generateSequentialCustomUserId(rolePrefix);

    // 4. Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);

    // 5. Save to database (only core fields)
    return prisma.user.create({
        data: {
            customUserId,
            email,
            password: hashedPassword,
            roleCode: rolePrefix
        },
    });
};

export interface LoginResult {
    user: User;
    token: string;
}

interface AuthTokenPayload extends JwtPayload {
    customUserId?: string;
    email?: string;
    roleCode?: string;
}

//login function
export const loginUser = async (email: string, password: string): Promise<LoginResult> => {
    // 1. Find user by email
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
        throw new Error('Invalid email or password');
    }

    // 2. Compare password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
        throw new Error('Invalid email or password');
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

    return { user, token };
};

export interface CurrentUserResult {
    user: Pick<User, 'customUserId' | 'email' | 'roleCode' | 'createdAt' | 'updatedAt'>;
}

// Get current user from token
export const getCurrentUserFromToken = async (token: string): Promise<CurrentUserResult> => {
    const decoded = jwt.verify(token, getJwtSecret());
    if (typeof decoded === 'string') {
        throw new Error('Invalid token');
    }

    const payload = decoded as AuthTokenPayload;
    const userId = payload.sub;
    if (typeof userId !== 'string' || userId.length === 0) {
        throw new Error('Invalid token payload');
    }

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
        throw new Error('User not found');
    }

    return {
        user: {
            customUserId: user.customUserId,
            email: user.email,
            roleCode: user.roleCode,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt
        }
    };
};