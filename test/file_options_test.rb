require 'test_helper'

class FileOptionsTest < MiniTest::Test
  ZIPPATH = ::File.join(Dir.tmpdir, 'options.zip').freeze
  TXTPATH = ::File.expand_path(::File.join('data', 'file1.txt'), __dir__).freeze
  TXTPATH_600 = ::File.join(Dir.tmpdir, 'file1.600.txt').freeze
  TXTPATH_755 = ::File.join(Dir.tmpdir, 'file1.755.txt').freeze
  EXTPATH_1 = ::File.join(Dir.tmpdir, 'extracted_1.txt').freeze
  EXTPATH_2 = ::File.join(Dir.tmpdir, 'extracted_2.txt').freeze
  EXTPATH_3 = ::File.join(Dir.tmpdir, 'extracted_3.txt').freeze
  ENTRY_1 = 'entry_1.txt'.freeze
  ENTRY_2 = 'entry_2.txt'.freeze
  ENTRY_3 = 'entry_3.txt'.freeze

  def teardown
    ::File.unlink(ZIPPATH) if ::File.exist?(ZIPPATH)
    ::File.unlink(EXTPATH_1) if ::File.exist?(EXTPATH_1)
    ::File.unlink(EXTPATH_2) if ::File.exist?(EXTPATH_2)
    ::File.unlink(EXTPATH_3) if ::File.exist?(EXTPATH_3)
    ::File.unlink(TXTPATH_600) if ::File.exist?(TXTPATH_600)
    ::File.unlink(TXTPATH_755) if ::File.exist?(TXTPATH_755)
  end

  def test_restore_permissions
    # Copy and set up files with different permissions.
    ::FileUtils.cp(TXTPATH, TXTPATH_600)
    ::File.chmod(0600, TXTPATH_600)
    ::FileUtils.cp(TXTPATH, TXTPATH_755)
    ::File.chmod(0755, TXTPATH_755)

    ::Zip::File.open(ZIPPATH, true) do |zip|
      zip.add(ENTRY_1, TXTPATH)
      zip.add(ENTRY_2, TXTPATH_600)
      zip.add(ENTRY_3, TXTPATH_755)
    end

    ::Zip::File.open(ZIPPATH, false, restore_permissions: true) do |zip|
      zip.extract(ENTRY_1, EXTPATH_1)
      zip.extract(ENTRY_2, EXTPATH_2)
      zip.extract(ENTRY_3, EXTPATH_3)
    end

    assert_equal(::File.stat(TXTPATH).mode, ::File.stat(EXTPATH_1).mode)
    assert_equal(::File.stat(TXTPATH_600).mode, ::File.stat(EXTPATH_2).mode)
    assert_equal(::File.stat(TXTPATH_755).mode, ::File.stat(EXTPATH_3).mode)
  end

  def test_restore_times_true
    ::Zip::File.open(ZIPPATH, true) do |zip|
      zip.add(ENTRY_1, TXTPATH)
      zip.add_stored(ENTRY_2, TXTPATH)
    end

    ::Zip::File.open(ZIPPATH, false, restore_times: true) do |zip|
      zip.extract(ENTRY_1, EXTPATH_1)
      zip.extract(ENTRY_2, EXTPATH_2)
    end

    assert_time_equal(::File.mtime(TXTPATH), ::File.mtime(EXTPATH_1))
    assert_time_equal(::File.mtime(TXTPATH), ::File.mtime(EXTPATH_2))
  end

  def test_restore_times_false
    ::Zip::File.open(ZIPPATH, true) do |zip|
      zip.add(ENTRY_1, TXTPATH)
      zip.add_stored(ENTRY_2, TXTPATH)
    end

    ::Zip::File.open(ZIPPATH, false, restore_times: false) do |zip|
      zip.extract(ENTRY_1, EXTPATH_1)
      zip.extract(ENTRY_2, EXTPATH_2)
    end

    assert_time_equal(::Time.now, ::File.mtime(EXTPATH_1))
    assert_time_equal(::Time.now, ::File.mtime(EXTPATH_2))
  end

  private

  # Method to compare file times. DOS times only have 2 second accuracy.
  def assert_time_equal(expected, actual)
    assert_equal(expected.year, actual.year)
    assert_equal(expected.month, actual.month)
    assert_equal(expected.day, actual.day)
    assert_equal(expected.hour, actual.hour)
    assert_equal(expected.min, actual.min)
    assert_in_delta(expected.sec, actual.sec, 1)
  end
end
