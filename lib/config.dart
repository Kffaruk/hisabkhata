// ক্লাউড ব্যাকআপ (Supabase) চালু করতে দুটো উপায়ের যেকোনো একটা:
//  ১) নিচের defaultValue-তে নিজের Project URL ও anon key বসান, অথবা
//  ২) GitHub repo > Settings > Secrets > Actions-এ SUPABASE_URL ও SUPABASE_ANON_KEY দিন
//     (workflow নিজে থেকে বিল্ডের সময় ব্যবহার করবে)।
// anon key গোপন নয়; ডেটার নিরাপত্তা Row Level Security দেয় (supabase.sql দেখুন)।
// খালি থাকলে অ্যাপ শুধু ফোনে অফলাইনে চলবে।

const String kSupabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const String kSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

bool get cloudConfigured => kSupabaseUrl.isNotEmpty && kSupabaseAnonKey.isNotEmpty;
