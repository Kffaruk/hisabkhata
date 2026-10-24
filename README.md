# হিসাব খাতা

অফলাইনে চলা কাস্টমার/সাপ্লায়ার হিসাব খাতা (Flutter)। অনলাইনে থাকলে Supabase-এ অটো ব্যাকআপ।

## কীভাবে কাজ করে
- সব এন্ট্রি আগে ফোনের SQLite-এ জমা হয় (ইন্টারনেট লাগে না)।
- অফলাইনে করা এন্ট্রিতে "সিঙ্ক বাকি" (dirty) চিহ্ন থাকে। নেট এলে অটো ক্লাউডে যায়।
- একই এন্ট্রি দুই ডিভাইসে বদলালে যেটার সময় নতুন সেটা জেতে।
- মুছে ফেলাও সিঙ্ক হয় (soft delete)।

## APK বানানো (GitHub দিয়ে)
1. GitHub-এ নতুন repo বানিয়ে এই ফোল্ডারের সব ফাইল push করুন (`main` branch)।
2. repo > **Actions** ট্যাবে "Build APK" নিজে থেকে চলবে (বা "Run workflow" চাপুন)।
3. শেষ হলে run-এর নিচে **Artifacts > hisab-khata-apk** ডাউনলোড করে unzip করুন, ভেতরে `app-release.apk`।
4. ফোনে APK ইনস্টল করুন (Unknown sources চালু করতে হতে পারে)।

শুধু অফলাইন ব্যবহার করলে এখানেই শেষ।

## ক্লাউড ব্যাকআপ চালু করা (Supabase)
1. https://supabase.com এ ফ্রি প্রজেক্ট খুলুন।
2. **SQL Editor** এ `supabase.sql` এর পুরোটা পেস্ট করে Run করুন।
3. **Authentication > Providers > Email** এ "Confirm email" বন্ধ করুন (না হলে সাইন-আপের পর লগইন আটকাবে)।
4. **Project Settings > API** থেকে `Project URL` ও `anon public` key নিন।
5. GitHub repo > **Settings > Secrets and variables > Actions** এ দুটো secret দিন:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
6. Actions থেকে আবার বিল্ড চালান, নতুন APK ইনস্টল করুন।
7. অ্যাপে **মেনু > ক্লাউড ব্যাকআপ** এ নতুন একাউন্ট খুলে লগইন করুন।

একই ইমেইল দিয়ে অন্য ফোনে লগইন করলে সব ডেটা নেমে আসবে।
