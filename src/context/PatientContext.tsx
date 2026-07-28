import React, { createContext, useContext, useState, ReactNode } from 'react';
import { DatabaseHelper, AppointmentRecord } from '../services/DatabaseHelper';

interface PatientContextType {
  doctors: any[];
  filteredDoctors: any[];
  patientAppointments: AppointmentRecord[];
  doctorNames: { [key: number]: string };
  isLoading: boolean;
  loadDoctors: () => Promise<void>;
  filterDoctors: (query: string) => void;
  loadPatientAppointments: (patientId: number) => Promise<void>;
  getAvailableSlots: (doctorId: number, date: Date) => Promise<string[]>;
  bookAppointment: (
    patientId: number,
    doctorId: number,
    date: Date,
    selectedSlot?: string | null
  ) => Promise<void>;
  cancelAppointment: (appointmentId: number, patientId: number) => Promise<void>;
  rescheduleBooking: (
    appointmentId: number,
    patientId: number,
    doctorId: number,
    newDate: Date,
    newSlot: string
  ) => Promise<void>;
}

const PatientContext = createContext<PatientContextType | undefined>(undefined);

export function PatientProvider({ children }: { children: ReactNode }) {
  const [doctors, setDoctors] = useState<any[]>([]);
  const [filteredDoctors, setFilteredDoctors] = useState<any[]>([]);
  const [patientAppointments, setPatientAppointments] = useState<AppointmentRecord[]>([]);
  const [doctorNames, setDoctorNames] = useState<{ [key: number]: string }>({});
  const [isLoading, setIsLoading] = useState(false);

  const loadDoctors = async () => {
    setIsLoading(true);
    try {
      const list = await DatabaseHelper.getAllApprovedDoctorsWithDetails();
      setDoctors(list);
      setFilteredDoctors(list);
      setIsLoading(false);
    } catch (err) {
      setIsLoading(false);
      throw err;
    }
  };

  const filterDoctors = (query: string) => {
    if (!query.trim()) {
      setFilteredDoctors(doctors);
    } else {
      const q = query.toLowerCase();
      const filtered = doctors.filter((doc) => {
        const name = (doc.name || '').toLowerCase();
        const specialty = (doc.specialty || '').toLowerCase();
        const location = (doc.location || '').toLowerCase();
        const email = (doc.email || '').toLowerCase();
        const phone = (doc.phone || '').toLowerCase();

        return (
          name.includes(q) ||
          specialty.includes(q) ||
          location.includes(q) ||
          email.includes(q) ||
          phone.includes(q)
        );
      });
      setFilteredDoctors(filtered);
    }
  };

  const loadPatientAppointments = async (patientId: number) => {
    setIsLoading(true);
    try {
      const list = await DatabaseHelper.getAppointmentsForPatient(patientId);

      const names: { [key: number]: string } = {};
      for (const appt of list) {
        if (!names[appt.doctor_id]) {
          const docUser = await DatabaseHelper.getUserById(appt.doctor_id);
          if (docUser) {
            names[appt.doctor_id] = docUser.name;
          }
        }
      }

      setPatientAppointments(list);
      setDoctorNames(names);
      setIsLoading(false);
    } catch (err) {
      setIsLoading(false);
      throw err;
    }
  };

  const getAvailableSlots = async (doctorId: number, date: Date): Promise<string[]> => {
    const yyyy = date.getFullYear();
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const dd = String(date.getDate()).padStart(2, '0');
    const dateString = `${yyyy}-${mm}-${dd}`;

    let weekday = date.getDay();
    if (weekday === 0) weekday = 7;

    const allAvailability = await DatabaseHelper.getDoctorAvailability(doctorId);
    const dayAvailability = allAvailability.filter((av) => av.day_of_week === weekday);

    const slotToggles = await DatabaseHelper.getSlotToggles(doctorId, dateString);

    const allAppointments = await DatabaseHelper.getAppointmentsForDoctor(doctorId);
    const activeAppointments = allAppointments.filter((app) => {
      if (app.status === 'Cancelled') return false;
      return app.datetime.startsWith(dateString);
    });

    const slots: string[] = [];

    for (const avail of dayAvailability) {
      if (avail.is_open === 0) continue;

      const startParts = avail.start_time.split(':');
      const endParts = avail.end_time.split(':');
      if (startParts.length !== 2 || endParts.length !== 2) continue;

      const startHour = parseInt(startParts[0], 10);
      const startMin = parseInt(startParts[1], 10);
      const endHour = parseInt(endParts[0], 10);
      const endMin = parseInt(endParts[1], 10);

      let currentHour = startHour;
      let currentMin = startMin;

      while (currentHour < endHour || (currentHour === endHour && currentMin < endMin)) {
        const timeStr = `${String(currentHour).padStart(2, '0')}:${String(currentMin).padStart(2, '0')}`;

        const overrideToggle = slotToggles.find((t) => t.start_time === timeStr);
        let slotIsOpen = true;

        if (overrideToggle) {
          slotIsOpen = overrideToggle.is_open === 1;
        }

        const isBooked = activeAppointments.some((app) => {
          const apptTime = app.datetime.split(' ')[1].substring(0, 5);
          return apptTime === timeStr;
        });

        if (slotIsOpen && !isBooked) {
          slots.push(timeStr);
        }

        currentHour += 1;
      }
    }

    for (const toggle of slotToggles) {
      if (toggle.is_open === 1) {
        const timeStr = toggle.start_time;
        if (!slots.includes(timeStr)) {
          const isBooked = activeAppointments.some((app) => {
            const apptTime = app.datetime.split(' ')[1].substring(0, 5);
            return apptTime === timeStr;
          });
          if (!isBooked) {
            slots.push(timeStr);
          }
        }
      }
    }

    slots.sort();
    return slots;
  };

  const bookAppointment = async (
    patientId: number,
    doctorId: number,
    date: Date,
    selectedSlot?: string | null
  ) => {
    setIsLoading(true);
    try {
      let finalSlot = selectedSlot;
      let bookingDate = date;

      if (!finalSlot) {
        let checkDate = new Date(date);
        for (let i = 0; i < 14; i++) {
          const openSlots = await getAvailableSlots(doctorId, checkDate);
          if (openSlots.length > 0) {
            finalSlot = openSlots[0];
            bookingDate = checkDate;
            break;
          }
          checkDate.setDate(checkDate.getDate() + 1);
        }
      }

      if (!finalSlot) {
        throw new Error('No available slots found for this doctor within the next 2 weeks.');
      }

      const yyyy = bookingDate.getFullYear();
      const mm = String(bookingDate.getMonth() + 1).padStart(2, '0');
      const dd = String(bookingDate.getDate()).padStart(2, '0');
      const dateStr = `${yyyy}-${mm}-${dd}`;
      const datetimeStr = `${dateStr} ${finalSlot}:00`;

      await DatabaseHelper.createAppointment({
        patient_id: patientId,
        doctor_id: doctorId,
        datetime: datetimeStr,
        status: 'Booked'
      });

      await loadPatientAppointments(patientId);
      setIsLoading(false);
    } catch (err) {
      setIsLoading(false);
      throw err;
    }
  };

  const cancelAppointment = async (appointmentId: number, patientId: number) => {
    setIsLoading(true);
    try {
      const list = await DatabaseHelper.getAppointmentsForPatient(patientId);
      const appt = list.find((a) => a.id === appointmentId);
      if (!appt) {
        throw new Error('Appointment not found');
      }

      const apptTime = new Date(appt.datetime.replace(' ', 'T'));
      const diffMs = apptTime.getTime() - Date.now();
      const diffHours = diffMs / (1000 * 60 * 60);

      if (diffHours < 24) {
        throw new Error('Appointments can only be cancelled up to 24 hours before the scheduled time.');
      }

      await DatabaseHelper.updateAppointmentStatus(appointmentId, 'Cancelled');
      await loadPatientAppointments(patientId);
      setIsLoading(false);
    } catch (err) {
      setIsLoading(false);
      throw err;
    }
  };

  const rescheduleBooking = async (
    appointmentId: number,
    patientId: number,
    doctorId: number,
    newDate: Date,
    newSlot: string
  ) => {
    setIsLoading(true);
    try {
      const openSlots = await getAvailableSlots(doctorId, newDate);
      if (!openSlots.includes(newSlot)) {
        throw new Error('The selected slot is no longer available.');
      }

      const yyyy = newDate.getFullYear();
      const mm = String(newDate.getMonth() + 1).padStart(2, '0');
      const dd = String(newDate.getDate()).padStart(2, '0');
      const dateStr = `${yyyy}-${mm}-${dd}`;
      const datetimeStr = `${dateStr} ${newSlot}:00`;

      await DatabaseHelper.rescheduleAppointment(appointmentId, datetimeStr);
      await loadPatientAppointments(patientId);
      setIsLoading(false);
    } catch (err) {
      setIsLoading(false);
      throw err;
    }
  };

  return (
    <PatientContext.Provider
      value={{
        doctors,
        filteredDoctors,
        patientAppointments,
        doctorNames,
        isLoading,
        loadDoctors,
        filterDoctors,
        loadPatientAppointments,
        getAvailableSlots,
        bookAppointment,
        cancelAppointment,
        rescheduleBooking
      }}
    >
      {children}
    </PatientContext.Provider>
  );
}

export function usePatient() {
  const context = useContext(PatientContext);
  if (context === undefined) {
    throw new Error('usePatient must be used within a PatientProvider');
  }
  return context;
}
