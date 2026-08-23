export interface RegisterInput {
    email?: string;
    password?: string;
    confirmPassword?: string;
    role?: string;
}

export const validateRegistrationInput = (data: RegisterInput): string[] => {
    const { email, password, confirmPassword, role } = data;
    const errors: string[] = [];

    if (!email || !password || !confirmPassword || !role) {
        errors.push("All fields are required.");
    }

    if (password !== confirmPassword) {
        errors.push("Password and confirm password do not match.");
    }

    const validRoles = ['recipient', 'donor', 'volunteer delivery partner', 'ngo coordinator'];
    if (role && !validRoles.includes(role.toLowerCase())) {
        errors.push("Invalid role selected.");
    }

    return errors;
};