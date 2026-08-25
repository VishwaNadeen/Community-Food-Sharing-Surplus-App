import { describe, expect, it } from 'vitest';
import { validateRegistrationInput } from '../src/validators/auth.validator';

describe('validateRegistrationInput', () => {
  it('accepts a valid registration payload', () => {
    const result = validateRegistrationInput({
      email: 'donor@example.com',
      password: 'StrongPass123',
      confirmPassword: 'StrongPass123',
      role: 'donor',
    });

    expect(result).toEqual([]);
  });

  it('returns errors for missing values', () => {
    const result = validateRegistrationInput({
      email: '',
      password: 'abc',
      confirmPassword: '',
      role: '',
    });

    expect(result).toContain('All fields are required.');
  });

  it('returns an error when password confirmation does not match', () => {
    const result = validateRegistrationInput({
      email: 'user@example.com',
      password: 'pass123',
      confirmPassword: 'pass456',
      role: 'recipient',
    });

    expect(result).toContain('Password and confirm password do not match.');
  });

  it('rejects an unsupported role', () => {
    const result = validateRegistrationInput({
      email: 'user@example.com',
      password: 'pass123',
      confirmPassword: 'pass123',
      role: 'admin',
    });

    expect(result).toContain('Invalid role selected.');
  });
});
