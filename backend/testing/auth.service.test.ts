import { beforeEach, describe, expect, it, vi } from 'vitest';

const prismaMocks = vi.hoisted(() => ({
  findUnique: vi.fn(),
  findFirst: vi.fn(),
  create: vi.fn(),
  delete: vi.fn(),
  update: vi.fn(),
  recipientFindUnique: vi.fn(),
}));

const bcryptMocks = vi.hoisted(() => ({
  hash: vi.fn(),
  compare: vi.fn(),
}));

const jwtMocks = vi.hoisted(() => ({
  sign: vi.fn(),
  verify: vi.fn(),
}));

vi.mock('../src/services/email.service', () => ({
  sendVerificationEmail: vi.fn().mockResolvedValue(true),
  sendPasswordResetEmail: vi.fn().mockResolvedValue(true),
}));

vi.mock('@prisma/client', () => ({
  PrismaClient: vi.fn().mockImplementation(() => ({
    user: {
      findUnique: prismaMocks.findUnique,
      findFirst: prismaMocks.findFirst,
      create: prismaMocks.create,
      delete: prismaMocks.delete,
      update: prismaMocks.update,
    },
    recipient: {
      findUnique: prismaMocks.recipientFindUnique,
    },
  })),
}));

vi.mock('bcrypt', () => ({
  default: {
    hash: bcryptMocks.hash,
    compare: bcryptMocks.compare,
  },
}));

vi.mock('jsonwebtoken', () => ({
  default: {
    sign: jwtMocks.sign,
    verify: jwtMocks.verify,
  },
  __esModule: true,
}));

import { getCurrentUserFromToken, loginUser, registerUser } from '../src/services/auth.service';

describe('auth service', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    process.env.JWT_SECRET = 'test-secret';
    process.env.JWT_EXPIRES_IN = '1h';
  });

  it('registers a donor user with a generated customUserId', async () => {
    prismaMocks.findUnique.mockResolvedValue(null);
    prismaMocks.findFirst.mockResolvedValue(null);
    bcryptMocks.hash.mockResolvedValue('hashed-password');
    prismaMocks.create.mockResolvedValue({
      id: 'user-1',
      customUserId: 'D1',
      email: 'donor@example.com',
      password: 'hashed-password',
      roleCode: 'D',
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    prismaMocks.update.mockResolvedValue({
      id: 'user-1',
      customUserId: 'D1',
      email: 'donor@example.com',
      password: 'hashed-password',
      roleCode: 'D',
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const result = await registerUser({
      email: 'donor@example.com',
      password: 'StrongPass123',
      confirmPassword: 'StrongPass123',
      role: 'donor',
    });

    expect(prismaMocks.findUnique).toHaveBeenCalledWith({ where: { email: 'donor@example.com' } });
    expect(prismaMocks.create).toHaveBeenCalledWith({
      data: {
        customUserId: 'D1',
        email: 'donor@example.com',
        password: 'hashed-password',
        roleCode: 'D',
        isEmailVerified: false,
      },
    });
    expect(result.email).toBe('donor@example.com');
  });

  it('logs in a user and returns a token', async () => {
    const user = {
      id: 'user-123',
      customUserId: 'R1',
      email: 'recipient@example.com',
      password: 'hashed-password',
      roleCode: 'R',
      isEmailVerified: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    prismaMocks.findUnique.mockResolvedValue(user);
    prismaMocks.recipientFindUnique.mockResolvedValue(null);
    bcryptMocks.compare.mockResolvedValue(true);
    jwtMocks.sign.mockReturnValue('signed-token');

    const result = await loginUser('recipient@example.com', 'StrongPass123');

    expect(bcryptMocks.compare).toHaveBeenCalledWith('StrongPass123', 'hashed-password');
    expect(jwtMocks.sign).toHaveBeenCalledWith(
      {
        sub: 'user-123',
        customUserId: 'R1',
        email: 'recipient@example.com',
        roleCode: 'R',
      },
      'test-secret',
      { expiresIn: '1h' }
    );
    expect(result.token).toBe('signed-token');
    expect(result.user.email).toBe('recipient@example.com');
  });

  it('returns the current user from a valid token', async () => {
    const user = {
      id: 'user-123',
      customUserId: 'R1',
      email: 'recipient@example.com',
      password: 'hashed-password',
      roleCode: 'R',
      createdAt: new Date('2024-01-01T00:00:00Z'),
      updatedAt: new Date('2024-01-02T00:00:00Z'),
    };

    jwtMocks.verify.mockReturnValue({
      sub: 'user-123',
      customUserId: 'R1',
      email: 'recipient@example.com',
      roleCode: 'R',
    });
    prismaMocks.findUnique.mockResolvedValue(user);

    const result = await getCurrentUserFromToken('valid-token');

    expect(jwtMocks.verify).toHaveBeenCalledWith('valid-token', 'test-secret');
    expect(result.user.email).toBe('recipient@example.com');
    expect(result.user.customUserId).toBe('R1');
  });
});
