require 'test_helper'
require 'ndr_import/helpers/file/excel'

# Excel file helper tests
class ExcelTest < ActiveSupport::TestCase
  # This is a test importer class to test the excel file helper mixin
  class TestImporter
    include NdrImport::Helpers::File::Excel
  end

  def setup
    @permanenttestfiles = SafePath.new('permanent_test_files')
    @importer = TestImporter.new
  end

  test 'read_excel_file helper should read xls file' do
    file_content = @importer.send(:read_excel_file, @permanenttestfiles.join('sample_xls.xls'))
    assert_equal file_content.count, 2
    assert_equal file_content.first, %w(1A 1B)
  end

  test 'read_excel_file helper should read xlsx file' do
    file_content = @importer.send(:read_excel_file, @permanenttestfiles.join('sample_xlsx.xlsx'))
    assert_equal file_content.count, 2
    assert_equal file_content.first, %w(1A 1B)
  end

  test 'read_excel_file helper should read xlsx file with the incorrect xls extension' do
    file_path = @permanenttestfiles.join('xlsx_file_xls_extension.xls')
    file_content = @importer.send(:read_excel_file, file_path)
    assert_equal file_content.count, 2
    assert_equal file_content.first, %w(1A 1B)

    SafeFile.delete @permanenttestfiles.join('xlsx_file_xls_extension_amend.xlsx')
  end

  test 'read_excel_file helper should handle exceptions' do
    # txt file
    SafeFile.open(@permanenttestfiles.join('temp.txt'), 'w') { |f| f.write 'dummy line' }
    assert_raises RuntimeError do
      @importer.send(:read_excel_file, @permanenttestfiles.join('temp.txt'))
    end

    # .txt file in .xls extension
    File.rename @permanenttestfiles.join('temp.txt'), @permanenttestfiles.join('temp.xls')
    assert_raises RuntimeError do
      @importer.send(:read_excel_file, @permanenttestfiles.join('temp.xls'))
    end

    # .txt file in .xlsx extension
    File.rename @permanenttestfiles.join('temp.xls'), @permanenttestfiles.join('temp.xlsx')
    assert_raises RuntimeError do
      @importer.send(:read_excel_file, @permanenttestfiles.join('temp.xlsx'))
    end

    SafeFile.delete @permanenttestfiles.join('temp.xlsx')
    SafeFile.delete @permanenttestfiles.join('temp_amend.xlsx')
  end

  test 'excel_tables helper should read xls table correctly' do
    table = @importer.send(:excel_tables, @permanenttestfiles.join('sample_xls.xls'))
    table.each do |tablename, sheet|
      assert_equal 'Sheet1', tablename
      assert_equal %w(1A 1B), sheet.first
    end
  end

  test 'excel_tables helper should read xlsx table correctly' do
    table = @importer.send(:excel_tables, @permanenttestfiles.join('sample_xlsx.xlsx'))
    table.each do |tablename, sheet|
      assert_equal 'Sheet1', tablename
      assert_equal %w(1A 1B), sheet.first
    end
  end

  def test_each_excel_table_should_be_deprecated
    original_stderr = $stderr
    $stderr = StringIO.new

    table = @importer.send(:each_excel_table, @permanenttestfiles.join('sample_xlsx.xlsx'))
    table.each do |tablename, sheet|
      assert_equal 'Sheet1', tablename
      assert_equal %w(1A 1B), sheet.first
    end

    assert_match(/\A\[warning\] each_excel_table will be deprecated/, $stderr.string)
  ensure
    $stderr = original_stderr
  end if Gem::Requirement.new('< 3.0.0').satisfied_by?(Gem::Version.new(NdrImport::VERSION))

  def test_deprecated_methods_removed_in_v3
    refute @importer.protected_methods.include?(:each_excel_table), 'should be removed in v3.0.0'
    refute @importer.private_methods.include?(:each_excel_row), 'should be removed in v3.0.0'
    refute @importer.private_methods.include?(:each_xls_row), 'should be removed in v3.0.0'
    refute @importer.private_methods.include?(:each_xlsx_row), 'should be removed in v3.0.0'
  end if Gem::Requirement.new('>= 3.0.0').satisfied_by?(Gem::Version.new(NdrImport::VERSION))
end
