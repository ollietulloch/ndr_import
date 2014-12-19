module UnifiedSources
  module Import
    # This mixin adds excel spreadsheet functionality to unified importers.
    # It provides a file reader method and methods to cast raw values
    # appropriately. These methods can be overridden or aliased as required.
    #
    module ExcelFileHelper
      require 'roo'
      require 'ole/storage'
      # Ruby 1.9 does not auto-require iconv
      require 'iconv'

      protected

      def cast_excel_value(raw_value)
        return raw_value if raw_value.nil?

        if raw_value.is_a?(Date) || raw_value.is_a?(DateTime) || raw_value.is_a?(Time)
          cast_excel_datetime_as_date(raw_value)
        elsif raw_value.is_a?(Float)
          if raw_value.to_f == raw_value.to_i
            # Whole number
            return raw_value.to_i.to_s
          else
            return raw_value.to_f.to_s
          end
        else
          return raw_value.to_s.strip
        end
      end

      def cast_excel_datetime_as_date(raw_value)
        raw_value.to_s(:db)
      end

      private

      def read_excel_file(path, selected_sheet = nil)
        # SECURE: TVB Mon Aug 13 15:30:32 BST 2012 SafeFile.safepath_to_string makes sure that
        # the path is SafePath.

        # Load the workbook
        workbook = load_workbook(path)

        # Choose selected worksheet (if provided and exist) or the first worksheet
        workbook.default_sheet = (selected_sheet.nil? || !workbook.sheets.include?(selected_sheet.to_s)) ? workbook.sheets.first : selected_sheet.to_s

        # Read the cells from working worksheet into a nested array
        array = []
        workbook.first_row.upto(workbook.last_row) do |row|
          line = []
          workbook.first_column.upto(workbook.last_column) do |col|
            line << cast_excel_value(workbook.cell(row, col))
          end
          array << line
        end
        array
      end

      def get_excel_sheets_name(path)
        workbook = load_workbook(path)
        workbook.sheets
      end

      def load_workbook(path)
        case SafeFile.extname(path).downcase
        when '.xls'
          Roo::Excel.new(SafeFile.safepath_to_string(path))
        when '.xlsx'
          Roo::Excelx.new(SafeFile.safepath_to_string(path))
        else
          fail "Received file path with unexpected extension #{SafeFile.extname(path)}"
        end
      rescue Ole::Storage::FormatError => e
        # TODO: Do we need to remove the new_file after using it?

        # try to load the .xls file as an .xlsx file, useful for sources like USOM
        # roo check file extensions in file_type_check (GenericSpreadsheet),
        # so we create a duplicate file in xlsx extension
        if /(.*)\.xls$/.match(path)
          new_file_name = SafeFile.basename(path).gsub(/(.*)\.xls$/, '\1_amend.xlsx')
          new_file_path = SafeFile.dirname(path).join(new_file_name)
          copy_file(path, new_file_path)

          load_workbook(new_file_path)
        else
          raise e.message
        end
      rescue => e
        raise ["Unable to read the file '#{path}'", e.message].join('; ')
      end
    end
  end
end