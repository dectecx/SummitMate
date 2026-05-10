package apiutil

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"summitmate/internal/apperror"
	"strings"
)

// DecodeBody 解析 HTTP request body 的 JSON，並自動將 JSON 解析錯誤
// 轉換成帶有欄位資訊的 AppError，方便 log 精確記錄原因。
//
// 用法：
//
//	var req api.SomeRequest
//	if err := apiutil.DecodeBody(r, &req); err != nil {
//	    apiutil.SendError(w, r, err)
//	    return
//	}
func DecodeBody[T any](r *http.Request, dest *T) error {
	dec := json.NewDecoder(r.Body)
	if err := dec.Decode(dest); err != nil {
		return buildDecodeError(err)
	}
	return nil
}

// buildDecodeError 解析 JSON 的具體錯誤型別，提取欄位名稱與原因，
// 組成帶有詳細說明的 AppError。
// 錯誤細節僅記錄在 log，不會回傳給前端使用者。
func buildDecodeError(err error) error {
	// EOF 通常代表 request body 為空
	if errors.Is(err, io.EOF) {
		return apperror.ErrBadRequest.
			WithMessage("請求 body 不可為空").
			Wrap(err)
	}

	// 非預期的 EOF（body 截斷）
	if errors.Is(err, io.ErrUnexpectedEOF) {
		return apperror.ErrBadRequest.
			WithMessage("請求 body 格式不完整").
			Wrap(err)
	}

	var typeErr *json.UnmarshalTypeError
	if errors.As(err, &typeErr) {
		// Field 可能是 "" 若是 top-level 以外的 nested field
		field := typeErr.Field
		if field == "" {
			field = "(unknown)"
		}
		msg := fmt.Sprintf("欄位 %q 型別錯誤：期望 %s，收到 JSON %s",
			field, humanizeType(typeErr.Type.String()), typeErr.Value)
		return apperror.ErrBadRequest.WithMessage(msg).Wrap(err)
	}

	var syntaxErr *json.SyntaxError
	if errors.As(err, &syntaxErr) {
		msg := fmt.Sprintf("JSON 語法錯誤（偏移位置 %d）", syntaxErr.Offset)
		return apperror.ErrBadRequest.WithMessage(msg).Wrap(err)
	}

	// 其他未知 JSON 錯誤（e.g. 自訂 UnmarshalJSON 回傳的錯誤）
	return apperror.ErrBadRequest.Wrap(err)
}

// humanizeType 將 Go reflect 型別名稱轉換為更易讀的形式。
func humanizeType(t string) string {
	replacer := strings.NewReplacer(
		"openapi_types.", "",
		"types.", "",
		"int64", "number",
		"float64", "number",
		"bool", "boolean",
	)
	return replacer.Replace(t)
}

// DecodeBodyRaw 與 DecodeBody 相同，但接受 *http.Request 以外的 io.Reader。
// 保留此方法供測試使用。
func DecodeBodyFromReader[T any](r io.Reader, dest *T) error {
	dec := json.NewDecoder(r)
	if err := dec.Decode(dest); err != nil {
		return buildDecodeError(err)
	}
	return nil
}
