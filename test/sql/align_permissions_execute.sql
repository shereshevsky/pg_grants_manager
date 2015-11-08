begin;

create user test_user;

create table test_table_n (col1 int4);

create table test_table_r (col1 int4);

grant select on test_table_r to test_user;

select gm_generate_current();

select object_name, postgres, test_user from public.grants_manager
where
  (schema_name, object_type) = ('public', 'TABLE')
  and object_name in ('test_table_n', 'test_table_r')
;

update public.grants_manager set test_user = '{r, w, D}' where object_name = 'test_table_n';
update public.grants_manager set test_user = '{}' where object_name = 'test_table_r';

select object_name, postgres, test_user from public.grants_manager
where
  (schema_name, object_type) = ('public', 'TABLE')
  and object_name in ('test_table_n', 'test_table_r')
;

select gm_align_permissions(true);

select gm_align_permissions(false);

select gm_generate_current();

select object_name, postgres, test_user from public.grants_manager
where
  (schema_name, object_type) = ('public', 'TABLE')
  and object_name in ('test_table_n', 'test_table_r')
;

rollback;