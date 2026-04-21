const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const dgram = require('dgram');
const os = require('os');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '12mb' }));

const JWT_SECRET = process.env.JWT_SECRET || 'aura_dev_secret_change_me';
const JWT_ISSUER = 'aura-backend';
const DISCOVERY_PORT = Number(process.env.AURA_DISCOVERY_PORT || 40404);
const DISCOVERY_REQUEST = 'AURA_DISCOVER_V1';

function trimString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function normalizeEmail(value) {
  return trimString(value).toLowerCase();
}

function isValidEmail(value) {
  const email = normalizeEmail(value);
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function toStringArray(value) {
  if (Array.isArray(value)) {
    return value
      .map((entry) => String(entry).trim())
      .filter((entry) => entry.length > 0);
  }
  if (typeof value === 'string' && value.trim().length > 0) {
    return value
      .split(',')
      .map((entry) => entry.trim())
      .filter((entry) => entry.length > 0);
  }
  return [];
}

function toOptionalNumber(value) {
  if (value === null || value === undefined || value === '') {
    return null;
  }
  const num = Number(value);
  return Number.isFinite(num) ? num : null;
}

function isPrivateIPv4(address) {
  return (
    /^10\./.test(address) ||
    /^192\.168\./.test(address) ||
    /^172\.(1[6-9]|2\d|3[01])\./.test(address)
  );
}

function getPrimaryHostIp() {
  const interfaces = os.networkInterfaces();
  const candidates = [];

  for (const entries of Object.values(interfaces)) {
    for (const entry of entries || []) {
      if (!entry || entry.family !== 'IPv4' || entry.internal) {
        continue;
      }
      candidates.push(entry.address);
    }
  }

  const privateCandidates = candidates.filter(isPrivateIPv4);
  return privateCandidates[0] || candidates[0] || '127.0.0.1';
}

function startDiscoveryServer(httpPort) {
  const socket = dgram.createSocket('udp4');
  const hostIp = getPrimaryHostIp();

  socket.on('error', (error) => {
    console.error('Aura discovery socket error:', error);
  });

  socket.on('message', (message, remoteInfo) => {
    const payload = trimString(message.toString());
    if (payload !== DISCOVERY_REQUEST) {
      return;
    }

    const response = JSON.stringify({
      service: 'aura-backend',
      httpBaseUrl: `http://${hostIp}:${httpPort}`,
      hostIp,
      port: httpPort,
    });

    socket.send(Buffer.from(response, 'utf8'), remoteInfo.port, remoteInfo.address);
  });

  socket.bind(DISCOVERY_PORT, '0.0.0.0', () => {
    socket.setBroadcast(true);
    console.log(`Aura discovery listening on UDP ${DISCOVERY_PORT}`);
  });

  return socket;
}

function signAccessToken(userId, rememberMe) {
  const expiresIn = rememberMe ? '30d' : '1d';
  const token = jwt.sign(
    {
      sub: userId,
      typ: 'access',
    },
    JWT_SECRET,
    {
      expiresIn,
      issuer: JWT_ISSUER,
    }
  );
  return { token, expiresIn };
}

function readBearerToken(req) {
  const header = trimString(req.headers.authorization);
  if (!header.toLowerCase().startsWith('bearer ')) {
    return null;
  }
  return header.slice(7).trim();
}

function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET, { issuer: JWT_ISSUER });
  } catch (_error) {
    return null;
  }
}

function authRequired(req, res, next) {
  const token = readBearerToken(req);
  if (!token) {
    return res.status(401).json({ error: 'Authorization token is required' });
  }

  const payload = verifyToken(token);
  if (!payload || !payload.sub || !mongoose.Types.ObjectId.isValid(payload.sub)) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }

  req.authUserId = payload.sub;
  return next();
}

const userProfileSchema = new mongoose.Schema(
  {
    age: { type: Number, default: null },
    sex: { type: String, default: '' },
    weightKg: { type: Number, default: null },
    heightCm: { type: Number, default: null },
    bloodGroup: { type: String, default: '' },
    city: { type: String, default: '' },
    conditions: { type: [String], default: [] },
    medications: { type: [String], default: [] },
    photoDataUrl: { type: String, default: '' },
  },
  { _id: false }
);

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, index: true },
    phone: { type: String, required: true },
    passwordHash: { type: String, required: true },
    profile: { type: userProfileSchema, default: () => ({}) },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

const imageReferenceSchema = new mongoose.Schema(
  {
    bucket: { type: String, default: '' },
    objectName: { type: String, default: '' },
    gcsUri: { type: String, default: '' },
    mediaLink: { type: String, default: '' },
    contentType: { type: String, default: '' },
    uploadedAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

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
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true, default: null },
    sessionId: { type: String, required: true, index: true },
    userText: { type: String, default: '' },
    assessment: { type: assessmentSchema, required: true },
    imageName: { type: String, default: '' },
    imageMimeType: { type: String, default: '' },
    imageBytesLength: { type: Number, default: 0 },
    imageReference: { type: imageReferenceSchema, default: null },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

const User = mongoose.model('User', userSchema);
const DiagnosisRecord = mongoose.model('DiagnosisRecord', diagnosisRecordSchema);

function serializeUser(userDoc) {
  return {
    id: userDoc._id.toString(),
    name: trimString(userDoc.name),
    email: normalizeEmail(userDoc.email),
    phone: trimString(userDoc.phone),
    profile: {
      age: toOptionalNumber(userDoc.profile?.age),
      sex: trimString(userDoc.profile?.sex),
      weightKg: toOptionalNumber(userDoc.profile?.weightKg),
      heightCm: toOptionalNumber(userDoc.profile?.heightCm),
      bloodGroup: trimString(userDoc.profile?.bloodGroup),
      city: trimString(userDoc.profile?.city),
      conditions: toStringArray(userDoc.profile?.conditions),
      medications: toStringArray(userDoc.profile?.medications),
      photoDataUrl: trimString(userDoc.profile?.photoDataUrl),
    },
    createdAt: userDoc.createdAt,
    updatedAt: userDoc.updatedAt,
  };
}

function serializeDiagnosisRecord(record) {
  const assessment = record.assessment || {};
  return {
    id: record._id?.toString?.() || '',
    createdAt: record.createdAt,
    diagnosisSummary: trimString(assessment.diagnosisSummary),
    spokenResponse: trimString(assessment.spokenResponse),
    targetSpecialty: trimString(assessment.targetSpecialty),
    urgency: trimString(assessment.urgency),
    likelyConditions: toStringArray(assessment.likelyConditions),
    redFlags: toStringArray(assessment.redFlags),
    recommendedNextStep: trimString(assessment.recommendedNextStep),
    bodyPart: trimString(assessment.bodyPart),
    confidence: Number.isFinite(assessment.confidence) ? assessment.confidence : 0.0,
  };
}

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'aura-backend' });
});

app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, phone, password, rememberMe } = req.body || {};

    const normalizedName = trimString(name);
    const normalizedEmail = normalizeEmail(email);
    const normalizedPhone = trimString(phone);
    const normalizedPassword = trimString(password);

    if (!normalizedName || !normalizedEmail || !normalizedPhone || !normalizedPassword) {
      return res.status(400).json({ error: 'name, email, phone and password are required' });
    }

    if (!isValidEmail(normalizedEmail)) {
      return res.status(400).json({ error: 'Please enter a valid email address' });
    }

    if (normalizedPassword.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    const existingUser = await User.findOne({ email: normalizedEmail }).lean();
    if (existingUser) {
      return res.status(409).json({ error: 'An account with this email already exists' });
    }

    const passwordHash = await bcrypt.hash(normalizedPassword, 10);
    const user = await User.create({
      name: normalizedName,
      email: normalizedEmail,
      phone: normalizedPhone,
      passwordHash,
      profile: {},
    });

    const remember = Boolean(rememberMe);
    const { token, expiresIn } = signAccessToken(user._id.toString(), remember);

    return res.status(201).json({
      ok: true,
      token,
      expiresIn,
      rememberMe: remember,
      user: serializeUser(user),
    });
  } catch (error) {
    console.error('Register failed:', error);
    return res.status(500).json({ error: 'Failed to register user' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password, rememberMe } = req.body || {};

    const normalizedEmail = normalizeEmail(email);
    const normalizedPassword = trimString(password);

    if (!normalizedEmail || !normalizedPassword) {
      return res.status(400).json({ error: 'email and password are required' });
    }

    const user = await User.findOne({ email: normalizedEmail });
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const validPassword = await bcrypt.compare(normalizedPassword, user.passwordHash);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const remember = Boolean(rememberMe);
    const { token, expiresIn } = signAccessToken(user._id.toString(), remember);

    return res.json({
      ok: true,
      token,
      expiresIn,
      rememberMe: remember,
      user: serializeUser(user),
    });
  } catch (error) {
    console.error('Login failed:', error);
    return res.status(500).json({ error: 'Failed to login' });
  }
});

app.get('/api/auth/me', authRequired, async (req, res) => {
  try {
    const user = await User.findById(req.authUserId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    return res.json({ ok: true, user: serializeUser(user) });
  } catch (error) {
    console.error('Fetch me failed:', error);
    return res.status(500).json({ error: 'Failed to fetch user profile' });
  }
});

app.put('/api/auth/profile', authRequired, async (req, res) => {
  try {
    const user = await User.findById(req.authUserId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const payload = req.body || {};
    const profile = payload.profile && typeof payload.profile === 'object' ? payload.profile : {};

    const nextName = trimString(payload.name);
    const nextPhone = trimString(payload.phone);

    if (nextName) {
      user.name = nextName;
    }

    if (nextPhone) {
      user.phone = nextPhone;
    }

    const existingProfile = user.profile || {};
    user.profile = {
      age: toOptionalNumber(profile.age ?? existingProfile.age),
      sex: trimString(profile.sex ?? existingProfile.sex),
      weightKg: toOptionalNumber(profile.weightKg ?? existingProfile.weightKg),
      heightCm: toOptionalNumber(profile.heightCm ?? existingProfile.heightCm),
      bloodGroup: trimString(profile.bloodGroup ?? existingProfile.bloodGroup),
      city: trimString(profile.city ?? existingProfile.city),
      conditions: profile.conditions !== undefined
        ? toStringArray(profile.conditions)
        : toStringArray(existingProfile.conditions),
      medications: profile.medications !== undefined
        ? toStringArray(profile.medications)
        : toStringArray(existingProfile.medications),
      photoDataUrl: trimString(profile.photoDataUrl ?? existingProfile.photoDataUrl),
    };

    await user.save();
    return res.json({ ok: true, user: serializeUser(user) });
  } catch (error) {
    console.error('Update profile failed:', error);
    return res.status(500).json({ error: 'Failed to update profile' });
  }
});

app.post('/api/diagnosis-records', async (req, res) => {
  try {
    const {
      sessionId,
      userText,
      assessment,
      imageName,
      imageMimeType,
      imageBytesLength,
      imageReference,
      userId,
      createdAt,
    } = req.body || {};

    if (!sessionId || typeof sessionId !== 'string') {
      return res.status(400).json({ error: 'sessionId is required' });
    }

    if (!assessment || typeof assessment !== 'object') {
      return res.status(400).json({ error: 'assessment is required' });
    }

    const bearerToken = readBearerToken(req);
    const tokenPayload = bearerToken ? verifyToken(bearerToken) : null;
    const tokenUserId = tokenPayload?.sub;

    let resolvedUserId = null;
    if (tokenUserId && mongoose.Types.ObjectId.isValid(tokenUserId)) {
      resolvedUserId = tokenUserId;
    } else if (typeof userId === 'string' && mongoose.Types.ObjectId.isValid(userId)) {
      resolvedUserId = userId;
    }

    const record = await DiagnosisRecord.create({
      userId: resolvedUserId,
      sessionId,
      userText: typeof userText === 'string' ? userText : '',
      assessment,
      imageName: typeof imageName === 'string' ? imageName : '',
      imageMimeType: typeof imageMimeType === 'string' ? imageMimeType : '',
      imageBytesLength: Number.isFinite(imageBytesLength) ? imageBytesLength : 0,
      imageReference: imageReference && typeof imageReference === 'object' ? imageReference : null,
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

app.get('/api/client/dashboard', authRequired, async (req, res) => {
  try {
    const user = await User.findById(req.authUserId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const [totalSessions, recentRecordsRaw] = await Promise.all([
      DiagnosisRecord.countDocuments({ userId: user._id }),
      DiagnosisRecord.find({ userId: user._id }).sort({ createdAt: -1 }).limit(12).lean(),
    ]);

    const recentRecords = recentRecordsRaw.map((record) => serializeDiagnosisRecord(record));
    const specialtySet = new Set(
      recentRecords
        .map((record) => trimString(record.targetSpecialty))
        .filter((value) => value.length > 0)
    );
    const urgentCases = recentRecords.filter((record) => {
      const urgency = trimString(record.urgency).toLowerCase();
      return urgency === 'urgent' || urgency === 'emergency';
    }).length;

    return res.json({
      ok: true,
      user: serializeUser(user),
      metrics: {
        sessions: totalSessions,
        doctors: specialtySet.size,
        urgentCases,
      },
      latestRecord: recentRecords.length > 0 ? recentRecords[0] : null,
      recentRecords,
    });
  } catch (error) {
    console.error('Failed to build client dashboard:', error);
    return res.status(500).json({ error: 'Failed to load dashboard data' });
  }
});

async function start() {
  const mongoUri = process.env.MONGODB_URI;
  const mongoDirectUri = process.env.MONGODB_URI_DIRECT;
  if (!mongoUri) {
    throw new Error('MONGODB_URI is required');
  }

  const port = Number(process.env.PORT || 3000);
  const dbName = process.env.MONGODB_DB;

  try {
    await mongoose.connect(mongoUri, dbName ? { dbName } : undefined);
  } catch (error) {
    const message = String(error?.message || '');
    const isSrvResolutionError = message.includes('querySrv');

    if (!mongoDirectUri || !isSrvResolutionError) {
      throw error;
    }

    console.warn(
      'MONGODB_URI SRV lookup failed. Retrying with MONGODB_URI_DIRECT fallback...'
    );
    await mongoose.connect(mongoDirectUri, dbName ? { dbName } : undefined);
  }

  app.listen(port, () => {
    console.log(`Aura backend listening on http://localhost:${port}`);
    startDiscoveryServer(port);
  });
}

start().catch((error) => {
  console.error('Failed to start Aura backend:', error);
  process.exit(1);
});
