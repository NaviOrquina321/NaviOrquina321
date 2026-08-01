import * as Crypto from 'expo-crypto';
import { Platform } from 'react-native';

export interface UserRecord {
  id: number;
  role: 'Patient' | 'Doctor' | 'Admin';
  email: string;
  password_hash: string;
  name: string;
  phone?: string;
  status: 'Approved' | 'Pending' | 'Rejected';
}

export interface DoctorRecord {
  user_id: number;
  license_number: string;
  certificate_path: string;
  approved: number;
  specialty: string;
  location: string;
}

export interface AppointmentRecord {
  id: number;
  patient_id: number;
  doctor_id: number;
  datetime: string;
  status: 'Booked' | 'Rescheduled' | 'Cancelled';
}

export interface AvailabilityRecord {
  doctor_id: number;
  day_of_week: number;
  start_time: string;
  end_time: string;
  is_open: number;
}

export interface SlotToggleRecord {
  doctor_id: number;
  date: string;
  start_time: string;
  is_open: number;
}

export class DatabaseHelper {
  static hashPasswordPlain(password: string): string {
    let hash = 0;
    for (let i = 0; i < password.length; i++) {
      const char = password.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash |= 0;
    }
    return 'sha256-' + Math.abs(hash).toString(16);
  }

  static async hashPassword(password: string): Promise<string> {
    try {
      if (Platform.OS !== 'web') {
        return await Crypto.digestStringAsync(Crypto.CryptoDigestAlgorithm.SHA256, password);
      }
    } catch {}
    return this.hashPasswordPlain(password);
  }

  static isNative(): boolean {
    return Platform.OS !== 'web';
  }

  static async registerUser(user: Omit<UserRecord, 'id'>, doctor?: Omit<DoctorRecord, 'user_id'>): Promise<number> {
    const emailLower = user.email.trim().toLowerCase();
    const existing = memoryDbInstance.users.find((u) => u.email === emailLower);
    if (existing) {
      throw new Error('Email already registered');
    }

    const userId = memoryDbInstance.userAutoId++;
    const newUser: UserRecord = { ...user, id: userId, email: emailLower };
    memoryDbInstance.users.push(newUser);

    if (user.role === 'Doctor' && doctor) {
      memoryDbInstance.doctors.push({ ...doctor, user_id: userId });
      for (let day = 1; day <= 5; day++) {
        memoryDbInstance.availability.push({
          doctor_id: userId,
          day_of_week: day,
          start_time: '09:00',
          end_time: '17:00',
          is_open: 1
        });
      }
    }
    return userId;
  }

  static async getUserByEmail(email: string): Promise<UserRecord | null> {
    return memoryDbInstance.users.find((u) => u.email === email.trim().toLowerCase()) || null;
  }

  static async getUserById(id: number): Promise<UserRecord | null> {
    return memoryDbInstance.users.find((u) => u.id === id) || null;
  }

  static async getPendingDoctors(): Promise<any[]> {
    const pending: any[] = [];
    for (const user of memoryDbInstance.users) {
      if (user.role === 'Doctor' && user.status === 'Pending') {
        const docDetails = memoryDbInstance.doctors.find((d) => d.user_id === user.id);
        pending.push({
          ...user,
          license_number: docDetails?.license_number || '',
          certificate_path: docDetails?.certificate_path || '',
          approved: docDetails?.approved || 0,
          specialty: docDetails?.specialty || 'General Practice',
          location: docDetails?.location || 'General Clinic'
        });
      }
    }
    return pending;
  }

  static async getDoctorDetails(userId: number): Promise<DoctorRecord | null> {
    return memoryDbInstance.doctors.find((d) => d.user_id === userId) || null;
  }

  static async updateDoctorApproval(userId: number, approve: boolean): Promise<void> {
    const user = memoryDbInstance.users.find((u) => u.id === userId);
    if (user) user.status = approve ? 'Approved' : 'Rejected';
    const doc = memoryDbInstance.doctors.find((d) => d.user_id === userId);
    if (doc) doc.approved = approve ? 1 : 0;
  }

  static async getAllApprovedDoctorsWithDetails(): Promise<any[]> {
    const approved: any[] = [];
    for (const user of memoryDbInstance.users) {
      if (user.role === 'Doctor' && user.status === 'Approved') {
        const docDetails = memoryDbInstance.doctors.find((d) => d.user_id === user.id);
        approved.push({
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          specialty: docDetails?.specialty || 'General Practice',
          location: docDetails?.location || 'General Clinic'
        });
      }
    }
    return approved;
  }

  static async getAllUsers(): Promise<UserRecord[]> {
    return memoryDbInstance.users;
  }

  static async getDoctorAvailability(doctorId: number): Promise<AvailabilityRecord[]> {
    return memoryDbInstance.availability.filter((a) => a.doctor_id === doctorId);
  }

  static async saveDoctorAvailability(doctorId: number, list: AvailabilityRecord[]): Promise<void> {
    memoryDbInstance.availability = memoryDbInstance.availability.filter((a) => a.doctor_id !== doctorId);
    memoryDbInstance.availability.push(...list);
  }

  static async getSlotToggles(doctorId: number, date: string): Promise<SlotToggleRecord[]> {
    return memoryDbInstance.slot_toggles.filter((s) => s.doctor_id === doctorId && s.date === date);
  }

  static async setSlotToggle(toggle: SlotToggleRecord): Promise<void> {
    memoryDbInstance.slot_toggles = memoryDbInstance.slot_toggles.filter(
      (s) => s.doctor_id !== toggle.doctor_id || s.date !== toggle.date || s.start_time !== toggle.start_time
    );
    memoryDbInstance.slot_toggles.push(toggle);
  }

  static async createAppointment(appt: Omit<AppointmentRecord, 'id'>): Promise<number> {
    const id = memoryDbInstance.apptAutoId++;
    memoryDbInstance.appointments.push({ ...appt, id });
    return id;
  }

  static async updateAppointmentStatus(id: number, status: 'Booked' | 'Rescheduled' | 'Cancelled'): Promise<void> {
    const appt = memoryDbInstance.appointments.find((a) => a.id === id);
    if (appt) appt.status = status;
  }

  static async rescheduleAppointment(id: number, newDatetime: string): Promise<void> {
    const appt = memoryDbInstance.appointments.find((a) => a.id === id);
    if (appt) {
      appt.datetime = newDatetime;
      appt.status = 'Rescheduled';
    }
  }

  static async getAppointmentsForDoctor(doctorId: number): Promise<AppointmentRecord[]> {
    return memoryDbInstance.appointments.filter((a) => a.doctor_id === doctorId);
  }

  static async getAppointmentsForPatient(patientId: number): Promise<AppointmentRecord[]> {
    return memoryDbInstance.appointments.filter((a) => a.patient_id === patientId);
  }

  static async getAllAppointments(): Promise<AppointmentRecord[]> {
    return memoryDbInstance.appointments;
  }

  static clearDatabase(): void {
    memoryDbInstance.clearAll();
  }
}

class MemoryDB {
  users: UserRecord[] = [];
  doctors: DoctorRecord[] = [];
  appointments: AppointmentRecord[] = [];
  availability: AvailabilityRecord[] = [];
  slot_toggles: SlotToggleRecord[] = [];
  userAutoId = 1;
  apptAutoId = 1;

  constructor() {
    this.seedAdmin();
  }

  seedAdmin() {
    const adminHash = DatabaseHelper.hashPasswordPlain('admin123');
    this.users.push({
      id: 9999,
      role: 'Admin',
      email: 'admin@clinic.com',
      password_hash: adminHash,
      name: 'System Admin',
      phone: '1234567890',
      status: 'Approved'
    });
  }

  clearAll() {
    this.users = [];
    this.doctors = [];
    this.appointments = [];
    this.availability = [];
    this.slot_toggles = [];
    this.userAutoId = 1;
    this.apptAutoId = 1;
    this.seedAdmin();
  }
}

const memoryDbInstance = new MemoryDB();
