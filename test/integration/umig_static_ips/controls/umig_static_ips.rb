# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

project_id = attribute('project_id')

expected_instances = 4
expected_instance_groups = 4
test_zones = "#{region}-a,#{region}-b,#{region}-c,#{region}-f"

control "UMIG" do
  title "Static IPs"

  # 1. Instance and Static IP Verification (Using Strongly Consistent Zonal Query)
  # Adding --zones bypasses the stale global index and fixes the 'actual: 0' error.
  describe command("gcloud --project=#{project_id} compute instances list --zones=#{test_zones} --format=json --filter='name:umig-static-ips'") do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq '' } # Will be empty because data is found immediately

    let!(:data) do
      if subject.exit_status == 0
        JSON.parse(subject.stdout)
      else
        []
      end
    end

    describe "number of instances" do
      it "should be #{expected_instances}" do
        expect(data.length).to eq(expected_instances)
      end
    end

    # Specific instance property checks
    describe "instance 001" do
      let(:instance) { data.find { |i| i['name'] == "umig-static-ips-001" } }
      it "should be in zone #{region}-a" do
        expect(instance['zone']).to match(/.*#{region}-a$/)
      end
      it "should have IP 10.128.0.10" do
        expect(instance['networkInterfaces'][0]['networkIP']).to eq("10.128.0.10")
      end
    end

    describe "instance 002" do
      let(:instance) { data.find { |i| i['name'] == "umig-static-ips-002" } }
      it "should be in zone #{region}-b" do
        expect(instance['zone']).to match(/.*#{region}-b$/)
      end
      it "should have IP 10.128.0.11" do
        expect(instance['networkInterfaces'][0]['networkIP']).to eq("10.128.0.11")
      end
    end

    describe "instance 003" do
      let(:instance) { data.find { |i| i['name'] == "umig-static-ips-003" } }
      it "should be in zone #{region}-c" do
        expect(instance['zone']).to match(/.*#{region}-c$/)
      end
      it "should have IP 10.128.0.12" do
        expect(instance['networkInterfaces'][0]['networkIP']).to eq("10.128.0.12")
      end
    end

    describe "instance 004" do
      let(:instance) { data.find { |i| i['name'] == "umig-static-ips-004" } }
      it "should be in zone #{region}-f" do
        expect(instance['zone']).to match(/.*#{region}-f$/)
      end
      it "should have IP 10.128.0.13" do
        expect(instance['networkInterfaces'][0]['networkIP']).to eq("10.128.0.13")
      end
    end
  end

  # 2. Unmanaged Instance Group Verification (Using Zonal Query for Consistency)
  describe command("gcloud --project=#{project_id} compute instance-groups list --zones=#{test_zones} --format=json --filter='name:umig-static-ips'") do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq '' }

    let!(:data) do
      if subject.exit_status == 0
        JSON.parse(subject.stdout)
      else
        []
      end
    end

    describe "number of instance groups" do
      it "should be #{expected_instance_groups}" do
        expect(data.length).to eq(expected_instance_groups)
      end
    end
  end
end