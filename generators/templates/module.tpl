package {{.ModulePluralLowercase}}

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	configs "{{.PackageName}}/configs"
	events "{{.PackageName}}/events"
	handlers "{{.PackageName}}/handlers"
	paginations "{{.PackageName}}/paginations"
	grpcs "{{.PackageName}}/protos/builds"
	models "{{.PackageName}}/{{.ModulePluralLowercase}}/models"
	validations "{{.PackageName}}/{{.ModulePluralLowercase}}/validations"
	utils "{{.PackageName}}/utils"
	uuid "github.com/google/uuid"
	copier "github.com/jinzhu/copier"
)

type Module struct {
	Handler   *handlers.Handler
	Logger    *handlers.Logger
	Messenger *handlers.Messenger
	Validator *validations.{{.Module}}
	Cache     *utils.Cache
	Paginator *paginations.Pagination
}

func NewModule(
	dispatcher *events.Dispatcher,
	service configs.Service,
	logger *handlers.Logger,
	messenger *handlers.Messenger,
	handler *handlers.Handler,
	validator *validations.{{.Module}},
	cache *utils.Cache,
	paginator *paginations.Pagination,
) *Module {
	handler.SetService(service)

	return &Module{
		Handler:   handler,
		Logger:    logger,
		Messenger: messenger,
		Validator: validator,
		Cache:     cache,
		Paginator: paginator,
	}
}

func (m *Module) GetPaginated(c context.Context, r *grpcs.Pagination) (*grpcs.{{.Module}}PaginatedResponse, error) {
	m.Logger.Info(fmt.Sprintf("%+v", r))

	m.Paginator.Handle(r)

	metadata, result := m.Handler.Paginate(*m.Paginator)
	records := []*grpcs.Todo{}
	record := &grpcs.Todo{}

	model := models.Todo{}
	for _, v := range result {
		data, _ := json.Marshal(v)
		json.Unmarshal(data, &model)
		copier.Copy(&v, &model)
		records = append(records, record)
	}

	return &grpcs.{{.Module}}PaginatedResponse{
		Code: http.StatusOK,
		Data: records,
		Meta: &grpcs.PaginationMetadata{
			Record:   int32(metadata.Record),
			Page:     int32(metadata.Page),
			Previous: int32(metadata.Previous),
			Next:     int32(metadata.Next),
			Limit:    int32(metadata.Limit),
			Total:    int32(metadata.Total),
		},
	}, nil
}

func (m *Module) Create(c context.Context, r *grpcs.{{.Module}}) (*grpcs.{{.Module}}Response, error) {
	m.Logger.Info(fmt.Sprintf("%+v", r))

	v := models.{{.Module}}{}
	copier.Copy(&v, &r)

	ok, err := m.Validator.Validate(&v)
	if !ok {
		m.Logger.Info(fmt.Sprintf("%+v", err))
		return &grpcs.{{.Module}}Response{
			Code:    http.StatusBadRequest,
			Data:    r,
			Message: err.Error(),
		}, nil
	}

	err = m.Handler.Create(&v, uuid.New().String())
	if err != nil {
		return &grpcs.{{.Module}}Response{
			Code:    http.StatusBadRequest,
			Data:    r,
			Message: err.Error(),
		}, nil
	}

	r.Id = v.Id

	return &grpcs.{{.Module}}Response{
		Code: http.StatusCreated,
		Data: r,
	}, nil
}

func (m *Module) Update(c context.Context, r *grpcs.{{.Module}}) (*grpcs.{{.Module}}Response, error) {
	m.Logger.Info(fmt.Sprintf("%+v", r))

	v := models.{{.Module}}{}
	copier.Copy(&v, &r)

	ok, err := m.Validator.Validate(&v)
	if !ok {
		m.Logger.Info(fmt.Sprintf("%+v", err))
		return &grpcs.{{.Module}}Response{
			Code:    http.StatusBadRequest,
			Data:    r,
			Message: err.Error(),
		}, nil
	}

	err = m.Handler.Bind(&models.{{.Module}}{}, r.Id)
	if err != nil {
		m.Logger.Info(fmt.Sprintf("Data with ID '%s' Not found.", r.Id))

		return &grpcs.{{.Module}}Response{
			Code:    http.StatusNotFound,
			Data:    nil,
			Message: err.Error(),
		}, nil
	}

	data, _ := json.Marshal(v)
	err = m.Messenger.Publish(v.TableName(), data)
	if err != nil {
		m.Logger.Error(fmt.Sprintf("%+v", err))
	}

	return &grpcs.{{.Module}}Response{
		Code: http.StatusOK,
		Data: r,
	}, nil
}

func (m *Module) Get(c context.Context, r *grpcs.{{.Module}}) (*grpcs.{{.Module}}Response, error) {
	m.Logger.Info(fmt.Sprintf("%+v", r))

	var v models.{{.Module}}

	data, found := m.Cache.Get(r.Id)
	if found {
		v = data.(models.{{.Module}})
	} else {
		err := m.Handler.Bind(&v, r.Id)
		if err != nil {
			m.Logger.Info(fmt.Sprintf("Data with ID '%s' Not found.", r.Id))

			return &grpcs.{{.Module}}Response{
				Code:    http.StatusNotFound,
				Data:    nil,
				Message: err.Error(),
			}, nil
		}

		m.Cache.Set(r.Id, &v)
	}

	copier.Copy(&r, &v)

	return &grpcs.{{.Module}}Response{
		Code: http.StatusOK,
		Data: r,
	}, nil
}

func (m *Module) Delete(c context.Context, r *grpcs.{{.Module}}) (*grpcs.{{.Module}}Response, error) {
	m.Logger.Info(fmt.Sprintf("%+v", r))

	v := models.{{.Module}}{}

	err := m.Handler.Delete(&v, r.Id)
	if err != nil {
		m.Logger.Info(fmt.Sprintf("Data with ID '%s' Not found.", r.Id))

		return &grpcs.{{.Module}}Response{
			Code:    http.StatusNotFound,
			Data:    nil,
			Message: err.Error(),
		}, nil
	}

	return &grpcs.{{.Module}}Response{
		Code: http.StatusNoContent,
		Data: nil,
	}, nil
}

func (m *Module) Consume() {
	v := models.{{.Module}}{}
	messages, err := m.Messenger.Consume(v.TableName())
	if err != nil {
		m.Logger.Error(fmt.Sprintf("%+v", err))
	}

	for message := range messages {
		json.Unmarshal(message.Payload, &v)

		m.Logger.Info(fmt.Sprintf("%+v", v))

		err := m.Handler.Update(&v, v.Id)
		if err != nil {
			m.Logger.Error(fmt.Sprintf("%+v", err))
		}

		message.Ack()
	}
}
