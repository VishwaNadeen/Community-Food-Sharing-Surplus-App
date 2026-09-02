import {Request, Response} from 'express';
import {AuthLocals} from '../middleware/auth.middleware';
import {
    updateVolunteerAvailability,
    getVolunteerAvailability,
    getVolunteerDeliveries,
    getDeliveryById,
    acceptDelivery,
    rejectDelivery,
    updateDeliveryStatus,
    updateVolunteerLocation,
    getDeliveryTracking,
    reportDeliveryProblem,
    getDeliveryProblems
} from '../services/volunteerDelivery.service';

import {
    validateAvailability,
    validateRejectDelivery,
    validateDeliveryStatus,
    validateLocation,
    validateDeliveryProblem
} from '../validators/volunteerDelivery.validator';

import {DeliveryStatus} from '@prisma/client';


const getVolunteerId = (
    res: Response<any, AuthLocals>
) => {

    return res.locals
        .currentUser
        .user
        .customUserId;
};

export const updateAvailabilityHandler =
    async (
        req: Request,
        res: Response<any, AuthLocals>
    ): Promise<void> => {

        try {

            const errors =
                validateAvailability(req.body);

            if (errors.length > 0) {

                res.status(400).json({
                    errors
                });

                return;
            }

            const availability =
                await updateVolunteerAvailability(
                    getVolunteerId(res),
                    req.body
                );

            res.status(200).json({
                message:
                    'Availability updated successfully.',
                availability
            });

        } catch (error: any) {

            res.status(500).json({
                error: error.message
            });
        }
    };


export const getAvailabilityHandler =
    async (
        req: Request,
        res: Response<any, AuthLocals>
    ): Promise<void> => {

        try {

            const availability =
                await getVolunteerAvailability(
                    getVolunteerId(res)
                );

            res.status(200).json({

                availability:
                    availability || {
                        status: 'UNAVAILABLE',
                        notes: null
                    }
            });

        } catch (error: any) {

            res.status(500).json({
                error: error.message
            });
        }
    };

export const getMyDeliveriesHandler =
    async (
        req: Request,
        res: Response<any, AuthLocals>
    ): Promise<void> => {

        try {

            const deliveries =
                await getVolunteerDeliveries(
                    getVolunteerId(res)
                );

            res.status(200).json({
                count: deliveries.length,
                deliveries
            });

        } catch (error: any) {

            res.status(500).json({
                error: error.message
            });
        }
    };


export const getDeliveryHandler =
    async (
        req: Request,
        res: Response<any, AuthLocals>
    ): Promise<void> => {

        try {

            const delivery =
                await getDeliveryById(

                    String(req.params.id),

                    getVolunteerId(res)
                );

            res.status(200).json({
                delivery
            });

        } catch (error: any) {

            res.status(400).json({
                error: error.message
            });
        }
    };


export const acceptDeliveryHandler =
    async (
        req: Request,
        res: Response<any, AuthLocals>
    ): Promise<void> => {

        try {

            const delivery =
                await acceptDelivery(

                    String(req.params.id),

                    getVolunteerId(res)
                );

            res.status(200).json({
                message:
                    'Delivery accepted successfully.',
                delivery
            });

        } catch (error: any) {

            res.status(400).json({
                error: error.message
            });
        }
    };


export const rejectDeliveryHandler =
    async (
        req: Request,
        res: Response<any, AuthLocals>
    ): Promise<void> => {

        try {

            const errors =
                validateRejectDelivery(req.body);

            if (errors.length > 0) {

                res.status(400).json({
                    errors
                });

                return;
            }

            const delivery =
                await rejectDelivery(

                    String(req.params.id),

                    getVolunteerId(res),

                    req.body.rejectionReason
                );

            res.status(200).json({
                message:
                    'Delivery rejected successfully.',
                delivery
            });

        } catch (error: any) {

            res.status(400).json({
                error: error.message
            });
        }
    };


export const updateDeliveryStatusHandler =
    async (
        req: Request,
        res: Response<any, AuthLocals>
    ): Promise<void> => {

        try {

            const errors =
                validateDeliveryStatus(req.body);

            if (errors.length > 0) {

                res.status(400).json({
                    errors
                });

                return;
            }

            const status =
                req.body.status.toUpperCase()
                as DeliveryStatus;

            const delivery =
                await updateDeliveryStatus(

                    String(req.params.id),

                    getVolunteerId(res),

                    status
                );

            res.status(200).json({
                message:
                    'Delivery status updated successfully.',
                delivery
            });

        } catch (error: any) {

            res.status(400).json({
                error: error.message
            });
        }
    };

export const updateLocationHandler =
    async (
        req: Request,
        res: Response<any, AuthLocals>
    ): Promise<void> => {

        try {

            const errors =
                validateLocation(req.body);

            if (errors.length > 0) {

                res.status(400).json({
                    errors
                });

                return;
            }

            const tracking =
                await updateVolunteerLocation(

                    String(req.params.id),

                    getVolunteerId(res),

                    req.body
                );

            res.status(200).json({
                message:
                    'Location updated successfully.',
                tracking
            });

        } catch (error: any) {

            res.status(400).json({
                error: error.message
            });
        }
    };


export const getTrackingHandler =
    async (
        req: Request,
        res: Response<any, AuthLocals>
    ): Promise<void> => {

        try {

            const tracking =
                await getDeliveryTracking(

                    String(req.params.id),

                    getVolunteerId(res)
                );

            res.status(200).json({
                tracking
            });

        } catch (error: any) {

            res.status(400).json({
                error: error.message
            });
        }
    };

export const reportProblemHandler =
    async (
        req: Request,
        res: Response<any, AuthLocals>
    ): Promise<void> => {

        try {

            const errors =
                validateDeliveryProblem(
                    req.body
                );

            if (errors.length > 0) {

                res.status(400).json({
                    errors
                });

                return;
            }

            const problem =
                await reportDeliveryProblem(

                    String(req.params.id),

                    getVolunteerId(res),

                    req.body
                );

            res.status(201).json({
                message:
                    'Delivery problem reported successfully.',
                problem
            });

        } catch (error: any) {

            res.status(400).json({
                error: error.message
            });
        }
    };


export const getProblemsHandler =
    async (
        req: Request,
        res: Response<any, AuthLocals>
    ): Promise<void> => {

        try {

            const problems =
                await getDeliveryProblems(

                    String(req.params.id),

                    getVolunteerId(res)
                );

            res.status(200).json({
                problems
            });

        } catch (error: any) {

            res.status(400).json({
                error: error.message
            });
        }
    };