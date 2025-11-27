import nodemailer from 'nodemailer';

interface EmailOptions {
  email: string;
  subject: string;
  message: string;
}

const sendEmail = async (options: EmailOptions): Promise<void> => {
  // Check if SMTP is configured
  if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASS) {
    // In development, log the email instead of sending
    if (process.env.NODE_ENV === 'development') {
      console.log('📧 Email would be sent (SMTP not configured):');
      console.log(`To: ${options.email}`);
      console.log(`Subject: ${options.subject}`);
      console.log(`Message: ${options.message}`);
      return;
    }
    throw new Error('SMTP is not configured. Please set SMTP_HOST, SMTP_USER, and SMTP_PASS environment variables.');
  }

  // Create a transporter object using the default SMTP transport
  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT || '587', 10),
    secure: process.env.SMTP_PORT === '465', // true for 465, false for other ports
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
    // Add TLS options for secure connections
    tls: {
      rejectUnauthorized: process.env.NODE_ENV === 'production',
    },
  });

  // Define email options
  const mailOptions = {
    from: `${process.env.FROM_NAME || 'Delivery System'} <${process.env.FROM_EMAIL || 'noreply@deliverysystem.com'}>`,
    to: options.email,
    subject: options.subject,
    text: options.message,
    // html: '<b>Hello world?</b>', // html body
  };

  // Send email
  const info = await transporter.sendMail(mailOptions);

  // Log email sent (only messageId, not sensitive content)
  if (process.env.NODE_ENV === 'development') {
    console.log('Email sent successfully. Message ID:', info.messageId);
  }
};

export default sendEmail; 