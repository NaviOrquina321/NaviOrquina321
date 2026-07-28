import React, { createContext, useContext, useState, ReactNode } from 'react';
import { DatabaseHelper, UserRecord } from '../services/DatabaseHelper';

interface AuthContextType {
  currentUser: UserRecord | null;
  isLoading: boolean;
  login: (email: string, password: string, expectedRole: string) => Promise<boolean>;
  registerPatient: (name: string, email: string, password: string, phone?: string) => Promise<void>;
  registerDoctor: (
    name: string,
    email: string,
    password: string,
    licenseNumber: string,
    certificatePath: string,
    certificateSize: number,
    specialty: string,
    location: string,
    phone?: string
  ) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [currentUser, setCurrentUser] = useState<UserRecord | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const login = async (email: string, password: string, expectedRole: string): Promise<boolean> => {
    setIsLoading(true);
    try {
      const user = await DatabaseHelper.getUserByEmail(email);
      if (!user) throw new Error('User not found');

      const hash = await DatabaseHelper.hashPassword(password);
      if (user.password_hash !== hash) throw new Error('Invalid password');

      if (user.role !== expectedRole) {
        throw new Error(`Incorrect role selection. This account is registered as a ${user.role}.`);
      }

      if (user.role === 'Doctor' && user.status === 'Pending') {
        throw new Error('Your doctor account is pending administrator approval.');
      } else if (user.status === 'Rejected') {
        throw new Error('Your account has been rejected or suspended.');
      }

      setCurrentUser(user);
      setIsLoading(false);
      return true;
    } catch (err: any) {
      setIsLoading(false);
      throw err;
    }
  };

  const registerPatient = async (name: string, email: string, password: string, phone?: string): Promise<void> => {
    setIsLoading(true);
    try {
      const existing = await DatabaseHelper.getUserByEmail(email);
      if (existing) throw new Error('Email already registered');

      const hash = await DatabaseHelper.hashPassword(password);
      await DatabaseHelper.registerUser({
        role: 'Patient',
        email,
        password_hash: hash,
        name,
        phone,
        status: 'Approved'
      });
      setIsLoading(false);
    } catch (err: any) {
      setIsLoading(false);
      throw err;
    }
  };

  const registerDoctor = async (
    name: string,
    email: string,
    password: string,
    licenseNumber: string,
    certificatePath: string,
    certificateSize: number,
    specialty: string,
    location: string,
    phone?: string
  ): Promise<void> => {
    setIsLoading(true);
    try {
      const lowerPath = certificatePath.toLowerCase();
      const isPdf = lowerPath.endsWith('.pdf');
      const isImage = lowerPath.endsWith('.png') || lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg') || lowerPath.endsWith('.webp');

      if (!isPdf && !isImage) throw new Error('Invalid file format. Only PDF and image uploads are supported.');
      if (certificateSize > 5 * 1024 * 1024) throw new Error('File size too large. Maximum file size allowed is 5MB.');

      const existing = await DatabaseHelper.getUserByEmail(email);
      if (existing) throw new Error('Email already registered');

      const hash = await DatabaseHelper.hashPassword(password);
      await DatabaseHelper.registerUser(
        { role: 'Doctor', email, password_hash: hash, name, phone, status: 'Pending' },
        { license_number: licenseNumber, certificate_path: certificatePath, approved: 0, specialty, location }
      );
      setIsLoading(false);
    } catch (err: any) {
      setIsLoading(false);
      throw err;
    }
  };

  const logout = () => setCurrentUser(null);

  return (
    <AuthContext.Provider value={{ currentUser, isLoading, login, registerPatient, registerDoctor, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) throw new Error('useAuth must be used within an AuthProvider');
  return context;
}
