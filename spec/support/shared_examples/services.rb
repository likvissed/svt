shared_examples_for 'not run methods' do |methods|
  case methods.class.name
  when 'Array'
    methods.each do |method|
      it "not runs the '#{method}' method" do
        expect(subject).not_to receive method.to_sym
        subject.run
      end
    end
  when 'String'
    it "not runs the '#{methods}' method" do
      expect(subject).not_to receive methods.to_sym
      subject.run
    end
  else
    raise 'Parameter must have Array or String class'
  end
end

shared_examples_for 'run methods' do |methods|
  case methods.class.name
  when 'Array'
    methods.each do |method|
      it "runs the '#{method}' method" do
        expect(subject).to receive method.to_sym
        subject.run
      end
    end
  when 'String'
    it "runs the '#{methods}' method" do
      expect(subject).to receive methods.to_sym
      subject.run
    end
  else
    raise 'Parameter must have Array or String class'
  end
end
