-- 001_schema.sql — notchpets backend tables + RLS

-- Pairs
create table pairs (
  id         uuid primary key default gen_random_uuid(),
  user_a     uuid not null references auth.users(id),
  user_b     uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

alter table pairs enable row level security;

create policy "Users can read own pair"
  on pairs for select
  using (auth.uid() = user_a or auth.uid() = user_b);

create policy "Users can insert pair"
  on pairs for insert
  with check (auth.uid() = user_a or auth.uid() = user_b);

-- Invites
create table invites (
  id         uuid primary key default gen_random_uuid(),
  code       text not null unique,
  creator_id uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  accepted   boolean not null default false
);

alter table invites enable row level security;

create policy "Users can read own invites"
  on invites for select
  using (auth.uid() = creator_id);

create policy "Users can create invites"
  on invites for insert
  with check (auth.uid() = creator_id);

create policy "Anyone authenticated can read invite by code"
  on invites for select
  using (auth.uid() is not null);

create policy "Anyone authenticated can accept invite"
  on invites for update
  using (auth.uid() is not null)
  with check (accepted = true);

-- Pets
create table pets (
  id                   uuid primary key default gen_random_uuid(),
  pair_id              uuid not null references pairs(id),
  owner_id             uuid not null references auth.users(id),
  name                 text not null,
  species              text not null,
  background           text not null,
  hunger               int not null default 100,
  happiness            int not null default 100,
  last_fed             timestamptz,
  last_played          timestamptz,
  current_message      text,
  message_sent_at      timestamptz,
  current_track_name   text,
  current_track_artist text,
  updated_at           timestamptz not null default now()
);

alter table pets enable row level security;

-- Users can read pets in their pair
create policy "Users can read pets in own pair"
  on pets for select
  using (
    pair_id in (
      select id from pairs where user_a = auth.uid() or user_b = auth.uid()
    )
  );

-- Users can insert their own pet
create policy "Users can insert own pet"
  on pets for insert
  with check (
    auth.uid() = owner_id
    and pair_id in (
      select id from pairs where user_a = auth.uid() or user_b = auth.uid()
    )
  );

-- Users can update their own pet
create policy "Users can update own pet"
  on pets for update
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- Enable realtime for pets table
alter publication supabase_realtime add table pets;

-- RPC for pet stat decay (called by edge function cron)
create or replace function decay_pet_stats()
returns void as $$
begin
  update pets
  set hunger    = greatest(0, hunger - 5),
      happiness = greatest(0, happiness - 3);
end;
$$ language plpgsql security definer;

-- Auto-update updated_at
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger pets_updated_at
  before update on pets
  for each row execute function update_updated_at();
