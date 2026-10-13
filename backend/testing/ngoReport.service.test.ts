import { describe, expect, it, vi } from 'vitest';

vi.mock('@prisma/client', async () => {
    const actual = await vi.importActual<typeof import('@prisma/client')>('@prisma/client');
    return { ...actual, PrismaClient: vi.fn(() => ({})) };
});

import { createImpactReport, reportToCsv, reportToPdf } from '../src/services/ngoReport.service';

const impact = {
    donationStatistics: {
        total: 3,
        approved: 1,
        completedDeliveryRecords: 1,
        byStatus: { PENDING: 1, APPROVED: 2 },
        quantityByUnit: { KG: 5 }
    },
    summary: {
        totalDonations: 3,
        approvedDonations: 2,
        totalRequests: 4,
        approvedRequests: 2,
        suitableMatches: 2,
        acceptedMatches: 1,
        donatedQuantityByUnit: { KG: 5.5 },
        foodWastePreventedByUnit: { KG: 4 },
        mealsDelivered: 8,
        activeVolunteers: 1,
        completedDeliveries: 1
    },
    monthlyImpact: [{ month: 'Oct', donations: 3, requests: 4 }],
    donationsByCategory: [{ category: '=HYPERLINK("x")', count: 2 }, { category: 'Rice, cooked', count: 1 }],
    dataAvailability: {
        deliveryMetricsAvailable: true,
        volunteerMetricsAvailable: true,
        note: 'Meal total is estimated using 0.5 kg per meal.'
    }
};

const volunteers = {
    totalVolunteers: 2,
    availableVolunteers: 1,
    totalAssignedDeliveries: 3,
    completedDeliveries: 1,
    activeDeliveries: 1,
    deliveryStatusCounts: {},
    volunteers: [{
        volunteerId: 'V-1',
        totalDeliveries: 3,
        completedDeliveries: 1,
        activeDeliveries: 1,
        lastDeliveredAt: null
    }]
};

describe('community impact report', () => {
    const report = createImpactReport(impact, volunteers, new Date('2026-10-11T00:00:00.000Z'));

    it('builds the defined report sections', () => {
        expect(report.title).toBe('Community Impact Report');
        expect(report.sections.map((section) => section.title)).toEqual([
            'Platform Summary',
            'Donations by Status',
            'Donated Quantity by Unit',
            'Donations by Category',
            'Monthly Activity (Donations / Requests)',
            'Volunteer Activity',
            'Top Volunteers (completed / total deliveries)'
        ]);
    });

    it('exports CSV with escaping and formula protection', () => {
        const csv = reportToCsv(report);
        expect(csv).toContain('Section,Metric,Value');
        expect(csv).toContain('Platform Summary,Meals delivered (estimated),8');
        expect(csv).toContain(`Donations by Category,"'=HYPERLINK(""x"")",2`);
        expect(csv).toContain('Donations by Category,"Rice, cooked",1');
    });

    it('exports a valid PDF document', async () => {
        const pdf = await reportToPdf(report);
        expect(pdf.subarray(0, 5).toString()).toBe('%PDF-');
        expect(pdf.length).toBeGreaterThan(1000);
    });
});
