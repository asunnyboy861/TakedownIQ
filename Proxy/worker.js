// TakedownIQ GLM Proxy — Cloudflare Worker
// Hides GLM_API_KEY, soft rate-limits per device (KV), validates payload size.
// GLM behavior rules (verified 2026-09-17): glm-5.3-flash always thinks (cannot disable),
// supports thinking:{level}, max_tokens must be generous (>=8192 for vision), response_format json_object.

const GLM_ENDPOINT = "https://api.z.ai/api/paas/v4/chat/completions";
const DAILY_LIMIT = 25;
const MAX_BODY_BYTES = 8_000_000;
const MAX_FRAMES = 6;

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }
    if (request.method !== "POST") {
      return json({ error: "method_not_allowed" }, 405);
    }

    const fingerprint = request.headers.get("X-Device-ID") || request.headers.get("CF-Connecting-IP") || "unknown";
    const day = new Date().toISOString().slice(0, 10);
    const quotaKey = `q:${day}:${fingerprint}`;
    const count = Number((await env.KV.get(quotaKey)) || 0);
    if (count >= DAILY_LIMIT) {
      return json({ error: "daily_limit" }, 429);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "bad_json" }, 400);
    }
    if (JSON.stringify(body).length > MAX_BODY_BYTES) {
      return json({ error: "too_large" }, 413);
    }
    const messages = body?.payload?.messages;
    if (!Array.isArray(messages) || messages.length === 0) {
      return json({ error: "bad_request" }, 400);
    }
    const imageCount = JSON.stringify(messages).split("image_url").length - 1;
    if (imageCount > MAX_FRAMES) {
      return json({ error: "bad_frames" }, 400);
    }

    await env.KV.put(quotaKey, String(count + 1), { expirationTtl: 86400 });

    const glmPayload = {
      model: body.payload.model || "glm-5.3-flash",
      messages,
      thinking: body.payload.thinking || { level: "low" },
      temperature: body.payload.temperature ?? 0.2,
      max_tokens: body.payload.max_tokens ?? 8192,
      ...(body.payload.response_format ? { response_format: body.payload.response_format } : {})
    };

    const upstream = await fetch(GLM_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${env.GLM_API_KEY}`
      },
      body: JSON.stringify(glmPayload)
    });

    return new Response(upstream.body, {
      status: upstream.status,
      headers: {
        "Content-Type": upstream.headers.get("Content-Type") ?? "application/json",
        "Cache-Control": "no-store",
        ...corsHeaders()
      }
    });
  }
};

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-Device-ID"
  };
}

function json(obj, status) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders() }
  });
}
