shared_examples_for '@data into init_properties_service is filleable' do
  it 'puts the :eq_types at least with %q[name short_description inv_properties] keys' do
    expect(subject.data[:eq_types].first.keys).to include('name', 'short_description', 'inv_properties')
  end

  it 'puts the :wp_types at least with %q[name long_description full_description] keys' do
    expect(subject.data[:wp_types].first.keys).to include('name', 'long_description', 'full_description')
  end

  it 'puts the :iss_locations with "iss_reference_buildings" array' do
    expect(subject.data[:iss_locations].first.keys).to include 'iss_reference_buildings'
  end

  it 'removes properties with "mandatory: true" fields from :eq_types array' do
    expect(subject.data[:eq_types].any? { |type| type['mandatory'] }).to be_falsey
  end
end
