import { config } from '@/config/config';
import { prisma } from '@/config/database';

type NotificationPayload = {
  title: string;
  body: string;
  data?: Record<string, string>;
};

export class NotificationService {
  static async sendToUser(userId: string, payload: NotificationPayload): Promise<void> {
    if (!config.firebaseServerKey) return;
    const tokens = await prisma.deviceToken.findMany({ where: { userId } });
    if (!tokens.length) return;
    await this.send(tokens.map((t: { token: string }) => t.token), payload);
  }

  static async sendToTokens(tokens: string[], payload: NotificationPayload): Promise<void> {
    if (!config.firebaseServerKey) return;
    if (!tokens.length) return;
    await this.send(tokens, payload);
  }

  private static async send(tokens: string[], payload: NotificationPayload): Promise<void> {
    const body = {
      registration_ids: tokens,
      notification: { title: payload.title, body: payload.body },
      data: payload.data || {},
    };
    await (await import('node-fetch')).default('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `key=${config.firebaseServerKey}`,
      },
      body: JSON.stringify(body),
    }).catch(() => undefined);
  }
}

