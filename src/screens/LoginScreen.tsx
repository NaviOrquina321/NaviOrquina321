import React, { useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  ScrollView,
  SafeAreaView
} from 'react-native';
import { useAuth } from '../context/AuthContext';
import { Stethoscope } from 'lucide-react-native';

export function LoginScreen({ navigation }: any) {
  const { login, isLoading } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<'Patient' | 'Doctor' | 'Admin'>('Patient');
  const [errorMsg, setErrorMsg] = useState('');

  const handleLogin = async () => {
    setErrorMsg('');
    if (!email.trim() || !password) {
      setErrorMsg('Please fill in all fields.');
      return;
    }

    try {
      const success = await login(email, password, role);
      if (success) {
        if (role === 'Patient') {
          navigation.navigate('PatientDashboard');
        } else if (role === 'Doctor') {
          navigation.navigate('DoctorDashboard');
        } else if (role === 'Admin') {
          navigation.navigate('AdminDashboard');
        }
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'An error occurred during login.');
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.card}>
          <View style={styles.logoContainer}>
            <Stethoscope size={64} color="#1d4ed8" />
            <Text style={styles.title}>Clinic Scheduler</Text>
            <Text style={styles.subtitle}>Unified Medical Appointment Portal</Text>
          </View>

          {errorMsg ? <Text style={styles.errorText}>{errorMsg}</Text> : null}

          <Text style={styles.label}>I am logging in as a:</Text>
          <View style={styles.roleContainer}>
            {(['Patient', 'Doctor', 'Admin'] as const).map((r) => (
              <TouchableOpacity
                key={r}
                style={[styles.roleButton, role === r && styles.roleButtonActive]}
                onPress={() => setRole(r)}
              >
                <Text style={[styles.roleButtonText, role === r && styles.roleButtonTextActive]}>
                  {r}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          <Text style={styles.label}>Email Address</Text>
          <TextInput
            style={styles.input}
            placeholder="e.g. john@example.com"
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
            autoCapitalize="none"
          />

          <Text style={styles.label}>Password</Text>
          <TextInput
            style={styles.input}
            placeholder="Enter your password"
            value={password}
            onChangeText={setPassword}
            secureTextEntry
          />

          <TouchableOpacity style={styles.loginButton} onPress={handleLogin} disabled={isLoading}>
            {isLoading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.loginButtonText}>LOGIN</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.registerLink}
            onPress={() => navigation.navigate('Register')}
          >
            <Text style={styles.registerLinkText}>Don't have an account? Register here</Text>
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
    flexGrow: 1,
    justifyContent: 'center',
    padding: 20
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
    maxWidth: 450,
    width: '100%',
    alignSelf: 'center'
  },
  logoContainer: {
    alignItems: 'center',
    marginBottom: 24
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1e3a8a',
    marginTop: 12
  },
  subtitle: {
    fontSize: 14,
    color: '#6b7280',
    marginTop: 4,
    textAlign: 'center'
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
    justifyContent: 'space-between',
    marginBottom: 16,
    gap: 8
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
    marginBottom: 12
  },
  loginButton: {
    backgroundColor: '#1d4ed8',
    paddingVertical: 14,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 16
  },
  loginButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold'
  },
  registerLink: {
    marginTop: 16,
    alignItems: 'center'
  },
  registerLinkText: {
    color: '#1d4ed8',
    fontSize: 14,
    fontWeight: '500'
  }
});
