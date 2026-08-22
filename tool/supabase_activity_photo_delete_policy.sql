-- Выполнить один раз в Supabase SQL Editor перед выпуском версии,
-- которая физически удаляет фотографии активностей из Storage.
-- Политика разрешает пользователю удалять файлы только из собственной папки.
BEGIN;

DROP POLICY IF EXISTS "Storage Delete Own Photos Policy" ON storage.objects;

CREATE POLICY "Storage Delete Own Photos Policy" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'activity_photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

COMMIT;
