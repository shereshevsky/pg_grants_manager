create or replace function gm_generate_current()
returns void as $$
declare
  c_users cursor for  select distinct usename
    from (select (aclexplode(relacl)).grantee from pg_class
      where relkind in ('S', 'r') and relacl is not null )z
    join pg_user on usesysid = z.grantee;
  c_grants cursor for select * from gm_get_status();
begin


execute 'drop table if exists grants_manager_old';
execute 'alter table if exists public.grants_manager rename to grants_manager_old';
execute 'create table public.grants_manager (schema_name text, object_name text, object_type text)';

insert into public.grants_manager (schema_name, object_type, object_name)
select nspname, case when relkind = 'r' then 'TABLE' when relkind = 'S' then 'SEQUENCE' else relkind::text end, (c.oid::regclass)::text
from pg_class c
join pg_namespace n
on c.relnamespace = n.oid
where relkind in ('r', 'S')
and relacl is not null
and nspname not like 'pg_%'
and nspname != 'information_schema';

for u in c_users
loop
  execute format ('alter table public.grants_manager add %s _text', u.usename);
end loop;
for g in c_grants
loop
--  raise notice 'update public.grants_manager set % = ''%'' where object_name = ''%''', g.grantee, g.grants, g.oid;
  execute format ('update public.grants_manager set %s = %L where object_name = %L ', g.grantee, g.grants, g.object_name);
end loop;
end;
$$ language plpgsql;

-- select gm_generate_current();