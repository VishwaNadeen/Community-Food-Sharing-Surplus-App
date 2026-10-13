
import multer from 'multer';
import type { Request, Response, NextFunction } from 'express';

const storage = multer.memoryStorage();

const allowedMimeTypes = new Set([
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
    'image/heic-sequence',
    'image/heif-sequence',
]);

const fileFilter: multer.Options['fileFilter'] = (
    req,
    file,
    callback
) => {
    console.log(
        `[Image Upload] File: ${file.originalname}, MIME type: ${file.mimetype}`
    );

    if (!allowedMimeTypes.has(file.mimetype.toLowerCase())) {
        callback(
            new Error(
                `Unsupported image type: ${file.mimetype}. Please select a JPEG, PNG, WebP, HEIC, or HEIF image.`
            )
        );
        return;
    }

    callback(null, true);
};

const upload = multer({
    storage,
    fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024,
    },
});

// Convert Multer errors into JSON responses instead of HTML 500 pages.
export const handleUploadError = (
    error: unknown,
    req: Request,
    res: Response,
    next: NextFunction
): void => {
    if (error instanceof multer.MulterError) {
        const statusCode =
            error.code === 'LIMIT_FILE_SIZE' ? 413 : 400;

        res.status(statusCode).json({
            error:
                error.code === 'LIMIT_FILE_SIZE'
                    ? 'Image must be 5 MB or smaller.'
                    : error.message,
        });
        return;
    }

    if (
        error instanceof Error &&
        error.message.startsWith('Unsupported image type:')
    ) {
        res.status(400).json({
            error: error.message,
        });
        return;
    }

    next(error);
};

export default upload;
