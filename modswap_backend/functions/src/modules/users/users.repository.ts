import { Timestamp, FieldValue } from 'firebase-admin/firestore';
import { firestore } from '../../config/firebase.config';
import { COLLECTIONS } from '../../config/constants';
import { User, CreateUserData, UpdateUserProfileData } from './users.types';

/**
 * Users Repository - จัดการ Firestore collection 'users'
 * ห้ามใส่ business logic ที่นี่
 */
export class UsersRepository {
  private readonly collection = firestore.collection(COLLECTIONS.USERS);

  /**
   * สร้าง user profile ใหม่ (ใช้ uid จาก Firebase Auth เป็น document id)
   */
  async create(uid: string, data: CreateUserData): Promise<User> {
    const now = Timestamp.now();
    const user: User = {
      ...data,
      id: uid,
      createdAt: now,
      updatedAt: now,
    };
    await this.collection.doc(uid).set(user);
    return user;
  }

  async findById(uid: string): Promise<User | null> {
    const doc = await this.collection.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data() as User;
  }

  async exists(uid: string): Promise<boolean> {
    const doc = await this.collection.doc(uid).get();
    return doc.exists;
  }

  async findByLineId(lineId: string): Promise<User | null> {
    const snapshot = await this.collection
      .where('lineId', '==', lineId)
      .limit(1)
      .get();
    if (snapshot.empty) return null;
    return snapshot.docs[0].data() as User;
  }

  async findByStudentId(studentId: string, excludeUid?: string): Promise<User | null> {
    const snapshot = await this.collection
      .where('studentId', '==', studentId)
      .limit(1)
      .get();
    if (snapshot.empty) return null;
    const doc = snapshot.docs[0];
    if (excludeUid && doc.id === excludeUid) return null;
    return doc.data() as User;
  }

  async update(uid: string, data: UpdateUserProfileData): Promise<void> {
    await this.collection.doc(uid).update({
      ...data,
      updatedAt: Timestamp.now(),
    });
  }

  async incrementTotalTrades(uid: string): Promise<void> {
    await this.collection.doc(uid).update({
      totalTrades: FieldValue.increment(1),
      updatedAt: Timestamp.now(),
    });
  }

  async delete(uid: string): Promise<void> {
    await this.collection.doc(uid).delete();
  }
}
