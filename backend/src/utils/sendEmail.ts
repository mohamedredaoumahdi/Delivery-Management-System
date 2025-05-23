import nodemailer from 'nodemailer';

interface EmailOptions {
  email: string;
  subject: string;
  message: string;
}

const sendEmail = async (options: EmailOptions): Promise<void> => {
  // Create a transporter object using the default SMTP transport
  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT || '587', 10),
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
    // Add security options if needed, e.g., secure: true for TLS
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

  console.log('Message sent: %s', info.messageId);
};

export default sendEmail; 