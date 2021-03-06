package configs

import (
	"context"
	"net/http"

	"google.golang.org/grpc"
	"gorm.io/gorm"
)

type (
	Driver interface {
		Connect(host string, port int, user string, password string, dbname string, debug bool) *gorm.DB
	}

	Listener interface {
		Handle(event interface{})
		Listen() string
	}

	Model interface {
		TableName() string
		SetCreatedBy(user *User)
		SetUpdatedBy(user *User)
		SetDeletedBy(user *User)
		IsSoftDelete() bool
	}

	Service interface {
		Name() string
		Create(value interface{}, id string) error
		Update(value interface{}, id string) error
		Bind(value interface{}, id string) error
		Delete(value interface{}, id string) error
		All(value interface{}) error
	}

	Module interface {
		Consume()
	}

	Server interface {
		RegisterGRpc(server *grpc.Server)
		RegisterAutoMigrate()
		RegisterQueueConsumer()
	}

	Router interface {
		Handle(context context.Context, server *http.ServeMux, client *grpc.ClientConn) *http.ServeMux
	}

	Middleware interface {
		Attach(request *http.Request, response http.ResponseWriter) bool
	}

	Application interface {
		Run()
	}
)
