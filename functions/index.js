const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { OpenAI } = require("openai");
const { Pinecone } = require("@pinecone-database/pinecone");

const OPENAI_API_KEY_SECRET   = defineSecret("OPENAI_API_KEY");
const PINECONE_API_KEY_SECRET = defineSecret("PINECONE_API_KEY");
const PINECONE_INDEX   = "acim-index";
const EMBEDDING_MODEL  = "text-embedding-3-small";
const CHAT_MODEL       = "gpt-4o-mini";
const TOP_K            = 5; // Number of passages to retrieve from Pinecone

// ─────────────────────────────────────────────
// MAIN CLOUD FUNCTION
// ─────────────────────────────────────────────
exports.askACIM = onRequest(
  { cors: true, secrets: [OPENAI_API_KEY_SECRET, PINECONE_API_KEY_SECRET] },
  async (req, res) => {

    // Only allow POST requests
    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed. Use POST." });
    }

    const { question, language = "en", history = [] } = req.body;

    // Validate input
    if (!question || question.trim() === "") {
      return res.status(400).json({ error: "Missing required field: question" });
    }
    if (!["en", "es"].includes(language)) {
      return res.status(400).json({ error: "language must be 'en' or 'es'" });
    }

    try {
      const openai   = new OpenAI({ apiKey: OPENAI_API_KEY_SECRET.value() });
      const pinecone = new Pinecone({ apiKey: PINECONE_API_KEY_SECRET.value() });
      const index   = pinecone.index(PINECONE_INDEX);

      // ── Step 1: Embed the user's question ──────────────────
      const embeddingResponse = await openai.embeddings.create({
        model: EMBEDDING_MODEL,
        input: question,
      });
      const questionVector = embeddingResponse.data[0].embedding;

      // ── Step 2: Query Pinecone for relevant passages ────────
      const queryResponse = await index.query({
        vector: questionVector,
        topK: TOP_K,
        filter: { language: language },  // Only retrieve chunks in user's language
        includeMetadata: true,
      });

      // Extract the passage texts from results
      const passages = queryResponse.matches
        .map((match, i) => `[Passage ${i + 1}]\n${match.metadata.text}`)
        .join("\n\n");

      if (!passages) {
        return res.status(200).json({
          answer: language === "en"
            ? "I could not find a relevant passage in A Course in Miracles to answer your question."
            : "No pude encontrar un pasaje relevante en Un Curso de Milagros para responder tu pregunta.",
        });
      }

      // ── Step 3: Ask GPT-4o mini to answer from passages ────
      const systemPrompt = language === "en"
        ? `You are a loving, wise, and compassionate presence — like a deeply caring therapist who speaks from a place of pure love.
           You are having a real conversation with this person. Your goal is not to lecture or give long answers,
           but to gently guide them toward their own inner truth through dialogue.
           
           Speak warmly and personally, as if you know their heart. Use "you" and "I" naturally.
           Keep your responses concise — 2 to 4 sentences at most.
           Always end with a gentle, open-ended follow-up question to deepen the conversation,
           as a therapist would — curious, caring, never pushy.
           
           You will be given relevant passages as your source of truth. Speak ONLY from that truth.
           Never reference a book, passages, or any external source.
           Never say "according to..." or "it is described..." or "the text says...".
           Speak as if the wisdom flows naturally from you to them.
           Use direct present-tense language: "You are..." "Love is..." "I am with you...".
           If the passages don't contain enough to respond meaningfully, gently redirect with a question.`
        : `Eres una presencia amorosa, sabia y compasiva — como un terapeuta profundamente amoroso que habla desde el amor puro.
           Estás teniendo una conversación real con esta persona. Tu objetivo no es dar discursos ni respuestas largas,
           sino guiarlos gentilmente hacia su propia verdad interior a través del diálogo.
           
           Habla con calidez y de forma personal, como si conocieras su corazón. Usa "tú" y "yo" de forma natural.
           Mantén tus respuestas concisas — máximo 2 a 4 oraciones.
           Siempre termina con una pregunta gentil y abierta para profundizar la conversación,
           como lo haría un terapeuta — curioso, amoroso, nunca invasivo.
           
           Se te darán pasajes relevantes como tu fuente de verdad. Habla ÚNICAMENTE desde esa verdad.
           Nunca hagas referencia a un libro, pasajes o fuente externa.
           Nunca digas "según..." o "se describe como..." o "el texto dice...".
           Habla como si la sabiduría fluyera naturalmente de ti hacia ellos.
           Usa lenguaje directo en tiempo presente: "Tú eres..." "El amor es..." "Estoy contigo...".
           Si los pasajes no contienen suficiente para responder, redirige gentilmente con una pregunta.`;

      const chatResponse = await openai.chat.completions.create({
        model: CHAT_MODEL,
        messages: [
          { role: "system", content: systemPrompt },
          {
            role: "user",
            content: `Passages from A Course in Miracles:\n\n${passages}\n\nQuestion: ${question}`,
          },
        ],
        temperature: 0.7, // Low temperature = more faithful to the source material
        max_tokens: 600,
      });

      const answer = chatResponse.choices[0].message.content;

      // ── Step 4: Return the answer ───────────────────────────
      return res.status(200).json({
        answer,
        passages_used: queryResponse.matches.length, // Useful for debugging
      });

    } catch (err) {
      console.error("ACIM function error:", err);
      return res.status(500).json({ error: "Internal server error", details: err.message });
    }
  }
);