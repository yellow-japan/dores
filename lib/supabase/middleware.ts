import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { resolveHost } from "@/lib/host";

// 認証チェック＋URL(ホスト名)で画面を分ける（追加7・データ化）。
//   ・未登録URL → 入口を出さない（/login で「登録されていません」を表示）
//   ・dores-home のルート → 運営ホーム /platform（ただし運営が会社に入っている間は会社アプリ）
export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const path = request.nextUrl.pathname;
  const isPublic =
    path === "/login" || path.startsWith("/preview") || path.startsWith("/auth");

  const info = await resolveHost(supabase, request.headers.get("host"));

  // 未登録URL：入口を出さない（公開パスは除く）。/login では UnknownHost を表示。
  if (info.kind === "unknown") {
    if (isPublic) return response;
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    return NextResponse.rewrite(url);
  }

  if (!user && !isPublic) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    return NextResponse.redirect(url);
  }

  const isPlatformHost = info.kind === "platform";

  if (user && path === "/login") {
    const url = request.nextUrl.clone();
    url.pathname = isPlatformHost ? "/platform" : "/";
    return NextResponse.redirect(url);
  }

  // dores-home のルートは運営ホームへ。運営が会社に入っている間（dores_enter）は会社アプリを出す。
  if (isPlatformHost && path === "/") {
    const entering = request.cookies.get("dores_enter");
    if (!entering) {
      const url = request.nextUrl.clone();
      url.pathname = "/platform";
      return NextResponse.rewrite(url);
    }
  }

  return response;
}
