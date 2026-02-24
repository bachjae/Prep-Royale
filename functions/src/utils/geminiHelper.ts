/**
 * Gemini API helper using Firebase Vertex AI.
 * Uses project credentials automatically - no API key needed!
 */

import { VertexAI, GenerativeModel } from "@google-cloud/vertexai";
import { Difficulty, DIFFICULTY_DISTRIBUTION } from "../config/questionConfig";

// Rate limiting configuration (Vertex AI has higher limits)
const RATE_LIMIT = {
  requestsPerMinute: 60,
  retryDelayMs: 2000,
  maxRetries: 3
};

// Track request counts for rate limiting
let requestsThisMinute = 0;
let lastMinuteReset = Date.now();

// Question interface for generated questions
export interface GeneratedQuestion {
  examType: string;
  section: string;
  skill: string;
  difficulty: Difficulty;
  questionText: string;
  passage?: string; // Optional passage for Reading/Writing/Science questions
  choices: string[];
  correctChoiceIndex: number;
  explanation: string;
}

// Sections that require passage-based questions
const PASSAGE_SECTIONS = new Set([
  "Reading",  // SAT Reading, ACT Reading
  "Writing",  // SAT Writing
  "English",  // ACT English
  "Science",  // ACT Science
]);

// Vertex AI client singleton
let vertexAI: VertexAI | null = null;
let generativeModel: GenerativeModel | null = null;

/**
 * Initialize Vertex AI client using Firebase project credentials.
 * No API key needed - uses the project's service account automatically!
 */
function getGeminiModel(): GenerativeModel {
  if (generativeModel) {
    return generativeModel;
  }

  // Get project ID from environment (automatically set by Firebase)
  let projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;

  // For local development with emulator, we might need a fallback
  if (!projectId || projectId === "undefined") {
    projectId = "sat-act-battle-royale"; // Fallback to the project ID in firebase.json
    console.warn(`Project ID not found in environment. Using fallback: ${projectId}`);
  }

  if (!projectId) {
    throw new Error(
      "Could not determine project ID. Make sure you're running in Firebase environment or set GCLOUD_PROJECT."
    );
  }

  // Initialize Vertex AI with project credentials
  vertexAI = new VertexAI({
    project: projectId,
    location: "us-central1", // You can change this to your preferred region
  });

  // Use Gemini 2.0 Flash for fast, cost-effective generation
  generativeModel = vertexAI.getGenerativeModel({
    model: "gemini-2.0-flash",
    generationConfig: {
      maxOutputTokens: 8192,
      temperature: 0.7,
    },
  });

  return generativeModel;
}

// Check and update rate limits
function checkRateLimits(): { canProceed: boolean; waitMs: number } {
  const now = Date.now();

  // Reset minute counter if a minute has passed
  if (now - lastMinuteReset >= 60000) {
    requestsThisMinute = 0;
    lastMinuteReset = now;
  }

  if (requestsThisMinute >= RATE_LIMIT.requestsPerMinute) {
    const waitMs = 60000 - (now - lastMinuteReset) + 1000;
    return { canProceed: false, waitMs };
  }

  return { canProceed: true, waitMs: 0 };
}

// Sleep helper
function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Sections that may need visual elements (graphs, charts, diagrams)
const VISUAL_SECTIONS = new Set(["Math", "Science"]);

// Build the prompt for question generation
function buildPrompt(
  examType: string,
  section: string,
  skill: string,
  count: number,
  difficultyDistribution: Record<Difficulty, number> = DIFFICULTY_DISTRIBUTION
): string {
  const easyCount = Math.round(count * difficultyDistribution.easy);
  const mediumCount = Math.round(count * difficultyDistribution.medium);
  const hardCount = count - easyCount - mediumCount;

  // Check if this section requires passage-based questions
  const requiresPassage = PASSAGE_SECTIONS.has(section);

  // Check if this section may need visual elements
  const mayNeedVisuals = VISUAL_SECTIONS.has(section);

  // Build visual element instructions for Math/Science
  const visualInstructions = mayNeedVisuals ? `
VISUAL ELEMENTS (CRITICAL FOR MATH/SCIENCE):
- If a question involves a graph, chart, table, or diagram, you MUST include it as text-based representation
- For graphs: Describe using ASCII art or provide exact coordinates/data points. Example:
  "The graph shows a line passing through points (0, 2) and (4, 10), representing the equation y = 2x + 2"
- For tables: Use formatted text tables with clear headers. Example:
  "| Time (s) | Distance (m) |
   |    0     |      0       |
   |    2     |     10       |
   |    4     |     25       |"
- For charts: Describe the data in detail. Example:
  "Bar chart data: Category A = 45, Category B = 32, Category C = 58, Category D = 21"
- For diagrams: Provide detailed descriptions with all measurements and labels
- NEVER reference "the figure below" or "see the graph" without including the actual data
- All visual information MUST be self-contained in the question text or passage
` : "";

  // Build passage-specific instructions
  const passageInstructions = requiresPassage ? `
PASSAGE REQUIREMENTS (CRITICAL):
- Each question MUST include a "passage" field containing an original passage of text
- Passages should be 150-300 words for Reading questions, 50-150 words for Writing/English questions, and 100-200 words for Science questions
- For Reading: Create engaging passages from various genres (literary fiction, historical documents, scientific articles, social science)
- For Writing/English: Create passages with deliberate grammar, style, or rhetoric issues that the question addresses
- For Science: Create data-rich passages that INCLUDE full data tables, experimental results, or scientific arguments. Include all data as formatted tables within the passage text.
- The question must directly reference and require understanding of the passage to answer
- Do NOT create standalone questions — every question must be passage-based
` : "";

  // Build the JSON schema example with or without passage field
  const jsonSchema = requiresPassage ? `{
  "examType": "${examType}",
  "section": "${section}",
  "skill": "${skill}",
  "difficulty": "easy" | "medium" | "hard",
  "passage": "The full passage text (150-300 words for Reading, 50-150 for Writing/English, 100-200 for Science)",
  "questionText": "The question about the passage",
  "choices": ["Choice A", "Choice B", "Choice C", "Choice D"],
  "correctChoiceIndex": 0-3,
  "explanation": "Brief explanation of why the correct answer is right"
}` : `{
  "examType": "${examType}",
  "section": "${section}",
  "skill": "${skill}",
  "difficulty": "easy" | "medium" | "hard",
  "questionText": "The full question text",
  "choices": ["Choice A", "Choice B", "Choice C", "Choice D"],
  "correctChoiceIndex": 0-3,
  "explanation": "Brief explanation of why the correct answer is right"
}`;

  return `You are an expert educational content creator writing original test preparation questions for an independent study app called Prep Royale.

Generate exactly ${count} unique ${section} questions that test the skill: "${skill}".

These questions should follow the same general format, question types, and skill areas tested by college entrance exams like the SAT and ACT — so students can genuinely use them to prepare. However, every question must be written with original content (your own invented scenarios, passages, numbers, and wording), not reproduced or closely paraphrased from any real test.
${visualInstructions}${passageInstructions}
Distribution:
- ${easyCount} questions at "easy" difficulty
- ${mediumCount} questions at "medium" difficulty
- ${hardCount} questions at "hard" difficulty

Requirements for each question:
1. Match the format and question style of college entrance exam ${section} sections (question structure, answer choice style, complexity level)
2. Use entirely original, invented content — your own passages, scenarios, data sets, and wording
3. Include exactly 4 answer choices (A, B, C, D)
4. Have exactly one correct answer
5. Include plausible but incorrect distractors that target common misconceptions
6. Provide a clear explanation referencing the "${skill}" concept
7. Difficulty levels should be:
   - easy: Straightforward application of basic concepts
   - medium: Requires multi-step reasoning or deeper understanding
   - hard: Complex scenarios, multiple concepts, or tricky edge cases

CRITICAL: Respond ONLY with a valid JSON array. No markdown, no code blocks, no explanation text.

Each element must have exactly these fields:
${jsonSchema}

Generate the JSON array now:`;
}

// Parse and validate JSON response from Gemini
function parseGeminiResponse(responseText: string): GeneratedQuestion[] {
  let jsonText = responseText.trim();

  // Remove markdown code blocks if present
  if (jsonText.startsWith("```json")) {
    jsonText = jsonText.slice(7);
  } else if (jsonText.startsWith("```")) {
    jsonText = jsonText.slice(3);
  }
  if (jsonText.endsWith("```")) {
    jsonText = jsonText.slice(0, -3);
  }
  jsonText = jsonText.trim();

  // Try to find JSON array in response
  const arrayMatch = jsonText.match(/\[[\s\S]*\]/);
  if (arrayMatch) {
    jsonText = arrayMatch[0];
  }

  try {
    const parsed = JSON.parse(jsonText);

    if (!Array.isArray(parsed)) {
      throw new Error("Response is not an array");
    }

    return parsed;
  } catch (error) {
    console.error("Failed to parse Gemini response:", error);
    console.error("Raw response:", responseText.substring(0, 500));
    throw new Error(`JSON parse error: ${error}`);
  }
}

// Validate a single question object
export function validateQuestion(q: unknown): q is GeneratedQuestion {
  if (!q || typeof q !== "object") return false;

  const question = q as Record<string, unknown>;

  const requiredFields = [
    "examType", "section", "skill", "difficulty",
    "questionText", "choices", "correctChoiceIndex", "explanation"
  ];

  for (const field of requiredFields) {
    if (!(field in question)) {
      console.warn(`Missing field: ${field}`);
      return false;
    }
  }

  if (typeof question.examType !== "string") return false;
  if (typeof question.section !== "string") return false;
  if (typeof question.skill !== "string") return false;
  if (!["easy", "medium", "hard"].includes(question.difficulty as string)) return false;
  if (typeof question.questionText !== "string" || question.questionText.length < 10) return false;
  if (!Array.isArray(question.choices) || question.choices.length !== 4) return false;
  if (typeof question.correctChoiceIndex !== "number" ||
      question.correctChoiceIndex < 0 || question.correctChoiceIndex > 3) return false;
  if (typeof question.explanation !== "string" || question.explanation.length < 5) return false;

  for (const choice of question.choices) {
    if (typeof choice !== "string" || choice.length === 0) return false;
  }

  // Validate passage for sections that require it
  const section = question.section as string;
  if (PASSAGE_SECTIONS.has(section)) {
    if (!question.passage || typeof question.passage !== "string" || question.passage.length < 50) {
      console.warn(`Passage required for ${section} section but missing or too short`);
      return false;
    }
  }

  // If passage is provided (optional), validate it's a string
  if (question.passage !== undefined && typeof question.passage !== "string") {
    return false;
  }

  return true;
}

/**
 * Generate questions using Vertex AI Gemini with rate limiting and retry logic.
 */
export async function generateQuestionsWithGemini(
  examType: string,
  section: string,
  skill: string,
  count: number = 10
): Promise<GeneratedQuestion[]> {
  const model = getGeminiModel();
  const prompt = buildPrompt(examType, section, skill, count);

  let lastError: Error | null = null;

  for (let attempt = 0; attempt < RATE_LIMIT.maxRetries; attempt++) {
    const rateCheck = checkRateLimits();

    if (!rateCheck.canProceed) {
      console.log(`Rate limited. Waiting ${rateCheck.waitMs}ms before retry...`);
      await sleep(rateCheck.waitMs);
      continue;
    }

    try {
      console.log(`Generating ${count} questions for ${examType}/${section}/${skill} (attempt ${attempt + 1})`);

      requestsThisMinute++;

      // Make the API call using Vertex AI
      const result = await model.generateContent({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
      });

      console.log("Gemini API call successful. Parsing response...");

      const response = result.response;
      const text = response.candidates?.[0]?.content?.parts?.[0]?.text;

      if (!text) {
        throw new Error("Empty response from Gemini");
      }

      const questions = parseGeminiResponse(text);
      const validQuestions = questions.filter(validateQuestion);

      if (validQuestions.length === 0) {
        throw new Error("No valid questions in response");
      }

      console.log(`Successfully generated ${validQuestions.length}/${questions.length} valid questions`);
      return validQuestions;

    } catch (error) {
      lastError = error as Error;
      const errorMessage = lastError.message || String(error);

      if (errorMessage.includes("429") || errorMessage.includes("rate limit") ||
          errorMessage.includes("RESOURCE_EXHAUSTED")) {
        console.warn(`Rate limit hit on attempt ${attempt + 1}. Backing off...`);
        await sleep(RATE_LIMIT.retryDelayMs * (attempt + 1));
        continue;
      }

      console.error(`Attempt ${attempt + 1} failed:`, errorMessage);
      if (attempt < RATE_LIMIT.maxRetries - 1) {
        await sleep(RATE_LIMIT.retryDelayMs * (attempt + 1));
      }
    }
  }

  throw lastError || new Error("Failed to generate questions after max retries");
}

/**
 * Generate questions in batches to handle large counts.
 */
export async function generateQuestionsBatch(
  examType: string,
  section: string,
  skill: string,
  totalCount: number,
  batchSize: number = 10
): Promise<GeneratedQuestion[]> {
  const allQuestions: GeneratedQuestion[] = [];
  const batches = Math.ceil(totalCount / batchSize);

  console.log(`Generating ${totalCount} questions in ${batches} batches for ${examType}/${section}/${skill}`);

  for (let i = 0; i < batches; i++) {
    const remaining = totalCount - allQuestions.length;
    const count = Math.min(batchSize, remaining);

    if (count <= 0) break;

    try {
      const questions = await generateQuestionsWithGemini(examType, section, skill, count);
      allQuestions.push(...questions);

      console.log(`Batch ${i + 1}/${batches}: Generated ${questions.length} questions (total: ${allQuestions.length})`);

      if (i < batches - 1) {
        await sleep(2000); // 2 second delay between batches
      }

    } catch (error) {
      console.error(`Batch ${i + 1} failed:`, error);
      if ((error as Error).message?.includes("quota") ||
          (error as Error).message?.includes("RESOURCE_EXHAUSTED")) {
        break;
      }
    }
  }

  return allQuestions;
}
