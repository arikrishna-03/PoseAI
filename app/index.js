import { View, Text, StyleSheet, Pressable } from 'react-native';
import { Link } from 'expo-router';
import { StatusBar } from 'expo-status-bar';

export default function Home() {
    return (
        <View style={styles.container}>
            <StatusBar style="light" />
            <View style={styles.header}>
                <Text style={styles.title}>PoseAI</Text>
                <Text style={styles.subtitle}>Environment-Aware Posing</Text>
            </View>

            <Link href="/scan" asChild>
                <Pressable style={styles.button}>
                    <Text style={styles.buttonText}>Scan Environment</Text>
                </Pressable>
            </Link>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#121212',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 20,
    },
    header: {
        marginBottom: 60,
        alignItems: 'center',
    },
    title: {
        color: '#fff',
        fontSize: 42,
        fontWeight: 'bold',
        letterSpacing: 2,
        marginBottom: 10,
    },
    subtitle: {
        color: '#888',
        fontSize: 16,
        letterSpacing: 1,
    },
    button: {
        backgroundColor: '#fff',
        paddingVertical: 18,
        paddingHorizontal: 40,
        borderRadius: 30,
        elevation: 5,
        shadowColor: '#fff',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.3,
        shadowRadius: 10,
    },
    buttonText: {
        color: '#000',
        fontSize: 18,
        fontWeight: '600',
        letterSpacing: 0.5,
    },
});
