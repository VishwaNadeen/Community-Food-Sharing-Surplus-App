import { Request, Response } from 'express';
import { AuthLocals } from '../middleware/auth.middleware';
import {
    AdminValidationError,
    getAdminOverview,
    getAlerts,
    getDonorSummaries,
    getRecipientSummaries,
    updateAlertStatus
} from '../services/ngoAdmin.service';

const sendError = (res: Response<any, AuthLocals>, error: any): void => {
    const statusCode = error instanceof AdminValidationError ? error.statusCode : 500;
    res.status(statusCode).json({ error: error.message });
};

// GET /ngo/admin/overview
export const getAdminOverviewHandler = async (
    _req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        res.status(200).json({ overview: await getAdminOverview() });
    } catch (error: any) {
        sendError(res, error);
    }
};

// GET /ngo/admin/donors
export const getDonorsHandler = async (
    _req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const donors = await getDonorSummaries();
        res.status(200).json({ count: donors.length, donors });
    } catch (error: any) {
        sendError(res, error);
    }
};

// GET /ngo/admin/recipients
export const getRecipientsHandler = async (
    _req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const recipients = await getRecipientSummaries();
        res.status(200).json({ count: recipients.length, recipients });
    } catch (error: any) {
        sendError(res, error);
    }
};

// GET /ngo/admin/alerts
export const getAlertsHandler = async (
    _req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        res.status(200).json(await getAlerts());
    } catch (error: any) {
        sendError(res, error);
    }
};

// PATCH /ngo/admin/alerts/:id/status
export const updateAlertStatusHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const alert = await updateAlertStatus(String(req.params.id), req.body?.status);
        res.status(200).json({ message: 'Alert updated successfully', alert });
    } catch (error: any) {
        sendError(res, error);
    }
};
