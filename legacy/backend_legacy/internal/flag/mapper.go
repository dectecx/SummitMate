package flag

import "summitmate/api"

// ToSystemFlagResponse converts a Flag (DB model) to api.SystemFlag
func ToSystemFlagResponse(f Flag) api.SystemFlag {
	description := f.Description
	updatedAt := f.UpdatedAt
	return api.SystemFlag{
		Key:         f.Key,
		Value:       f.Value,
		Description: &description,
		UpdatedAt:   &updatedAt,
	}
}

// ToSystemFlagResponseList converts a slice of Flag to api.SystemFlag list
func ToSystemFlagResponseList(flags []Flag) []api.SystemFlag {
	result := make([]api.SystemFlag, 0, len(flags))
	for i := range flags {
		result = append(result, ToSystemFlagResponse(flags[i]))
	}
	return result
}
