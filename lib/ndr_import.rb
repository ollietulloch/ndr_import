require 'ndr_import/version'
require 'ndr_import/excel_file_helper'
require 'ndr_import/mapping_error'
require 'ndr_import/mapper'
require 'ndr_import/non_tabular_file_helper'

module NdrImport
  def self.root
    File.expand_path('../..', __FILE__)
  end
end
