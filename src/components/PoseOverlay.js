import { View, StyleSheet, Text } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

const CATEGORY_ICONS = {
    'standing': 'person-outline',
    'sitting': 'body-outline',
    'leaning': 'walk-outline',
    'default': 'star-outline'
};

export default function PoseOverlay({ pose }) {
    if (!pose) return null;

    // Default to center if no position provided
    const left = (pose.position_x !== undefined ? pose.position_x : 0.5) * 100 + '%';
    const top = (pose.position_y !== undefined ? pose.position_y : 0.6) * 100 + '%';

    return (
        <View style={[styles.container, { left, top }]} pointerEvents="none">
            <View style={styles.avatarContainer}>
                {/* Stylized Avatar Character */}
                <Ionicons
                    name={CATEGORY_ICONS[pose.category] || CATEGORY_ICONS.default}
                    size={220}
                    color="rgba(0, 255, 204, 0.4)"
                />

                {/* Dynamic Instruction Tag */}
                <View style={styles.instructionTag}>
                    <Text style={styles.instructionText}>{pose.visual_cue}</Text>
                </View>

                {/* Local Framing Guides */}
                <View style={styles.cornerTopLeft} />
                <View style={styles.cornerBottomRight} />
            </View>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        position: 'absolute',
        width: 250,
        height: 350,
        marginLeft: -125, // Compensation for width
        marginTop: -175,  // Compensation for height
        justifyContent: 'center',
        alignItems: 'center',
        zIndex: 10,
    },
    avatarContainer: {
        width: '100%',
        height: '100%',
        justifyContent: 'center',
        alignItems: 'center',
    },
    instructionTag: {
        backgroundColor: 'rgba(0,0,0,0.7)',
        paddingVertical: 6,
        paddingHorizontal: 12,
        borderRadius: 15,
        borderWidth: 1,
        borderColor: '#00ffcc',
        marginTop: 10,
    },
    instructionText: {
        color: '#fff',
        fontSize: 12,
        fontWeight: 'bold',
        textAlign: 'center',
    },
    cornerTopLeft: {
        position: 'absolute',
        top: 0,
        left: 0,
        width: 30,
        height: 30,
        borderTopWidth: 2,
        borderLeftWidth: 2,
        borderColor: '#00ffcc',
    },
    cornerBottomRight: {
        position: 'absolute',
        bottom: 0,
        right: 0,
        width: 30,
        height: 30,
        borderBottomWidth: 2,
        borderRightWidth: 2,
        borderColor: '#00ffcc',
    },
});
