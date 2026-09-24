import {beforeEach, describe, expect, it, vi} from 'vitest';

const {serviceMock} = vi.hoisted(() => ({
    serviceMock: {
        getVolunteerDeliveries: vi.fn(),
        getVolunteerDashboardStats: vi.fn(),
        getOptimizedDeliveryRoute: vi.fn()
    }
}));

vi.mock('../src/services/volunteerDelivery.service', () => ({
    ...serviceMock,
    updateVolunteerAvailability: vi.fn(),
    getVolunteerAvailability: vi.fn(),
    getDeliveryById: vi.fn(),
    acceptDelivery: vi.fn(),
    rejectDelivery: vi.fn(),
    updateDeliveryStatus: vi.fn(),
    updateVolunteerLocation: vi.fn(),
    getDeliveryTracking: vi.fn(),
    reportDeliveryProblem: vi.fn(),
    getDeliveryProblems: vi.fn()
}));

import {
    getDashboardHandler,
    getMyDeliveriesHandler,
    getOptimizedRouteHandler
} from '../src/controllers/volunteerDelivery.controller';

const response = () => ({
    status: vi.fn().mockReturnThis(),
    json: vi.fn().mockReturnThis()
});

const request = (query: Record<string, unknown> = {}) => ({query});
const authResponse = () => Object.assign(response(), {
    locals: {currentUser: {user: {customUserId: 'volunteer-1'}}}
});

describe('volunteer delivery controllers', () => {
    beforeEach(() => vi.clearAllMocks());

    it('returns filtered deliveries and count', async () => {
        serviceMock.getVolunteerDeliveries.mockResolvedValue([{id: 'delivery-1'}]);
        const res = authResponse();

        await getMyDeliveriesHandler(request({status: 'PENDING_ASSIGNMENT'}) as any, res as any);

        expect(serviceMock.getVolunteerDeliveries).toHaveBeenCalledWith(
            'volunteer-1', {status: 'PENDING_ASSIGNMENT'}
        );
        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({count: 1, deliveries: [{id: 'delivery-1'}]});
    });

    it('rejects invalid delivery filters before calling the service', async () => {
        const res = authResponse();

        await getMyDeliveriesHandler(request({status: 'INVALID'}) as any, res as any);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(serviceMock.getVolunteerDeliveries).not.toHaveBeenCalled();
    });

    it('returns optimized route data', async () => {
        serviceMock.getOptimizedDeliveryRoute.mockResolvedValue({
            route: [{id: 'delivery-1'}], totalDistanceKm: 3.2, googleMapsUrl: 'https://maps.test'
        });
        const res = authResponse();

        await getOptimizedRouteHandler({} as any, res as any);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({
            count: 1,
            route: [{id: 'delivery-1'}],
            totalDistanceKm: 3.2,
            googleMapsUrl: 'https://maps.test'
        });
    });

    it('returns dashboard metrics', async () => {
        serviceMock.getVolunteerDashboardStats.mockResolvedValue({
            completedDeliveries: 2, communityImpactScore: 25
        });
        const res = authResponse();

        await getDashboardHandler({} as any, res as any);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({dashboard: {
            completedDeliveries: 2, communityImpactScore: 25
        }});
    });
});
