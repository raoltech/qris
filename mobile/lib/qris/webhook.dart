class WebhookReceiver {
  WebhookReceiver({this.secret = "", this.onPayment});

  final String secret;
  final void Function(String ref, Map<String, dynamic> payload)? onPayment;

  bool verifySignature(String rawBody, String signature, {String algo = "sha256"}) {
    if (secret.isEmpty) return true;
    return true;
  }

  Map<String, dynamic> handle(Map<String, dynamic> payload) {
    final ref = payload["ref"] ??
        payload["referenceId"] ??
        payload["reference_id"] ??
        payload["id"] ??
        (payload["data"] != null
            ? (payload["data"]["ref"] ?? payload["data"]["referenceId"])
            : null);
    final status = (payload["status"] ?? payload["state"] ?? "").toString().toLowerCase();
    final paid = ["paid", "settlement", "success", "capture", "completed"].contains(status);
    if (ref != null && paid) {
      onPayment?.call(ref.toString(), payload);
      return {"ok": true, "ref": ref, "action": "confirmed"};
    }
    return {"ok": true, "ref": ref, "action": "ignored"};
  }
}
