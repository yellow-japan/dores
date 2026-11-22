import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

/**
 * サーバー（サーバーコンポーネント／Route Handler）用の Supabase クライアント。
 * 環境変数から接続情報を読み、Cookie でログインセッションを引き継ぐ。
 * ここでも匿名キーを使う。service_role key を使う管理操作は別途サーバー専用で実装する。
 */
export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options),
            );
          } catch {
            // サーバーコンポーネントから呼ばれた場合は set できない（middleware 側で更新する）。無視してよい。
          }
        },
      },
    },
  );
}
