require "test_helper"

class BackupTest < ActiveSupport::TestCase
  setup do
    @dumps = Pathname(Dir.mktmpdir)
    @storage = Pathname(Dir.mktmpdir)
    @backup = Backup.new(storage_box: "backups@box.example", ssh_key: "private key", dumps: @dumps, storage: @storage)
    @commands = []
  end

  teardown do
    FileUtils.remove_entry(@dumps)
    FileUtils.remove_entry(@storage)
  end

  test "dumps the database, then sends the dumps and photos to the storage box and prunes old snapshots" do
    run_backup

    assert_equal %w[ pg_dump cat backup forget ], steps
    _, backup = @commands.third
    assert_includes backup, @dumps.to_s
    assert_includes backup, @storage.to_s
  end

  test "sets up the storage box repository the first time" do
    run_backup(repository_exists: false)

    assert_equal %w[ pg_dump cat init backup forget ], steps
  end

  test "keeps only the most recent dumps on the server" do
    dumps = 9.times.map { |day| @dumps.join("gifting_production-202610#{10 + day}T030000Z.dump").tap { FileUtils.touch(it) } }

    run_backup

    assert_equal dumps.last(Backup::LOCAL_DUMPS_KEPT), @dumps.glob("*.dump").sort
  end

  test "hands the key to ssh in a file that's gone afterwards" do
    run_backup

    _, arguments = @commands.second
    key_file = arguments.second[/-i (\S+)/, 1]
    assert_not File.exist?(key_file)
  end

  private
    def run_backup(repository_exists: true)
      commands = @commands
      @backup.define_singleton_method(:system) do |_env, program, *arguments, **_options|
        commands << [ program, arguments ]
        program != "restic" || arguments.third != "cat" || repository_exists
      end

      @backup.run
    end

    def steps
      @commands.map { |program, arguments| program == "restic" ? arguments.third : program }
    end
end
