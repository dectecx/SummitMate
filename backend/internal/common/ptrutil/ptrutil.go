package ptrutil

// SafeGet returns the value pointed to by ptr if it is not nil.
// Otherwise, it returns the zero value of type T.
func SafeGet[T any](ptr *T) T {
	if ptr == nil {
		var zero T
		return zero
	}
	return *ptr
}

// SafeGetDefault returns the value pointed to by ptr if it is not nil.
// Otherwise, it returns the provided default value.
func SafeGetDefault[T any](ptr *T, def T) T {
	if ptr == nil {
		return def
	}
	return *ptr
}

// AssignIfPresent assigns the value pointed to by src to dest if src is not nil.
func AssignIfPresent[T any](dest *T, src *T) {
	if src != nil && dest != nil {
		*dest = *src
	}
}

// AssignPtrIfPresent assigns src to dest if src is not nil.
func AssignPtrIfPresent[T any](dest **T, src *T) {
	if src != nil && dest != nil {
		*dest = src
	}
}
