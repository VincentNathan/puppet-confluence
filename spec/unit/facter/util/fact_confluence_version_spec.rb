require 'spec_helper'
require 'facter/confluence_version'

describe Facter::Util::Fact do
  pgrep_line = 'pgrep --list-full --full java.*atlassian-confluence-[0-9].*org.apache.catalina.startup.Bootstrap'
  context 'confluence_version with confluence running' do
    before do
      Facter.clear
      Facter.fact(:kernel).stubs(:value).returns('Linux')
      Facter::Util::Resolution.stubs(:exec).with(pgrep_line).returns('27999 /usr//bin/java -Djava.util.logging.config.file=/opt/confluence/atlassian-confluence-5.7.1/conf/logging.properties -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Xms256m -Xmx1024m -XX:MaxPermSize=256m -Djava.awt.headless=true -Djava.endorsed.dirs=/opt/confluence/atlassian-confluence-5.7.1/endorsed -classpath /opt/confluence/atlassian-confluence-5.7.1/bin/bootstrap.jar:/opt/confluence/atlassian-confluence-5.7.1/bin/tomcat-juli.jar -Dcatalina.base=/opt/confluence/atlassian-confluence-5.7.1 -Dcatalina.home=/opt/confluence/atlassian-confluence-5.7.1 -Djava.io.tmpdir=/opt/confluence/atlassian-confluence-5.7.1/temp org.apache.catalina.startup.Bootstrap start')
    end
    it 'returns the running version' do
      expect(Facter.fact(:confluence_version).value).to eq('5.7.1')
    end
  end

  context 'confluence_version with confluence running non-standard java' do
    before do
      Facter.clear
      Facter.fact(:kernel).stubs(:value).returns('Linux')
      Facter::Util::Resolution.stubs(:exec).with(pgrep_line).returns('27999 /usr/lib/jvm/java-1.8.0-oracle/bin/java -Djava.util.logging.config.file=/opt/confluence/atlassian-confluence-5.7.1/conf/logging.properties -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Xms256m -Xmx1024m -XX:MaxPermSize=256m -Djava.awt.headless=true -Djava.endorsed.dirs=/opt/confluence/atlassian-confluence-5.7.1/endorsed -classpath /opt/confluence/atlassian-confluence-5.7.1/bin/bootstrap.jar:/opt/confluence/atlassian-confluence-5.7.1/bin/tomcat-juli.jar -Dcatalina.base=/opt/confluence/atlassian-confluence-5.7.1 -Dcatalina.home=/opt/confluence/atlassian-confluence-5.7.1 -Djava.io.tmpdir=/opt/confluence/atlassian-confluence-5.7.1/temp org.apache.catalina.startup.Bootstrap start')
    end
    it 'returns the running version' do
      expect(Facter.fact(:confluence_version).value).to eq('5.7.1')
    end
  end

  context 'confluence_version with confulence not running' do
    before do
      Facter.clear
      Facter.fact(:kernel).stubs(:value).returns('Linux')
      Facter::Util::Resolution.stubs(:exec).with(pgrep_line).returns('')
    end
    it 'returns "unknown"' do
      expect(Facter.fact(:confluence_version).value).to eq('unknown')
    end
  end
end
