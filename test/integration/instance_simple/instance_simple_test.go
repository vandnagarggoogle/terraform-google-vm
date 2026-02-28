package instance_simple

import (
	"fmt"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"
	"github.com/tidwall/gjson"
)

func TestInstanceSimpleModule(t *testing.T) {
	const instanceNamePrefix = "instance-simple"
	zoneIns := map[string]string{
		"instance-simple-001": "us-central1-a",
		"instance-simple-002": "us-central1-b",
		"instance-simple-003": "us-central1-c",
		"instance-simple-004": "us-central1-f",
	}

	insSimpleT := tft.NewTFBlueprintTest(t)

	insSimpleT.DefineVerify(func(assert *assert.Assertions) {
		insSimpleT.DefaultVerify(assert)

		projectId := insSimpleT.GetStringOutput("project_id")
		expectedCount := len(zoneIns)

		var instances gjson.Result
		for i := 0; i < 12; i++ {
			instances = gcloud.Run(t, fmt.Sprintf("compute instances list --project %s --filter name~%s", projectId, instanceNamePrefix))
			if len(instances.Array()) == expectedCount {
				break
			}
			t.Logf("Expected %d instances, found %d. Retrying in 10s... (Attempt %d/12)", expectedCount, len(instances.Array()), i+1)
			time.Sleep(10 * time.Second)
		}

		assert.Equal(expectedCount, len(instances.Array()), fmt.Sprintf("expected to find %d gce instances, but found %d", expectedCount, len(instances.Array())))

		for _, instance := range instances.Array() {
			instanceName := instance.Get("name").String()
			expectedZone := zoneIns[instanceName]
			actualZone := instance.Get("zone").String()
			assert.Contains(actualZone, expectedZone, fmt.Sprintf("instance %s is in the right zone", instanceName))
		}
	})

	insSimpleT.Test()
}
