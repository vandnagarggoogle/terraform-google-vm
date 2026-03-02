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

control "UMIG" do
  title "Static IPs"

  # Define attributes INSIDE the control block to avoid 'undefined local variable' errors
  project_id = attribute('project_id')
  region     = attribute('region') || 'us-central1'

  expected_instances = 4
  expected_instance_groups = 4

  # Map of instances and their expected properties for verification
  instances_to_verify = {
    "umig-static-ips-001" => { zone: "a", ip: "10.128.0.10" },
    "umig-static-ips-002" => { zone: "b", ip: "10.128.0.11" },
    "umig-static-ips-003" => { zone: "c", ip: "10.128.0.12" },
    "umig-static-ips-004" => { zone: "f", ip: "10.128.0.13" }
  }

  # 1. Individual Instance and Static IP Verification (Strongly Consistent)
  # Hits the regional/zonal source of truth directly to avoid global index lag.
  instances_to_verify.each do |name, props|
    describe "Instance #{name}" do
      let(:cmd) { command("gcloud compute instances describe #{name} --zone=#{region}-#{props[:zone]} --project=#{project_id} --format=json") }

      it "should exist and be in RUNNING state" do
        expect(cmd.exit_status).to eq 0
        expect(JSON.parse(cmd.stdout)['status']).to eq "RUNNING"
      end

      it "should have the correct static IP #{props[:ip]}" do
        # Verification fails if data is not present, ensuring no 'actual: 0' false passes
        data = JSON.parse(cmd.stdout)
        expect(data['networkInterfaces'][0]['networkIP']).to eq props[:ip]
      end

      it "should be in the correct zone #{region}-#{props[:zone]}" do
        data = JSON.parse(cmd.stdout)
        expect(data['zone']).to match(/.*#{region}-#{props[:zone]}$/)
      end
    end
  end

  # 2. Unmanaged Instance Group Verification (Using Strongly Consistent Zonal Query)
  test_zones = "#{region}-a,#{region}-b,#{region}-c,#{region}-f"
  describe command("gcloud compute instance-groups list --project=#{project_id} --zones=#{test_zones} --format=json --filter='name:umig-static-ips'") do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq '' } # No warning because data is found immediately via --zones

    let!(:data) do
      if subject.exit_status == 0
        JSON.parse(subject.stdout)
      else
        []
      end
    end

    it "should find all #{expected_instance_groups} instance groups" do
      expect(data.length).to eq(expected_instance_groups)
    end
  end
end
