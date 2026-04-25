package main

import (
	"context"
	"fmt"
	"github.com/pashagolub/pgxmock/v4"
)

func main() {
	mock, err := pgxmock.NewPool()
	if err != nil {
		panic(err)
	}
	defer mock.Close()

	columns := []string{"id"}
	mock.ExpectQuery("SELECT id").WillReturnRows(pgxmock.NewRows(columns).AddRow("1"))

	var id string
	err = mock.QueryRow(context.Background(), "SELECT id").Scan(&id)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
	} else {
		fmt.Printf("ID: %s\n", id)
	}
}
