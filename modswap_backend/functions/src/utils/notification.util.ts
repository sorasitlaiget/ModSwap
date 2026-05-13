import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase.config';
import { COLLECTIONS, SUBCOLLECTIONS } from '../config/constants';

type NotificationType =
  | 'wishlist'
  | 'ratingReceived'
  | 'rateRequest'
  | 'markSoldReminder'
  | 'priceDrop'
  | 'trending'
  | 'newItemFromSeller'
  | 'welcome'
  | 'emailVerified'
  | 'passwordChanged'
  | 'securityAlert';

interface SendNotificationOptions {
  recipientUid: string;
  type: NotificationType;
  title: string;
  body: string;
  deepLinkTarget?: string;
  data?: Record<string, unknown>;
}

export async function sendNotification(opts: SendNotificationOptions): Promise<void> {
  await db
    .collection(COLLECTIONS.USERS)
    .doc(opts.recipientUid)
    .collection(SUBCOLLECTIONS.NOTIFICATIONS)
    .add({
      type: opts.type,
      title: opts.title,
      body: opts.body,
      createdAt: FieldValue.serverTimestamp(),
      isRead: false,
      ...(opts.deepLinkTarget !== undefined && { deepLinkTarget: opts.deepLinkTarget }),
      ...(opts.data !== undefined && { data: opts.data }),
    });
}
