CREATE OR REPLACE FUNCTION pglogical.create_subscription(subscription_name name, provider_dsn text,
    replication_sets text[] = '{default,default_insert_only,ddl_sql}', synchronize_structure boolean = true,
    synchronize_data boolean = true, forward_origins text[] = '{all}')
RETURNS oid STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_create_subscription';

DO $$
BEGIN
	IF (SELECT count(1) FROM pglogical.node) > 0 THEN
		SELECT * FROM pglogical.create_replication_set('ddl_sql', true, false, false, false);
	END IF;
END; $$;

UPDATE pglogical.subscription SET sub_replication_sets = array_append(sub_replication_sets, 'ddl_sql');

WITH applys AS (
	SELECT sub_name FROM pglogical.subscription WHERE sub_enabled
),
disable AS (
	SELECT pglogical.alter_subscription_disable(sub_name, true) FROM applys
)
SELECT pglogical.alter_subscription_enable(sub_name, true) FROM applys;


CREATE FUNCTION pglogical.alter_node_add_interface(node_name name, interface_name name, dsn text)
RETURNS oid STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_node_add_interface';
CREATE FUNCTION pglogical.alter_node_drop_interface(node_name name, interface_name name)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_node_drop_interface';

CREATE FUNCTION pglogical.alter_subscription_interface(subscription_name name, interface_name name)
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_alter_subscription_interface';

DROP FUNCTION pglogical.replicate_ddl_command(command text);
CREATE OR REPLACE FUNCTION pglogical.replicate_ddl_command(command text, replication_sets text[] DEFAULT '{ddl_sql}')
RETURNS boolean STRICT VOLATILE LANGUAGE c AS 'MODULE_PATHNAME', 'pglogical_replicate_ddl_command';