
import { Router } from 'express';
import {
    create,
    getMyDonations,
    update,
    cancel,
} from '../controllers/donation.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import upload, { handleUploadError } from '../middleware/upload.middleware';

const router = Router();

router.post(
    '/',
    authenticateToken,
    upload.single('image'),
    handleUploadError,
    create
);

router.get('/', authenticateToken, getMyDonations);

router.put(
    '/:id',
    authenticateToken,
    upload.single('image'),
    handleUploadError,
    update
);

router.patch(
    '/:id/cancel',
    authenticateToken,
    cancel
);

export default router;
