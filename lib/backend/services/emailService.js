const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.EMAIL_PORT || '587'),
  secure: false,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

const sendGroupInvitationEmail = async ({ toEmail, toName, senderName, tripName, invitationId }) => {
  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    console.log('[Email] Skipped — EMAIL_USER/EMAIL_PASS not set in .env');
    return { success: false, reason: 'Email not configured' };
  }

  const mailOptions = {
    from: `"SafarSync" <${process.env.EMAIL_USER}>`,
    to: toEmail,
    subject: 'SafarSync Group Booking Invitation',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background: #f9f9f9; border-radius: 12px;">
        <div style="background: linear-gradient(135deg, #1B5A6E, #13E8D0); padding: 24px; border-radius: 12px 12px 0 0; text-align: center;">
          <h1 style="color: white; margin: 0; font-size: 24px;">SafarSync</h1>
          <p style="color: rgba(255,255,255,0.8); margin: 8px 0 0; font-size: 14px;">Travel Smarter. Travel Safer. Travel Together.</p>
        </div>
        <div style="background: white; padding: 32px; border-radius: 0 0 12px 12px; border: 1px solid #e0e0e0; border-top: none;">
          <h2 style="color: #1B5A6E; margin: 0 0 16px;">You have been invited!</h2>
          <p style="color: #333; font-size: 16px;">Hello <strong>${toName || toEmail}</strong>,</p>
          <p style="color: #555; line-height: 1.6;">
            <strong>${senderName}</strong> has invited you to join the group trip:
          </p>
          <div style="background: #f0f9ff; border-left: 4px solid #13E8D0; padding: 16px; margin: 20px 0; border-radius: 4px;">
            <p style="margin: 0; font-size: 20px; font-weight: bold; color: #1B5A6E;">${tripName}</p>
            <p style="margin: 8px 0 0; color: #666; font-size: 14px;">Trip Type: Group Booking</p>
          </div>
          <p style="color: #555; line-height: 1.6;">
            Please open the <strong>SafarSync</strong> app and navigate to your invitations to accept or decline this trip.
          </p>
          <div style="text-align: center; margin: 24px 0;">
            <p style="color: #888; font-size: 13px;">Invitation ID: #${invitationId}</p>
          </div>
          <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
          <p style="color: #aaa; font-size: 12px; text-align: center; margin: 0;">
            Travel Smarter. Travel Safer. Travel Together.<br/>
            <strong>SafarSync Team</strong>
          </p>
        </div>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`[Email] Invitation sent to ${toEmail}`);
    return { success: true };
  } catch (err) {
    console.error('[Email] Failed to send invitation:', err.message);
    return { success: false, reason: err.message };
  }
};

const sendInvitationResponseEmail = async ({ toEmail, toName, responderName, tripName, status }) => {
  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) return;

  const isAccepted = status === 'Accepted';
  const mailOptions = {
    from: `"SafarSync" <${process.env.EMAIL_USER}>`,
    to: toEmail,
    subject: `SafarSync — ${responderName} ${isAccepted ? 'accepted' : 'declined'} your trip invitation`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background: #f9f9f9; border-radius: 12px;">
        <div style="background: linear-gradient(135deg, #1B5A6E, #13E8D0); padding: 24px; border-radius: 12px 12px 0 0; text-align: center;">
          <h1 style="color: white; margin: 0; font-size: 24px;">SafarSync</h1>
        </div>
        <div style="background: white; padding: 32px; border-radius: 0 0 12px 12px; border: 1px solid #e0e0e0; border-top: none;">
          <p style="color: #333; font-size: 16px;">Hello <strong>${toName || toEmail}</strong>,</p>
          <p style="color: #555; line-height: 1.6;">
            <strong>${responderName}</strong> has <strong style="color: ${isAccepted ? '#16a34a' : '#dc2626'};">${status}</strong>
            the invitation to join <strong>${tripName}</strong>.
          </p>
          ${isAccepted ? `<p style="color: #555;">They will now appear on the group live map during the trip.</p>` : ''}
          <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
          <p style="color: #aaa; font-size: 12px; text-align: center; margin: 0;">SafarSync Team</p>
        </div>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
  } catch (err) {
    console.error('[Email] Failed to send response email:', err.message);
  }
};

// ── Emergency SOS alert email (sent to all admins) ────────────────────────────
const sendEmergencyAlertEmail = async ({
  toEmail,
  toName,
  userName,
  userPhone,
  userEmail,
  tripName,
  latitude,
  longitude,
  alertId,
  message,
  timestamp,
}) => {
  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    console.log('[Email] Skipped emergency alert — EMAIL_USER/EMAIL_PASS not set');
    return { success: false, reason: 'Email not configured' };
  }

  const mapsLink = `https://maps.google.com/?q=${latitude},${longitude}`;
  const locationText = `${parseFloat(latitude).toFixed(5)}, ${parseFloat(longitude).toFixed(5)}`;

  const mailOptions = {
    from: `"SafarSync Emergency" <${process.env.EMAIL_USER}>`,
    to: toEmail,
    subject: `🚨 EMERGENCY SOS — ${userName} needs help!`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 640px; margin: 0 auto; background: #fff; border-radius: 12px; overflow: hidden; border: 2px solid #B71C1C;">
        <!-- Header -->
        <div style="background: linear-gradient(135deg, #B71C1C, #E53935); padding: 28px 24px; text-align: center;">
          <div style="font-size: 48px; margin-bottom: 8px;">🚨</div>
          <h1 style="color: white; margin: 0; font-size: 26px; letter-spacing: 1px;">EMERGENCY SOS ALERT</h1>
          <p style="color: rgba(255,255,255,0.85); margin: 8px 0 0; font-size: 13px;">SafarSync — Travel Safety System</p>
        </div>

        <!-- Alert body -->
        <div style="padding: 28px 24px;">
          <p style="color: #333; font-size: 16px; margin: 0 0 20px;">
            Hello <strong>${toName || 'Admin'}</strong>, a user has triggered an emergency SOS alert.
          </p>

          <!-- User card -->
          <div style="background: #FFF3F3; border-left: 4px solid #E53935; border-radius: 6px; padding: 20px; margin-bottom: 20px;">
            <h3 style="color: #B71C1C; margin: 0 0 14px; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px;">
              User Information
            </h3>
            <table style="width: 100%; border-collapse: collapse;">
              <tr>
                <td style="padding: 6px 0; color: #666; font-size: 13px; width: 110px;">Name</td>
                <td style="padding: 6px 0; color: #111; font-weight: bold; font-size: 14px;">${userName}</td>
              </tr>
              <tr>
                <td style="padding: 6px 0; color: #666; font-size: 13px;">Phone</td>
                <td style="padding: 6px 0; color: #111; font-size: 14px;">
                  ${userPhone && userPhone !== 'N/A'
                    ? `<a href="tel:${userPhone}" style="color: #E53935;">${userPhone}</a>`
                    : '<span style="color: #999;">Not provided</span>'}
                </td>
              </tr>
              <tr>
                <td style="padding: 6px 0; color: #666; font-size: 13px;">Email</td>
                <td style="padding: 6px 0; color: #111; font-size: 14px;">
                  <a href="mailto:${userEmail}" style="color: #1565C0;">${userEmail}</a>
                </td>
              </tr>
              ${tripName ? `
              <tr>
                <td style="padding: 6px 0; color: #666; font-size: 13px;">Trip</td>
                <td style="padding: 6px 0; color: #111; font-size: 14px;">${tripName}</td>
              </tr>` : ''}
            </table>
          </div>

          <!-- Location card -->
          <div style="background: #F3F8FF; border-left: 4px solid #1565C0; border-radius: 6px; padding: 20px; margin-bottom: 20px;">
            <h3 style="color: #1565C0; margin: 0 0 14px; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px;">
              Location
            </h3>
            <p style="margin: 0 0 10px; color: #333; font-size: 14px;">📍 <strong>${locationText}</strong></p>
            <a href="${mapsLink}" style="display: inline-block; background: #1565C0; color: white; padding: 10px 20px; border-radius: 6px; text-decoration: none; font-size: 13px; font-weight: bold;">
              Open in Google Maps
            </a>
          </div>

          ${message ? `
          <!-- Message -->
          <div style="background: #FFFDE7; border-left: 4px solid #F9A825; border-radius: 6px; padding: 16px; margin-bottom: 20px;">
            <h3 style="color: #F57F17; margin: 0 0 8px; font-size: 13px; text-transform: uppercase;">Message from user</h3>
            <p style="margin: 0; color: #333; font-size: 14px;">"${message}"</p>
          </div>` : ''}

          <!-- Meta -->
          <div style="border-top: 1px solid #eee; padding-top: 16px; margin-top: 8px;">
            <p style="color: #999; font-size: 12px; margin: 0 0 4px;">
              Alert ID: <strong>#${alertId}</strong>
            </p>
            <p style="color: #999; font-size: 12px; margin: 0;">
              Time: <strong>${timestamp}</strong>
            </p>
          </div>
        </div>

        <!-- Footer -->
        <div style="background: #1A1A1A; padding: 16px 24px; text-align: center;">
          <p style="color: #aaa; font-size: 12px; margin: 0;">
            SafarSync Emergency Response System — Travel Smarter. Travel Safer.
          </p>
        </div>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`[Email] Emergency alert sent to ${toEmail}`);
    return { success: true };
  } catch (err) {
    console.error('[Email] Failed to send emergency alert:', err.message);
    return { success: false, reason: err.message };
  }
};

// ── Emergency SOS contact email (sent to personal emergency contacts) ─────────
const sendEmergencyContactEmail = async ({
  toEmail,
  toName,
  relationship,
  userName,
  userPhone,
  tripName,
  latitude,
  longitude,
  alertId,
  message,
  timestamp,
}) => {
  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    console.log('[Email] Skipped emergency contact email — EMAIL_USER/EMAIL_PASS not set');
    return { success: false, reason: 'Email not configured' };
  }

  const mapsLink = `https://maps.google.com/?q=${latitude},${longitude}`;
  const locationText = `${parseFloat(latitude).toFixed(5)}, ${parseFloat(longitude).toFixed(5)}`;
  const relationshipLabel = relationship ? ` (${relationship})` : '';

  const mailOptions = {
    from: `"SafarSync Emergency" <${process.env.EMAIL_USER}>`,
    to: toEmail,
    subject: `🚨 ${userName} needs help — Emergency SOS Activated`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 640px; margin: 0 auto; background: #fff; border-radius: 12px; overflow: hidden; border: 2px solid #B71C1C;">
        <!-- Header -->
        <div style="background: linear-gradient(135deg, #B71C1C, #E53935); padding: 28px 24px; text-align: center;">
          <div style="font-size: 48px; margin-bottom: 8px;">🚨</div>
          <h1 style="color: white; margin: 0; font-size: 24px; letter-spacing: 0.5px;">Emergency SOS Alert</h1>
          <p style="color: rgba(255,255,255,0.85); margin: 8px 0 0; font-size: 13px;">SafarSync — Travel Safety System</p>
        </div>

        <!-- Body -->
        <div style="padding: 28px 24px;">
          <p style="color: #333; font-size: 16px; margin: 0 0 8px;">
            Hello <strong>${toName || 'there'}${relationshipLabel}</strong>,
          </p>
          <p style="color: #555; font-size: 15px; line-height: 1.6; margin: 0 0 24px;">
            This is an urgent message. <strong style="color: #B71C1C;">${userName}</strong> has activated an
            <strong>Emergency SOS</strong> on the SafarSync travel app and may need your immediate assistance.
          </p>

          <!-- Traveler info -->
          <div style="background: #FFF3F3; border-left: 4px solid #E53935; border-radius: 6px; padding: 20px; margin-bottom: 20px;">
            <h3 style="color: #B71C1C; margin: 0 0 14px; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px;">
              Traveler Information
            </h3>
            <table style="width: 100%; border-collapse: collapse;">
              <tr>
                <td style="padding: 6px 0; color: #666; font-size: 13px; width: 100px;">Name</td>
                <td style="padding: 6px 0; color: #111; font-weight: bold; font-size: 14px;">${userName}</td>
              </tr>
              <tr>
                <td style="padding: 6px 0; color: #666; font-size: 13px;">Phone</td>
                <td style="padding: 6px 0; font-size: 14px;">
                  ${userPhone && userPhone !== 'N/A'
                    ? `<a href="tel:${userPhone}" style="color: #E53935; font-weight: bold;">${userPhone}</a>`
                    : '<span style="color: #999;">Not available</span>'}
                </td>
              </tr>
              ${tripName ? `
              <tr>
                <td style="padding: 6px 0; color: #666; font-size: 13px;">Trip</td>
                <td style="padding: 6px 0; color: #111; font-size: 14px;">${tripName}</td>
              </tr>` : ''}
            </table>
          </div>

          <!-- Location -->
          <div style="background: #F3F8FF; border-left: 4px solid #1565C0; border-radius: 6px; padding: 20px; margin-bottom: 20px;">
            <h3 style="color: #1565C0; margin: 0 0 14px; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px;">
              Last Known Location
            </h3>
            <p style="margin: 0 0 12px; color: #333; font-size: 14px;">📍 <strong>${locationText}</strong></p>
            <a href="${mapsLink}" style="display: inline-block; background: #1565C0; color: white; padding: 10px 22px; border-radius: 6px; text-decoration: none; font-size: 13px; font-weight: bold;">
              Open in Google Maps
            </a>
          </div>

          ${message ? `
          <!-- Message -->
          <div style="background: #FFFDE7; border-left: 4px solid #F9A825; border-radius: 6px; padding: 16px; margin-bottom: 20px;">
            <h3 style="color: #F57F17; margin: 0 0 8px; font-size: 13px; text-transform: uppercase;">Message from ${userName}</h3>
            <p style="margin: 0; color: #333; font-size: 14px;">"${message}"</p>
          </div>` : ''}

          <p style="color: #555; font-size: 14px; line-height: 1.6; margin: 0 0 8px;">
            Please try to reach them immediately. If you are unable to contact them, consider alerting local emergency services.
          </p>

          <!-- Meta -->
          <div style="border-top: 1px solid #eee; padding-top: 16px; margin-top: 16px;">
            <p style="color: #999; font-size: 11px; margin: 0 0 3px;">Alert ID: <strong>#${alertId}</strong></p>
            <p style="color: #999; font-size: 11px; margin: 0;">Time: <strong>${timestamp}</strong></p>
          </div>
        </div>

        <!-- Footer -->
        <div style="background: #1A1A1A; padding: 16px 24px; text-align: center;">
          <p style="color: #aaa; font-size: 12px; margin: 0;">
            You received this because you are listed as an emergency contact in SafarSync.<br/>
            SafarSync — Travel Smarter. Travel Safer. Travel Together.
          </p>
        </div>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`[Email] Emergency contact alert sent to ${toEmail}`);
    return { success: true };
  } catch (err) {
    console.error('[Email] Failed to send emergency contact email:', err.message);
    return { success: false, reason: err.message };
  }
};

module.exports = {
  sendGroupInvitationEmail,
  sendInvitationResponseEmail,
  sendEmergencyAlertEmail,
  sendEmergencyContactEmail,
};
