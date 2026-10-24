-- Supabase > SQL Editor-এ পুরোটা পেস্ট করে একবার Run করুন।

create table if not exists public.parties (
  id          text primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  type        text not null check (type in ('customer','supplier')),
  name        text not null,
  phone       text not null default '',
  created_at  bigint not null,
  updated_at  bigint not null,
  deleted     boolean not null default false,
  server_ts   bigint not null default 0
);

create table if not exists public.txns (
  id          text primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  party_id    text not null,
  gave        numeric not null default 0,
  got         numeric not null default 0,
  note        text not null default '',
  date        bigint not null,
  created_at  bigint not null,
  updated_at  bigint not null,
  deleted     boolean not null default false,
  server_ts   bigint not null default 0
);

create index if not exists parties_user_ts on public.parties (user_id, server_ts);
create index if not exists txns_user_ts on public.txns (user_id, server_ts);

-- server_ts সার্ভার নিজে বসায় (অ্যাপ কোন রো কখন বদলেছে তা এ থেকে জানে)।
-- কোনো পুরোনো ডিভাইস থেকে পুরোনো updated_at এলে আপডেট বাদ দেওয়া হয় (সবচেয়ে নতুন পরিবর্তন জেতে)।
create or replace function public.hk_before_write() returns trigger
language plpgsql as $$
begin
  if tg_op = 'UPDATE' and new.updated_at < old.updated_at then
    return null;
  end if;
  new.server_ts := (extract(epoch from clock_timestamp()) * 1000)::bigint;
  return new;
end $$;

drop trigger if exists parties_hk on public.parties;
create trigger parties_hk before insert or update on public.parties
  for each row execute function public.hk_before_write();

drop trigger if exists txns_hk on public.txns;
create trigger txns_hk before insert or update on public.txns
  for each row execute function public.hk_before_write();

-- প্রত্যেক ইউজার শুধু নিজের ডেটা দেখতে ও বদলাতে পারবে।
alter table public.parties enable row level security;
alter table public.txns enable row level security;

drop policy if exists parties_own on public.parties;
create policy parties_own on public.parties
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists txns_own on public.txns;
create policy txns_own on public.txns
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
