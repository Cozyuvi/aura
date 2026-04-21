# Aura

Aura is a voice-first telehealth assistant built with Flutter. It supports live doctor-style conversation, on-demand body-part image capture, and structured diagnosis storage in MongoDB through the backend service.

## Backend

The Node backend lives in [backend/server.js](backend/server.js) and uses these environment variables:

- `MONGODB_URI`: MongoDB connection string
- `MONGODB_DB`: optional database name
- `PORT`: backend port, defaults to `3000`

Copy [backend/.env.example](backend/.env.example) to `backend/.env`, fill in the values, then run:

```bash
cd backend
npm install
npm start
```

## Flutter App

The app stores diagnosis records through `AURA_BACKEND_URL`. If that is not set, it falls back to a local backend URL on desktop and emulator targets.

Typical workflow:

```bash
flutter pub get
flutter run
```

If the consultation needs visual context, the assistant will request a body-part image and then refine the diagnosis using that image.
