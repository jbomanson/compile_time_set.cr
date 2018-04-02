require "spec"
require "../src/compile_time_set"

private CRYSTAL = %x(which crystal).chomp

# Runs "crystal eval ..." on a given string and returns its standard output and
# standard error concatenated in a single string.
def eval(string) : String
  output = nil
  Process.run(CRYSTAL, ["eval", "--error-trace", string]) do |process|
    output = process.output.gets_to_end + process.error.gets_to_end
  end
  output.not_nil!
end

describe "#eval" do
  it "found CRYSTAL" do
    CRYSTAL.should_not eq("")
  end

  greeting = "Hello world!"
  program = "print \"#{greeting}\""
  it "evaluates #{program}" do
    eval(program).should eq(greeting)
  end

  program = "1 + :symbol"
  it "evaluates #{program}" do
    eval(program).should match(/Error/)
  end
end
