require "test_helper"
require "stringio"

invalid_json = '["Invalid" "JSON"]'
incomplete_json = '["Incomplete JSON'

class DummyOutputter
  def process_token(*); end
end

def it_should_tokenize(json, *tokens)
  it "should tokenize #{json.inspect} to #{tokens.map(&:inspect).join ", "}" do
    assert_equal tokens, Jiffy.new(in: StringIO.new(json)).tokenize.to_a
  end
end

def it_should_not_tokenize(json)
  it "should not tokenize #{json.inspect}" do
    assert_raises Jiffy::UnexpectedEndError, Jiffy::UnparseableError do
      Jiffy.new(in: StringIO.new(json)).tokenize.to_a
    end
  end
end

describe Jiffy do
  describe "#tokenize" do
    it_should_tokenize '{}',
      :begin_object,
      :end_object

    it_should_tokenize '{"":{}}',
      :begin_object,
      :begin_name,
      :end_name,
      :name_separator,
      :begin_object,
      :end_object,
      :end_object

    it_should_tokenize '{"":"","":""}',
      :begin_object,
      :begin_name,
      :end_name,
      :name_separator,
      :begin_string,
      :end_string,
      :value_separator,
      :begin_name,
      :end_name,
      :name_separator,
      :begin_string,
      :end_string,
      :end_object

    it_should_tokenize '[]',
      :begin_array,
      :end_array

    it_should_tokenize '[[]]',
      :begin_array,
      :begin_array,
      :end_array,
      :end_array

    it_should_tokenize '[{}]',
      :begin_array,
      :begin_object,
      :end_object,
      :end_array

    it_should_tokenize '{"":[]}',
      :begin_object,
      :begin_name,
      :end_name,
      :name_separator,
      :begin_array,
      :end_array,
      :end_object

    it_should_tokenize '["",""]',
      :begin_array,
      :begin_string,
      :end_string,
      :value_separator,
      :begin_string,
      :end_string,
      :end_array

    it_should_tokenize '[false]',
      :begin_array,
      :false,
      :end_array

    it_should_tokenize '[true]',
      :begin_array,
      :true,
      :end_array

    it_should_tokenize '[null]',
      :begin_array,
      :null,
      :end_array

    it_should_tokenize '["foo"]',
      :begin_array,
      :begin_string,
      [:char, "f"],
      [:char, "o"],
      [:char, "o"],
      :end_string,
      :end_array

    it_should_tokenize '["\b"]',
      :begin_array,
      :begin_string,
      :escaped_backspace,
      :end_string,
      :end_array

    it_should_tokenize '["\r"]',
      :begin_array,
      :begin_string,
      :escaped_carriage_return,
      :end_string,
      :end_array

    it_should_tokenize '["\f"]',
      :begin_array,
      :begin_string,
      :escaped_formfeed,
      :end_string,
      :end_array

    it_should_tokenize '["\t"]',
      :begin_array,
      :begin_string,
      :escaped_horizontal_tab,
      :end_string,
      :end_array

    it_should_tokenize '["\n"]',
      :begin_array,
      :begin_string,
      :escaped_newline,
      :end_string,
      :end_array

    it_should_tokenize '["\""]',
      :begin_array,
      :begin_string,
      :escaped_quotation_mark,
      :end_string,
      :end_array

    it_should_tokenize '["\\\\"]',
      :begin_array,
      :begin_string,
      :escaped_reverse_solidus,
      :end_string,
      :end_array

    it_should_tokenize '["\/"]',
      :begin_array,
      :begin_string,
      :escaped_solidus,
      :end_string,
      :end_array

    it_should_tokenize '["\u1111"]',
      :begin_array,
      :begin_string,
      [:escaped_unicode, "1111"],
      :end_string,
      :end_array

    it_should_tokenize '[-100]',
      :begin_array,
      :minus,
      [:number, 1],
      [:number, 0],
      [:number, 0],
      :end_array

    it_should_tokenize '[1.123]',
      :begin_array,
      [:number, 1],
      [:char, "."],
      [:number, 1],
      [:number, 2],
      [:number, 3],
      :end_array

    it_should_tokenize '[1.123e10]',
      :begin_array,
      [:number, 1],
      [:char, "."],
      [:number, 1],
      [:number, 2],
      [:number, 3],
      :exponent,
      [:number, 1],
      [:number, 0],
      :end_array

    it_should_tokenize '[-1.123e-10]',
      :begin_array,
      :minus,
      [:number, 1],
      [:char, "."],
      [:number, 1],
      [:number, 2],
      [:number, 3],
      :exponent,
      :minus,
      [:number, 1],
      [:number, 0],
      :end_array

    it_should_tokenize '[1.123E+10]',
      :begin_array,
      [:number, 1],
      [:char, "."],
      [:number, 1],
      [:number, 2],
      [:number, 3],
      :exponent,
      :plus,
      [:number, 1],
      [:number, 0],
      :end_array

    it_should_not_tokenize '[0x00]'
    it_should_not_tokenize '[Infinity]'
    it_should_not_tokenize '[,""]'
    it_should_not_tokenize '["",]'
    it_should_not_tokenize '[01]'
    it_should_not_tokenize "[\"line\nbreak\"]"
    it_should_not_tokenize '{"" ""}'
    it_should_not_tokenize '[NaN]'
    it_should_not_tokenize '[+1.123]'
    it_should_not_tokenize '[+100]'
    it_should_not_tokenize "['single quoted string']"
    it_should_not_tokenize "[\"tab\tcharacter\"]"
    it_should_not_tokenize '{"":"",}'
    it_should_not_tokenize 'true'
    it_should_not_tokenize '""'
    it_should_not_tokenize '[true'
    it_should_not_tokenize '{"":""'

    it "should raise UnexpectedEndError on valid, but incomplete JSON input" do
      example = StringIO.new incomplete_json

      assert_raises Jiffy::UnexpectedEndError do
        Jiffy.new(in: example).tokenize.to_a
      end
    end

    it "should raise UnexpectedEndError on empty input" do
      example = StringIO.new ""

      assert_raises Jiffy::UnexpectedEndError do
        Jiffy.new(in: example).tokenize.to_a
      end
    end

    it "should raise UnparseableError on invalid JSON input" do
      example = StringIO.new invalid_json

      assert_raises Jiffy::UnparseableError do
        Jiffy.new(in: example).tokenize.to_a
      end
    end
  end

  describe "#initialize" do
    it "should not raise en error when :in respond to :readpartial" do
      class Bar
        def readpartial(*); end
      end

      Jiffy.new(in: Bar.new)
    end

    it "should raise an error when :in doesn't respond to :readpartial" do
      class Foo; end

      assert_raises ArgumentError do
        Jiffy.new(in: Foo.new)
      end
    end
  end
end
