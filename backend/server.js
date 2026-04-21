const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));

const assessmentSchema = new mongoose.Schema(
  {
    spokenResponse: { type: String, default: '' },
    diagnosisSummary: { type: String, default: '' },
    targetSpecialty: { type: String, default: '' },
    urgency: { type: String, default: '' },
    needsImage: { type: Boolean, default: false },
    imageRequest: { type: String, default: '' },
    bodyPart: { type: String, default: '' },
    followUpQuestion: { type: String, default: '' },
    likelyConditions: { type: [String], default: [] },
    redFlags: { type: [String], default: [] },
    recommendedNextStep: { type: String, default: '' },
    confidence: { type: Number, default: 0.5 },
    rawJson: { type: String, default: '' },
  },
  { _id: false }
);

const diagnosisRecordSchema = new mongoose.Schema(
  {
    sessionId: { type: String, required: true, index: true },
    userText: { type: String, default: '' },
    assessment: { type: assessmentSchema, required: true },
    imageName: { type: String, default: '' },
    imageMimeType: { type: String, default: '' },
    imageBytesLength: { type: Number, default: 0 },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

const DiagnosisRecord = mongoose.model('DiagnosisRecord', diagnosisRecordSchema);

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'aura-backend' });
});

app.post('/api/diagnosis-records', async (req, res) => {
  try {
    const { sessionId, userText, assessment, imageName, imageMimeType, imageBytesLength, createdAt } = req.body || {};

    if (!sessionId || typeof sessionId !== 'string') {
      return res.status(400).json({ error: 'sessionId is required' });
    }

    if (!assessment || typeof assessment !== 'object') {
      return res.status(400).json({ error: 'assessment is required' });
    }

    const record = await DiagnosisRecord.create({
      sessionId,
      userText: typeof userText === 'string' ? userText : '',
      assessment,
      imageName: typeof imageName === 'string' ? imageName : '',
      imageMimeType: typeof imageMimeType === 'string' ? imageMimeType : '',
      imageBytesLength: Number.isFinite(imageBytesLength) ? imageBytesLength : 0,
      createdAt: createdAt ? new Date(createdAt) : new Date(),
    });

    return res.status(201).json({ ok: true, record });
  } catch (error) {
    console.error('Failed to store diagnosis record:', error);
    return res.status(500).json({ error: 'Failed to store diagnosis record' });
  }
});

app.get('/api/diagnosis-records/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const records = await DiagnosisRecord.find({ sessionId }).sort({ createdAt: -1 }).lean();
    return res.json({ ok: true, records });
  } catch (error) {
    console.error('Failed to read diagnosis records:', error);
    return res.status(500).json({ error: 'Failed to read diagnosis records' });
  }
});

async function start() {
  const mongoUri = process.env.MONGODB_URI;
  if (!mongoUri) {
    throw new Error('MONGODB_URI is required');
  }

  const port = Number(process.env.PORT || 3000);
  const dbName = process.env.MONGODB_DB;

  await mongoose.connect(mongoUri, dbName ? { dbName } : undefined);
  app.listen(port, () => {
    console.log(`Aura backend listening on http://localhost:${port}`);
  });
}

start().catch((error) => {
  console.error('Failed to start Aura backend:', error);
  process.exit(1);
});
