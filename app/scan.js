import { useState, useRef } from 'react';
import { CameraView, useCameraPermissions } from 'expo-camera';
import { View, Text, StyleSheet, Pressable, SafeAreaView, Image } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import PoseCarousel from '../src/components/PoseCarousel';
import PoseOverlay from '../src/components/PoseOverlay';
import { analyzeEnvironment } from '../src/services/GeminiService';

const MODES = {
    ENVIRONMENT: 'ENVIRONMENT',
    SELECTION: 'SELECTION',
    CAPTURE: 'CAPTURE',
    RESULT: 'RESULT',
};

export default function ScanScreen() {
    const [permission, requestPermission] = useCameraPermissions();
    const [mode, setMode] = useState(MODES.ENVIRONMENT);
    const [isProcessing, setIsProcessing] = useState(false);
    const [environmentUri, setEnvironmentUri] = useState(null);
    const [capturedPhotoUri, setCapturedPhotoUri] = useState(null);
    const [poses, setPoses] = useState([]);
    const [selectedPose, setSelectedPose] = useState(null);
    const [showOverlay, setShowOverlay] = useState(true);

    const cameraRef = useRef(null);
    const router = useRouter();

    if (!permission) return <View style={styles.container} />;
    if (!permission.granted) {
        return (
            <View style={styles.permissionContainer}>
                <Text style={styles.permissionText}>Camera access needed for PoseAI</Text>
                <Pressable onPress={requestPermission} style={styles.permissionButton}>
                    <Text style={styles.permissionButtonText}>Allow Camera</Text>
                </Pressable>
            </View>
        );
    }

    const captureEnvironment = async () => {
        if (!cameraRef.current || isProcessing) return;

        setIsProcessing(true);
        try {
            const photo = await cameraRef.current.takePictureAsync({
                quality: 0.7,
                base64: true,
            });
            setEnvironmentUri(photo.uri);
            setMode(MODES.SELECTION);

            const analysis = await analyzeEnvironment(photo.uri, photo.base64);
            if (analysis && analysis.poses) {
                setPoses(analysis.poses);
                setSelectedPose(analysis.poses[0]);
            }
        } catch (error) {
            console.error("Environment Capture Error:", error);
        } finally {
            setIsProcessing(false);
        }
    };

    const confirmPose = () => {
        if (selectedPose) {
            setMode(MODES.CAPTURE);
            setShowOverlay(true);
        }
    };

    const handleBack = () => {
        if (mode === MODES.RESULT) setMode(MODES.CAPTURE);
        else if (mode === MODES.CAPTURE) setMode(MODES.SELECTION);
        else if (mode === MODES.SELECTION) setMode(MODES.ENVIRONMENT);
        else router.back();
    };

    const resetApp = () => {
        setMode(MODES.ENVIRONMENT);
        setEnvironmentUri(null);
        setCapturedPhotoUri(null);
        setSelectedPose(null);
        setPoses([]);
    };

    const takeFinalPhoto = async () => {
        if (!cameraRef.current || isProcessing) return;
        setIsProcessing(true);
        try {
            const photo = await cameraRef.current.takePictureAsync({
                quality: 1.0,
            });
            setCapturedPhotoUri(photo.uri);
            setMode(MODES.RESULT);
        } catch (error) {
            console.error("Final Capture Error:", error);
        } finally {
            setIsProcessing(false);
        }
    };

    return (
        <View style={styles.container}>
            {/* Live Camera for Environment and Final Capture */}
            {(mode === MODES.ENVIRONMENT || mode === MODES.CAPTURE) && (
                <CameraView style={styles.camera} facing="back" ref={cameraRef}>
                    <SafeAreaView style={styles.uiContainer}>
                        <View style={styles.header}>
                            <Pressable onPress={handleBack} style={styles.headerBtn}>
                                <Ionicons name="arrow-back" size={24} color="white" />
                            </Pressable>
                            <Text style={styles.headerTitle}>
                                {mode === MODES.ENVIRONMENT ? "Scan Scene" : "Match Avatar"}
                            </Text>

                            {mode === MODES.CAPTURE ? (
                                <Pressable onPress={() => setShowOverlay(!showOverlay)} style={[styles.headerBtn, !showOverlay && styles.headerBtnDisabled]}>
                                    <Ionicons name={showOverlay ? "eye" : "eye-off"} size={22} color="white" />
                                </Pressable>
                            ) : (
                                <View style={{ width: 44 }} />
                            )}
                        </View>

                        {/* Ghost Overlay in CAPTURE mode */}
                        {mode === MODES.CAPTURE && selectedPose && showOverlay && (
                            <PoseOverlay pose={selectedPose} />
                        )}

                        <View style={styles.bottomControls}>
                            {mode === MODES.ENVIRONMENT ? (
                                <Pressable disabled={isProcessing} onPress={captureEnvironment} style={styles.captureBtn}>
                                    <View style={styles.captureBtnInner} />
                                </Pressable>
                            ) : (
                                <Pressable onPress={takeFinalPhoto} style={styles.captureBtn}>
                                    <View style={styles.captureBtnInnerInner}>
                                        <Ionicons name="camera" size={32} color="#000" />
                                    </View>
                                </Pressable>
                            )
                            }
                        </View>
                    </SafeAreaView>
                </CameraView>
            )}

            {/* Selection Mode: Avatar IN Environment */}
            {mode === MODES.SELECTION && environmentUri && (
                <View style={styles.container}>
                    <Image source={{ uri: environmentUri }} style={styles.previewImage} />

                    {/* Render Avatar Silhouette IN the preview */}
                    {selectedPose && <PoseOverlay pose={selectedPose} />}

                    <SafeAreaView style={styles.uiContainer}>
                        <View style={styles.header}>
                            <Pressable onPress={handleBack} style={styles.headerBtn}>
                                <Ionicons name="close" size={24} color="white" />
                            </Pressable>
                            <Text style={styles.headerTitle}>Position Avatar</Text>
                            <Pressable onPress={confirmPose} style={[styles.headerBtn, { backgroundColor: '#00ffcc' }]}>
                                <Ionicons name="checkmark" size={24} color="black" />
                            </Pressable>
                        </View>

                        {isProcessing && (
                            <View style={styles.loadingToast}>
                                <Text style={styles.loadingText}>Avatar is exploring...</Text>
                            </View>
                        )}

                        <PoseCarousel
                            poses={poses}
                            selectedPoseId={selectedPose?.id}
                            onSelectPose={setSelectedPose}
                        />
                    </SafeAreaView>
                </View>
            )}
            {/* 3. Result Mode: Preview Final Shot */}
            {mode === MODES.RESULT && capturedPhotoUri && (
                <View style={styles.container}>
                    <Image source={{ uri: capturedPhotoUri }} style={styles.previewImage} resizeMode="cover" />
                    <SafeAreaView style={styles.uiContainer}>
                        <View style={styles.header}>
                            <Pressable onPress={handleBack} style={styles.headerBtn}>
                                <Ionicons name="arrow-back" size={24} color="white" />
                            </Pressable>
                            <Text style={styles.headerTitle}>Masterpiece</Text>
                            <View style={{ width: 44 }} />
                        </View>

                        <View style={styles.resultActions}>
                            <Pressable onPress={handleBack} style={styles.resultBtnSecondary}>
                                <Ionicons name="refresh" size={20} color="white" />
                                <Text style={styles.resultBtnText}>Retake</Text>
                            </Pressable>
                            <Pressable onPress={resetApp} style={styles.resultBtnPrimary}>
                                <Ionicons name="home" size={20} color="black" />
                                <Text style={[styles.resultBtnText, { color: '#000' }]}>New Scan</Text>
                            </Pressable>
                        </View>
                    </SafeAreaView>
                </View>
            )}
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#000',
    },
    permissionContainer: {
        flex: 1,
        backgroundColor: '#121212',
        justifyContent: 'center',
        alignItems: 'center',
        padding: 20,
    },
    permissionText: {
        color: '#fff',
        fontSize: 16,
        textAlign: 'center',
        marginBottom: 20,
    },
    permissionButton: {
        backgroundColor: '#fff',
        paddingVertical: 12,
        paddingHorizontal: 24,
        borderRadius: 20,
    },
    permissionButtonText: {
        color: '#000',
        fontSize: 16,
        fontWeight: 'bold',
    },
    camera: {
        flex: 1,
    },
    previewContainer: {
        flex: 1,
    },
    previewImage: {
        ...StyleSheet.absoluteFillObject,
    },
    uiContainer: {
        flex: 1,
        justifyContent: 'space-between',
    },
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 20,
        paddingTop: 50,
    },
    headerBtn: {
        width: 44,
        height: 44,
        borderRadius: 22,
        backgroundColor: 'rgba(0,0,0,0.5)',
        justifyContent: 'center',
        alignItems: 'center',
    },
    headerTitle: {
        color: '#fff',
        fontSize: 18,
        fontWeight: 'bold',
        textShadowColor: 'rgba(0,0,0,0.5)',
        textShadowOffset: { width: 0, height: 1 },
        textShadowRadius: 4,
    },
    bottomControls: {
        alignItems: 'center',
        paddingBottom: 40,
    },
    captureBtn: {
        width: 80,
        height: 80,
        borderRadius: 40,
        borderWidth: 4,
        borderColor: '#fff',
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: 'rgba(255,255,255,0.2)',
    },
    captureBtnInner: {
        width: 64,
        height: 64,
        borderRadius: 32,
        backgroundColor: '#fff',
    },
    captureBtnInnerInner: {
        width: 64,
        height: 64,
        borderRadius: 32,
        backgroundColor: '#00ffcc',
        justifyContent: 'center',
        alignItems: 'center',
    },
    headerBtnDisabled: {
        opacity: 0.5,
        backgroundColor: 'rgba(255,100,100,0.3)',
    },
    loadingToast: {
        position: 'absolute',
        top: '40%',
        alignSelf: 'center',
        backgroundColor: 'rgba(0,0,0,0.8)',
        paddingVertical: 12,
        paddingHorizontal: 24,
        borderRadius: 25,
    },
    loadingText: {
        color: '#00ffcc',
        fontSize: 16,
        fontWeight: '600',
    },
    resultActions: {
        flexDirection: 'row',
        justifyContent: 'center',
        gap: 15,
        paddingBottom: 40,
    },
    resultBtnPrimary: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: '#00ffcc',
        paddingVertical: 14,
        paddingHorizontal: 24,
        borderRadius: 30,
        gap: 8,
    },
    resultBtnSecondary: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: 'rgba(255,255,255,0.1)',
        paddingVertical: 14,
        paddingHorizontal: 24,
        borderRadius: 30,
        borderWidth: 1,
        borderColor: 'rgba(255,255,255,0.3)',
        gap: 8,
    },
    resultBtnText: {
        color: '#fff',
        fontSize: 16,
        fontWeight: 'bold',
    },
});
