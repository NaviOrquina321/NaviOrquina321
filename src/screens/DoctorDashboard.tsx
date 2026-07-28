import React, { useEffect, useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  ScrollView,
  SafeAreaView,
  ActivityIndicator,
  Alert,
  TextInput,
  Switch
} from 'react-native';
import { useAuth } from '../context/AuthContext';
import { useDoctor } from '../context/DoctorContext';
import { Stethoscope, LogOut, Calendar, Clock, Edit2, ShieldAlert } from 'lucide-react-native';
import { AvailabilityRecord } from '../services/DatabaseHelper';

const DAYS_OF_WEEK = [
  { id: 1, name: 'Monday' },
  { id: 2, name: 'Tuesday' },
  { id: 3, name: 'Wednesday' },
  { id: 4, name: 'Thursday' },
  { id: 5, name: 'Friday' }
];

export function DoctorDashboard({ navigation }: any) {
  const { logout, currentUser } = useAuth();
  const {
    availabilityList,
    appointments,
    patientNames,
    isLoading,
    loadDoctorSchedule,
    saveAvailability,
    toggleSlot,
    loadTogglesForDate
  } = useDoctor();

  // Active Tab: 'appointments' | 'availability' | 'overrides'
  const [activeTab, setActiveTab] = useState<'appointments' | 'availability' | 'overrides'>('appointments');

  // Availability editing state
  const [localAvailability, setLocalAvailability] = useState<AvailabilityRecord[]>([]);

  // Override State
  const [overrideDate, setOverrideDate] = useState(() => {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  });
  const [overrideSlots, setOverrideSlots] = useState<{ time: string; is_open: boolean }[]>([]);

  useEffect(() => {
    if (currentUser) {
      loadDoctorSchedule(currentUser.id)
        .then(() => {
          // Initialize local state for availability
          setLocalAvailability(availabilityList);
        })
        .catch((err: any) => {
          Alert.alert('Error', err.message || 'Failed to load doctor schedule.');
        });
    }
  }, [currentUser]);

  // Update local state when context availability list changes
  useEffect(() => {
    setLocalAvailability(availabilityList);
  }, [availabilityList]);

  // Load slot overrides when overrideDate is updated or tab becomes active
  useEffect(() => {
    if (activeTab === 'overrides' && currentUser) {
      fetchSlotOverrides();
    }
  }, [overrideDate, activeTab]);

  const fetchSlotOverrides = async () => {
    if (!currentUser) return;
    try {
      const toggles = await loadTogglesForDate(currentUser.id, overrideDate);

      // We will offer toggling for standard hourly slots 09:00 to 17:00
      const standardTimes = ['09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00'];
      const merged = standardTimes.map((time) => {
        const toggle = toggles.find((t: any) => t.start_time === time);
        if (toggle) {
          return { time, is_open: toggle.is_open === 1 };
        }
        // If no toggle, default is open (true) since standard hours are 09:00-17:00
        return { time, is_open: true };
      });
      setOverrideSlots(merged);
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to load slot overrides.');
    }
  };

  const handleToggleWeeklyDay = (day_of_week: number) => {
    setLocalAvailability((prev) =>
      prev.map((item) =>
        item.day_of_week === day_of_week
          ? { ...item, is_open: item.is_open === 1 ? 0 : 1 }
          : item
      )
    );
  };

  const handleWeeklyTimeChange = (day_of_week: number, field: 'start_time' | 'end_time', value: string) => {
    setLocalAvailability((prev) =>
      prev.map((item) =>
        item.day_of_week === day_of_week
          ? { ...item, [field]: value }
          : item
      )
    );
  };

  const handleSaveWeeklyAvailability = async () => {
    if (!currentUser) return;
    try {
      // Basic format validation
      for (const item of localAvailability) {
        if (!/^\d{2}:\d{2}$/.test(item.start_time) || !/^\d{2}:\d{2}$/.test(item.end_time)) {
          Alert.alert('Validation Error', 'Time must be in HH:MM format.');
          return;
        }
      }
      await saveAvailability(currentUser.id, localAvailability);
      Alert.alert('Success', 'Weekly availability saved successfully!');
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to save weekly availability.');
    }
  };

  const handleToggleOverrideSlot = async (time: string, currentStatus: boolean) => {
    if (!currentUser) return;
    const newStatus = !currentStatus;
    try {
      await toggleSlot(currentUser.id, overrideDate, time, newStatus);
      setOverrideSlots((prev) =>
        prev.map((s) => (s.time === time ? { ...s, is_open: newStatus } : s))
      );
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to toggle slot override.');
    }
  };

  const handleLogout = () => {
    logout();
    navigation.navigate('Login');
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <View style={styles.headerTitleContainer}>
          <Stethoscope size={24} color="#fff" />
          <Text style={styles.headerTitle}>Doctor Portal</Text>
        </View>
        <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
          <LogOut size={20} color="#fff" />
          <Text style={styles.logoutText}>Log Out</Text>
        </TouchableOpacity>
      </View>

      {/* Tabs */}
      <View style={styles.tabContainer}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'appointments' && styles.tabActive]}
          onPress={() => setActiveTab('appointments')}
        >
          <Text style={[styles.tabText, activeTab === 'appointments' && styles.tabTextActive]}>Appointments</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'availability' && styles.tabActive]}
          onPress={() => setActiveTab('availability')}
        >
          <Text style={[styles.tabText, activeTab === 'availability' && styles.tabTextActive]}>Weekly Schedule</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'overrides' && styles.tabActive]}
          onPress={() => setActiveTab('overrides')}
        >
          <Text style={[styles.tabText, activeTab === 'overrides' && styles.tabTextActive]}>Slot Overrides</Text>
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent}>
        {activeTab === 'appointments' && (
          <View>
            <View style={styles.welcomeCard}>
              <Text style={styles.welcomeTitle}>Dr. {currentUser?.name}</Text>
              <Text style={styles.welcomeSubtitle}>View and manage your appointments with patients</Text>
            </View>

            <Text style={styles.sectionTitle}>Your Schedule</Text>

            {isLoading ? (
              <ActivityIndicator size="large" color="#1d4ed8" style={styles.loader} />
            ) : appointments.length === 0 ? (
              <View style={styles.emptyContainer}>
                <Text style={styles.emptyText}>You have no scheduled appointments.</Text>
              </View>
            ) : (
              appointments.map((appt) => (
                <View key={appt.id} style={styles.appointmentCard}>
                  <View style={styles.apptHeader}>
                    <Calendar size={20} color="#1d4ed8" />
                    <Text style={styles.apptTime}>{appt.datetime}</Text>
                  </View>
                  <View style={styles.apptDetailRow}>
                    <Text style={styles.apptLabel}>Patient:</Text>
                    <Text style={styles.apptVal}>{patientNames[appt.patient_id] || `Patient #${appt.patient_id}`}</Text>
                  </View>
                  <View style={styles.apptDetailRow}>
                    <Text style={styles.apptLabel}>Status:</Text>
                    <View style={[styles.statusBadge, appt.status === 'Cancelled' ? styles.statusCancel : appt.status === 'Rescheduled' ? styles.statusResched : styles.statusBooked]}>
                      <Text style={styles.statusText}>{appt.status}</Text>
                    </View>
                  </View>
                </View>
              ))
            )}
          </View>
        )}

        {activeTab === 'availability' && (
          <View>
            <View style={styles.welcomeCard}>
              <Text style={styles.welcomeTitle}>Configure Weekly Availability</Text>
              <Text style={styles.welcomeSubtitle}>Set standard office hours (Monday to Friday)</Text>
            </View>

            {DAYS_OF_WEEK.map((day) => {
              const currentSet = localAvailability.find((a) => a.day_of_week === day.id);
              const isOpen = currentSet ? currentSet.is_open === 1 : false;

              return (
                <View key={day.id} style={styles.dayConfigRow}>
                  <View style={styles.dayLabelContainer}>
                    <Text style={styles.dayName}>{day.name}</Text>
                    <Switch
                      value={isOpen}
                      onValueChange={() => handleToggleWeeklyDay(day.id)}
                      trackColor={{ false: '#d1d5db', true: '#93c5fd' }}
                      thumbColor={isOpen ? '#1d4ed8' : '#f3f4f6'}
                    />
                  </View>

                  {isOpen && currentSet && (
                    <View style={styles.timeInputsRow}>
                      <View style={styles.timeInputContainer}>
                        <Clock size={16} color="#6b7280" />
                        <TextInput
                          style={styles.timeInput}
                          value={currentSet.start_time}
                          onChangeText={(val) => handleWeeklyTimeChange(day.id, 'start_time', val)}
                          placeholder="09:00"
                          maxLength={5}
                        />
                      </View>
                      <Text style={styles.timeSeparator}>to</Text>
                      <View style={styles.timeInputContainer}>
                        <Clock size={16} color="#6b7280" />
                        <TextInput
                          style={styles.timeInput}
                          value={currentSet.end_time}
                          onChangeText={(val) => handleWeeklyTimeChange(day.id, 'end_time', val)}
                          placeholder="17:00"
                          maxLength={5}
                        />
                      </View>
                    </View>
                  )}
                  {!isOpen && (
                    <Text style={styles.closedText}>Clinic is closed on this day</Text>
                  )}
                </View>
              );
            })}

            <TouchableOpacity style={styles.saveBtn} onPress={handleSaveWeeklyAvailability} disabled={isLoading}>
              {isLoading ? (
                <ActivityIndicator color="#fff" />
              ) : (
                <Text style={styles.saveBtnText}>Save Standard Schedule</Text>
              )}
            </TouchableOpacity>
          </View>
        )}

        {activeTab === 'overrides' && (
          <View>
            <View style={styles.welcomeCard}>
              <Text style={styles.welcomeTitle}>Date-Specific Overrides</Text>
              <Text style={styles.welcomeSubtitle}>Open or close specific timeslots for a chosen day</Text>
            </View>

            <View style={styles.dateSelectorContainer}>
              <Text style={styles.dateLabel}>Select Date (YYYY-MM-DD):</Text>
              <TextInput
                style={styles.dateInput}
                value={overrideDate}
                onChangeText={setOverrideDate}
                placeholder="YYYY-MM-DD"
              />
            </View>

            <Text style={styles.sectionTitle}>Timeslots for {overrideDate}</Text>
            <Text style={styles.hintText}>Toggle to make timeslots open or closed on this specific day.</Text>

            <View style={styles.slotsGrid}>
              {overrideSlots.map((slot) => (
                <View key={slot.time} style={[styles.slotOverrideCard, !slot.is_open && styles.slotOverrideCardClosed]}>
                  <Text style={styles.slotTimeText}>{slot.time}</Text>
                  <TouchableOpacity
                    style={[styles.toggleBtn, slot.is_open ? styles.toggleBtnOpen : styles.toggleBtnClosed]}
                    onPress={() => handleToggleOverrideSlot(slot.time, slot.is_open)}
                  >
                    <Text style={styles.toggleBtnText}>{slot.is_open ? 'OPEN' : 'CLOSED'}</Text>
                  </TouchableOpacity>
                </View>
              ))}
            </View>
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f3f4f6'
  },
  header: {
    backgroundColor: '#1e3a8a',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 16,
    paddingHorizontal: 20
  },
  headerTitleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#fff'
  },
  logoutButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6
  },
  logoutText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 14
  },
  tabContainer: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e5e7eb'
  },
  tab: {
    flex: 1,
    paddingVertical: 14,
    alignItems: 'center'
  },
  tabActive: {
    borderBottomWidth: 3,
    borderBottomColor: '#1d4ed8'
  },
  tabText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#4b5563'
  },
  tabTextActive: {
    color: '#1d4ed8'
  },
  scrollContent: {
    padding: 20,
    flexGrow: 1
  },
  welcomeCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2
  },
  welcomeTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1e3a8a'
  },
  welcomeSubtitle: {
    fontSize: 13,
    color: '#6b7280',
    marginTop: 4
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#374151',
    marginBottom: 12
  },
  loader: {
    marginTop: 40
  },
  emptyContainer: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 24,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#e5e7eb'
  },
  emptyText: {
    color: '#6b7280',
    fontSize: 14,
    textAlign: 'center'
  },
  appointmentCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2
  },
  apptHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 10
  },
  apptTime: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#1e3a8a'
  },
  apptDetailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6,
    alignItems: 'center'
  },
  apptLabel: {
    fontSize: 13,
    color: '#6b7280',
    fontWeight: '500'
  },
  apptVal: {
    fontSize: 13,
    color: '#374151',
    fontWeight: '600'
  },
  statusBadge: {
    paddingVertical: 4,
    paddingHorizontal: 8,
    borderRadius: 4
  },
  statusBooked: {
    backgroundColor: '#dbeafe'
  },
  statusResched: {
    backgroundColor: '#fef3c7'
  },
  statusCancel: {
    backgroundColor: '#fee2e2'
  },
  statusText: {
    fontSize: 11,
    fontWeight: 'bold',
    color: '#374151'
  },
  dayConfigRow: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2
  },
  dayLabelContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10
  },
  dayName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1e3a8a'
  },
  timeInputsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12
  },
  timeInputContainer: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#d1d5db',
    borderRadius: 6,
    paddingHorizontal: 10,
    paddingVertical: 6,
    gap: 8,
    backgroundColor: '#f9fafb'
  },
  timeInput: {
    flex: 1,
    fontSize: 14,
    color: '#374151',
    padding: 0
  },
  timeSeparator: {
    fontSize: 13,
    color: '#6b7280',
    fontWeight: '500'
  },
  closedText: {
    fontSize: 13,
    color: '#9ca3af',
    fontStyle: 'italic',
    marginTop: 4
  },
  saveBtn: {
    backgroundColor: '#1d4ed8',
    paddingVertical: 14,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 16,
    marginBottom: 24
  },
  saveBtnText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold'
  },
  dateSelectorContainer: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2
  },
  dateLabel: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#374151',
    marginBottom: 8
  },
  dateInput: {
    borderWidth: 1,
    borderColor: '#d1d5db',
    borderRadius: 8,
    padding: 10,
    fontSize: 15,
    backgroundColor: '#fff'
  },
  hintText: {
    fontSize: 12,
    color: '#6b7280',
    marginBottom: 12,
    marginTop: -8
  },
  slotsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12
  },
  slotOverrideCard: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 12,
    width: '47%',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
    borderWidth: 1,
    borderColor: '#e5e7eb'
  },
  slotOverrideCardClosed: {
    borderColor: '#fca5a5',
    backgroundColor: '#fef2f2'
  },
  slotTimeText: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#374151',
    marginBottom: 8
  },
  toggleBtn: {
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 6,
    width: '100%',
    alignItems: 'center'
  },
  toggleBtnOpen: {
    backgroundColor: '#dcfce7',
    borderWidth: 1,
    borderColor: '#86efac'
  },
  toggleBtnClosed: {
    backgroundColor: '#fee2e2',
    borderWidth: 1,
    borderColor: '#fca5a5'
  },
  toggleBtnText: {
    fontSize: 11,
    fontWeight: 'bold',
    color: '#374151'
  }
});
