package events

import (
	paginations "github.com/crowdeco/skeleton/paginations"
	elastic "github.com/olivere/elastic/v7"
)

type PaginationEvent struct {
	service string
	query   *elastic.BoolQuery
	filters []paginations.Filter
}

func NewPaginationEvent(service string, query *elastic.BoolQuery, filters []paginations.Filter) *PaginationEvent {
	return &PaginationEvent{
		query:   query,
		filters: filters,
	}
}

func (e *PaginationEvent) Query() *elastic.BoolQuery {
	return e.query
}

func (e *PaginationEvent) Filters() []paginations.Filter {
	return e.filters
}

func (e *PaginationEvent) Service() string {
	return e.service
}
