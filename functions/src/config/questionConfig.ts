/**
 * Canonical skill configuration for SAT/ACT question generation.
 * These skill IDs are used in Firestore and in Gemini prompts.
 */

export interface SectionConfig {
  skills: readonly string[];
  perSkillCount: number;
}

export interface ExamConfig {
  [section: string]: SectionConfig;
}

export interface QuestionConfigType {
  SAT: {
    Math: SectionConfig;
    Reading: SectionConfig;
    Writing: SectionConfig;
  };
  ACT: {
    Math: SectionConfig;
    English: SectionConfig;
    Reading: SectionConfig;
    Science: SectionConfig;
  };
}

export const QUESTION_CONFIG: QuestionConfigType = {
  SAT: {
    Math: {
      skills: [
        "LinearEquations",
        "SystemsOfEquations",
        "Functions",
        "Quadratics",
        "RatiosProportionsPercentages",
        "StatisticsDataAnalysis",
        "GeometryAndTrigonometry",
        "WordProblems",
        "ExponentsAndRadicals"
      ] as const,
      perSkillCount: 300 // Increased from 150 - ensures users never run out
    },
    Reading: {
      skills: [
        "MainIdea",
        "SupportingEvidence",
        "Inference",
        "WordsInContext",
        "AuthorPurposeTone",
        "GraphAndTableInterpretation"
      ] as const,
      perSkillCount: 250 // Increased from 120
    },
    Writing: {
      skills: [
        "GrammarUsage",
        "SentenceStructure",
        "Punctuation",
        "Conciseness",
        "TransitionsAndOrganization"
      ] as const,
      perSkillCount: 250 // Increased from 120
    }
  },
  ACT: {
    Math: {
      skills: [
        "PreAlgebra",
        "Algebra",
        "CoordinateGeometry",
        "PlaneGeometry",
        "Trigonometry",
        "WordProblems"
      ] as const,
      perSkillCount: 250 // Increased from 120
    },
    English: {
      skills: [
        "GrammarUsage",
        "SentenceStructure",
        "Punctuation",
        "RhetoricalSkills",
        "StyleAndTone"
      ] as const,
      perSkillCount: 250 // Increased from 120
    },
    Reading: {
      skills: [
        "MainIdea",
        "DetailQuestions",
        "Inference",
        "ComparativePassages"
      ] as const,
      perSkillCount: 200 // Increased from 100
    },
    Science: {
      skills: [
        "DataRepresentation",
        "ResearchSummaries",
        "ConflictingViewpoints"
      ] as const,
      perSkillCount: 200 // Increased from 100
    }
  }
} as const;

export type ExamType = keyof typeof QUESTION_CONFIG;
export type SATSection = keyof typeof QUESTION_CONFIG.SAT;
export type ACTSection = keyof typeof QUESTION_CONFIG.ACT;
export type Difficulty = "easy" | "medium" | "hard";

// Difficulty distribution for question generation
export const DIFFICULTY_DISTRIBUTION: Record<Difficulty, number> = {
  easy: 0.4,
  medium: 0.4,
  hard: 0.2
};

// Get all skills for a given exam type and section
export function getSkillsForSection(examType: ExamType, section: string): readonly string[] {
  const examConfig = QUESTION_CONFIG[examType];
  const sectionConfig = examConfig[section as keyof typeof examConfig];
  return sectionConfig?.skills || [];
}

// Get target count per skill for a section
export function getPerSkillCount(examType: ExamType, section: string): number {
  const examConfig = QUESTION_CONFIG[examType];
  const sectionConfig = examConfig[section as keyof typeof examConfig];
  return sectionConfig?.perSkillCount || 100;
}
