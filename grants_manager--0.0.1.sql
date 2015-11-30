-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION base36" to load this file. \quit
create or replace function gm_array_sort(anyarray)
returns anyarray language sql
as $$
	select array(select unnest($1) order by 1)
$$;
create or replace function gm_translate(text)
returns text as
$$
select case
    when $1 = 'SELECT' then 'r'
    when $1 = 'UPDATE' then 'w'
    when $1 = 'USAGE' then 'U'
    when $1 = 'DELETE' then 'd'
    when $1 = 'INSERT' then 'a'
    when $1 = 'REFERENCES' then 'x'
    when $1 = 'TRIGGER' then 't'
    when $1 = 'TRUNCATE' then 'D'
    when $1 = 'r' then 'SELECT'
    when $1 = 'w' then 'UPDATE'
    when $1 = 'U' then 'USAGE'
    when $1 = 'd' then 'DELETE'
    when $1 = 'a' then 'INSERT'
    when $1 = 'x' then 'REFERENCES'
    when $1 = 't' then 'TRIGGER'
    when $1 = 'D' then 'TRUNCATE'
end;
$$ language sql immutable;


-- select gm_translate('SELECT');
-- drop function gm_get_status();
create or replace function gm_get_status()
  returns table (schema_name text, object_name text, grantee text, grants _text)
as $$
  with object_list as (
    select nspname schema_name, c.oid::regclass object_name, c.relacl, usename relowner
    from   pg_class c
    join pg_namespace n
    on c.relnamespace = n.oid
    join pg_user u on c.relowner = u.usesysid
    where relkind in ('r', 'S')
    and nspname not like 'pg_%'
    and nspname not like 'pg_%'
    and nspname != 'information_schema'
  ) --,
--   non_empty_grants as (
    select schema_name::text, object_name::text, u.grantee::text,
    array_agg(distinct gm_translate(u.privilege_type)) grants
    from
    object_list c,
    lateral (
      select  u.usename as grantee, privilege_type
      from aclexplode( c.relacl ) as x
      join pg_user u on x.grantee = u.usesysid
    ) u
    where relacl is not null
    group by c.schema_name, c.object_name, u.grantee
  union
  select schema_name::text, object_name::text, relowner::text, '{a,d,D,r,t,w,x}'::_text
  from object_list;
  -- with object_list as (
  --   select nspname schema_name, c.oid::regclass object_name, c.relacl
  --   from   pg_class c
  --   join pg_namespace n
  --   on c.relnamespace = n.oid
  --   where relkind in ('r', 'S')
  --   and nspname not like 'pg_%'
  --   and nspname not like 'pg_%'
  --   and nspname != 'information_schema'
  -- ),
  -- non_empty_grants as (
  --   select schema_name, object_name, u.grantee::text,
  --   array_agg(distinct gm_translate(u.privilege_type)) grants
  --   from
  --   object_list c,
  --   lateral (
  --     select  u.usename as grantee, privilege_type
  --     from aclexplode( c.relacl ) as x
  --     join pg_user u on x.grantee = u.usesysid
  --   ) u
  --   where relacl is not null
  --   group by c.schema_name, c.object_name, u.grantee
  -- )
  -- select schema_name::text, object_name::text, coalesce(grantee, 'none') grantee, coalesce(grants, '{}') grants
  -- from object_list o
  -- left join non_empty_grants n
  -- using (schema_name, object_name);
  -- select nspname::text schema_name, (c.oid::regclass)::text object_name, u.grantee::text,
  -- array_agg(distinct gm_translate(u.privilege_type)) grants
  -- from
  -- pg_class c,
  -- lateral (
  --   select
  --     u.usename as grantee, privilege_type
  --   from
  --     aclexplode( c.relacl ) as x
  --     join pg_user u on x.grantee = u.usesysid
  -- ) u,
  -- pg_namespace n
  -- where c.relnamespace = n.oid
  -- and relkind in ('r', 'S')
  -- and relacl is not null
  -- and nspname not like 'pg_%'
  -- and nspname != 'information_schema'
  -- group by nspname, c.oid, u.grantee;
$$ language sql immutable;

-- select * from gm_get_status();
create or replace function gm_generate_current()
returns void as $$
declare
  c_users cursor for
    select distinct usename
    from (select ((aclexplode(relacl)).grantee) from pg_class
      where relkind in ('S', 'r') and relacl is not null)z
    join pg_user
    on usesysid = z.grantee;
  c_grants cursor for select * from gm_get_status();
begin

  execute 'drop table if exists grants_manager_old';
  execute 'alter table if exists public.grants_manager rename to grants_manager_old';
  execute 'create table public.grants_manager (schema_name text, object_name text, object_type text, primary key(schema_name, object_name))';

  insert into public.grants_manager (schema_name, object_type, object_name)
  select nspname,
    case when relkind = 'r' then 'TABLE' when relkind = 'S' then 'SEQUENCE' else relkind::text end,
    (c.oid::regclass)::text
  from pg_class c
  join pg_namespace n
  on c.relnamespace = n.oid
  where relkind in ('r', 'S')
  -- and relacl is not null
  and nspname not like 'pg_%'
  and nspname != 'information_schema';

  for u in c_users
  loop
    execute format ('alter table public.grants_manager add %s _text not null default ''{}''', u.usename);
  end loop;
  for g in c_grants
  loop
    execute format ('update public.grants_manager set %s = %L where object_name = %L ', g.grantee, g.grants, g.object_name);
  end loop;
end;
$$ language plpgsql;

-- select gm_generate_current();
create or replace function gm_align_permissions(p_execute boolean default false)
returns void as $$
declare
  v_grants _text;
  v_grant text;
  c_grants cursor for select * from
    (select * from gm_get_status() ) partial_pop
    right join
    (select *
      from
      (select schema_name, object_name from public.grants_manager) objs,
      (select attname grantee
      from pg_attribute
      where attrelid = 'public.grants_manager'::regclass
      and attnum > 0
      and not attisdropped
      and attname not in ('schema_name', 'object_name', 'object_type')) usrs
    ) full_pop
    using (schema_name, object_name, grantee);
begin

for g in c_grants
loop
  execute format ('select %s from public.grants_manager where object_name = %L', g.grantee, g.object_name) into v_grants;
  if gm_array_sort(g.grants) <> gm_array_sort(v_grants) then
    if p_execute
      then
        execute format ('revoke all on %s from %s', g.object_name, g.grantee);
        foreach v_grant in array v_grants loop
          execute format ('grant %s on %s to %s', gm_translate(v_grant), g.object_name, g.grantee);
        end loop;
    -- report only
      else raise notice
        '% table permissions for user % not aligned. current - %, should be - %',
          g.object_name, g.grantee, coalesce(g.grants, '{}'), coalesce(v_grants, '{}');
    end if;
  end if;
  -- raise notice 'update public.grants_manager set % = ''%'' where object_name = ''%''', g.grantee, g.grants, g.object_name;
  -- execute format ('update public.grants_manager set %s = %L where object_name = %L', g.grantee, g.grants, g.object_name);
end loop;
end;
$$ language plpgsql;

-- select gm_align_permissions();