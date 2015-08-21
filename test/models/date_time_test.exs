defmodule LaFamiglia.DateTimeTest do
  use LaFamiglia.ModelCase

  test "should set and get game time" do
    LaFamiglia.DateTime.start_link

    assert LaFamiglia.DateTime.now == nil

    LaFamiglia.DateTime.clock!

    assert LaFamiglia.DateTime.now != nil
  end
end
