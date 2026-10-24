class Backup
  LOCAL_DUMPS_KEPT = 7

  attr_reader :storage_box, :ssh_key, :dumps, :storage

  def initialize(storage_box: ENV.fetch("STORAGE_BOX"), ssh_key: Base64.decode64(ENV.fetch("STORAGE_BOX_SSH_KEY_BASE64")),
                 dumps: Rails.root.join("backups"), storage: Rails.root.join("storage"))
    @storage_box, @ssh_key, @dumps, @storage = storage_box, ssh_key, Pathname(dumps), Pathname(storage)
  end

  def run
    dump_database
    keep_recent_dumps

    restic "init" unless restic?("cat", "config")
    restic "backup", dumps.to_s, storage.to_s
    restic "forget", "--keep-daily", "7", "--keep-weekly", "4", "--keep-monthly", "12", "--prune"
  end

  def restic(*arguments)
    with_key_file { |key_file| system(restic_env, "restic", *restic_options(key_file), *arguments, exception: true) }
  end

  private
    def restic?(*arguments)
      with_key_file { |key_file| system(restic_env, "restic", *restic_options(key_file), *arguments, out: File::NULL, err: File::NULL) }
    end

    def dump_database
      database = ActiveRecord::Base.connection_db_config.configuration_hash
      file = dumps.join("#{database.fetch(:database)}-#{Time.current.utc.strftime("%Y%m%dT%H%M%SZ")}.dump")

      system({ "PGPASSWORD" => database[:password].to_s },
        "pg_dump", "--format=custom", "--host=#{database[:host]}", "--username=#{database[:username]}", "--file=#{file}", database.fetch(:database),
        exception: true)
    end

    def keep_recent_dumps
      dumps.glob("*.dump").sort.reverse.drop(LOCAL_DUMPS_KEPT).each(&:delete)
    end

    def with_key_file
      Tempfile.create("storage-box-key") do |file|
        file.write(ssh_key.end_with?("\n") ? ssh_key : "#{ssh_key}\n")
        file.close
        yield file.path
      end
    end

    def restic_env
      { "RESTIC_REPOSITORY" => "sftp:#{storage_box}:restic" }
    end

    def restic_options(key_file)
      [ "--option", "sftp.command=ssh -p 23 -i #{key_file} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new " \
        "-o UserKnownHostsFile=#{dumps.join(".known_hosts")} #{storage_box} -s sftp" ]
    end
end
