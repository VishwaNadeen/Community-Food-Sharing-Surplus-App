import { Request, Response } from 'express';
import { AuthLocals } from '../middleware/auth.middleware';
import {
    getImpactAnalytics,
    getVolunteerActivityAnalytics
} from '../services/ngoImpact.service';
import { buildImpactReport, reportToCsv, reportToPdf } from '../services/ngoReport.service';

// GET /ngo/impact/report?format=pdf|csv|json - downloadable impact report.
export const getImpactReportHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    const format = String(req.query.format ?? 'pdf').toLowerCase();
    if (!['pdf', 'csv', 'json'].includes(format)) {
        res.status(400).json({ error: 'Format must be pdf, csv or json' });
        return;
    }

    try {
        const report = await buildImpactReport();
        const fileName = `community-impact-report-${report.generatedAt.slice(0, 10)}`;

        if (format === 'json') {
            res.status(200).json({ report });
            return;
        }

        res.setHeader('Content-Disposition', `attachment; filename="${fileName}.${format}"`);
        if (format === 'csv') {
            res.type('text/csv; charset=utf-8').send(reportToCsv(report));
            return;
        }
        res.type('application/pdf').send(await reportToPdf(report));
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

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
