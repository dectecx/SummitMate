package weather

import (
	"summitmate/api"

	"github.com/google/uuid"
)

// ToWeatherRecordResponse converts a WeatherRecord (DB model) to api.WeatherRecord
func ToWeatherRecordResponse(rec WeatherRecord) api.WeatherRecord {
	id := uuid.MustParse(rec.ID)
	location := rec.Location
	startTime := rec.StartTime
	endTime := rec.EndTime
	wx := rec.Wx
	temp := float32(rec.Temp)
	pop := rec.PoP
	minTemp := float32(rec.MinTemp)
	maxTemp := float32(rec.MaxTemp)
	humidity := float32(rec.Humidity)
	windSpeed := float32(rec.WindSpeed)
	minAt := float32(rec.MinAT)
	maxAt := float32(rec.MaxAT)
	fetchedAt := rec.FetchedAt

	return api.WeatherRecord{
		Id:        &id,
		Location:  &location,
		StartTime: &startTime,
		EndTime:   &endTime,
		Wx:        &wx,
		Temp:      &temp,
		Pop:       &pop,
		MinTemp:   &minTemp,
		MaxTemp:   &maxTemp,
		Humidity:  &humidity,
		WindSpeed: &windSpeed,
		MinAt:     &minAt,
		MaxAt:     &maxAt,
		IssueTime: rec.IssueTime,
		FetchedAt: &fetchedAt,
	}
}

// ToWeatherRecordResponseList converts a slice of WeatherRecord to api.WeatherRecord list
func ToWeatherRecordResponseList(records []WeatherRecord) []api.WeatherRecord {
	result := make([]api.WeatherRecord, 0, len(records))
	for i := range records {
		result = append(result, ToWeatherRecordResponse(records[i]))
	}
	return result
}
