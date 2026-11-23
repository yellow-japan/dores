import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* ログイン必須のアプリ（各ページは毎回サーバーで描画）。実験的なプリレンダー機能は使わない。 */
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
