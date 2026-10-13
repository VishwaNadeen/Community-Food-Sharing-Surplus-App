import {Router} from 'express';
import {authenticateToken,requireVolunteer} from '../middleware/auth.middleware';
import {

    updateAvailabilityHandler,
    getAvailabilityHandler,

    getMyDeliveriesHandler,
    getDeliveryHandler,

    acceptDeliveryHandler,
    rejectDeliveryHandler,

    updateDeliveryStatusHandler,

    updateLocationHandler,
    getTrackingHandler,

    reportProblemHandler,
    getProblemsHandler,
    getOptimizedRouteHandler,
    getDashboardHandler,
    getVolunteerProfileHandler,
    updateVolunteerProfileHandler,
    getVolunteerLiveLocationHandler,
    getDonorLocationHandler,
    getNavigationDataHandler

} from '../controllers/volunteerDelivery.controller';

const router = Router();

router.get('/profile', authenticateToken, requireVolunteer, getVolunteerProfileHandler);
router.post('/profile', authenticateToken, requireVolunteer, updateVolunteerProfileHandler);
router.put('/profile', authenticateToken, requireVolunteer, updateVolunteerProfileHandler);
router.get('/availability',authenticateToken,requireVolunteer,getAvailabilityHandler);
router.put('/availability',authenticateToken,requireVolunteer,updateAvailabilityHandler);
router.get('/routes/optimized',authenticateToken,requireVolunteer,getOptimizedRouteHandler);
router.get('/dashboard',authenticateToken,requireVolunteer,getDashboardHandler);
router.get('/deliveries',authenticateToken,requireVolunteer,getMyDeliveriesHandler);
router.get('/deliveries/:id',authenticateToken,requireVolunteer,getDeliveryHandler);
router.patch( '/deliveries/:id/accept', authenticateToken,requireVolunteer,acceptDeliveryHandler);
router.patch('/deliveries/:id/reject',authenticateToken,requireVolunteer,rejectDeliveryHandler);
router.patch('/deliveries/:id/status',authenticateToken,requireVolunteer,updateDeliveryStatusHandler);
router.post('/deliveries/:id/location',authenticateToken,requireVolunteer,updateLocationHandler);
router.get('/deliveries/:id/tracking',authenticateToken,requireVolunteer,getTrackingHandler);
router.post('/deliveries/:id/problems',authenticateToken,requireVolunteer,reportProblemHandler);
router.get('/deliveries/:id/problems',authenticateToken,requireVolunteer,getProblemsHandler);

// NEW: Location tracking and navigation endpoints
router.get('/location/live', authenticateToken, requireVolunteer, getVolunteerLiveLocationHandler);
router.get('/deliveries/:deliveryId/donor-location', authenticateToken, requireVolunteer, getDonorLocationHandler);
router.get('/deliveries/:deliveryId/navigation', authenticateToken, requireVolunteer, getNavigationDataHandler);

export default router;