import { logger } from './logger.util';

/**
 * Gemini Embedding Utility
 *
 * Uses gemini-embedding-001 via HTTP API with outputDimensionality=768.
 *
 * ⚠️ IMPORTANT: When using outputDimensionality < 3072, Gemini returns
 * UN-NORMALIZED vectors. We must L2-normalize them before computing
 * cosine similarity, otherwise scores will be biased toward ~0.6 for everything.
 *
 * Free tier:
 *  - 1,500 requests/minute
 *  - 1,500 requests/day
 */

const API_KEY = process.env.GEMINI_API_KEY ?? '';
const MODEL = 'gemini-embedding-001';
const API_BASE = 'https://generativelanguage.googleapis.com/v1beta';

if (!API_KEY) {
  logger.warn('GEMINI_API_KEY not set — embedding generation will fail');
}

/** Embedding dimensionality — 768 balances quality and storage. */
export const EMBEDDING_DIM = 768;

type TaskType =
  | 'RETRIEVAL_QUERY'
  | 'RETRIEVAL_DOCUMENT'
  | 'SEMANTIC_SIMILARITY'
  | 'CLASSIFICATION'
  | 'CLUSTERING'
  | 'QUESTION_ANSWERING'
  | 'FACT_VERIFICATION';

/**
 * L2-normalize a vector (so its length becomes 1.0)
 * Required when outputDimensionality < 3072.
 */
function normalize(vec: number[]): number[] {
  let sumSq = 0;
  for (const v of vec) sumSq += v * v;
  const norm = Math.sqrt(sumSq);
  if (norm === 0) return vec;
  return vec.map((v) => v / norm);
}

/**
 * Generate embedding via Gemini HTTP API
 */
export async function generateEmbedding(
  text: string,
  taskType: TaskType = 'RETRIEVAL_DOCUMENT',
): Promise<number[] | null> {
  if (!text || text.trim().length === 0) return null;
  if (!API_KEY) return null;

  const cleaned = text.trim().slice(0, 8000);

  try {
    const url = `${API_BASE}/models/${MODEL}:embedContent?key=${API_KEY}`;
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        content: { parts: [{ text: cleaned }] },
        taskType,
        outputDimensionality: EMBEDDING_DIM,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      logger.error('Gemini API returned error', {
        status: response.status,
        body: errorText.slice(0, 500),
      });
      return null;
    }

    const data = (await response.json()) as {
      embedding?: { values?: number[] };
    };

    const values = data.embedding?.values;
    if (!Array.isArray(values) || values.length === 0) {
      logger.error('Gemini returned invalid embedding', { data });
      return null;
    }

    // ⭐ L2-normalize (Gemini doesn't normalize when outputDimensionality < 3072)
    return normalize(values);
  } catch (err) {
    logger.error('Embedding generation failed', {
      err: String(err),
      textLength: cleaned.length,
    });
    return null;
  }
}

export function embedDocument(text: string): Promise<number[] | null> {
  return generateEmbedding(text, 'RETRIEVAL_DOCUMENT');
}

export function embedQuery(text: string): Promise<number[] | null> {
  return generateEmbedding(text, 'RETRIEVAL_QUERY');
}

/**
 * Cosine similarity between two vectors.
 * Both vectors should be L2-normalized for correct results — see generateEmbedding above.
 */
export function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length !== b.length) return 0;
  if (a.length === 0) return 0;

  let dotProduct = 0;
  let normA = 0;
  let normB = 0;

  for (let i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  const denom = Math.sqrt(normA) * Math.sqrt(normB);
  if (denom === 0) return 0;

  return dotProduct / denom;
}

export function buildEmbedText(parts: {
  title: string;
  description?: string | null;
  category?: string | null;
  condition?: string | null;
}): string {
  return [parts.title, parts.description, parts.category, parts.condition]
    .filter((p): p is string => Boolean(p))
    .join(' ');
}
