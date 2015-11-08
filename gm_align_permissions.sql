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