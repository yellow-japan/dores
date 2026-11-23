# DO'reS

株式会社イエローの**新システム DO'reS**。現行のGAS版ポータル（`yellow-portal`）から移行していくための土台。

- フロント／サーバー：**Next.js（App Router・TypeScript）**
- データベース・認証：**Supabase**（プロジェクト `dores-dev`）
- 会社の方針・設計の正本：**`../yellow-brain`**（`06_system/master-data-design.md` など）

## 必要なもの

- Node.js 20 以上（確認済み：v24）
- Supabase CLI は **`npx supabase <...>`** で使う（グローバル導入不要・Docker不要）

## ローカルでの起動

```bash
# 1. 依存をインストール
npm install

# 2. 環境変数を用意（.env.example をコピーして値を入れる）
cp .env.example .env.local
#   → .env.local に Supabase の URL と anon key を入れる（下記参照）

# 3. 開発サーバー起動
npm run dev
#   → http://localhost:3000 を開くと「DO'reS」と表示される
```

## 環境変数（`.env.local` に設定）

値は **Supabaseダッシュボード → `dores-dev` → Project Settings → API** で取得する。
`.env.local` は Git に上がらない（`.gitignore` 済み）。**このファイルに秘密を直接書かない。**

| 変数名 | 用途 | 置き場所 |
|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | プロジェクトのURL | ブラウザ・サーバー両方（公開可） |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | 匿名キー | ブラウザ・サーバー両方（公開可） |
| `SUPABASE_SERVICE_ROLE_KEY` | 管理操作用 | **サーバー専用。画面側に絶対入れない** |

## Supabase クライアント

- ブラウザ用：`lib/supabase/client.ts`（`createClient()`・anon key）
- サーバー用：`lib/supabase/server.ts`（`createClient()`・Cookieでセッション引き継ぎ）

## データベースの変更ルール

表・RLSの変更は**必ずマイグレーション（`supabase/migrations/*.sql`）**で行う。Supabase管理画面で直接いじらない（変更履歴をGitに残すため）。本物の個人情報・店舗データは入れない（テストは明らかに架空のデータで行う）。

## 背景イラストの差し替え方（設定から変更）

背景はコードに埋め込まず、設定（`app_settings`）から読みます。差し替え手順：

1. Supabaseダッシュボード → **Storage** → バケット **`branding`** を開く → 新しい画像をアップロード（例 `bg-2.jpg`）。
2. SQL Editor で、その画像のパスを設定に入れる：
   ```sql
   update app_settings set background_image_path = 'bg-2.jpg' where id = 1;
   ```
3. 画面を再読み込みすると、新しい背景になります（ログインした人だけが見られる署名付きURLで表示）。
4. 同梱の初期画像に戻すには `background_image_path` を空にする：
   ```sql
   update app_settings set background_image_path = null where id = 1;
   ```

会社名を変えるときも SQL Editor で：
```sql
update app_settings set company_display_name = '新しい会社名' where id = 1;
```

## コミット／Push

コミットとPushは **GitHub Desktop** で行う（このMacはgit CLIの認証が未設定のため）。
