import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

// ログインしていない人を /login に戻す。ログイン済みが /login を開いたら / に送る。
// /login・/preview・/auth は未ログインでも見られる（公開）。
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

  if (!user && !isPublic) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    return NextResponse.redirect(url);
  }

  // URLの分け方（追加7）：
  //   dores-home.vercel.app（ドメイン前のDO'reS運営）→ ルートは運営ホーム /platform
  //   それ以外（yellow-dores.vercel.app など）→ ルートは会社アプリ（従来どおり）
  const host = request.headers.get("host") ?? "";
  const isPlatformHost = host.startsWith("dores-home");

  if (user && path === "/login") {
    const url = request.nextUrl.clone();
    url.pathname = isPlatformHost ? "/platform" : "/";
    return NextResponse.redirect(url);
  }
  if (isPlatformHost && path === "/") {
    const url = request.nextUrl.clone();
    url.pathname = "/platform";
    return NextResponse.rewrite(url);
  }

  return response;
}
