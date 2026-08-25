import multer from 'multer';

const storage = multer.memoryStorage();

const fileFilter: multer.Options['fileFilter'] = (
    req,
    file,
    callback
) => {
    const allowedMimeTypes = [
        'image/jpeg',
        'image/png',
        'image/webp'
    ];

    if (!allowedMimeTypes.includes(file.mimetype)) {
        callback(new Error('Only JPEG, PNG, and WebP images are allowed.'));
        return;
    }

    callback(null, true);
};

const upload = multer({
    storage,
    fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024
    }
});

export default upload;