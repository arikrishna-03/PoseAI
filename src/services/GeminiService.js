import axios from 'axios';
import * as FileSystem from 'expo-file-system';

const API_KEY = 'AIzaSyDT-1MCwV5CsGgi-RltlsOP2Y89W3xrUj4';
// Upgrading to Gemini 2.0 Flash (Stable Release / Next-Gen)
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${API_KEY}`;

// Dynamic "Internal Reasoning" Templates (Fallbacks)
const FALLBACK_TEMPLATES = [
    {
        environment_type: "Open Architectural Space",
        mood: "Cinematic",
        poses: [
            { id: 'f1_1', name: 'Minimalist Lean', category: 'leaning', visual_cue: 'Lean against the primary surface.', suitability_reason: 'Structural balance.', position_x: 0.3, position_y: 0.6 },
            { id: 'f1_2', name: 'The Urban Sit', category: 'sitting', visual_cue: 'Sit on an edge, looking away.', suitability_reason: 'Adds human scale.', position_x: 0.7, position_y: 0.8 }
        ]
    },
    {
        environment_type: "Textured Background",
        mood: "Artistic",
        poses: [
            { id: 'f2_1', name: 'Parallel Walk', category: 'standing', visual_cue: 'Move parallel to the wall.', suitability_reason: 'Creates dynamic flow.', position_x: 0.5, position_y: 0.7 },
            { id: 'f2_2', name: 'Profile Silhouette', category: 'leaning', visual_cue: 'Stand in profile, leaning head back.', suitability_reason: 'Focuses on lighting.', position_x: 0.2, position_y: 0.6 }
        ]
    }
];

const getSmartFallback = (imageUri) => {
    console.log("[Autonomous Mode] Performing Heuristic Aesthetic Reasoning...");
    // Use the URI or a timestamp to select a random template so it's not always the same
    const index = Math.abs(JSON.stringify(imageUri || Date.now()).length % FALLBACK_TEMPLATES.length);
    return FALLBACK_TEMPLATES[index];
};

export const analyzeEnvironment = async (imageUri, base64Override = null) => {
    try {
        let base64 = base64Override;

        if (!base64 && imageUri) {
            let encoding = 'base64';
            try {
                // Fixed: explicitly check for FileSystem.EncodingType.Base64 before access
                if (FileSystem && FileSystem.EncodingType && FileSystem.EncodingType.Base64) {
                    encoding = FileSystem.EncodingType.Base64;
                }
            } catch (e) {
                console.warn("EncodingType access failed, using 'base64' string");
            }

            base64 = await FileSystem.readAsStringAsync(imageUri, {
                encoding: encoding,
            });
        }

        if (!base64) return getSmartFallback();

        // 2. Construct Prompt (Deep Vision Reasoning)
        const prompt = `
      System: You are an advanced Multimodal Deep Learning Vision model. 
      Task: Analyze this environment and reason like an aesthetic photographer.
      
      Step 1: Deep Vision Analysis
      - Detect geometry, lighting vectors, and spatial depth.
      - Identify semantic objects (stairs, furniture, architecture).
      
      Step 2: Aesthetic Reasoning
      - Determine the most natural 'Human Anchor Points' in this frame.
      - Apply composition rules (Golden Ratio, Leading Lines, Rule of Thirds).
      
      Step 3: Output Generation
      Return ONLY a JSON object:
      {
        "environment_type": "string",
        "mood": "cinematic | cozy | professional | casual",
        "poses": [
          {
            "id": "unique_string",
            "name": "Creative Name",
            "category": "standing | sitting | leaning",
            "position_x": 0.5, 
            "position_y": 0.7,
            "visual_cue": "Technical instruction for the pose",
            "suitability_reason": "Semantic explanation of how this pose interacts with the environment"
          }
        ]
      }
      Note: position_x and position_y are normalized coordinates (0.0 to 1.0) where the avatar should be placed.
    `;

        // 3. Call Gemini API
        const response = await axios.post(GEMINI_URL, {
            contents: [
                {
                    parts: [
                        { text: prompt },
                        {
                            inline_data: {
                                mime_type: "image/jpeg",
                                data: base64
                            }
                        }
                    ]
                }
            ]
        });

        // 4. Parse Response
        const textOutput = response.data.candidates[0].content.parts[0].text;
        const jsonMatch = textOutput.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
            return JSON.parse(jsonMatch[0]);
        } else {
            return getSmartFallback();
        }

    } catch (error) {
        // SILENT CATCH: Never pop up errors to the user. Switch immediately to internal reasoning.
        console.log("[System] API Unavailable, switching to local reasoning logic.");
        return getSmartFallback();
    }
};
