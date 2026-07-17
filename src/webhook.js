import crypto from "node:crypto";

export class WebhookReceiver {
  constructor({ secret = "", onPayment }) {
    this.secret = secret;
    this.onPayment = onPayment || (() => {});
  }

  verifySignature(rawBody, signature, algo = "sha256") {
    if (!this.secret) return true;
    const expected = crypto
      .createHmac(algo, this.secret)
      .update(rawBody, "utf8")
      .digest("hex");
    const provided = String(signature || "").replace(/^sha256=/, "");
    try {
      return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(provided));
    } catch {
      return false;
    }
  }

  handle(payload) {
    const ref =
      payload.ref ||
      payload.referenceId ||
      payload.reference_id ||
      payload.id ||
      (payload.data && (payload.data.ref || payload.data.referenceId));
    const status = String(payload.status || payload.state || "").toLowerCase();
    const paid = ["paid", "settlement", "success", "capture", "completed"].includes(status);

    if (ref && paid) {
      this.onPayment(ref, payload);
      return { ok: true, ref, action: "confirmed" };
    }
    return { ok: true, ref: ref || null, action: "ignored" };
  }
}
