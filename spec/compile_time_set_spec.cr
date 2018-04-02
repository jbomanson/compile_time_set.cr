require "./spec_helper"

empty = CompileTimeSet.create
a = CompileTimeSet.create(:a)
b = CompileTimeSet.create(:b)
c = CompileTimeSet.create(:c)
ab = CompileTimeSet.create(:a, :b)
ac = CompileTimeSet.create(:a, :c)
bc = CompileTimeSet.create(:b, :c)
abc = CompileTimeSet.create(:a, :b, :c)

program_format = <<-EOF
  require "./src/compile_time_set"

  empty = CompileTimeSet.create
  a = CompileTimeSet.create(:a)
  b = CompileTimeSet.create(:b)
  c = CompileTimeSet.create(:c)
  ab = CompileTimeSet.create(:a, :b)
  ac = CompileTimeSet.create(:a, :c)
  bc = CompileTimeSet.create(:b, :c)
  abc = CompileTimeSet.create(:a, :b, :c)

  %s
EOF

describe CompileTimeSet do
  it "has a size of zero" do
    sizeof(typeof(empty)).should eq(0)
    sizeof(typeof(a)).should eq(0)
    sizeof(typeof(b)).should eq(0)
    sizeof(typeof(c)).should eq(0)
    sizeof(typeof(ab)).should eq(0)
    sizeof(typeof(ac)).should eq(0)
    sizeof(typeof(bc)).should eq(0)
    sizeof(typeof(abc)).should eq(0)
  end

  it "compares sets" do
    a.should eq(a)
    a.should_not eq(abc)
  end

  it "constructs sets with .create and .from_option_keys" do
    CompileTimeSet.create(:a).should eq(CompileTimeSet.from_option_keys(a: 1))
  end

  it "constructs sets with .create and .from_named_tuple_type" do
    CompileTimeSet.create(:a).should eq(
      CompileTimeSet.from_named_tuple_type(typeof({a: 1}))
    )
  end

  it "implements the union operator |" do
    (empty | empty).should eq(empty)
    (empty | a).should eq(a)
    (a | empty).should eq(a)
    (a | a).should eq(a)
    (a | b).should eq(ab)
    (a | b | c).should eq(abc)
    (ab | c).should eq(abc)
    (a | b | c | ab | abc).should eq(abc)
  end

  it "implements the intersection operator &" do
    (empty & empty).should eq(empty)
    (empty & a).should eq(empty)
    (a & empty).should eq(empty)
    (a & a).should eq(a)
    (a & b).should eq(empty)
    (ab & a).should eq(a)
    (ab & b).should eq(b)
    (abc & c).should eq(c)
    (abc & ab).should eq(ab)
    (ab & bc).should eq(b)
  end

  it "implements the difference operator -" do
    (empty - empty).should eq(empty)
    (empty - a).should eq(empty)
    (a - empty).should eq(a)
    (a - a).should eq(empty)
    (a - b).should eq(a)
    (ab - a).should eq(b)
    (ab - b).should eq(a)
    (abc - c).should eq(ab)
    (abc - ab).should eq(c)
  end

  it "implements the symmetric difference operator ^" do
    (empty ^ empty).should eq(empty)
    (empty ^ a).should eq(a)
    (a ^ empty).should eq(a)
    (a ^ a).should eq(empty)
    (a ^ b).should eq(ab)
    (ab ^ a).should eq(b)
    (ab ^ b).should eq(a)
    (abc ^ c).should eq(ab)
    (abc ^ ab).should eq(c)
    (ab ^ bc).should eq(ac)
  end

  it "implements disjoint!" do
    empty.disjoint! a
    empty.disjoint! b
    empty.disjoint! ab
    empty.disjoint! abc
    a.disjoint! b
    a.disjoint! c
    a.disjoint! bc
    ab.disjoint! c
  end

  it "catches disjoint! violations at compile time" do
    output = eval(program_format % "a.disjoint! abc")
    output.should match(/\QCompileTimeSet(NamedTuple(a: In))#disjoint!\E/)
    output.should match(/\QExpected {a} and {a, b, c} to be disjoint\E/)
  end

  it "implements empty!" do
    empty.empty!
  end

  it "catches empty! violations at compile time" do
    output = eval(program_format % "a.empty!")
    output.should match(/\QCompileTimeSet(NamedTuple(a: In))#empty!\E/)
    output.should match(/\QExpected {a} to be empty\E/)
  end

  it "implements size" do
    empty.size.should eq(0)
    a.size.should eq(1)
    ab.size.should eq(2)
    abc.size.should eq(3)
  end

  it "implements superset!" do
    a.superset! empty
    b.superset! empty
    ab.superset! empty
    abc.superset! empty
    ab.superset! a
    abc.superset! a
    ab.superset! b
    abc.superset! b
  end

  it "catches superset! violations at compile time" do
    output = eval(program_format % "a.superset! b")
    output.should match(/\QCompileTimeSet(NamedTuple(a: In))#superset!\E/)
    output.should match(/\QExpected {a} to be a superset of {b}\E/)
  end

  it "implements subset!" do
    empty.subset! a
    empty.subset! b
    empty.subset! ab
    empty.subset! abc
    a.subset! ab
    a.subset! abc
    b.subset! ab
    b.subset! abc
  end

  it "catches subset! violations at compile time" do
    output = eval(program_format % "a.subset! b")
    output.should match(/\QCompileTimeSet(NamedTuple(a: In))#subset!\E/)
    output.should match(/\QExpected {a} to be a subset of {b}\E/)
  end

  it "implements #to_named_tuple" do
    a.to_named_tuple.should eq({a: 1})
    abc.to_named_tuple("value").should eq({a: "value", b: "value", c: "value"})
  end

  it "implements #to_s" do
    abc.to_s.should eq("{a, b, c}")
    a.to_s.should eq("{a}")
    empty.to_s.should eq("{}")
  end
end
