-- ========================================================
-- ASR App: Supabase PostgreSQL Schema & RLS Policies
-- Выполните этот скрипт в Supabase Dashboard -> SQL Editor
-- ========================================================

-- 1. Таблица профилей пользователей
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE,
    display_name TEXT NOT NULL DEFAULT 'ASR Member',
    avatar_url TEXT,
    mission_statement TEXT,
    is_pro BOOLEAN NOT NULL DEFAULT false,
    subscription_tier TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Добавляем колонку username и display_name, если таблица уже существовала
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'username') THEN
        ALTER TABLE public.user_profiles ADD COLUMN username TEXT UNIQUE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'display_name') THEN
        ALTER TABLE public.user_profiles ADD COLUMN display_name TEXT NOT NULL DEFAULT 'ASR Member';
    END IF;
END $$;


-- 2. Таблица записей активности (Focus Logs)
CREATE TABLE IF NOT EXISTS public.activity_entries (
    id BIGINT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category_key TEXT NOT NULL,
    started_at BIGINT NOT NULL,
    ended_at BIGINT NOT NULL,
    duration_seconds BIGINT NOT NULL,
    date_key TEXT NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    mood TEXT,
    obstacles TEXT[],
    next_experiment TEXT,
    note TEXT,
    photo_urls TEXT[],
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (id, user_id)
);


-- 3. Таблица целей
CREATE TABLE IF NOT EXISTS public.goals (
    id BIGINT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_key TEXT NOT NULL,
    activity_name TEXT,
    target_seconds BIGINT NOT NULL DEFAULT 0,
    period_type TEXT NOT NULL DEFAULT 'month',
    created_at BIGINT NOT NULL DEFAULT 0,
    is_archived BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (id, user_id)
);


-- 4. Таблица связей дружбы (Сообщество)
CREATE TABLE IF NOT EXISTS public.friendships (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE (user_id, friend_id)
);


-- 5. Таблица правил приватности (что я разрешаю видеть другу)
CREATE TABLE IF NOT EXISTS public.sharing_permissions (
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    scope TEXT NOT NULL DEFAULT 'none' CHECK (scope IN ('none', 'category', 'fullActivity')),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (owner_id, friend_id)
);


-- 6. Таблица текущего Live Focus статуса пользователей
CREATE TABLE IF NOT EXISTS public.live_presence (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    activity_name TEXT,
    category_key TEXT,
    started_at BIGINT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);


-- 7. Включение Row Level Security (RLS)
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sharing_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.live_presence ENABLE ROW LEVEL SECURITY;


-- 8. Политики RLS
-- Профили: каждый может читать публичные профили (для поиска друзей), но редактировать только свой
DROP POLICY IF EXISTS "User profiles read policy" ON public.user_profiles;
CREATE POLICY "User profiles read policy" ON public.user_profiles
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "User profiles modify policy" ON public.user_profiles;
CREATE POLICY "User profiles modify policy" ON public.user_profiles
    FOR ALL TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Записи и цели: строгая приватность (только владелец)
DROP POLICY IF EXISTS "Activity entries access policy" ON public.activity_entries;
CREATE POLICY "Activity entries access policy" ON public.activity_entries
    FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Goals access policy" ON public.goals;
CREATE POLICY "Goals access policy" ON public.goals
    FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Дружба: пользователь видит заявки, где он отправитель или получатель
DROP POLICY IF EXISTS "Friendships access policy" ON public.friendships;
CREATE POLICY "Friendships access policy" ON public.friendships
    FOR ALL TO authenticated 
    USING (auth.uid() = user_id OR auth.uid() = friend_id) 
    WITH CHECK (auth.uid() = user_id OR auth.uid() = friend_id);

-- Права доступа: владелец управляет правилами для друзей
DROP POLICY IF EXISTS "Sharing permissions access policy" ON public.sharing_permissions;
CREATE POLICY "Sharing permissions access policy" ON public.sharing_permissions
    FOR ALL TO authenticated 
    USING (auth.uid() = owner_id OR auth.uid() = friend_id) 
    WITH CHECK (auth.uid() = owner_id);

-- Live Presence: каждый может обновлять свой статус и читать статусы друзей
DROP POLICY IF EXISTS "Live presence access policy" ON public.live_presence;
CREATE POLICY "Live presence access policy" ON public.live_presence
    FOR ALL TO authenticated 
    USING (true)
    WITH CHECK (auth.uid() = user_id);


-- 9. Бакет хранилища для фото
INSERT INTO storage.buckets (id, name, public)
VALUES ('activity_photos', 'activity_photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Storage Insert Policy" ON storage.objects;
CREATE POLICY "Storage Insert Policy" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'activity_photos' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Storage Select Policy" ON storage.objects;
CREATE POLICY "Storage Select Policy" ON storage.objects
    FOR SELECT USING (bucket_id = 'activity_photos');


-- 10. Триггер автоматического создания профиля при регистрации в Supabase
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
    raw_name TEXT;
    derived_username TEXT;
BEGIN
    raw_name := COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1));
    derived_username := LOWER(REGEXP_REPLACE(split_part(NEW.email, '@', 1), '[^a-zA-Z0-9_]', '_', 'g')) || '_' || SUBSTRING(NEW.id::text, 1, 4);

    INSERT INTO public.user_profiles (id, username, display_name, avatar_url, is_pro, updated_at)
    VALUES (
        NEW.id,
        derived_username,
        raw_name,
        NEW.raw_user_meta_data->>'avatar_url',
        false,
        now()
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- 11. Функция полного удаления аккаунта (GDPR / Apple Review Compliant)
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void AS $$
DECLARE
    _user_id UUID := auth.uid();
BEGIN
    IF _user_id IS NULL THEN
        RAISE EXCEPTION 'Пользователь не авторизован';
    END IF;

    -- Удаление фото из Storage
    DELETE FROM storage.objects 
    WHERE bucket_id = 'activity_photos' 
      AND (storage.foldername(name))[1] = _user_id::text;

    -- Каскадное удаление данных
    DELETE FROM public.friendships WHERE user_id = _user_id OR friend_id = _user_id;
    DELETE FROM public.sharing_permissions WHERE owner_id = _user_id OR friend_id = _user_id;
    DELETE FROM public.live_presence WHERE user_id = _user_id;
    DELETE FROM public.activity_entries WHERE user_id = _user_id;
    DELETE FROM public.goals WHERE user_id = _user_id;
    DELETE FROM public.user_profiles WHERE id = _user_id;

    -- Удаление аккаунта из auth.users
    DELETE FROM auth.users WHERE id = _user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


