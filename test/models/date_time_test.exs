defmodule LaFamiglia.DateTimeTest do
  use LaFamiglia.ModelCase

  test "should set and get game time" do
    LaFamiglia.DateTime.clock!(nil)

    assert LaFamiglia.DateTime.now == nil

    LaFamiglia.DateTime.clock!

    assert LaFamiglia.DateTime.now != nil
  end
end
