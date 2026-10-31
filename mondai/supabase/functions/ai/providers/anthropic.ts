// Anthropic（Claude）プロバイダー。公式 TypeScript SDK を使う（Deno の npm: 指定子で読み込む）
import Anthropic from "npm:@anthropic-ai/sdk@0.133.0";
import {
  type AIProvider,
  type CompletionRequest,
  type CompletionResult,
  ProviderError,
} from "./types.ts";

const DEFAULT_MODEL = "claude-opus-5-5";
const EFFORTS = ["low", "medium", "high", "xhigh", "max"] as const;
type Effort = typeof EFFORTS[number];

export class AnthropicProvider implements AIProvider {
  readonly name = "anthropic";
  private readonly apiKey: string;
  private readonly model: string;
  private readonly effort: Effort;
  private readonly fallbacks: boolean;
  private client: Anthropic | null = null;

  constructor(env: { get(key: string): string | undefined }) {
    this.apiKey = env.get("ANTHROPIC_API_KEY") ?? "";
    this.model = env.get("AI_MODEL") || DEFAULT_MODEL;
    // 思考の深さ。Claude Opus 5.5 の既定は medium なので、教材の正確さを優先して high を明示する
    const effort = (env.get("AI_EFFORT") || "high") as Effort;
    this.effort = EFFORTS.includes(effort) ? effort : "high";
    // 安全判定で拒否されたとき、サーバー側で適切なモデルに自動で切り替える（既定で有効、AI_FALLBACKS=off で無効）
    this.fallbacks = (env.get("AI_FALLBACKS") ?? "on") !== "off";
  }

  isConfigured(): boolean {
    return this.apiKey.length > 0;
  }

  private getClient(): Anthropic {
    if (!this.client) this.client = new Anthropic({ apiKey: this.apiKey });
    return this.client;
  }

  async complete(req: CompletionRequest): Promise<CompletionResult> {
    let message;
    try {
      // 出力が長くなることがあるので、ストリーミングで受け取り最後にまとめる（HTTP のタイムアウトを避ける）
      const stream = this.getClient().beta.messages.stream({
        model: this.model,
        max_tokens: req.maxTokens,
        system: req.system,
        messages: [{ role: "user", content: req.user }],
        output_config: { effort: this.effort },
        ...(this.fallbacks ? { betas: ["server-side-fallback-2026-07-01"], fallbacks: "default" as const } : {}),
      });
      message = await stream.finalMessage();
    } catch (e) {
      if (e instanceof Anthropic.AuthenticationError) throw new ProviderError("Anthropic の API キーが正しくありません", 401);
      if (e instanceof Anthropic.RateLimitError) throw new ProviderError("AI の利用が混み合っています。少し待ってからやり直してください", 429);
      if (e instanceof Anthropic.BadRequestError) throw new ProviderError(`AI への依頼の形が正しくありません: ${e.message}`, 400);
      if (e instanceof Anthropic.APIError) throw new ProviderError(`Anthropic API エラー: ${e.message}`, e.status ?? null);
      throw new ProviderError(`Anthropic API に接続できません: ${(e as Error).message}`);
    }

    // 内容を読む前に、拒否（安全上の理由）でないか確かめる
    if (message.stop_reason === "refusal") {
      throw new ProviderError("AI が依頼を処理できませんでした（安全上の理由）", 200);
    }

    // 思考ブロックなどを除き、テキストブロックだけをつなげる
    let text = "";
    for (const block of message.content) {
      if (block.type === "text") text += block.text;
    }

    return {
      text,
      model: message.model ?? this.model,
      usage: {
        inputTokens: message.usage?.input_tokens ?? 0,
        outputTokens: message.usage?.output_tokens ?? 0,
      },
      stopReason: message.stop_reason ?? null,
    };
  }
}
