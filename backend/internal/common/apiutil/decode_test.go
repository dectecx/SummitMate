package apiutil

import (
	"bytes"
	"errors"
	"net/http"
	"testing"

	"summitmate/internal/apperror"

	"github.com/stretchr/testify/assert"
)

type DummyRequest struct {
	Name string `json:"name"`
	Age  int    `json:"age"`
	Flag bool   `json:"flag"`
}

func TestDecodeBody(t *testing.T) {
	t.Run("Given valid JSON body, When decoding body, Then it returns decoded object without error", func(t *testing.T) {
		jsonStr := `{"name": "Alice", "age": 25, "flag": true}`
		req, _ := http.NewRequest("POST", "/test", bytes.NewBufferString(jsonStr))

		var dest DummyRequest
		err := DecodeBody(req, &dest)

		assert.NoError(t, err)
		assert.Equal(t, "Alice", dest.Name)
		assert.Equal(t, 25, dest.Age)
		assert.True(t, dest.Flag)
	})

	t.Run("Given empty request body, When decoding body, Then it returns EOF error", func(t *testing.T) {
		req, _ := http.NewRequest("POST", "/test", bytes.NewBufferString(""))

		var dest DummyRequest
		err := DecodeBody(req, &dest)

		assert.Error(t, err)
		var appErr *apperror.AppError
		assert.True(t, errors.As(err, &appErr))
		assert.Equal(t, apperror.ErrBadRequest.Code, appErr.Code)
		assert.Contains(t, appErr.Message, "請求 body 不可為空")
	})

	t.Run("Given truncated request body, When decoding body, Then it returns UnexpectedEOF error", func(t *testing.T) {
		// 不完整的 JSON 字串會觸發 io.ErrUnexpectedEOF
		req, _ := http.NewRequest("POST", "/test", bytes.NewBufferString(`{"name": "Alice"`))

		var dest DummyRequest
		err := DecodeBody(req, &dest)

		assert.Error(t, err)
		var appErr *apperror.AppError
		assert.True(t, errors.As(err, &appErr))
		assert.Equal(t, apperror.ErrBadRequest.Code, appErr.Code)
		assert.Contains(t, appErr.Message, "請求 body 格式不完整")
	})

	t.Run("Given type mismatch in JSON, When decoding body, Then it returns UnmarshalTypeError", func(t *testing.T) {
		// age 期望為 int，但傳入 string "twenty-five"
		jsonStr := `{"name": "Alice", "age": "twenty-five"}`
		req, _ := http.NewRequest("POST", "/test", bytes.NewBufferString(jsonStr))

		var dest DummyRequest
		err := DecodeBody(req, &dest)

		assert.Error(t, err)
		var appErr *apperror.AppError
		assert.True(t, errors.As(err, &appErr))
		assert.Equal(t, apperror.ErrBadRequest.Code, appErr.Code)
		assert.Contains(t, appErr.Message, "欄位 \"age\" 型別錯誤")
		assert.Contains(t, appErr.Message, "期望 int")
		assert.Contains(t, appErr.Message, "收到 JSON string")
	})

	t.Run("Given syntax error in JSON, When decoding body, Then it returns syntax error", func(t *testing.T) {
		// 錯誤的 JSON 語法 (多了一個逗號且不合法)
		jsonStr := `{"name": "Alice",, "age": 25}`
		req, _ := http.NewRequest("POST", "/test", bytes.NewBufferString(jsonStr))

		var dest DummyRequest
		err := DecodeBody(req, &dest)

		assert.Error(t, err)
		var appErr *apperror.AppError
		assert.True(t, errors.As(err, &appErr))
		assert.Equal(t, apperror.ErrBadRequest.Code, appErr.Code)
		assert.Contains(t, appErr.Message, "JSON 語法錯誤")
	})
}
