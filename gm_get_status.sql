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
