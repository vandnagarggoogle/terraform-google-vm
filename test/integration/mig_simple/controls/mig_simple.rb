# Copyright 2018 Google LLC
# ... (standard header) ...

project_id = attribute('project_id')
region     = attribute('region')

expected_instances = 4
expected_instance_groups = 1

control "MIG" do
  title "Simple Configuration"

  # 1. Add a wait loop to handle Compute API eventual consistency.
  # Regional queries are strongly consistent, but a 30s buffer is safest for CI.
  describe "GCE API Propagation" do
    it "should find resources within 60 seconds" do
      success = false
      6.times do |i|
        # Use '--filter=name:...' (substring) which is more robust than regex in gcloud
        # IMPORTANT: Added '--regions' flag to hit the strongly consistent regional endpoint
        cmd = command("gcloud compute instances list --project=#{project_id} --regions=#{region} --format=json --filter='name:mig-simple'")
        if cmd.exit_status == 0 && JSON.parse(cmd.stdout).length == expected_instances
          success = true
          break
        end
        puts "Attempt #{i+1}/6: Instances not visible yet. Sleeping 10s..."
        sleep 10
      end
      expect(success).to be true
    end
  end

  # 2. Update Instance Verification to use the Regional endpoint
  describe command("gcloud --project=#{project_id} compute instances list --regions=#{region} --format=json --filter='name:mig-simple'") do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq '' }

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
  end

  # 3. Update Instance Group Verification to use the Regional endpoint
  describe command("gcloud --project=#{project_id} compute instance-groups list --regions=#{region} --format=json --filter='name:mig-simple'") do
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

  # 4. Update Managed Instance Group Verification to use the Regional endpoint
  describe command("gcloud --project=#{project_id} compute instance-groups managed list --regions=#{region} --format=json --filter='name:mig-simple'") do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq '' }

    let!(:data) do
      if subject.exit_status == 0
        JSON.parse(subject.stdout)
      else
        []
      end
    end

    describe "number of managed instance groups" do
      it "should be #{expected_instance_groups}" do
        expect(data.length).to eq(expected_instance_groups)
      end
    end
  end
end
