import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { StatusBar } from 'expo-status-bar';

// Context Providers
import { AuthProvider } from './src/context/AuthContext';
import { DoctorProvider } from './src/context/DoctorContext';
import { PatientProvider } from './src/context/PatientContext';

// Screens
import { LoginScreen } from './src/screens/LoginScreen';
import { RegisterScreen } from './src/screens/RegisterScreen';
import { AdminDashboard } from './src/screens/AdminDashboard';
import { DoctorDashboard } from './src/screens/DoctorDashboard';
import { PatientDashboard } from './src/screens/PatientDashboard';

const Stack = createStackNavigator();

export default function App() {
  return (
    <AuthProvider>
      <DoctorProvider>
        <PatientProvider>
          <NavigationContainer>
            <StatusBar style="dark" />
            <Stack.Navigator
              initialRouteName="Login"
              screenOptions={{
                headerStyle: { backgroundColor: '#1e3a8a' },
                headerTintColor: '#fff',
                headerTitleStyle: { fontWeight: 'bold' },
                cardStyle: { backgroundColor: '#f3f4f6' }
              }}
            >
              <Stack.Screen
                name="Login"
                component={LoginScreen}
                options={{ headerShown: false }}
              />
              <Stack.Screen
                name="Register"
                component={RegisterScreen}
                options={{ title: 'Register Account' }}
              />
              <Stack.Screen
                name="AdminDashboard"
                component={AdminDashboard}
                options={{ headerShown: false }}
              />
              <Stack.Screen
                name="DoctorDashboard"
                component={DoctorDashboard}
                options={{ headerShown: false }}
              />
              <Stack.Screen
                name="PatientDashboard"
                component={PatientDashboard}
                options={{ headerShown: false }}
              />
            </Stack.Navigator>
          </NavigationContainer>
        </PatientProvider>
      </DoctorProvider>
    </AuthProvider>
  );
}
