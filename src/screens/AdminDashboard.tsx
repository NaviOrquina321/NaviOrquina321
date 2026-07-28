import React, { useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  ScrollView,
  SafeAreaView,
  ActivityIndicator,
  Alert
} from 'react-native';
import { useAuth } from '../context/AuthContext';
import { useDoctor } from '../context/DoctorContext';
import { Shield, LogOut, Check, X, User } from 'lucide-react-native';

export function AdminDashboard({ navigation }: any) {
  const { logout, currentUser } = useAuth();
  const { pendingDoctors, loadPendingDoctors, approveDoctor, isLoading } = useDoctor();

  useEffect(() => {
    loadPendingDoctors().catch((err: any) => {
      Alert.alert('Error', err.message || 'Failed to load pending doctors.');
    });
  }, []);

  const handleApprove = async (userId: number, name: string) => {
    try {
      await approveDoctor(userId, true);
      Alert.alert('Success', `Doctor ${name} has been approved.`);
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to approve doctor.');
    }
  };

  const handleReject = async (userId: number, name: string) => {
    try {
      await approveDoctor(userId, false);
      Alert.alert('Success', `Doctor ${name} has been rejected.`);
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to reject doctor.');
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
          <Shield size={24} color="#fff" />
          <Text style={styles.headerTitle}>Admin Dashboard</Text>
        </View>
        <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
          <LogOut size={20} color="#fff" />
          <Text style={styles.logoutText}>Log Out</Text>
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.welcomeCard}>
          <Text style={styles.welcomeTitle}>Welcome, {currentUser?.name || 'Administrator'}</Text>
          <Text style={styles.welcomeSubtitle}>Manage doctor verifications and registrations</Text>
        </View>

        <Text style={styles.sectionTitle}>Pending Doctor Approvals</Text>

        {isLoading ? (
          <ActivityIndicator size="large" color="#1d4ed8" style={styles.loader} />
        ) : pendingDoctors.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyText}>No pending doctor registrations found.</Text>
          </View>
        ) : (
          pendingDoctors.map((doc) => (
            <View key={doc.id} style={styles.doctorCard}>
              <View style={styles.doctorHeader}>
                <User size={36} color="#4b5563" />
                <View style={styles.doctorMeta}>
                  <Text style={styles.doctorName}>{doc.name}</Text>
                  <Text style={styles.doctorEmail}>{doc.email}</Text>
                  {doc.phone ? <Text style={styles.doctorPhone}>{doc.phone}</Text> : null}
                </View>
              </View>

              <View style={styles.divider} />

              <View style={styles.detailsRow}>
                <Text style={styles.detailLabel}>License Number:</Text>
                <Text style={styles.detailValue}>{doc.license_number}</Text>
              </View>
              <View style={styles.detailsRow}>
                <Text style={styles.detailLabel}>Specialty:</Text>
                <Text style={styles.detailValue}>{doc.specialty}</Text>
              </View>
              <View style={styles.detailsRow}>
                <Text style={styles.detailLabel}>Clinic Location:</Text>
                <Text style={styles.detailValue}>{doc.location}</Text>
              </View>
              <View style={styles.detailsRow}>
                <Text style={styles.detailLabel}>Certificate Path:</Text>
                <Text style={styles.detailValue} numberOfLines={1}>{doc.certificate_path}</Text>
              </View>

              <View style={styles.actionRow}>
                <TouchableOpacity
                  style={[styles.actionBtn, styles.rejectBtn]}
                  onPress={() => handleReject(doc.id, doc.name)}
                >
                  <X size={16} color="#fff" />
                  <Text style={styles.actionBtnText}>Reject</Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={[styles.actionBtn, styles.approveBtn]}
                  onPress={() => handleApprove(doc.id, doc.name)}
                >
                  <Check size={16} color="#fff" />
                  <Text style={styles.actionBtnText}>Approve</Text>
                </TouchableOpacity>
              </View>
            </View>
          ))
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
    fontSize: 14,
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
  doctorCard: {
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
  doctorHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12
  },
  doctorMeta: {
    flex: 1
  },
  doctorName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1e3a8a'
  },
  doctorEmail: {
    fontSize: 13,
    color: '#6b7280',
    marginTop: 2
  },
  doctorPhone: {
    fontSize: 13,
    color: '#6b7280'
  },
  divider: {
    height: 1,
    backgroundColor: '#f3f4f6',
    marginVertical: 12
  },
  detailsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6
  },
  detailLabel: {
    fontSize: 13,
    color: '#6b7280',
    fontWeight: '500'
  },
  detailValue: {
    fontSize: 13,
    color: '#374151',
    fontWeight: '600',
    maxWidth: '60%'
  },
  actionRow: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 12,
    marginTop: 16
  },
  actionBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingVertical: 8,
    paddingHorizontal: 16,
    borderRadius: 6
  },
  rejectBtn: {
    backgroundColor: '#dc2626'
  },
  approveBtn: {
    backgroundColor: '#16a34a'
  },
  actionBtnText: {
    color: '#fff',
    fontWeight: 'bold',
    fontSize: 13
  }
});
