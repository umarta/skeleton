package middlewares

import (
	"net/http"

	configs "github.com/crowdeco/skeleton/configs"
)

type Auth struct {
	Env *configs.Env
}

func (a *Auth) Attach(request *http.Request, response http.ResponseWriter) bool {
	a.Env.User.ID = request.Header.Get(a.Env.HeaderUserId)
	a.Env.User.Email = request.Header.Get(a.Env.HeaderUserEmail)
	a.Env.User.Role = request.Header.Get(a.Env.HeaderUserRole)

	return false
}
