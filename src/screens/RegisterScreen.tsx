import React, { useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  ScrollView,
  SafeAreaView,
  Alert
} from 'react-native';
import * as DocumentPicker from 'expo-document-picker';
import { useAuth } from '../context/AuthContext';
import { FileUp } from 'lucide-react-native';

export function RegisterScreen({ navigation }: any) {
  const { registerPatient, registerDoctor, isLoading } = useAuth();

  const [role, setRole] = useState<'Patient' | 'Doctor'>('Patient');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [phone, setPhone] = useState('');

  const [license, setLicense] = useState('');
  const [specialty, setSpecialty] = useState('');
  const [location, setLocation] = useState('');
  const [certificateName, setCertificateName] = useState('');
  const [certificatePath, setCertificatePath] = useState('');
  const [certificateSize, setCertificateSize] = useState(0);

  const [errorMsg, setErrorMsg] = useState('');

  const pickCertificate = async () => {
    setErrorMsg('');
    try {
      const res = await DocumentPicker.getDocumentAsync({
        type: ['application/pdf', 'image/*']
      });

      if (!res.canceled && res.assets && res.assets.length > 0) {
        const file = res.assets[0];
        setCertificateName(file.name);
        setCertificatePath(file.uri || '');
        setCertificateSize(file.size || 0);
      }
    } catch (err: any) {
      setErrorMsg('Error picking file: ' + err.message);
    }
  };

  const handleRegister = async () => {
    setErrorMsg('');
    if (!name.trim() || !email.trim() || !password) {
      setErrorMsg('Please fill in all mandatory fields.');
      return;
    }

    if (password.length < 6) {
      setErrorMsg('Password must be at least 6 characters long.');
      return;
    }

    try {
      if (role === 'Patient') {
        await registerPatient(name, email, password, phone.trim() || undefined);
        Alert.alert('Registration Successful', 'You can now log in using your credentials.', [
          { text: 'OK', onPress: () => navigation.navigate('Login') }
        ]);
      } else {
        if (!license.trim() || !specialty.trim() || !location.trim()) {
          setErrorMsg('License number, Specialty, and Location are mandatory for Doctors.');
          return;
        }

        if (!certificatePath) {
          setErrorMsg('Please upload your professional license certificate.');
          return;
        }

        await registerDoctor(
          name,
          email,
          password,
          license,
          certificatePath,
          certificateSize,
          specialty,
          location,
          phone.trim() || undefined
        );

        Alert.alert(
          'Registration Submitted',
          'Your account is pending Administrator approval. You will be able to log in once approved.',
          [{ text: 'OK', onPress: () => navigation.navigate('Login') }]
        );
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'An error occurred during registration.');
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.card}>
          <Text style={styles.title}>Register Account</Text>
          <Text style={styles.subtitle}>Join Clinic Appointment Portal</Text>

          {errorMsg ? <Text style={styles.errorText}>{errorMsg}</Text> : null}

          <Text style={styles.label}>Register as a:</Text>
          <View style={styles.roleContainer}>
            <TouchableOpacity
              style={[styles.roleButton, role === 'Patient' && styles.roleButtonActive]}
              onPress={() => setRole('Patient')}
            >
              <Text style={[styles.roleButtonText, role === 'Patient' && styles.roleButtonTextActive]}>
                Patient
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.roleButton, role === 'Doctor' && styles.roleButtonActive]}
              onPress={() => setRole('Doctor')}
            >
              <Text style={[styles.roleButtonText, role === 'Doctor' && styles.roleButtonTextActive]}>
                Doctor
              </Text>
            </TouchableOpacity>
          </View>

          <Text style={styles.label}>Full Name *</Text>
          <TextInput
            style={styles.input}
            placeholder="Enter full name"
            value={name}
            onChangeText={setName}
          />

          <Text style={styles.label}>Email Address *</Text>
          <TextInput
            style={styles.input}
            placeholder="e.g. user@example.com"
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
            autoCapitalize="none"
          />

          <Text style={styles.label}>Password *</Text>
          <TextInput
            style={styles.input}
            placeholder="At least 6 characters"
            value={password}
            onChangeText={setPassword}
            secureTextEntry
          />

          <Text style={styles.label}>Phone Number (Optional)</Text>
          <TextInput
            style={styles.input}
            placeholder="e.g. +1 555-0199"
            value={phone}
            onChangeText={setPhone}
            keyboardType="phone-pad"
          />

          {role === 'Doctor' ? (
            <View style={styles.doctorFields}>
              <View style={styles.divider} />
              <Text style={styles.sectionTitle}>Professional Credentials</Text>

              <Text style={styles.label}>License Number / National ID *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. LIC-998877"
                value={license}
                onChangeText={setLicense}
              />

              <Text style={styles.label}>Specialty *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. Cardiology, Pediatrics"
                value={specialty}
                onChangeText={setSpecialty}
              />

              <Text style={styles.label}>Location / Clinic Address *</Text>
              <TextInput
                style={styles.input}
                placeholder="e.g. North Wing Clinic, Floor 3"
                value={location}
                onChangeText={setLocation}
              />

              <Text style={styles.label}>License Certificate (PDF/Image) *</Text>
              <View style={styles.uploadRow}>
                <TouchableOpacity style={styles.uploadButton} onPress={pickCertificate}>
                  <FileUp size={20} color="#1d4ed8" />
                  <Text style={styles.uploadButtonText}>Select File</Text>
                </TouchableOpacity>
                <Text style={styles.fileNameText} numberOfLines={1}>
                  {certificateName ? certificateName : 'No file selected'}
                </Text>
              </View>
              <Text style={styles.hintText}>
                Supported formats: PDF, PNG, JPG, JPEG, WEBP. Max size: 5MB.
              </Text>
            </View>
          ) : null}

          <TouchableOpacity style={styles.registerBtn} onPress={handleRegister} disabled={isLoading}>
            {isLoading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.registerBtnText}>REGISTER</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.loginLink}
            onPress={() => navigation.navigate('Login')}
          >
            <Text style={styles.loginLinkText}>Already have an account? Log in</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f3f4f6'
  },
  scrollContent: {
    paddingVertical: 24,
    paddingHorizontal: 16
  },
  card: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 12,
    elevation: 5,
    maxWidth: 500,
    width: '100%',
    alignSelf: 'center'
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1e3a8a',
    textAlign: 'center'
  },
  subtitle: {
    fontSize: 14,
    color: '#6b7280',
    textAlign: 'center',
    marginTop: 4,
    marginBottom: 20
  },
  errorText: {
    color: '#dc2626',
    backgroundColor: '#fef2f2',
    padding: 12,
    borderRadius: 8,
    marginBottom: 16,
    textAlign: 'center',
    fontWeight: '500'
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#374151',
    marginBottom: 6,
    marginTop: 12
  },
  roleContainer: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 12
  },
  roleButton: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#d1d5db',
    alignItems: 'center',
    backgroundColor: '#f9fafb'
  },
  roleButtonActive: {
    borderColor: '#1d4ed8',
    backgroundColor: '#eff6ff'
  },
  roleButtonText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#4b5563'
  },
  roleButtonTextActive: {
    color: '#1d4ed8',
    fontWeight: 'bold'
  },
  input: {
    borderWidth: 1,
    borderColor: '#d1d5db',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    backgroundColor: '#fff',
    marginBottom: 4
  },
  doctorFields: {
    marginTop: 16
  },
  divider: {
    height: 1,
    backgroundColor: '#e5e7eb',
    marginVertical: 16
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1e3a8a',
    marginBottom: 12
  },
  uploadRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginVertical: 4
  },
  uploadButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    borderWidth: 1,
    borderColor: '#1d4ed8',
    borderRadius: 8,
    paddingVertical: 10,
    paddingHorizontal: 16,
    backgroundColor: '#eff6ff'
  },
  uploadButtonText: {
    color: '#1d4ed8',
    fontWeight: 'bold',
    fontSize: 14
  },
  fileNameText: {
    flex: 1,
    fontSize: 14,
    color: '#374151'
  },
  hintText: {
    fontSize: 11,
    color: '#6b7280',
    marginTop: 4
  },
  registerBtn: {
    backgroundColor: '#1d4ed8',
    paddingVertical: 14,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 24
  },
  registerBtnText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold'
  },
  loginLink: {
    marginTop: 16,
    alignItems: 'center'
  },
  loginLinkText: {
    color: '#1d4ed8',
    fontSize: 14,
    fontWeight: '500'
  }
});
