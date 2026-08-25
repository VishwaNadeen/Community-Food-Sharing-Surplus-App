import nodemailer from 'nodemailer';

const getSmtpConfig = () => {
  const host = process.env.SMTP_HOST;
  const port = process.env.SMTP_PORT;
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const from = process.env.SMTP_FROM || user;

  if (!host || !port || !user || !pass || !from) {
    throw new Error('SMTP configuration is incomplete. Check your .env file');
  }

  return {
    host,
    port: Number(port),
    user,
    pass,
    from
  };
};

const createTransporter = () => {
  const smtpConfig = getSmtpConfig();

  return nodemailer.createTransport({
    host: smtpConfig.host,
    port: smtpConfig.port,
    secure: smtpConfig.port === 465, // true for 465, false for 587
    auth: {
      user: smtpConfig.user,
      pass: smtpConfig.pass
    }
  });
};

export const sendVerificationEmail = async (to: string, code: string): Promise<void> => {
  const smtpConfig = getSmtpConfig();

  await createTransporter().sendMail({
    from: smtpConfig.from,
    to,
    subject: 'FoodLink - Email Verification Code',
    text: `Your FoodLink verification code is ${code}. It expires in 15 minutes.`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2>FoodLink Email Verification</h2>
        <p>Your verification code is:</p>
        <h1 style="letter-spacing: 8px; color: #2563eb;">${code}</h1>
        <p>This code expires in <strong>15 minutes</strong>.</p>
        <p>If you did not request this, please ignore this email.</p>
      </div>
    `
  });
};

export const sendPasswordResetEmail = async (to: string, code: string): Promise<void> => {
  const smtpConfig = getSmtpConfig();

  await createTransporter().sendMail({
    from: smtpConfig.from,
    to,
    subject: 'FoodLink - Password Reset Code',
    text: `Your FoodLink password reset code is ${code}. It expires in 15 minutes.`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2>FoodLink Password Reset</h2>
        <p>You requested a password reset. Use the code below:</p>
        <h1 style="letter-spacing: 8px; color: #dc2626;">${code}</h1>
        <p>This code expires in <strong>15 minutes</strong>.</p>
        <p>If you did not request a password reset, please ignore this email.</p>
      </div>
    `
  });
};