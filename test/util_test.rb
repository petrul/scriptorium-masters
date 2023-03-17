require 'test/unit'
require_relative '../lib/util'

class MyTest < Test::Unit::TestCase

    def test_find_fodt_source

        odt = "build/a.odt"

        puts Util::find_source_file_for_odt(odt)
    end
end