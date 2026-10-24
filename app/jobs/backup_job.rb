class BackupJob < ApplicationJob
  def perform
    Backup.new.run
  end
end
