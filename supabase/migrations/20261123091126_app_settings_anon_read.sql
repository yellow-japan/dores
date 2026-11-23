-- ログイン画面（未ログイン=anon）でも会社名を表示できるように、
-- app_settings を anon にも読み取り許可する。
-- app_settings は「会社表示名」と「背景画像の場所」だけで機微情報は無い。
-- 書き込みは引き続き MAS のみ（変更なし）。
create policy app_settings_sel_anon on app_settings for select to anon using (true);
