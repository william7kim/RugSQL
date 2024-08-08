-- PersianRug Schema
-- Original version: John Shepherd (Sept 2021)
-- Current version: Armin Chitizadeh (June 2024)
--
-- To keep the schema a little shorter, I have ignored my usual
-- convention of putting foreign key definitions at the end of
-- the table definition.
--
-- Some general naming principles:
--   max 10 chars in field names
--   all entity tables are named using plural nouns
--   for tables with unique numeric identifier, always call the field "id"
--   for cases where there's a long name and a short name for something,
--      use "name" for the short version of the name (typically for display),
--      and use "longname" for the complete version of the name (which might
--      typically be used in lists of items)
--   for foreign keys referring to an "id" field in the foreign relation,
--      use the singular-noun name of the relation as the field name
--      OR use the name of the relationship being represented
--
-- Null values:
--  for each relation, a collection of fields is identified as being
--    compulsory (i.e. without them the data isn't really usable) and
--    they are all defined as NOT NULL
--  reminder: all of the primary keys (e.g. "id") are non-NULL
--  note also that fields that are allowed to be NULL will need to be
--    handled specially whenever they are displayed e.g. in a web-based
--    interface to this schema
--

-- Types/Domains

create type MaterialType as enum ('pile', 'warp', 'kilim', 'weft');
create type RugStopType  as enum ('leather', 'faux', 'bonded', 'plastic');

create domain YearValue        as integer check (value between 1000 and 2100);
create domain SquareFeet       as integer check (value > 0);
create domain URLvalue         as text    check (value like '%.%');            -- weak check
create domain KnotLenghValue   as real    check (value between 0.0 and 100.0);
create domain KnotPerFootValue as integer check (value between 0 and 200);

-- Tables

create table Locations (
    id             integer,        -- would normally use serial
    province       text not null,  -- must at least know province
    county         text,           -- geographic region of a country used for administrative or other purposes in some nations
    district       text,           -- area consisted of several cities and villages
    rural_district text,           -- area consisted of mainly villages
    city           text,           -- larger factories are located at cities
    village        text,           -- family small business are mostly located from villages
    primary key (id)
);

create table Styles (
    id                  integer,                 -- would normally use serial
    name                text not null unique,    -- name of style (e.g. Nain, Gol Henai)
    min_knot_length     knotLenghValue not null,
    max_knot_length     knotLenghValue not null,
    primary key (id),
    constraint minmax check (min_knot_length <= max_knot_length)
);

create table Materials (
    id          integer,               -- would normally use serial
    itype       MaterialType not null,
    name        text not null,
    primary key (id)
);

create table Factories (
    id          integer,              -- would normally use serial
    name        text not null unique,
    founded     YearValue,
    website     URLvalue,
    located_in  integer not null references Locations(id),
    primary key (id)
);

create table Rugs (
    id              integer,                                -- would normally use serial
    name            text not null,
    year_crafted    YearValue,
    style           integer not null references Styles(id),
    knot_leng       KnotLenghValue not null,
    knot_per_foot   KnotPerFootValue,
    rug_stop        RugStopType,
    size            SquareFeet,
    notes           text,
    rating          integer check (rating between 0 and 10),
    primary key (id)
);

create table Contains (
    rug      integer references Rugs(id),
    material integer references Materials(id),
    primary key (rug,material)
);

create table Crafted_by (
    rug     integer references Rugs(id),
    factory integer references Factories(id),
    primary key (rug,factory)
);