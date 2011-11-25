require 'redis'
require 'csv'

module RedisArray
  class RedisTable
    cattr_accessor :logger
    @silence = false

    def self.silence?
      @silence
    end

    # Silence the logger.
    def self.silence!
      @silence = true
      self
    end

    @redis = Redis.new(:host => 'localhost', :port => 6379)

    def self.get_redis
      @redis
    end

    def self.set_redis redis
      @redis = redis
    end

    def self.get_table_names main_key_part
      res = []
      @redis.keys("#{main_key_part}:*").each do |key|
        res << key.scan(/^#{Regexp.escape(main_key_part)}\:(.+):\d+/)[0][0]
      end
      res
    end

    def self.get_row_ranges main_key_part, table_name
      row_ranges = []
      @redis.keys("#{main_key_part}:#{table_name}:*").each do |key|
        row_ranges << key.scan(/^#{Regexp.escape(main_key_part)}\:#{Regexp.escape(table_name)}\:(\d+)/)[0][0]
      end
      row_ranges
    end

    # Parameters:
    # +rows+ - specifies a range of rows to return,
    # it is header row agnostic in meaning that its up to you
    # to track if you supplied a header or not
    # As to the place of the header:
    # if you supplied headers in +header_row+ parameter for +set_table+
    # then it is stored at index 0 and you can retrieve it usign +get_table_data+
    # in two ways:
    # 1. specify +rows+ with value of :all
    # 2. specify +rows+ with value of 0
    def self.get_table_data main_key_part, table_name, rows = 0..-1
      table = {}
      if rows == (0..-1)
        get_row_ranges(main_key_part, table_name).each do |kri|
          @redis.hgetall("#{main_key_part}:#{table_name}:#{kri}").each_pair do |k, v|
            table[(kri.to_i*100) + k.to_i] = v
          end
        end
      elsif rows.kind_of? Integer
        get_row_ranges(main_key_part, table_name).each do |kri|
          next if kri.to_i != rows / 100
          table[(kri.to_i*100) + rows.to_i] = @redis.hget("#{main_key_part}:#{table_name}:#{kri}", rows)
        end
      elsif rows.kind_of? Range
        # TODO: handle case where rows is range like 15..20
        raise "TODO: handle case where rows is range like 15..20"
      else
        raise "Unsupported type of 'rows' parameter!"
      end

      table
    end

    def self.get_table_data_as_array main_key_part, table_name, rows = 0..-1
      hash = get_table_data main_key_part, table_name, rows
      res = hash.inject([]) do |array, (k, v)|
        array[k] = CSV.parse(v+"\r\n"+v)[0].collect { |cell| cell.to_s } #if not cell.nil?}
        array
      end
      if rows.kind_of? Integer
        res.compact
      else
        res
      end
    end

    def self.append_table_data main_key_part, table_name, rows, options={}

      kri = get_row_ranges(main_key_part, table_name).sort[-1].to_i
      res = @redis.hgetall("#{main_key_part}:#{table_name}:#{kri}").sort do |p1, p2|
        p1[0].to_i <=> p2[0].to_i
      end
      first_empty_ri = 0 # the nearest (to the beginning) empty row index
      if res.length > 0
        first_empty_ri = res[-1][0].to_i + 1
      else
        # it is empty so start from the beginning
      end

      start_from_row = kri.to_i * 100 + first_empty_ri
      if start_from_row == 0
        set_table_data main_key_part, table_name, rows
      else
        set_table_data main_key_part, table_name, rows, options={:start_from_row => start_from_row}
      end
    end

    # options:
    # :start_from_row - i.e. the output index or in other words an offset of the output data
    #       it cannot be greater than 99
    # :header_row - array of strings - if specified they will be written at index 0 and the data rows will start at index 1
    # :skip_headers - boolean - if specified the :header_row will be skipped and the data rows will start at index 0
    # (unless the :start_from_row is specified at the same time that would overwrite this option,
    # that is when :start_from_row is specified the :skip_headers will not cause shifting the data)
    def self.set_table_data main_key_part, table_name, rows, options={}
      if options[:skip_headers]
        options.reverse_merge!(:start_from_row => 1)
      else
        options.reverse_merge!(:start_from_row => 0)
      end
      new_rows = Marshal::load(Marshal.dump(rows))
      new_rows.unshift(options[:header_row]) if options[:header_row] and not options[:skip_headers]
      source_row_index = 0 # the index in the source array of data (i.e. the one we are copying data from to put them to redis)
      (0).upto((new_rows.count + options[:start_from_row]) / 100) do |kri|
        next if kri < options[:start_from_row] / 100
        (options[:start_from_row] / 100 == kri ? options[:start_from_row] % 100 : 0).upto(99).each do |ri|
          break if source_row_index >= new_rows.count #+ options[:start_from_row]
          curr_key = "#{main_key_part}:#{table_name}:#{kri}", ri # + (kri==0 ? options[:start_from_row] : 0)
          log("HGET", "#{curr_key.to_s}  ==  #{@redis.hget(*curr_key).to_s}")
          log("HSET", "#{curr_key.to_s}  ==  #{CSV.generate_line(new_rows[source_row_index]).to_s}")
          if RUBY_VERSION < '1.9'
            @redis.hset(*(curr_key << CSV.generate_line(new_rows[source_row_index])))
          else
            @redis.hset(*(curr_key << CSV.generate_line(new_rows[source_row_index], :row_sep => '')))
          end
          source_row_index += 1
        end
      end
    end

    def self.delete_all_table main_key_part, table_name
      self.get_row_ranges(main_key_part, table_name).each do |kri|
        curr_key = "#{main_key_part}:#{table_name}:#{kri}"
        @redis.del(curr_key)
      end
    end

    def self.delete_table_data main_key_part, table_name, options={}
      if options[:skip_headers]
        options.reverse_merge!(:start_from_row => 1)
      else
        options.reverse_merge!(:start_from_row => 0)
      end

      # TODO: start_from_row is not handled yet

      if options[:skip_headers]
        header = self.get_table_data main_key_part, table_name, rows = 0
        self.delete_all_table main_key_part, table_name
        self.set_table_data main_key_part, table_name, [], :header_row => header
      else
        self.delete_all_table main_key_part, table_name
      end
    end

    def set_rows table_name, rows
      rows.each_with_index do |row, idx|
        @redis.zadd("matrix.#{table_name}.rows", idx, row)
      end
    end

    def append_row table_name, row
      @redis.zadd("matrix.#{table_name}.rows", idx, row)
    end

    private
    def self.log(operation, message)
      return unless logger && !silence?
      logger.debug("RedisTable: #{operation}: #{message}")
    end

  end
end