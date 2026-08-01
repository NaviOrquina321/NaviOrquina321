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
  TextInput
} from 'react-native';
import { useAuth } from '../context/AuthContext';
import { usePatient } from '../context/PatientContext';
import { Calendar, Search, User, MapPin, Clock, ArrowRight, X, CalendarCheck2 } from 'lucide-react-native';

export function PatientDashboard({ navigation }: any) {
  const { logout, currentUser } = useAuth();
  const {
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
  } = usePatient();

  // Navigation tab: 'appointments' | 'book'
  const [activeTab, setActiveTab] = useState<'appointments' | 'book'>('appointments');

  // Search query
  const [searchQuery, setSearchQuery] = useState('');

  // Booking states
  const [selectedDoctor, setSelectedDoctor] = useState<any | null>(null);
  const [bookingDateStr, setBookingDateStr] = useState(() => {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  });
  const [availableSlots, setAvailableSlots] = useState<string[]>([]);
  const [isLoadingSlots, setIsLoadingSlots] = useState(false);

  // Rescheduling states
  const [reschedulingAppt, setReschedulingAppt] = useState<any | null>(null);
  const [reschedDateStr, setReschedDateStr] = useState('');
  const [reschedSlots, setReschedSlots] = useState<string[]>([]);
  const [isLoadingReschedSlots, setIsLoadingReschedSlots] = useState(false);

  useEffect(() => {
    if (currentUser) {
      loadPatientAppointments(currentUser.id).catch((err: any) => {
        Alert.alert('Error', err.message || 'Failed to load appointments.');
      });
      loadDoctors().catch((err: any) => {
        Alert.alert('Error', err.message || 'Failed to load doctors.');
      });
    }
  }, [currentUser]);

  // Handle Search
  const handleSearch = (query: string) => {
    setSearchQuery(query);
    filterDoctors(query);
  };

  // Fetch Slots for Booking Date
  const handleFetchSlots = async () => {
    if (!selectedDoctor) return;
    setIsLoadingSlots(true);
    try {
      const dateParts = bookingDateStr.split('-');
      if (dateParts.length !== 3) throw new Error('Invalid Date format. Use YYYY-MM-DD');
      const dateObj = new Date(parseInt(dateParts[0], 10), parseInt(dateParts[1], 10) - 1, parseInt(dateParts[2], 10));
      if (isNaN(dateObj.getTime())) throw new Error('Invalid Date value.');

      const slots = await getAvailableSlots(selectedDoctor.id, dateObj);
      setAvailableSlots(slots);
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to fetch slots.');
    } finally {
      setIsLoadingSlots(false);
    }
  };

  // Fetch Slots for Rescheduling Date
  const handleFetchReschedSlots = async () => {
    if (!reschedulingAppt) return;
    setIsLoadingReschedSlots(true);
    try {
      const dateParts = reschedDateStr.split('-');
      if (dateParts.length !== 3) throw new Error('Invalid Date format. Use YYYY-MM-DD');
      const dateObj = new Date(parseInt(dateParts[0], 10), parseInt(dateParts[1], 10) - 1, parseInt(dateParts[2], 10));
      if (isNaN(dateObj.getTime())) throw new Error('Invalid Date value.');

      const slots = await getAvailableSlots(reschedulingAppt.doctor_id, dateObj);
      setReschedSlots(slots);
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to fetch slots.');
    } finally {
      setIsLoadingReschedSlots(false);
    }
  };

  useEffect(() => {
    if (selectedDoctor) {
      handleFetchSlots();
    }
  }, [selectedDoctor, bookingDateStr]);

  useEffect(() => {
    if (reschedulingAppt && reschedDateStr) {
      handleFetchReschedSlots();
    }
  }, [reschedulingAppt, reschedDateStr]);

  const handleBook = async (slot: string | null) => {
    if (!currentUser || !selectedDoctor) return;
    try {
      const dateParts = bookingDateStr.split('-');
      const dateObj = new Date(parseInt(dateParts[0], 10), parseInt(dateParts[1], 10) - 1, parseInt(dateParts[2], 10));

      await bookAppointment(currentUser.id, selectedDoctor.id, dateObj, slot);
      Alert.alert('Success', 'Your appointment has been booked successfully!');
      setSelectedDoctor(null);
      setActiveTab('appointments');
    } catch (err: any) {
      Alert.alert('Booking Failed', err.message || 'An error occurred.');
    }
  };

  const handleCancel = (appointmentId: number) => {
    if (!currentUser) return;
    Alert.alert(
      'Cancel Appointment',
      'Are you sure you want to cancel this appointment?',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Yes',
          onPress: async () => {
            try {
              await cancelAppointment(appointmentId, currentUser.id);
              Alert.alert('Cancelled', 'Your appointment has been cancelled.');
            } catch (err: any) {
              Alert.alert('Cancellation Failed', err.message || 'Cannot cancel this appointment.');
            }
          }
        }
      ]
    );
  };

  const startReschedule = (appt: any) => {
    setReschedulingAppt(appt);
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    setReschedDateStr(`${yyyy}-${mm}-${dd}`);
  };

  const handleRescheduleSubmit = async (slot: string) => {
    if (!currentUser || !reschedulingAppt) return;
    try {
      const dateParts = reschedDateStr.split('-');
      const dateObj = new Date(parseInt(dateParts[0], 10), parseInt(dateParts[1], 10) - 1, parseInt(dateParts[2], 10));

      await rescheduleBooking(reschedulingAppt.id, currentUser.id, reschedulingAppt.doctor_id, dateObj, slot);
      Alert.alert('Success', 'Your appointment has been rescheduled.');
      setReschedulingAppt(null);
    } catch (err: any) {
      Alert.alert('Reschedule Failed', err.message || 'An error occurred.');
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
          <Calendar size={24} color="#fff" />
          <Text style={styles.headerTitle}>Patient Portal</Text>
        </View>
        <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
          <X size={20} color="#fff" />
          <Text style={styles.logoutText}>Log Out</Text>
        </TouchableOpacity>
      </View>

      {/* Tabs */}
      <View style={styles.tabContainer}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'appointments' && styles.tabActive]}
          onPress={() => {
            setActiveTab('appointments');
            setReschedulingAppt(null);
          }}
        >
          <Text style={[styles.tabText, activeTab === 'appointments' && styles.tabTextActive]}>My Appointments</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'book' && styles.tabActive]}
          onPress={() => {
            setActiveTab('book');
            setSelectedDoctor(null);
          }}
        >
          <Text style={[styles.tabText, activeTab === 'book' && styles.tabTextActive]}>Book Appointment</Text>
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent}>
        {activeTab === 'appointments' && (
          <View>
            <View style={styles.welcomeCard}>
              <Text style={styles.welcomeTitle}>Hello, {currentUser?.name}</Text>
              <Text style={styles.welcomeSubtitle}>View and manage your scheduled healthcare visits</Text>
            </View>

            {reschedulingAppt ? (
              <View style={styles.reschedArea}>
                <View style={styles.reschedHeader}>
                  <Text style={styles.reschedTitle}>Reschedule Appointment</Text>
                  <TouchableOpacity onPress={() => setReschedulingAppt(null)}>
                    <X size={20} color="#6b7280" />
                  </TouchableOpacity>
                </View>

                <Text style={styles.reschedMeta}>
                  Doctor: {doctorNames[reschedulingAppt.doctor_id] || 'Doctor'}
                </Text>
                <Text style={styles.reschedMeta}>Current: {reschedulingAppt.datetime}</Text>

                <View style={styles.inputGroup}>
                  <Text style={styles.inputLabel}>New Date (YYYY-MM-DD):</Text>
                  <TextInput
                    style={styles.textInput}
                    value={reschedDateStr}
                    onChangeText={setReschedDateStr}
                    placeholder="YYYY-MM-DD"
                  />
                </View>

                <Text style={styles.subTitle}>Select a New Time Slot:</Text>
                {isLoadingReschedSlots ? (
                  <ActivityIndicator size="small" color="#1d4ed8" />
                ) : reschedSlots.length === 0 ? (
                  <Text style={styles.noSlotsText}>No slots available for this day.</Text>
                ) : (
                  <View style={styles.slotsRow}>
                    {reschedSlots.map((slot) => (
                      <TouchableOpacity
                        key={slot}
                        style={styles.slotBtn}
                        onPress={() => handleRescheduleSubmit(slot)}
                      >
                        <Text style={styles.slotBtnText}>{slot}</Text>
                      </TouchableOpacity>
                    ))}
                  </View>
                )}
              </View>
            ) : null}

            <Text style={styles.sectionTitle}>Your Appointments</Text>

            {isLoading ? (
              <ActivityIndicator size="large" color="#1d4ed8" style={styles.loader} />
            ) : patientAppointments.length === 0 ? (
              <View style={styles.emptyContainer}>
                <Text style={styles.emptyText}>You don't have any appointments scheduled.</Text>
              </View>
            ) : (
              patientAppointments.map((appt) => (
                <View key={appt.id} style={styles.apptCard}>
                  <View style={styles.apptHeaderRow}>
                    <View style={styles.docHeaderContainer}>
                      <User size={20} color="#1e3a8a" />
                      <Text style={styles.docName}>{doctorNames[appt.doctor_id] || `Doctor #${appt.doctor_id}`}</Text>
                    </View>
                    <View style={[styles.statusBadge, appt.status === 'Cancelled' ? styles.statusCancel : appt.status === 'Rescheduled' ? styles.statusResched : styles.statusBooked]}>
                      <Text style={styles.statusText}>{appt.status}</Text>
                    </View>
                  </View>

                  <View style={styles.apptBody}>
                    <Clock size={16} color="#4b5563" />
                    <Text style={styles.apptTime}>{appt.datetime}</Text>
                  </View>

                  {appt.status !== 'Cancelled' && (
                    <View style={styles.apptActions}>
                      <TouchableOpacity
                        style={[styles.actionBtn, styles.reschedBtn]}
                        onPress={() => startReschedule(appt)}
                      >
                        <Clock size={14} color="#1d4ed8" />
                        <Text style={styles.reschedBtnText}>Reschedule</Text>
                      </TouchableOpacity>

                      <TouchableOpacity
                        style={[styles.actionBtn, styles.cancelBtn]}
                        onPress={() => handleCancel(appt.id)}
                      >
                        <X size={14} color="#dc2626" />
                        <Text style={styles.cancelBtnText}>Cancel Booking</Text>
                      </TouchableOpacity>
                    </View>
                  )}
                </View>
              ))
            )}
          </View>
        )}

        {activeTab === 'book' && (
          <View>
            {selectedDoctor ? (
              <View style={styles.bookingArea}>
                <TouchableOpacity style={styles.backBtn} onPress={() => setSelectedDoctor(null)}>
                  <Text style={styles.backBtnText}>← Back to Doctor List</Text>
                </TouchableOpacity>

                <View style={styles.docDetailCard}>
                  <Text style={styles.docTitleName}>{selectedDoctor.name}</Text>
                  <Text style={styles.docTitleSpecialty}>{selectedDoctor.specialty}</Text>
                  <View style={styles.locRow}>
                    <MapPin size={16} color="#6b7280" />
                    <Text style={styles.docTitleLoc}>{selectedDoctor.location}</Text>
                  </View>
                </View>

                <View style={styles.inputGroup}>
                  <Text style={styles.inputLabel}>Choose Appointment Date (YYYY-MM-DD):</Text>
                  <TextInput
                    style={styles.textInput}
                    value={bookingDateStr}
                    onChangeText={setBookingDateStr}
                    placeholder="YYYY-MM-DD"
                  />
                </View>

                <View style={styles.bookingOptionsRow}>
                  <TouchableOpacity
                    style={styles.quickBookBtn}
                    onPress={() => handleBook(null)}
                  >
                    <CalendarCheck2 size={16} color="#fff" />
                    <Text style={styles.quickBookBtnText}>Quick Book (Next 2 Weeks Auto-Find)</Text>
                  </TouchableOpacity>
                </View>

                <Text style={styles.sectionTitle}>Select Timeslot:</Text>
                {isLoadingSlots ? (
                  <ActivityIndicator size="small" color="#1d4ed8" />
                ) : availableSlots.length === 0 ? (
                  <Text style={styles.noSlotsText}>No slots available for this day. Try quick booking or select another date.</Text>
                ) : (
                  <View style={styles.slotsRow}>
                    {availableSlots.map((slot) => (
                      <TouchableOpacity
                        key={slot}
                        style={styles.slotOptionBtn}
                        onPress={() => handleBook(slot)}
                      >
                        <Text style={styles.slotOptionBtnText}>{slot}</Text>
                      </TouchableOpacity>
                    ))}
                  </View>
                )}
              </View>
            ) : (
              <View>
                {/* Search Bar */}
                <View style={styles.searchBar}>
                  <Search size={20} color="#6b7280" />
                  <TextInput
                    style={styles.searchInput}
                    placeholder="Search doctors, specialties, or clinics..."
                    value={searchQuery}
                    onChangeText={handleSearch}
                  />
                </View>

                <Text style={styles.sectionTitle}>Available Medical Specialists</Text>

                {filteredDoctors.length === 0 ? (
                  <View style={styles.emptyContainer}>
                    <Text style={styles.emptyText}>No registered specialists match your criteria.</Text>
                  </View>
                ) : (
                  filteredDoctors.map((doc) => (
                    <TouchableOpacity
                      key={doc.id}
                      style={styles.doctorItemCard}
                      onPress={() => setSelectedDoctor(doc)}
                    >
                      <View style={styles.docItemHeader}>
                        <View style={styles.docItemMeta}>
                          <Text style={styles.docItemName}>{doc.name}</Text>
                          <Text style={styles.docItemSpecialty}>{doc.specialty}</Text>
                        </View>
                        <ArrowRight size={20} color="#1d4ed8" />
                      </View>
                      <View style={styles.docItemBody}>
                        <MapPin size={14} color="#6b7280" />
                        <Text style={styles.docItemLoc}>{doc.location}</Text>
                      </View>
                    </TouchableOpacity>
                  ))
                )}
              </View>
            )}
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
  subTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#4b5563',
    marginBottom: 8,
    marginTop: 12
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
  apptCard: {
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
  apptHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10
  },
  docHeaderContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8
  },
  docName: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#1e3a8a'
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
  apptBody: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 12
  },
  apptTime: {
    fontSize: 13,
    color: '#4b5563'
  },
  apptActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 12,
    borderTopWidth: 1,
    borderTopColor: '#f3f4f6',
    paddingTop: 12
  },
  actionBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 6,
    borderWidth: 1
  },
  reschedBtn: {
    borderColor: '#1d4ed8',
    backgroundColor: '#eff6ff'
  },
  reschedBtnText: {
    fontSize: 12,
    fontWeight: 'bold',
    color: '#1d4ed8'
  },
  cancelBtn: {
    borderColor: '#dc2626',
    backgroundColor: '#fef2f2'
  },
  cancelBtnText: {
    fontSize: 12,
    fontWeight: 'bold',
    color: '#dc2626'
  },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#d1d5db',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    gap: 10,
    marginBottom: 20
  },
  searchInput: {
    flex: 1,
    fontSize: 15,
    padding: 0,
    color: '#374151'
  },
  doctorItemCard: {
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
  docItemHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  docItemMeta: {
    flex: 1
  },
  docItemName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1e3a8a'
  },
  docItemSpecialty: {
    fontSize: 13,
    color: '#1d4ed8',
    marginTop: 2
  },
  docItemBody: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 8
  },
  docItemLoc: {
    fontSize: 13,
    color: '#6b7280'
  },
  bookingArea: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2
  },
  backBtn: {
    marginBottom: 16
  },
  backBtnText: {
    color: '#1d4ed8',
    fontWeight: 'bold',
    fontSize: 14
  },
  docDetailCard: {
    borderBottomWidth: 1,
    borderBottomColor: '#e5e7eb',
    paddingBottom: 16,
    marginBottom: 16
  },
  docTitleName: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1e3a8a'
  },
  docTitleSpecialty: {
    fontSize: 14,
    color: '#1d4ed8',
    fontWeight: '500',
    marginTop: 2
  },
  locRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 8
  },
  docTitleLoc: {
    fontSize: 13,
    color: '#6b7280'
  },
  inputGroup: {
    marginBottom: 16
  },
  inputLabel: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#374151',
    marginBottom: 8
  },
  textInput: {
    borderWidth: 1,
    borderColor: '#d1d5db',
    borderRadius: 8,
    padding: 10,
    fontSize: 15,
    backgroundColor: '#fff'
  },
  bookingOptionsRow: {
    marginBottom: 20
  },
  quickBookBtn: {
    flexDirection: 'row',
    backgroundColor: '#16a34a',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8
  },
  quickBookBtnText: {
    color: '#fff',
    fontWeight: 'bold',
    fontSize: 14
  },
  noSlotsText: {
    fontSize: 13,
    color: '#9ca3af',
    fontStyle: 'italic',
    marginTop: 4
  },
  slotsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 8
  },
  slotOptionBtn: {
    backgroundColor: '#eff6ff',
    borderWidth: 1,
    borderColor: '#bfdbfe',
    borderRadius: 6,
    paddingVertical: 8,
    paddingHorizontal: 14,
    minWidth: '22%',
    alignItems: 'center'
  },
  slotOptionBtnText: {
    color: '#1e40af',
    fontWeight: 'bold',
    fontSize: 13
  },
  reschedArea: {
    backgroundColor: '#fef3c7',
    borderWidth: 1,
    borderColor: '#fcd34d',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20
  },
  reschedHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10
  },
  reschedTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#92400e'
  },
  reschedMeta: {
    fontSize: 13,
    color: '#78350f',
    marginBottom: 4
  },
  slotBtn: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#fcd34d',
    borderRadius: 6,
    paddingVertical: 8,
    paddingHorizontal: 12,
    alignItems: 'center',
    minWidth: '22%'
  },
  slotBtnText: {
    color: '#92400e',
    fontWeight: 'bold',
    fontSize: 13
  }
});
