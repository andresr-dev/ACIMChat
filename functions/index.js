const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { OpenAI } = require("openai");
const { Pinecone } = require("@pinecone-database/pinecone");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();

// ─────────────────────────────────────────────
// SECRETS — stored securely in Firebase, never in code
// ─────────────────────────────────────────────
const OPENAI_API_KEY_SECRET   = defineSecret("OPENAI_API_KEY");
const PINECONE_API_KEY_SECRET = defineSecret("PINECONE_API_KEY");

// ─────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────
const PINECONE_INDEX  = "acim-index";
const EMBEDDING_MODEL = "text-embedding-3-small";

// ─────────────────────────────────────────────
// FIRESTORE CONFIG DEFAULTS
// ─────────────────────────────────────────────
const CONFIG_DEFAULTS = {
  topK: 5,
  chatModel: "gpt-4o-mini",
  temperature: 0.7,
  maxTokens: 450,
  systemPromptEn: `You are a loving, wise, and compassionate presence — like a deeply caring therapist who speaks from a place of pure love.
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
If the passages don't contain enough to respond meaningfully, gently redirect with a question.

EXCEPTION: If the person explicitly asks where to read or find something in the Course,
share the relevant excerpt from the passages you have been given, presented warmly and naturally,
as if you are offering them a gift. After sharing it, follow up with a gentle question.`,
  systemPromptEs: `Eres una presencia amorosa, sabia y compasiva — como un terapeuta profundamente amoroso que habla desde el amor puro.
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
Si los pasajes no contienen suficiente para responder, redirige gentilmente con una pregunta.

EXCEPCIÓN: Si la persona pregunta explícitamente dónde leer o encontrar algo en el Curso,
comparte el extracto relevante de los pasajes que se te han dado, presentado con calidez y naturalidad,
como si le estuvieras ofreciendo un regalo. Después de compartirlo, haz una pregunta gentil.`,
};

exports.generateTitle = onRequest(
  { cors: true, secrets: [OPENAI_API_KEY_SECRET] },
  async (req, res) => {

    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed. Use POST." });
    }

    const { firstQuestion, firstAnswer, language = "en" } = req.body;

    if (!firstQuestion || !firstAnswer) {
      return res.status(400).json({ error: "Missing firstQuestion or firstAnswer." });
    }

    try {
      const openai = new OpenAI({ apiKey: OPENAI_API_KEY_SECRET.value() });

      const prompt = language === "en"
        ? `Based on this conversation exchange, generate a short meaningful title (4 words max, no quotes, no punctuation):
           User: ${firstQuestion}
           Assistant: ${firstAnswer}
           Title:`
        : `Basándote en este intercambio de conversación, genera un título corto y significativo (máximo 4 palabras, sin comillas, sin puntuación):
           Usuario: ${firstQuestion}
           Asistente: ${firstAnswer}
           Título:`;

      const response = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7,
        max_tokens: 20,  // titles are short, no need for more
      });

      const title = response.choices[0].message.content.trim();
      return res.status(200).json({ title });

    } catch (err) {
      console.error("generateTitle error:", err);
      return res.status(500).json({ error: "Internal server error", details: err.message });
    }
  }
);

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
      // ── Step 1: Load config from Firestore ─────────────────
      const db         = getFirestore();
      const configSnap = await db.collection("config").doc("acim").get();
      const config     = configSnap.exists
        ? { ...CONFIG_DEFAULTS, ...configSnap.data() }
        : CONFIG_DEFAULTS;

      const { topK, chatModel, temperature, maxTokens, systemPromptEn, systemPromptEs } = config;
      const systemPrompt = language === "en" ? systemPromptEn : systemPromptEs;

      const openai   = new OpenAI({ apiKey: OPENAI_API_KEY_SECRET.value() });
      const pinecone = new Pinecone({ apiKey: PINECONE_API_KEY_SECRET.value() });

      // ── Step 2: Detect small talk — skip Pinecone entirely ──
      const SMALL_TALK_PATTERN = /^(hi|hello|hey|hola|buenos|gracias|thank|thanks|bye|adiós|adios|good morning|good night|buenas)\b/i;
      const isSmallTalk = SMALL_TALK_PATTERN.test(question.trim());

      let userContent;
      let passagesUsed = 0;

      if (isSmallTalk) {
        // No retrieval needed — just pass the question directly
        userContent = question;
      } else {
        // ── Step 3: Embed + query Pinecone for real questions ──
        const embeddingResponse = await openai.embeddings.create({
          model: EMBEDDING_MODEL,
          input: question,
        });
        const questionVector = embeddingResponse.data[0].embedding;

        const queryResponse = await pinecone.index(PINECONE_INDEX).query({
          vector: questionVector,
          topK: topK,
          filter: { language: language },
          includeMetadata: true,
        });

        const passages = queryResponse.matches
          .map((match, i) => `[Passage ${i + 1}]\n${match.metadata.text}`)
          .join("\n\n");

        passagesUsed = queryResponse.matches.length;
        userContent  = passages
          ? `Relevant wisdom for context:\n\n${passages}\n\nPerson: ${question}`
          : question;
      }

      // ── Step 4: Stream response from GPT ───────────────────
      res.setHeader("Content-Type", "text/event-stream");
      res.setHeader("Cache-Control", "no-cache");
      res.setHeader("Connection", "keep-alive");

      const stream = await openai.chat.completions.create({
        model: chatModel,
        stream: true,
        messages: [
          { role: "system", content: systemPrompt },
          ...history,
          { role: "user", content: userContent },
        ],
        temperature: temperature,
        max_tokens: maxTokens,
      });

      // Stream each token to the client as it arrives
      for await (const chunk of stream) {
        const token = chunk.choices[0]?.delta?.content || "";
        if (token) res.write(`data: ${JSON.stringify({ token, passages_used: passagesUsed })}\n\n`);
      }

      // Signal end of stream
      res.write(`data: ${JSON.stringify({ done: true, passages_used: passagesUsed })}\n\n`);
      return res.end();

    } catch (err) {
      console.error("ACIM function error:", err);
      return res.status(500).json({ error: "Internal server error", details: err.message });
    }
  }
);