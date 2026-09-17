import {
    approveDonation,
    getAllDonations,
    getDonationById,
    getPendingDonations,
    rejectDonation
} from './donation.service';
import {
    approveFoodRequest,
    getAllFoodRequests,
    getFoodRequestById,
    getPendingFoodRequests,
    rejectFoodRequest
} from './foodRequest.service';

export const ngoService = {
    // Donation operations for NGO Coordinator
    getPendingDonations,
    getDonationById,
    approveDonation,
    rejectDonation,
    getAllDonations,

    // Food Request operations for NGO Coordinator
    getPendingFoodRequests,
    getFoodRequestById,
    approveFoodRequest,
    rejectFoodRequest,
    getAllFoodRequests
};

export {
    getPendingDonations,
    getDonationById,
    approveDonation,
    rejectDonation,
    getAllDonations,
    getPendingFoodRequests,
    getFoodRequestById,
    approveFoodRequest,
    rejectFoodRequest,
    getAllFoodRequests
};
