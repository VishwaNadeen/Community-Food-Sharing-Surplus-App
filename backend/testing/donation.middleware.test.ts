import { describe, expect, it, vi } from 'vitest';
import { requireNgoCoordinator, requireRole } from '../src/middleware/auth.middleware';

describe('Role Authorization Middleware', () => {
    const createMockResponse = () => {
        const res: any = {
            locals: {},
            status: vi.fn().mockReturnThis(),
            json: vi.fn().mockReturnThis()
        };
        return res;
    };

    describe('requireNgoCoordinator', () => {
        it('allows access when user roleCode is N (NGO Coordinator)', () => {
            const req: any = {};
            const res = createMockResponse();
            res.locals.currentUser = {
                user: {
                    customUserId: 'N1',
                    email: 'ngo@example.com',
                    roleCode: 'N',
                    createdAt: new Date(),
                    updatedAt: new Date()
                }
            };
            const next = vi.fn();

            requireNgoCoordinator(req, res, next);

            expect(next).toHaveBeenCalled();
            expect(res.status).not.toHaveBeenCalled();
        });

        it('denies access with 403 when user roleCode is D (Donor)', () => {
            const req: any = {};
            const res = createMockResponse();
            res.locals.currentUser = {
                user: {
                    customUserId: 'D1',
                    email: 'donor@example.com',
                    roleCode: 'D',
                    createdAt: new Date(),
                    updatedAt: new Date()
                }
            };
            const next = vi.fn();

            requireNgoCoordinator(req, res, next);

            expect(next).not.toHaveBeenCalled();
            expect(res.status).toHaveBeenCalledWith(403);
            expect(res.json).toHaveBeenCalledWith({
                error: 'Access denied. Only NGO Coordinators can perform this action.'
            });
        });

        it('denies access with 403 when user roleCode is R (Recipient)', () => {
            const req: any = {};
            const res = createMockResponse();
            res.locals.currentUser = {
                user: {
                    customUserId: 'R1',
                    email: 'recipient@example.com',
                    roleCode: 'R',
                    createdAt: new Date(),
                    updatedAt: new Date()
                }
            };
            const next = vi.fn();

            requireNgoCoordinator(req, res, next);

            expect(next).not.toHaveBeenCalled();
            expect(res.status).toHaveBeenCalledWith(403);
            expect(res.json).toHaveBeenCalledWith({
                error: 'Access denied. Only NGO Coordinators can perform this action.'
            });
        });

        it('denies access with 403 when user roleCode is V (Volunteer Delivery Partner)', () => {
            const req: any = {};
            const res = createMockResponse();
            res.locals.currentUser = {
                user: {
                    customUserId: 'V1',
                    email: 'volunteer@example.com',
                    roleCode: 'V',
                    createdAt: new Date(),
                    updatedAt: new Date()
                }
            };
            const next = vi.fn();

            requireNgoCoordinator(req, res, next);

            expect(next).not.toHaveBeenCalled();
            expect(res.status).toHaveBeenCalledWith(403);
            expect(res.json).toHaveBeenCalledWith({
                error: 'Access denied. Only NGO Coordinators can perform this action.'
            });
        });

        it('returns 401 when currentUser is not present in res.locals', () => {
            const req: any = {};
            const res = createMockResponse();
            const next = vi.fn();

            requireNgoCoordinator(req, res, next);

            expect(next).not.toHaveBeenCalled();
            expect(res.status).toHaveBeenCalledWith(401);
            expect(res.json).toHaveBeenCalledWith({
                error: 'Authentication required'
            });
        });
    });

    describe('requireRole', () => {
        it('allows access when role matches one of allowed roles', () => {
            const req: any = {};
            const res = createMockResponse();
            res.locals.currentUser = {
                user: {
                    customUserId: 'N1',
                    email: 'ngo@example.com',
                    roleCode: 'N'
                }
            };
            const next = vi.fn();

            const middleware = requireRole('N', 'D');
            middleware(req, res, next);

            expect(next).toHaveBeenCalled();
        });

        it('denies access when role does not match allowed roles', () => {
            const req: any = {};
            const res = createMockResponse();
            res.locals.currentUser = {
                user: {
                    customUserId: 'R1',
                    email: 'recipient@example.com',
                    roleCode: 'R'
                }
            };
            const next = vi.fn();

            const middleware = requireRole('N');
            middleware(req, res, next);

            expect(next).not.toHaveBeenCalled();
            expect(res.status).toHaveBeenCalledWith(403);
            expect(res.json).toHaveBeenCalledWith({
                error: 'Access denied. You do not have permission to perform this action.'
            });
        });
    });
});
