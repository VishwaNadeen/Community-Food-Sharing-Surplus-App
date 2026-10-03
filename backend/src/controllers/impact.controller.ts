import { Request, Response } from 'express';
import { AuthLocals } from '../middleware/auth.middleware';
import { getImpactAnalytics } from '../services/impact.service';

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
