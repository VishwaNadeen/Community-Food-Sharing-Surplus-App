import { Request, Response } from 'express';
import { AuthLocals } from '../middleware/auth.middleware';
import { generateFoodMatches, getFoodMatches } from '../services/ngoMatching.service';

export const generateFoodMatchesHandler = async (
    _req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const generated = await generateFoodMatches();
        // Return full records (with donation/request details) for the app.
        const matches = await getFoodMatches();
        res.status(200).json({
            message: 'Food matches generated successfully',
            count: matches.length,
            generated: generated.length,
            matches
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const getFoodMatchesHandler = async (
    _req: Request,
    res: Response<any, AuthLocals>
): Promise<void> => {
    try {
        const matches = await getFoodMatches();
        res.status(200).json({
            message: 'Food matches fetched successfully',
            count: matches.length,
            matches
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};
