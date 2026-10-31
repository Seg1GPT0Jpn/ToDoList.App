// AI プロバイダーの共通インターフェース。
// 新しいプロバイダー（OpenAI / Gemini など）は、このインターフェースを実装した
// ファイルを providers/ に 1 つ追加し、index.ts の PROVIDERS に登録するだけでよい。

export interface CompletionRequest {
  /** システムプロンプト（役割・出力形式の指示） */
  system: string;
  /** ユーザーメッセージ（作業内容と入力データ） */
  user: string;
  /** 出力トークンの上限 */
  maxTokens: number;
}

export interface CompletionUsage {
  inputTokens: number;
  outputTokens: number;
}

export interface CompletionResult {
  /** モデルの出力テキスト（JSON を期待） */
  text: string;
  /** 実際に応答したモデル名 */
  model: string;
  usage: CompletionUsage;
  /** 打ち切り・拒否などの終了理由（プロバイダー固有の値をそのまま） */
  stopReason: string | null;
}

export interface AIProvider {
  /** プロバイダー名（ai_jobs にも記録） */
  readonly name: string;
  /** 必要な秘密情報がそろっているか */
  isConfigured(): boolean;
  complete(req: CompletionRequest): Promise<CompletionResult>;
}

/** プロバイダー呼び出しの失敗（ネットワーク・HTTP エラー・拒否など） */
export class ProviderError extends Error {
  readonly status: number | null;
  constructor(message: string, status: number | null = null) {
    super(message);
    this.name = "ProviderError";
    this.status = status;
  }
}
