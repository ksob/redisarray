require File.dirname(__FILE__) + "/spec_helper"

describe RedisArray::RedisHashGroup do

  before(:each) do
  end

  describe "#initialize" do
    before(:each) do
    end

    it "generates new group name with specified prefix" do
      @redis_hash_group_name = RedisHashGroup.new(:prefix => 'leb_standard_product').name
      @redis_hash_group_name.
          should =~ /^leb_standard_product/
    end

    it "generates new group name without specified prefix" do
      @redis_hash_group_name = RedisHashGroup.new.name
      @redis_hash_group_name.
          should =~ /^\d/
    end

    it "retrieves existing group name when specified the group name" do
      group_name = RedisHashGroup.new.name
      @workbook = RedisWorkbook.new group_name, 'matrix'
      @sheet_name = '__Status__'

      @workbook.set_sheet_data @sheet_name,
                               rows = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/five_rows.yaml"))),
                               :start_from_row => 3

      @redis_hash_group_name = RedisHashGroup.new(:existing_group_name => group_name).name

      @redis_hash_group_name.
          should == group_name
    end
  end

end
