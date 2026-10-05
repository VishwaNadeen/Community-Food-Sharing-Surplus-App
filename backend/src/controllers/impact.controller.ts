import { Request, Response } from 'express';
import { AuthLocals } from '../middleware/auth.middleware';
import {
    getImpactAnalytics,
    getVolunteerActivityAnalytics
} from '../services/impact.service';

// GET /ngo/impact - NGO-only platform impact analytics.
export const getImpactAnalyticsHandler = async (
    _req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const impact = await getImpactAnalytics();
        res.status(200).json({
            message: 'Impact analytics fetched successfully',
            impact
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// GET /ngo/impact/volunteers - NGO-only volunteer delivery activity.
export const getVolunteerActivityHandler = async (
    _req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const volunteerActivity = await getVolunteerActivityAnalytics();
        res.status(200).json({
            message: 'Volunteer activity fetched successfully',
            volunteerActivity
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};
