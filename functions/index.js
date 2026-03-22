const crypto = require("crypto");
const admin = require("firebase-admin");
const functions = require("firebase-functions");
const nodemailer = require("nodemailer");

admin.initializeApp();

const db = admin.firestore();

const RESET_CODE_TTL_MINUTES = 10;
const MAX_VERIFY_ATTEMPTS = 5;

function normalizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function hashText(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function generateSixDigitCode() {
  const code = Math.floor(100000 + Math.random() * 900000);
  return String(code);
}

function getMailTransporter() {
  const host = process.env.SMTP_HOST;
  const port = Number(process.env.SMTP_PORT || "587");
  const secure = String(process.env.SMTP_SECURE || "false") === "true";
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (!host || !user || !pass) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Email sender is not configured. Set SMTP_HOST, SMTP_PORT, SMTP_SECURE, SMTP_USER, SMTP_PASS."
    );
  }

  return nodemailer.createTransport({
    host,
    port,
    secure,
    auth: { user, pass },
  });
}

exports.requestPasswordResetCode = functions.https.onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "Email is required.");
  }

  const emailHash = hashText(email);
  const docRef = db.collection("password_reset_codes").doc(emailHash);

  try {
    const userRecord = await admin.auth().getUserByEmail(email);
    const now = admin.firestore.Timestamp.now();
    const nowMs = now.toMillis();

    const existingDoc = await docRef.get();
    if (existingDoc.exists) {
      const data = existingDoc.data() || {};
      const lastSentAt = data.lastSentAt;
      if (lastSentAt && typeof lastSentAt.toMillis === "function") {
        const diffSeconds = (nowMs - lastSentAt.toMillis()) / 1000;
        if (diffSeconds < 30) {
          throw new functions.https.HttpsError(
            "resource-exhausted",
            "Please wait before requesting another code."
          );
        }
      }
    }

    const resetCode = generateSixDigitCode();
    const resetCodeHash = hashText(resetCode);
    const expiresAt = admin.firestore.Timestamp.fromMillis(
      nowMs + RESET_CODE_TTL_MINUTES * 60 * 1000
    );

    await docRef.set(
      {
        email,
        uid: userRecord.uid,
        codeHash: resetCodeHash,
        attempts: 0,
        expiresAt,
        lastSentAt: now,
        createdAt: now,
      },
      { merge: true }
    );

    const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;
    const transporter = getMailTransporter();

    await transporter.sendMail({
      from: fromAddress,
      to: email,
      subject: "Your Study Mate password reset code",
      text: `Your password reset code is ${resetCode}. This code expires in ${RESET_CODE_TTL_MINUTES} minutes. If you did not request this, you can ignore this email.`,
      html: `<p>Your password reset code is <b style="font-size:22px;letter-spacing:2px;">${resetCode}</b>.</p><p>This code expires in ${RESET_CODE_TTL_MINUTES} minutes.</p><p>If you did not request this, you can ignore this email.</p>`,
    });

    return { success: true, message: "Reset code sent." };
  } catch (error) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    if (error && error.code === "auth/user-not-found") {
      return { success: true, message: "If the email exists, a code was sent." };
    }

    console.error("requestPasswordResetCode failed", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send reset code. Please try again."
    );
  }
});

exports.confirmPasswordResetWithCode = functions.https.onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  const code = String(request.data?.code || "").trim();
  const newPassword = String(request.data?.newPassword || "").trim();

  if (!email || !code || !newPassword) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Email, code and new password are required."
    );
  }

  if (newPassword.length < 6) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Password must be at least 6 characters."
    );
  }

  const emailHash = hashText(email);
  const docRef = db.collection("password_reset_codes").doc(emailHash);
  const snap = await docRef.get();

  if (!snap.exists) {
    throw new functions.https.HttpsError("not-found", "Reset request not found.");
  }

  const data = snap.data() || {};
  const expiresAt = data.expiresAt;
  const attempts = Number(data.attempts || 0);
  const storedCodeHash = String(data.codeHash || "");
  const uid = String(data.uid || "");

  if (!expiresAt || typeof expiresAt.toMillis !== "function") {
    await docRef.delete();
    throw new functions.https.HttpsError("failed-precondition", "Reset code is invalid.");
  }

  if (admin.firestore.Timestamp.now().toMillis() > expiresAt.toMillis()) {
    await docRef.delete();
    throw new functions.https.HttpsError("deadline-exceeded", "Reset code has expired.");
  }

  if (attempts >= MAX_VERIFY_ATTEMPTS) {
    await docRef.delete();
    throw new functions.https.HttpsError(
      "permission-denied",
      "Too many incorrect attempts. Request a new code."
    );
  }

  const incomingHash = hashText(code);
  if (incomingHash !== storedCodeHash) {
    await docRef.update({ attempts: attempts + 1, lastAttemptAt: admin.firestore.Timestamp.now() });
    throw new functions.https.HttpsError("permission-denied", "Invalid reset code.");
  }

  if (!uid) {
    await docRef.delete();
    throw new functions.https.HttpsError("failed-precondition", "Reset request is malformed.");
  }

  await admin.auth().updateUser(uid, { password: newPassword });
  await admin.auth().revokeRefreshTokens(uid);
  await docRef.delete();

  return { success: true, message: "Password updated successfully." };
});
