module RedisArray

  class RedisWorkbook
    def initialize hash_group_name, workbook_name
      @workbook_name = workbook_name
      @hash_group_name = hash_group_name
    end

    def delete_sheet_data sheet_name, options={}
      RedisTable.delete_table_data @hash_group_name.to_s + ':' + @workbook_name.to_s, sheet_name, options
    end

    def set_sheet_data sheet_name, sheet_data, options={}
      RedisTable.set_table_data @hash_group_name.to_s + ':' + @workbook_name.to_s, sheet_name, sheet_data, options
    end

    def append_sheet_data sheet_name, sheet_data, options={}
      RedisTable.append_table_data @hash_group_name.to_s + ':' + @workbook_name.to_s, sheet_name, sheet_data, options
    end

    # return single row or range from sheet specified as first parameter,
    # the row index(es) to retrieve should be specified as the second parameter
    # Parameters:
    # +sheet_name+
    # +rows+ - range or single integer
    def get_sheet_data_as_array sheet_name, rows = 0..-1
      RedisTable.get_table_data_as_array @hash_group_name.to_s + ':' + @workbook_name.to_s, sheet_name, rows
    end

    def get_sheet_data sheet_name, rows = 0..-1
      RedisTable.get_table_data @hash_group_name.to_s + ':' + @workbook_name.to_s, sheet_name, rows
    end

    def append_workbook workbook, options={}
      options.reverse_merge!(:skip_headers => false)
      workbook.sheets.each_pair do |sheet_name, sheet|
        next if options[:skip_headers] and sheet.getData() == []
        append_sheet_data sheet_name, sheet.getData(), options.merge(:header_row => sheet.getHeader())
      end
    end

    def set_workbook workbook, options={}
      options.reverse_merge!(:skip_headers => false)
      workbook.sheets.each_pair do |sheet_name, sheet|
        next if options[:skip_headers] and sheet.getData() == []
        set_sheet_data sheet_name, sheet.getData(), options.merge(:header_row => sheet.getHeader())
      end
    end

    def set_workbooks_raw workbooks
      workbooks.each_with_index do |workbook, wi|
        set_workbook workbook
      end
    end

    def set_workbooks workbooks
      final_workbook = LWorkbook.new
      workbooks.each_with_index do |workbook, wi|
        workbook.sheets.each_pair do |sheet_name, sheet|
          final_sheet = final_workbook.getSheet(sheet_name)
          if final_sheet.nil?
            final_sheet = LSheet.new
            final_sheet.setHeader(sheet.getHeader())
          end
          sheet.getData().each do |row|
            final_sheet.addRow(row)
          end if sheet.getData() != []

          final_workbook.setSheet(sheet_name, final_sheet)
        end
      end
      set_workbook final_workbook
    end

    def get_sheet_names
      RedisTable.get_table_names @hash_group_name.to_s + ':' + @workbook_name.to_s
    end

  end

end