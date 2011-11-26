require File.dirname(__FILE__) + "/spec_helper"

include RedisArray

describe RedisWorkbook do

  before(:each) do
    group_name = RedisHashGroup.new.name
    @workbook = RedisWorkbook.new group_name, 'matrix'
  end

  describe "#set_sheet_data" do
    before(:each) do
      @sheet_name = '__Status__'
    end

    it "saves all sheet rows in redis starting at given row index" do
      @workbook.set_sheet_data @sheet_name,
                               rows = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/five_rows.yaml"))),
                               :start_from_row => 3
      @workbook.get_sheet_data(@sheet_name).
          should include({5 => "(five rows) row 3 cell 1,(five rows) row 3 cell 2,(five rows) row 3 cell 3,(five rows) row 3 cell 4,(five rows) row 3 cell 5,,,"})
    end

    it "saves a single sheet row in redis at given row index" do
      @workbook.set_sheet_data @sheet_name,
                               rows = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/one_row.yaml"))),
                               :start_from_row => 0
      @workbook.get_sheet_data(@sheet_name).
          should == {0 => "(one row) row 1 cell 1,(one row) row 1 cell 2,(one row) row 1 cell 3,(one row) row 1 cell 4,(one row) row 1 cell 5,,,"}
    end

    context ":skip_headers option used" do
      it "saves only sheet data without header (i.e. omitting the 0 index and starting at 1 index) when specified to :skip_headers" do

        options = {:skip_headers => true}
        @workbook.set_sheet_data @sheet_name,
                                 rows = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/one_row_with_headers/one_row.yaml"))),
                                 options.merge(:header_row => YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/one_row_with_headers/headers.yaml"))))

        @workbook.get_sheet_data(@sheet_name).
            should == {1 => "(one row with header) row 1 cell 1,(one row with header) row 1 cell 2,(one row with header) row 1 cell 3,(one row with header) row 1 cell 4,(one row with header) row 1 cell 5,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,"}


        # the same for case where there is not :header_row specified
        @workbook.set_sheet_data @sheet_name,
                                 rows = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/one_row_with_headers/one_row.yaml"))),
                                 options

        @workbook.get_sheet_data(@sheet_name).
            should == {1 => "(one row with header) row 1 cell 1,(one row with header) row 1 cell 2,(one row with header) row 1 cell 3,(one row with header) row 1 cell 4,(one row with header) row 1 cell 5,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,"}
      end


      it "does not save anything when there is no data and when specified to :skip_headers" do
        options = {:skip_headers => true}
        @workbook.set_sheet_data @sheet_name,
                                 rows = [],
                                 options.merge(:header_row => YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/one_row_with_headers/headers.yaml"))))

        @workbook.get_sheet_data(@sheet_name).
            should == {}

        # the same for case where there is not :header_row specified
        @workbook.set_sheet_data @sheet_name,
                                 rows = [],
                                 options

        @workbook.get_sheet_data(@sheet_name).
            should == {}
      end

      it "follows a rule that :start_from_row option takes precedence over :skip_headers" do
        options = {:skip_headers => true, :start_from_row => 4}
        @workbook.set_sheet_data @sheet_name,
                                 rows = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/one_row_with_headers/one_row.yaml"))),
                                 options.merge(:header_row => YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/one_row_with_headers/headers.yaml"))))

        @workbook.get_sheet_data(@sheet_name).
            should == {4 => "(one row with header) row 1 cell 1,(one row with header) row 1 cell 2,(one row with header) row 1 cell 3,(one row with header) row 1 cell 4,(one row with header) row 1 cell 5,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,"}

        # the same for case where there is no :header_row specified
        @workbook.set_sheet_data @sheet_name,
                                 rows = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/one_row_with_headers/one_row.yaml"))),
                                 options

        @workbook.get_sheet_data(@sheet_name).
            should == {4 => "(one row with header) row 1 cell 1,(one row with header) row 1 cell 2,(one row with header) row 1 cell 3,(one row with header) row 1 cell 4,(one row with header) row 1 cell 5,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,"}
      end
    end
  end

  describe "#append_sheet_data" do
    before(:each) do
      @sheet_name = '__Status__'
    end

    context "the sheet is empty" do
      it "writes all rows in redis starting at row 0" do
        @workbook.append_sheet_data @sheet_name,
                                    rows = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/five_rows.yaml")))
        @workbook.get_sheet_data(@sheet_name).length.should == 5
        @workbook.get_sheet_data(@sheet_name).
            should include({0 => "(five rows) row 1 cell 1,(five rows) row 1 cell 2,(five rows) row 1 cell 3,(five rows) row 1 cell 4,(five rows) row 1 cell 5,,,"})
      end
    end

    context "the sheet contains a few rows already" do
      before(:each) do
        @sheet_name = '__Status__'
        @workbook.set_sheet_data @sheet_name,
                                 rows = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/five_rows.yaml"))),
                                 :start_from_row => 0
      end

      it "appends all rows in redis starting at the first empty row" do
        @workbook.append_sheet_data @sheet_name,
                                    rows = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/three_rows.yaml")))
        @workbook.get_sheet_data(@sheet_name).length.should == 8
        @workbook.get_sheet_data(@sheet_name).
            should include({0 => "(five rows) row 1 cell 1,(five rows) row 1 cell 2,(five rows) row 1 cell 3,(five rows) row 1 cell 4,(five rows) row 1 cell 5,,,"})
        @workbook.get_sheet_data(@sheet_name).
            should include({7 => '13000000,,3rd row 2nd cell,,,,,'})
      end
    end

    context "the sheet contains a few hundred rows already" do
      before(:each) do
        @sheet_name = '__Status__'
        @workbook.set_sheet_data @sheet_name,
                                 rows = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/328_rows.yaml"))),
                                 :start_from_row => 0
      end

      context "appending only a few rows" do
        before(:each) do
          @workbook.append_sheet_data @sheet_name,
                                      rows = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/three_rows.yaml")))
        end
        it "leaves existing data intact" do
          @workbook.get_sheet_data(@sheet_name).
              should include({0 => '10000000,random data,random data,,random data,,,'})
          @workbook.get_sheet_data(@sheet_name).
              should include({327 => '10000000,random data,random data,,random data,,,'})
        end
        it "appends all rows in redis starting at the first empty row" do
          @workbook.get_sheet_data(@sheet_name).length.should == 331
          @workbook.get_sheet_data(@sheet_name).
              should include({328 => '11000000,1st row 1st cell,1st row 2nd cell,,1st row 4th cell,,,'})
          @workbook.get_sheet_data(@sheet_name).
              should include({330 => "13000000,,3rd row 2nd cell,,,,,"})
          @workbook.get_sheet_data(@sheet_name).
              should include({331 => nil}) # i.e. the hash should not have key 331
        end
      end

      context "appending a few hundred rows" do
        before(:each) do
          @workbook.append_sheet_data @sheet_name,
                                      rows = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/256_rows.yaml")))
        end
        it "leaves existing data intact" do
          @workbook.get_sheet_data(@sheet_name).
              should include({0 => '10000000,random data,random data,,random data,,,'})
          @workbook.get_sheet_data(@sheet_name).
              should include({327 => '10000000,random data,random data,,random data,,,'})
        end
        it "appends all rows in redis starting at the first empty row" do
          @workbook.get_sheet_data(@sheet_name).length.should == 584
          @workbook.get_sheet_data(@sheet_name).
              should include({328 => "23400000,some data,,some data,some data,,,"})
          @workbook.get_sheet_data(@sheet_name).
              should include({583 => "23400000,some data,,some data,some data,,,"})
          @workbook.get_sheet_data(@sheet_name).
              should include({584 => nil}) # i.e. the hash should not have the key
        end
      end
    end
  end

  context "retrieving data" do
    before(:each) do
      @sheet_name = '__Status__'
      @workbook.set_sheet_data @sheet_name,
                               rows = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/five_rows.yaml"))),
                               :start_from_row => 0
    end

    describe "#get_sheet_data" do
      before(:each) do
      end

      it "retrieves all sheet rows from redis" do
        @workbook.get_sheet_data(@sheet_name, rows = 0..-1).
            should include({4 => "(five rows) row 5 cell 1,(five rows) row 5 cell 2,(five rows) row 5 cell 3,(five rows) row 5 cell 4,(five rows) row 5 cell 5,,,"})
      end

      it "retrieves single sheet row from redis" do
        @workbook.get_sheet_data(@sheet_name, rows = 2).
            should == {2 => "(five rows) row 3 cell 1,(five rows) row 3 cell 2,(five rows) row 3 cell 3,(five rows) row 3 cell 4,(five rows) row 3 cell 5,,,"}
      end
    end

    describe "#get_sheet_data_as_array" do
      before(:each) do
        @sheet_name = '__Status__'
        @workbook.set_sheet_data @sheet_name,
                                 rows = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), "fixtures/five_rows.yaml"))),
                                 :start_from_row => 0

        @third_row = YAML::load(
<<-STR
---
- (five rows) row 3 cell 1
- (five rows) row 3 cell 2
- (five rows) row 3 cell 3
- (five rows) row 3 cell 4
- (five rows) row 3 cell 5
- ""
- ""
- ""
STR
        )
      end

      it "retrieves all sheet rows from redis" do
        @workbook.get_sheet_data_as_array(@sheet_name, rows = 0..-1)[2].
            should eql @third_row
      end

      it "retrieves single sheet row from redis" do
        @workbook.get_sheet_data_as_array(@sheet_name, rows = 2)[0].
            should eql @third_row
      end
    end
  end


end

