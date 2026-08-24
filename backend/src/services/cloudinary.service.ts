import cloudinary from '../config/cloudinary';

export const uploadImageToCloudinary = (
    buffer: Buffer
): Promise<string> => {
    return new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
            {
                folder: 'community-food-sharing/donations',
                resource_type: 'image'
            },
            (error, result) => {
                if (error) {
                    reject(error);
                    return;
                }

                if (!result?.secure_url) {
                    reject(new Error('Cloudinary upload failed'));
                    return;
                }

                resolve(result.secure_url);
            }
        );

        uploadStream.end(buffer);
    });
};