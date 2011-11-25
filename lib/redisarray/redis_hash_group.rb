module RedisArray
  class RedisHashGroup
    attr_reader :name

    def initialize options={}
      options.reverse_merge!(:existing_group_name => nil)
      if options[:prefix]
        @name = options[:prefix] + "-" + rand(100000).to_s
        while not RedisTable.get_redis.keys("#{@name}:*").empty? do
          @name = options[:prefix] + "-" + rand(100000).to_s
        end
      elsif options[:existing_group_name].nil?
        @name = rand(100000).to_s
        while not RedisTable.get_redis.keys("#{@name}:*").empty? do
          @name = rand(100000).to_s
        end
      else
        @name = options[:existing_group_name].to_s
      end
    end
  end
end
