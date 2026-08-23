import { PrismaClient, User } from '@prisma/client';
import bcrypt from 'bcrypt';
import { RegisterInput } from '../validators/auth.validator';

const prisma = new PrismaClient();

// Role prefixes
const ROLE_PREFIX: Record<string, string> = {
    recipient: 'R',
    donor: 'D',
    'volunteer delivery partner': 'V',
    'ngo coordinator': 'N'
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

//login function
export const loginUser = async (email: string, password: string): Promise<User> => {
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

    // 3. Return user (you can later generate JWT here)
    return user;
};