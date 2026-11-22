# DO'reS — AI向けルール

このリポジトリは**株式会社イエローの新システム DO'reS**（Next.js + Supabase）。
現行のGAS版（`yellow-portal`）から移行していくための新基盤。

## 作業前に必ず読む（会社の方針・設計の正本）

`../yellow-brain` が正本。作業を始める前に次を読む：

- `../yellow-brain/home.md`（目次）
- `../yellow-brain/06_system/roadmap.md`（移行計画）
- `../yellow-brain/06_system/master-data-design.md`（共通マスター設計＝`status: approved` が正）

`yellow-brain` の `status: approved` の情報だけを会社の正式情報として扱う。承認を変えられるのは代表だけ。

## 開発ログ

作業の記録は **`../yellow-brain/06_system/dev-log/`** に書く（yellow-brain のルール＝フロントマター・末尾に `## 関連`・`home.md` へのリンクに従う）。

## 守ること（必須）

1. **秘密情報をGitHubに上げない。** Supabase の URL・anon key・service_role key・DBパスワード・アクセストークンは `.env.local` だけに置き、`.gitignore` に入れる。`.env.example` にはキー名だけ（値は空）。
2. **service_role key は画面側（ブラウザで動くコード）に絶対に入れない。** サーバー専用。
3. **秘密情報を代表にチャットで送らせない。** キー・パスワードの入力が必要なときは、代表が自分でターミナルや `.env.local` に入れる手順を案内する。
4. **表の変更は必ずマイグレーション（`supabase/migrations/*.sql`）で行う。** Supabase管理画面で直接いじらない（変更履歴をGitに残す）。
5. **本物の個人情報・店舗データを入れない。** テストデータは明らかに架空のもの（「テスト店舗A」「テスト太郎」など）。

## この環境のメモ

- Supabase CLI は **`npx supabase <...>`**（グローバル導入なし・Docker不要）。テストはローカルの `supabase start` ではなく **`dores-dev` で直接**行う（表を作る前に `supabase link` する）。
- コミット・Push は **GitHub Desktop** で代表が行う（git CLIの認証は未設定）。`login` / `link` のトークン・パスワード入力も代表自身が行う。

## 関連

- 会社の脳：`../yellow-brain/home.md`
- 現行システム：`../yellow-brain/06_system/current-system.md`
