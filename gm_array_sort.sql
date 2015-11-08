create or replace function gm_array_sort(anyarray)
returns anyarray language sql
as $$
	select array(select unnest($1) order by 1)
$$;
