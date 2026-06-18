import { View, Text, StyleSheet, ScrollView, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

const CATEGORY_ICONS = {
    'standing': 'person',
    'sitting': 'body',
    'leaning': 'walk',
    'default': 'star'
};

export default function PoseCarousel({ onSelectPose, selectedPoseId, poses = [] }) {
    if (poses.length === 0) {
        return (
            <View style={styles.container}>
                <View style={styles.placeholderContainer}>
                    <Text style={styles.placeholderText}>Gemini is choosing the best poses...</Text>
                </View>
            </View>
        );
    }

    return (
        <View style={styles.container}>
            <Text style={styles.label}>Suggested Aesthetics</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.scrollContent}>
                {poses.map((pose) => (
                    <Pressable
                        key={pose.id}
                        onPress={() => onSelectPose(pose)}
                        style={[styles.card, selectedPoseId === pose.id && styles.selectedCard]}
                    >
                        <View style={styles.iconContainer}>
                            <Ionicons
                                name={CATEGORY_ICONS[pose.category] || CATEGORY_ICONS.default}
                                size={40}
                                color={selectedPoseId === pose.id ? "#00ffcc" : "#888"}
                            />
                        </View>
                        <View style={styles.textContainer}>
                            <Text style={styles.poseName} numberOfLines={1}>{pose.name}</Text>
                            <Text style={styles.poseCategory}>{pose.category}</Text>
                        </View>
                    </Pressable>
                ))}
            </ScrollView>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        position: 'absolute',
        bottom: 30,
        width: '100%',
        height: 160,
    },
    label: {
        color: '#fff',
        fontSize: 12,
        marginLeft: 20,
        marginBottom: 10,
        fontWeight: 'bold',
        textTransform: 'uppercase',
        letterSpacing: 1.5,
        opacity: 0.8,
    },
    scrollContent: {
        paddingHorizontal: 15,
    },
    card: {
        width: 120,
        height: 120,
        backgroundColor: 'rgba(25,25,25,0.95)',
        borderRadius: 20,
        marginHorizontal: 6,
        padding: 12,
        alignItems: 'center',
        justifyContent: 'center',
        borderWidth: 2,
        borderColor: 'rgba(255,255,255,0.1)',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.3,
        shadowRadius: 5,
        elevation: 5,
    },
    selectedCard: {
        borderColor: '#00ffcc',
        backgroundColor: 'rgba(40,40,40,1)',
        transform: [{ scale: 1.05 }],
    },
    iconContainer: {
        marginBottom: 8,
    },
    textContainer: {
        alignItems: 'center',
    },
    poseName: {
        color: '#fff',
        fontSize: 13,
        fontWeight: 'bold',
        textAlign: 'center',
    },
    poseCategory: {
        color: '#888',
        fontSize: 10,
        textTransform: 'capitalize',
        marginTop: 2,
    },
    placeholderContainer: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        paddingHorizontal: 40,
    },
    placeholderText: {
        color: '#888',
        fontSize: 14,
        textAlign: 'center',
        fontStyle: 'italic',
    }
});
