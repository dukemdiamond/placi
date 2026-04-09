# Placi — iOS MVP Build Spec
> Hand this file to Claude Code as the primary reference. Keep it in the root of the Xcode project as `PLACI_MVP.md`.

---

## 1. What We're Building

Placi is a social sightseeing app. Users log places they've visited, rate them, and the app ranks those places against each other using a scoring algorithm to produce a personal "Placi Score" for each location. Friends can follow each other, view posts, like, comment, and share. The map is the hero feature.

**Closest reference:** Beli (food rating app) — but for sightseeing, landmarks, and any place you've been.

---

## 2. Tech Stack

| Layer | Choice | Notes |
|---|---|---|
| Language | Swift 5.9+ | Strict concurrency enabled |
| UI framework | SwiftUI | All new views in SwiftUI only, no UIKit unless absolutely necessary |
| Min deployment | iOS 17.0 | Required for new MapKit API |
| Maps | MapKit (native) | `Map` view with `Annotation`, `MapCameraPosition` — no third-party map libs |
| Place search | MKLocalSearch | Free, no API key needed for MVP; upgrade to Google Places API post-MVP if needed |
| Reverse geocode | CLGeocoder | Convert dropped-pin coordinates to address string |
| Backend | Supabase | Postgres database, Auth, Storage, Realtime |
| Supabase client | supabase-swift (v2) | Swift Package Manager |
| Image loading | SDWebImageSwiftUI | Async remote image loading |
| State management | `@Observable` macro + `@Environment` | iOS 17 native, no third-party state libs |
| Deep links / share | Universal Links + custom scheme `placi://` | |

---

## 3. Supabase Schema

Run this SQL in the Supabase SQL editor to create all tables before starting.

```sql
-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Users (mirrors Supabase auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique not null,
  display_name text not null,
  bio text,
  avatar_url text,
  created_at timestamptz default now()
);

-- Follows
create table public.follows (
  follower_id uuid references public.profiles(id) on delete cascade,
  following_id uuid references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (follower_id, following_id)
);

-- Canonical place records (one row per real-world place)
create table public.places (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  address text,
  latitude double precision not null,
  longitude double precision not null,
  category text,           -- e.g. "museum", "park", "landmark"
  mapkit_id text,          -- MKMapItem identifier if available
  created_at timestamptz default now()
);

-- Posts (a user's logged visit to a place)
create table public.posts (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  place_id uuid references public.places(id) on delete cascade not null,
  title text not null,
  notes text,
  base_rating integer not null check (base_rating between 1 and 10),
  placi_score numeric(5,2) default 0,   -- 0–100, computed by algorithm
  rank_position integer,                 -- user's personal rank among their posts
  is_draft boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Post photos
create table public.post_photos (
  id uuid default uuid_generate_v4() primary key,
  post_id uuid references public.posts(id) on delete cascade not null,
  storage_path text not null,   -- Supabase Storage path
  display_order integer not null default 0
);

-- Likes
create table public.likes (
  user_id uuid references public.profiles(id) on delete cascade,
  post_id uuid references public.posts(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, post_id)
);

-- Comments
create table public.comments (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  post_id uuid references public.posts(id) on delete cascade not null,
  parent_id uuid references public.comments(id) on delete cascade,  -- null = top-level
  body text not null,
  created_at timestamptz default now()
);

-- Shares (re-posts another user's post to your own feed)
create table public.shares (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  original_post_id uuid references public.posts(id) on delete cascade not null,
  created_at timestamptz default now()
);

-- Custom lists
create table public.lists (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  name text not null,
  is_public boolean default true,
  created_at timestamptz default now()
);

create table public.list_items (
  list_id uuid references public.lists(id) on delete cascade,
  post_id uuid references public.posts(id) on delete cascade,
  display_order integer not null default 0,
  primary key (list_id, post_id)
);

-- Notifications
create table public.notifications (
  id uuid default uuid_generate_v4() primary key,
  recipient_id uuid references public.profiles(id) on delete cascade not null,
  actor_id uuid references public.profiles(id) on delete cascade not null,
  type text not null,  -- 'like' | 'comment' | 'follow' | 'share'
  post_id uuid references public.posts(id) on delete set null,
  is_read boolean default false,
  created_at timestamptz default now()
);
```

---

## 4. Xcode Project Structure

```
Placi/
├── PlacIApp.swift
├── PLACI_MVP.md
├── Core/
│   ├── SupabaseClient.swift
│   ├── AuthManager.swift
│   └── AppEnvironment.swift
├── Models/
│   ├── Profile.swift
│   ├── Post.swift
│   ├── Place.swift
│   ├── Comment.swift
│   ├── Like.swift
│   ├── Follow.swift
│   ├── PlacList.swift
│   └── Notification.swift
├── Features/
│   ├── Auth/
│   ├── Feed/
│   ├── Map/
│   ├── AddPlace/
│   ├── Search/
│   ├── Profile/
│   ├── Post/
│   └── Leaderboard/
├── Components/
└── Services/
```

---

## 5. Navigation

TabView with 5 tabs: Home, Map, Add (+), Search, Profile.

---

## 12. Suggested Build Order

1. Project scaffolding
2. Auth + Onboarding
3. Models + Services
4. Add Place flow
5. Map tab
6. Ranking
7. Feed tab
8. Post detail
9. Profile
10. Search tab
11. Leaderboard
12. Notifications
13. Polish
