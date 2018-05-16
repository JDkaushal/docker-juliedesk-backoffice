## EVENT TRIGGER used to replicate DDL statement made to 'message_classifications' and 'julie_actions' respectively to 'automated_message_classifications' and 'automated_julie_actions'

## Need to be executed by hand with a superuser
class CreateDdlReplicationTriggerForAlterTables < ActiveRecord::Migration
  def self.up
    # execute %q{
    #   CREATE OR REPLACE FUNCTION replicate_ddl() RETURNS event_trigger AS $$
    #   DECLARE
    #     r RECORD;
    #     query VARCHAR(500);
    #   BEGIN
    #       FOR r IN SELECT * FROM pg_event_trigger_ddl_commands() LOOP
    #         IF ( r.objid::regclass::text = 'message_classifications' )
    #           THEN
    #             query := REPLACE(current_query(), 'message_classifications', 'automated_message_classifications');
    #             EXECUTE query;
    #         END IF;
    #
    #         IF ( r.objid::regclass::text = 'julie_actions' )
    #           THEN
    #             query := REPLACE(current_query(), 'julie_actions', 'automated_julie_actions');
    #             EXECUTE query;
    #         END IF;
    #       END LOOP;
    #   END;
    #   $$
    #   LANGUAGE plpgsql;
    # }
    #
    # execute %{
    #   CREATE EVENT TRIGGER ddl_replication
    #   ON ddl_command_end WHEN TAG IN ('ALTER TABLE')
    #   EXECUTE PROCEDURE replicate_ddl();
    # }
  end

  def self.down
    # execute %{DROP EVENT TRIGGER IF EXISTS ddl_replication;}
    # execute %{DROP FUNCTION IF EXISTS replicate_ddl();}
  end
end
