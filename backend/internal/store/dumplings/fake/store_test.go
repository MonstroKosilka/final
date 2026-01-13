package fake

import (
	"context"
	"reflect"
	"testing"

	"github.com/MonstroKosilka/final/backend/internal/store/dumplings"
)

func TestCreateOrder_IncrementsID(t *testing.T) {
	s := NewStore()

	id1, err := s.CreateOrder(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	id2, err := s.CreateOrder(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if id1 != 1 || id2 != 2 {
		t.Fatalf("expected ids 1 and 2, got %d and %d", id1, id2)
	}
}

func TestListProducts_ReturnsAvailablePacks(t *testing.T) {
	s := NewStore()

	expected := []dumplings.Product{
		{ID: 1, Name: "Momo", Price: 5},
		{ID: 2, Name: "Khinkali", Price: 3.5},
	}
	s.SetAvailablePacks(expected...)

	got, err := s.ListProducts(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !reflect.DeepEqual(got, expected) {
		t.Fatalf("products mismatch\nexpected: %#v\ngot: %#v", expected, got)
	}
}
