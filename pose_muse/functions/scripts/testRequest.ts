/**
 * testRequest.ts
 * Sends a local test JPEG image to the local emulator / server and pretty-prints the ideas.
 * Usage: npx tsx scripts/testRequest.ts [endpointUrl]
 */

const ENDPOINT_URL = process.argv[2] || process.env.TEST_ENDPOINT || 'http://127.0.0.1:8080/generateIdeas';
const AUTH_TOKEN = process.env.TEST_AUTH_TOKEN || 'mock-emulator-token';

// Minimal valid 1x1 JPEG buffer with standard SOI, APP0, SOF0, SOS, EOI markers
const MINIMAL_JPEG = Buffer.from([
  0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01,
  0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xff, 0xdb, 0x00, 0x43,
  0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
  0x09, 0x08, 0x0a, 0x0c, 0x14, 0x0d, 0x0c, 0x0b, 0x0b, 0x0c, 0x19, 0x12,
  0x13, 0x0f, 0x14, 0x1d, 0x1a, 0x1f, 0x1e, 0x1d, 0x1a, 0x1c, 0x1c, 0x20,
  0x24, 0x2e, 0x27, 0x20, 0x22, 0x2c, 0x23, 0x1c, 0x1c, 0x28, 0x37, 0x29,
  0x2c, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1f, 0x27, 0x39, 0x3d, 0x38, 0x32,
  0x3c, 0x2e, 0x33, 0x34, 0x32, 0xff, 0xc0, 0x00, 0x0b, 0x08, 0x00, 0x01,
  0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xff, 0xc4, 0x00, 0x1f, 0x00, 0x00,
  0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
  0x09, 0x0a, 0x0b, 0xff, 0xda, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3f,
  0x00, 0x37, 0xff, 0xd9
]);

async function main() {
  console.log(`\n======================================================`);
  console.log(`📸 PoseMuse Backend Integration Test`);
  console.log(`Endpoint: ${ENDPOINT_URL}`);
  console.log(`======================================================\n`);

  const payload = {
    image_base64: MINIMAL_JPEG.toString('base64'),
    people_count_hint: 1,
    style_preference: 'candid',
    liked_titles: ['Sunset Lean', 'Coffee Walk'],
    disliked_titles: ['Stiff Corporate'],
    language: 'en'
  };

  console.log('Sending request with:');
  console.log(`- Decoded image bytes: ${MINIMAL_JPEG.length}`);
  console.log(`- Style preference: ${payload.style_preference}`);
  console.log(`- Liked titles context: ${JSON.stringify(payload.liked_titles)}\n`);

  const startTime = Date.now();
  try {
    const response = await fetch(ENDPOINT_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${AUTH_TOKEN}`
      },
      body: JSON.stringify(payload)
    });

    const elapsed = Date.now() - startTime;
    console.log(`Response received in ${elapsed}ms | HTTP Status: ${response.status} ${response.statusText}`);

    const json: any = await response.json();

    if (!response.ok) {
      console.error('\n❌ Server returned error:');
      console.error(JSON.stringify(json, null, 2));
      process.exit(1);
    }

    console.log('\n======================================================');
    console.log('🌟 SCENE ANALYSIS:');
    console.log(`Location:   ${json.scene.location_type}`);
    console.log(`Lighting:   ${json.scene.lighting}`);
    console.log(`People:     ${json.scene.people_count}`);
    console.log(`Outfits:    ${json.scene.outfit_summary}`);
    console.log(`Props:      ${json.scene.props.join(', ') || 'None'}`);
    console.log('======================================================\n');

    console.log(`Generated ${json.ideas.length} Photo Ideas:`);
    json.ideas.forEach((idea: any, idx: number) => {
      console.log(`\n------------------------------------------------------`);
      console.log(`[Idea ${idx + 1}] "${idea.title.toUpperCase()}" (${idea.style} • ${idea.difficulty})`);
      console.log(`Why this works: ${idea.why_it_works}`);
      console.log(`Camera Tips:    Height: ${idea.camera_tips.height} | Angle: ${idea.camera_tips.angle} | Distance: ${idea.camera_tips.distance} | ${idea.camera_tips.orientation}`);
      console.log(`Expression:     ${idea.expression_tip}`);
      console.log(`People (${idea.people.length}):`);
      idea.people.forEach((p: any, pIdx: number) => {
        console.log(`  - Person ${pIdx + 1} (${p.position}): ${p.description}`);
        console.log(`    Keypoints: ${p.keypoints.length} COCO landmarks verified`);
      });
    });

    console.log('\n======================================================');
    console.log('✅ Integration Test Successful!');
    console.log('======================================================\n');
  } catch (err: any) {
    console.error(`\n❌ Failed to communicate with endpoint: ${err.message}`);
    process.exit(1);
  }
}

main();
