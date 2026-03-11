package handler

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/middleware"
	"summitmate/internal/model"
	"summitmate/internal/service"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

type PollHandler struct {
	service *service.PollService
}

func NewPollHandler(service *service.PollService) *PollHandler {
	return &PollHandler{service: service}
}

func (h *PollHandler) ListTripPolls(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	polls, err := h.service.ListTripPolls(r.Context(), tripID.String(), userID)
	if err != nil {
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "無法取得投票活動")
		return
	}

	resp := make([]api.Poll, len(polls))
	for i, p := range polls {
		resp[i] = mapToAPIPoll(p)
	}
	sendJSON(w, http.StatusOK, resp)
}

func (h *PollHandler) CreateTripPoll(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	var req api.PollRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數錯誤")
		return
	}

	poll := &model.Poll{
		Title:              req.Title,
		Description:        req.Description,
		IsAllowAddOption:   req.IsAllowAddOption != nil && *req.IsAllowAddOption,
		MaxOptionLimit:     20,
		AllowMultipleVotes: req.AllowMultipleVotes != nil && *req.AllowMultipleVotes,
		ResultDisplayType:  "realtime",
	}

	if req.Deadline != nil {
		poll.Deadline = req.Deadline
	}
	if req.MaxOptionLimit != nil {
		poll.MaxOptionLimit = *req.MaxOptionLimit
	}
	if req.ResultDisplayType != nil {
		poll.ResultDisplayType = *req.ResultDisplayType
	}

	created, err := h.service.CreateTripPoll(r.Context(), tripID.String(), userID, poll)
	if err != nil {
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "建立投票活動失敗")
		return
	}

	sendJSON(w, http.StatusCreated, mapToAPIPoll(created))
}

func (h *PollHandler) GetTripPoll(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, pollID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	poll, err := h.service.GetTripPoll(r.Context(), tripID.String(), pollID.String(), userID)
	if err != nil {
		if err == service.ErrNotFound {
			sendErrorResponse(w, http.StatusNotFound, "找不到投票活動")
			return
		}
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "查詢失敗")
		return
	}
	sendJSON(w, http.StatusOK, mapToAPIPoll(poll))
}

func (h *PollHandler) DeleteTripPoll(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, pollID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	err := h.service.DeleteTripPoll(r.Context(), tripID.String(), pollID.String(), userID)
	if err != nil {
		if err == service.ErrNotFound {
			sendErrorResponse(w, http.StatusNotFound, "找不到投票活動")
			return
		}
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "刪除失敗")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *PollHandler) AddPollOption(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, pollID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	var req api.PollOptionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數錯誤")
		return
	}

	poll, err := h.service.AddPollOption(r.Context(), tripID.String(), pollID.String(), userID, req.Text)
	if err != nil {
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "新增選項失敗")
		return
	}
	sendJSON(w, http.StatusCreated, mapToAPIPoll(poll))
}

func (h *PollHandler) VotePollOption(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, pollID openapi_types.UUID, optionID openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未授權")
		return
	}

	poll, err := h.service.VoteOption(r.Context(), tripID.String(), pollID.String(), optionID.String(), userID)
	if err != nil {
		if err == service.ErrNotFound {
			sendErrorResponse(w, http.StatusNotFound, "找不到投票活動的選項或活動已結束")
			return
		}
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "投票失敗")
		return
	}
	sendJSON(w, http.StatusOK, mapToAPIPoll(poll))
}

func mapToAPIPoll(p *model.Poll) api.Poll {
	options := make([]api.PollOption, len(p.Options))
	for i, opt := range p.Options {
		votersList := make([]openapi_types.UUID, len(opt.Voters))
		for j, v := range opt.Voters {
			votersList[j] = toOpenAPIUUID(v)
		}

		options[i] = api.PollOption{
			Id:        toOpenAPIUUID(opt.ID),
			PollId:    toOpenAPIUUID(opt.PollID),
			Text:      opt.Text,
			CreatorId: toOpenAPIUUID(opt.CreatorID),
			VoteCount: opt.VoteCount,
			Voters:    &votersList,
		}
	}

	updatedAt := toOpenAPITime(p.UpdatedAt)

	return api.Poll{
		Id:                 toOpenAPIUUID(p.ID),
		TripId:             toOpenAPIUUID(p.TripID),
		Title:              p.Title,
		Description:        p.Description,
		CreatorId:          toOpenAPIUUID(p.CreatorID),
		Deadline:           p.Deadline,
		IsAllowAddOption:   p.IsAllowAddOption,
		MaxOptionLimit:     p.MaxOptionLimit,
		AllowMultipleVotes: p.AllowMultipleVotes,
		ResultDisplayType:  p.ResultDisplayType,
		Status:             p.Status,
		Options:            options,
		CreatedAt:          toOpenAPITime(p.CreatedAt),
		UpdatedAt:          &updatedAt,
	}
}
