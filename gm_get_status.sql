drop function gm_get_status();
create or replace function gm_get_status()
  returns table (schema_name text, object_name text, grantee text, grants _text)
as $$
  select nspname::text schema_name, (c.oid::regclass)::text object_name, u.grantee::text,
  array_agg(distinct case
    when u.privilege_type='SELECT' then 'r'
    when u.privilege_type='UPDATE' then 'w'
    when u.privilege_type='USAGE' then 'U'
    when u.privilege_type='DELETE' then 'd'
    when u.privilege_type='INSERT' then 'a'
    when u.privilege_type='REFERENCES' then 'x'
    when u.privilege_type='TRIGGER' then 't'
    when u.privilege_type='TRUNCATE' then 'D'
    else u.privilege_type end) grants
  from
  pg_class c,
  lateral (
    select
      u.usename as grantee, privilege_type
    from
      aclexplode( c.relacl ) as x
      join pg_user u on x.grantee = u.usesysid
  ) u,
  pg_namespace n
  where c.relnamespace = n.oid
  and relkind in ('r', 'S')
  and relacl is not null
  and nspname not like 'pg_%'
  and nspname != 'information_schema'
  group by nspname, c.oid, u.grantee;
$$ language sql immutable;

-- select * from gm_get_status();
