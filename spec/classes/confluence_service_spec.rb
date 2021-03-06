require 'spec_helper.rb'

describe 'confluence' do
  describe 'confluence::config' do
    context 'default params' do
      let(:params) do
        {
          javahome: '/opt/java',
          version: '5.5.6'
        }
      end

      let :facts do
        {
          os: { family: 'RedHat' },
          operatingsystem: 'RedHat'
        }
      end

      it { is_expected.to contain_service('confluence') }
      it { is_expected.to compile.with_all_deps }
    end
  end
end
