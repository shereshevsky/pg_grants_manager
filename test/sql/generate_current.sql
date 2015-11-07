BEGIN;
create user test_user;
create table test_table (col1 int4);
grant select on test_table to test_user;
select gm_generate_current();
select postgres, test_user from public.grants_manager where (schema_name, object_name, object_type) = ('public', 'test_table', 'TABLE');
ROLLBACK;