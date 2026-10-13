import { Request, Response } from 'express';
import { AuthLocals } from '../middleware/auth.middleware';
import {
    getNgoCoordinatorProfile,
    updateNgoCoordinatorPhoto,
    updateNgoCoordinatorProfile
} from '../services/ngoProfile.service';
import { uploadImageToCloudinary } from '../services/cloudinary.service';

export const getNgoProfileHandler = async (
    _req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const userId = res.locals.currentUser.user.customUserId;
        res.status(200).json({ profile: await getNgoCoordinatorProfile(userId) });
    } catch (error: any) {
        const status = error.message === 'Coordinator account not found' ? 404 : 500;
        res.status(status).json({ error: error.message });
    }
};

export const updateNgoProfileHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const { firstName, lastName } = req.body ?? {};
        if (typeof firstName !== 'string' || typeof lastName !== 'string' ||
            !firstName.trim() || !lastName.trim()) {
            res.status(400).json({ error: 'First name and last name are required' });
            return;
        }
        const userId = res.locals.currentUser.user.customUserId;
        const profile = await updateNgoCoordinatorProfile(userId, firstName, lastName);
        res.status(200).json({ message: 'Profile updated successfully', profile });
    } catch (error: any) {
        const status = error.message === 'Coordinator account not found' ? 404 : 500;
        res.status(status).json({ error: error.message });
    }
};

export const uploadNgoProfilePhotoHandler = async (
    req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        if (!req.file) {
            res.status(400).json({ error: 'Choose a profile photo first' });
            return;
        }
        const imageUrl = await uploadImageToCloudinary(
            req.file.buffer,
            'community-food-sharing/ngo-profiles'
        );
        const userId = res.locals.currentUser.user.customUserId;
        const profile = await updateNgoCoordinatorPhoto(userId, imageUrl);
        res.status(200).json({ message: 'Profile photo updated successfully', profile });
    } catch (error: any) {
        res.status(500).json({ error: error.message || 'Could not upload profile photo' });
    }
};
