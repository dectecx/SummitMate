package email

import (
	"context"
	"io"
	"log/slog"
	"sync"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func discardLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(io.Discard, nil))
}

func TestWorkerPool(t *testing.T) {
	t.Run("Given a submitted task, When a worker is available, Then the task is executed", func(t *testing.T) {
		pool := NewWorkerPool(1, 10, discardLogger())
		t.Cleanup(pool.Shutdown)

		done := make(chan struct{})
		ok := pool.Submit(time.Second, func(_ context.Context) error {
			close(done)
			return nil
		})

		require.True(t, ok)
		select {
		case <-done:
		case <-time.After(2 * time.Second):
			t.Fatal("task was not executed within timeout")
		}
	})

	t.Run("Given a full queue, When submitting, Then it returns false without blocking", func(t *testing.T) {
		gate := make(chan struct{})
		pool := NewWorkerPool(1, 2, discardLogger())

		started := make(chan struct{}, 1)
		// First task occupies the single worker until the gate opens.
		ok1 := pool.Submit(time.Minute, func(_ context.Context) error {
			started <- struct{}{}
			<-gate
			return nil
		})
		require.True(t, ok1)
		<-started // ensure the worker is truly inside the task

		blockingFn := func(_ context.Context) error {
			<-gate
			return nil
		}

		// Fill the buffer (capacity = 2).
		require.True(t, pool.Submit(time.Minute, blockingFn))
		require.True(t, pool.Submit(time.Minute, blockingFn))

		// Buffer is now full; this submit must be dropped.
		ok := pool.Submit(time.Second, func(_ context.Context) error { return nil })
		assert.False(t, ok)

		close(gate)
		pool.Shutdown()
	})

	t.Run("Given an in-flight task, When shutting down, Then it blocks until the task finishes", func(t *testing.T) {
		pool := NewWorkerPool(1, 10, discardLogger())

		started := make(chan struct{})
		finished := make(chan struct{})

		ok := pool.Submit(time.Second, func(_ context.Context) error {
			close(started)
			time.Sleep(50 * time.Millisecond)
			close(finished)
			return nil
		})
		require.True(t, ok)
		<-started

		shutdownDone := make(chan struct{})
		go func() {
			pool.Shutdown()
			close(shutdownDone)
		}()

		select {
		case <-shutdownDone:
			select {
			case <-finished:
			default:
				t.Fatal("Shutdown returned before the in-flight task finished")
			}
		case <-time.After(500 * time.Millisecond):
			t.Fatal("Shutdown did not return within expected time")
		}
	})

	t.Run("Given a timeout, When the task runs, Then its context is cancelled with DeadlineExceeded", func(t *testing.T) {
		pool := NewWorkerPool(1, 10, discardLogger())
		t.Cleanup(pool.Shutdown)

		var gotErr error
		done := make(chan struct{})

		ok := pool.Submit(20*time.Millisecond, func(ctx context.Context) error {
			defer close(done)
			<-ctx.Done()
			gotErr = ctx.Err()
			return gotErr
		})
		require.True(t, ok)

		select {
		case <-done:
		case <-time.After(time.Second):
			t.Fatal("task ctx was not cancelled after timeout")
		}
		assert.ErrorIs(t, gotErr, context.DeadlineExceeded)
	})

	t.Run("Given multiple workers, When submitting multiple tasks, Then they run concurrently", func(t *testing.T) {
		const workers = 3
		pool := NewWorkerPool(workers, workers, discardLogger())
		t.Cleanup(pool.Shutdown)

		var mu sync.Mutex
		var cur, maxSeen int
		var wg sync.WaitGroup

		for range workers {
			wg.Add(1)
			pool.Submit(time.Second, func(_ context.Context) error {
				defer wg.Done()

				mu.Lock()
				cur++
				if cur > maxSeen {
					maxSeen = cur
				}
				mu.Unlock()

				time.Sleep(30 * time.Millisecond)

				mu.Lock()
				cur--
				mu.Unlock()

				return nil
			})
		}

		wg.Wait()
		assert.Equal(t, workers, maxSeen, "all workers should run concurrently")
	})

	t.Run("Given a task that returns an error, When it runs, Then the pool does not panic", func(t *testing.T) {
		pool := NewWorkerPool(1, 10, discardLogger())
		t.Cleanup(pool.Shutdown)

		done := make(chan struct{})
		require.NotPanics(t, func() {
			pool.Submit(time.Second, func(_ context.Context) error {
				defer close(done)
				return assert.AnError
			})
			<-done
		})
	})
}

func TestEmailServiceAsync(t *testing.T) {
	t.Run("Given no worker pool, When calling SubmitAsync, Then it returns false", func(t *testing.T) {
		svc := NewEmailService(nil, nil)
		ok := svc.SubmitAsync(time.Second, func(_ context.Context) error { return nil })
		assert.False(t, ok)
	})

	t.Run("Given no worker pool, When calling Shutdown, Then it does not panic", func(t *testing.T) {
		svc := NewEmailService(nil, nil)
		require.NotPanics(t, svc.Shutdown)
	})

	t.Run("Given a worker pool, When calling SubmitAsync, Then it delegates to the pool and runs the task", func(t *testing.T) {
		pool := NewWorkerPool(1, 10, discardLogger())
		svc := NewEmailServiceWithPool(nil, nil, pool, discardLogger())
		t.Cleanup(svc.Shutdown)

		done := make(chan struct{})
		ok := svc.SubmitAsync(time.Second, func(_ context.Context) error {
			close(done)
			return nil
		})
		require.True(t, ok)
		select {
		case <-done:
		case <-time.After(2 * time.Second):
			t.Fatal("task submitted via SubmitAsync was not executed")
		}
	})
}
