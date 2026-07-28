import React, { createContext, useContext, useState, ReactNode } from 'react';
import { DatabaseHelper, AvailabilityRecord, AppointmentRecord } from '../services/DatabaseHelper';

interface DoctorContextType {
  availabilityList: AvailabilityRecord[];
  appointments: AppointmentRecord[];
  patientNames: { [key: number]: string };
  pendingDoctors: any[];
  isLoading: boolean;
  loadDoctorSchedule: (doctorId: number) => Promise<void>;
  saveAvailability: (doctorId: number, updatedList: AvailabilityRecord[]) => Promise<void>;
  toggleSlot: (doctorId: number, date: string, startTime: string, makeOpen: boolean) => Promise<void>;
  loadTogglesForDate: (doctorId: number, date: string) => Promise<any[]>;
  loadPendingDoctors: () => Promise<void>;
  approveDoctor: (userId: number, approve: boolean) => Promise<void>;
}

const DoctorContext = createContext<DoctorContextType | undefined>(undefined);

export function DoctorProvider({ children }: { children: ReactNode }) {
  const [availabilityList, setAvailabilityList] = useState<AvailabilityRecord[]>([]);
  const [appointments, setAppointments] = useState<AppointmentRecord[]>([]);
  const [patientNames, setPatientNames] = useState<{ [key: number]: string }>({});
  const [pendingDoctors, setPendingDoctors] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  const loadDoctorSchedule = async (doctorId: number) => {
    setIsLoading(true);
    try {
      const avList = await DatabaseHelper.getDoctorAvailability(doctorId);
      const appts = await DatabaseHelper.getAppointmentsForDoctor(doctorId);

      const names: { [key: number]: string } = {};
      for (const appt of appts) {
        if (!names[appt.patient_id]) {
          const patient = await DatabaseHelper.getUserById(appt.patient_id);
          if (patient) {
            names[appt.patient_id] = patient.name;
          }
        }
      }

      setAvailabilityList(avList);
      setAppointments(appts);
      setPatientNames(names);
      setIsLoading(false);
    } catch (err) {
      setIsLoading(false);
      throw err;
    }
  };

  const saveAvailability = async (doctorId: number, updatedList: AvailabilityRecord[]) => {
    setIsLoading(true);
    try {
      await DatabaseHelper.saveDoctorAvailability(doctorId, updatedList);
      setAvailabilityList(updatedList);
      setIsLoading(false);
    } catch (err) {
      setIsLoading(false);
      throw err;
    }
  };

  const toggleSlot = async (doctorId: number, date: string, startTime: string, makeOpen: boolean) => {
    try {
      await DatabaseHelper.setSlotToggle({
        doctor_id: doctorId,
        date,
        start_time: startTime,
        is_open: makeOpen ? 1 : 0
      });
    } catch (err) {
      throw err;
    }
  };

  const loadTogglesForDate = async (doctorId: number, date: string) => {
    return await DatabaseHelper.getSlotToggles(doctorId, date);
  };

  const loadPendingDoctors = async () => {
    setIsLoading(true);
    try {
      const list = await DatabaseHelper.getPendingDoctors();
      setPendingDoctors(list);
      setIsLoading(false);
    } catch (err) {
      setIsLoading(false);
      throw err;
    }
  };

  const approveDoctor = async (userId: number, approve: boolean) => {
    try {
      await DatabaseHelper.updateDoctorApproval(userId, approve);
      await loadPendingDoctors();
    } catch (err) {
      throw err;
    }
  };

  return (
    <DoctorContext.Provider
      value={{
        availabilityList,
        appointments,
        patientNames,
        pendingDoctors,
        isLoading,
        loadDoctorSchedule,
        saveAvailability,
        toggleSlot,
        loadTogglesForDate,
        loadPendingDoctors,
        approveDoctor
      }}
    >
      {children}
    </DoctorContext.Provider>
  );
}

export function useDoctor() {
  const context = useContext(DoctorContext);
  if (context === undefined) {
    throw new Error('useDoctor must be used within a DoctorProvider');
  }
  return context;
}
