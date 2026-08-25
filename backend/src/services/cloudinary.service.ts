import cloudinary from "../config/cloudinary";
import {
  UploadApiErrorResponse,
  UploadApiResponse,
} from "cloudinary";

export const uploadImageToCloudinary = (
  buffer: Buffer
): Promise<string> => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder: "community-food-sharing/donations",
        resource_type: "image",
      },
      (
        error: UploadApiErrorResponse | undefined,
        result: UploadApiResponse | undefined
      ) => {
        if (error) {
          reject(error);
          return;
        }

        if (!result?.secure_url) {
          reject(new Error("Cloudinary upload failed"));
          return;
        }

        resolve(result.secure_url);
      }
    );

    uploadStream.end(buffer);
  });
};