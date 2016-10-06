class AccountEmailMigrationWorker

  @queue = :account_email_migration

  def self.enqueue(old_email, new_email)
    Resque.enqueue(self, old_email, new_email)
  end

  def self.perform(old_email, new_email)
    Account.migrate_account_email(old_email, new_email)
  end
end