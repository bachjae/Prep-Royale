/**
 * Post-deploy admin script:
 *  1. Purges 18 known broken Math questions from Firestore
 *  2. Generates 50 replacement Math questions (SAT + ACT) using the
 *     deployed Gemini helper directly (no HTTP hop needed).
 *
 * Prerequisites:
 *   - firebase deploy --only functions  (so compiled JS is up-to-date)
 *   - Service account JSON present at repo root
 *
 * Run: node tool/post-deploy-math-fix.js
 */

const path = require("path");
// Resolve all paths relative to repo root, regardless of CWD
const repoRoot = path.resolve(__dirname, "..");

// Add functions/node_modules to search path so firebase-admin and other
// Cloud Function deps are found when the script runs from the repo root.
require("module").globalPaths.push(path.join(repoRoot, "functions", "node_modules"));

const admin = require("firebase-admin");
const serviceAccount = require(path.join(repoRoot, "sat-act-battle-royale-firebase-adminsdk-fbsvc-eb52a46726.json"));
const flagged = require(path.join(repoRoot, "functions", "flagged_questions.json"));

// Import compiled Gemini helper and validation from built functions
const { generateQuestionsWithGemini, validateQuestion } = require(path.join(repoRoot, "functions", "lib", "utils", "geminiHelper"));
const { writeQuestionsToFirestore } = require(path.join(repoRoot, "functions", "lib", "utils", "validation"));

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore(); // used for purge batch; validation.ts uses getDb() lazily on same instance

// ── Skills to generate replacements for ─────────────────────────────────────
// 50 total: 27 SAT Math + 24 ACT Math (rounds to 51, close enough)
const MATH_TARGETS = [
  // SAT Math — 3 per skill × 9 skills = 27
  { examType: "SAT", section: "Math", skill: "LinearEquations",           count: 3 },
  { examType: "SAT", section: "Math", skill: "SystemsOfEquations",        count: 3 },
  { examType: "SAT", section: "Math", skill: "Functions",                  count: 3 },
  { examType: "SAT", section: "Math", skill: "Quadratics",                 count: 3 },
  { examType: "SAT", section: "Math", skill: "RatiosProportionsPercentages", count: 3 },
  { examType: "SAT", section: "Math", skill: "StatisticsDataAnalysis",    count: 3 },
  { examType: "SAT", section: "Math", skill: "GeometryAndTrigonometry",   count: 3 },
  { examType: "SAT", section: "Math", skill: "WordProblems",              count: 3 },
  { examType: "SAT", section: "Math", skill: "ExponentsAndRadicals",      count: 3 },
  // ACT Math — 4 per skill × 6 skills = 24
  { examType: "ACT", section: "Math", skill: "PreAlgebra",                count: 4 },
  { examType: "ACT", section: "Math", skill: "Algebra",                   count: 4 },
  { examType: "ACT", section: "Math", skill: "CoordinateGeometry",        count: 4 },
  { examType: "ACT", section: "Math", skill: "PlaneGeometry",             count: 4 },
  { examType: "ACT", section: "Math", skill: "Trigonometry",              count: 4 },
  { examType: "ACT", section: "Math", skill: "WordProblems",              count: 4 },
];

// ── Step 1: Purge flagged questions ──────────────────────────────────────────
async function purgeKnownBroken() {
  const ids = flagged.map(q => q.id).filter(Boolean);
  if (ids.length === 0) {
    console.log("No flagged IDs found in flagged_questions.json — skipping purge.");
    return;
  }

  console.log(`\nPurging ${ids.length} known broken questions...`);
  const batch = db.batch();
  for (const id of ids) {
    batch.delete(db.collection("questions").doc(id));
  }
  await batch.commit();
  console.log(`✓ Purged ${ids.length} broken questions.`);
}

// ── Step 2: Generate replacements ────────────────────────────────────────────
async function generateReplacements() {
  let totalGenerated = 0;
  let totalWritten = 0;

  for (const target of MATH_TARGETS) {
    const { examType, section, skill, count } = target;
    process.stdout.write(`Generating ${count} × ${examType} ${skill}... `);

    try {
      const questions = await generateQuestionsWithGemini(examType, section, skill, count);
      const valid = questions.filter(validateQuestion);

      if (valid.length > 0) {
        const written = await writeQuestionsToFirestore(valid);
        totalGenerated += valid.length;
        totalWritten += written;
        console.log(`✓ ${written} written (${valid.length} valid / ${questions.length} raw)`);
      } else {
        console.log(`✗ 0 valid questions returned`);
      }

      // Respect rate limits — 2s between skills
      await new Promise(r => setTimeout(r, 2000));
    } catch (err) {
      console.error(`✗ Failed: ${err.message}`);
    }
  }

  console.log(`\nDone. Generated: ${totalGenerated} | Written to Firestore: ${totalWritten}`);
}

// ── Main ─────────────────────────────────────────────────────────────────────
(async () => {
  try {
    await purgeKnownBroken();
    await generateReplacements();
    process.exit(0);
  } catch (err) {
    console.error("Fatal:", err);
    process.exit(1);
  }
})();
