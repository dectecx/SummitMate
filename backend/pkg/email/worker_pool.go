package email

import (
	"context"
	"log/slog"
	"sync"
	"time"
)

// mailTask bundles a timeout and the work function for one outbound email.
type mailTask struct {
	timeout time.Duration
	fn      func(ctx context.Context) error
}

// WorkerPool is a bounded goroutine pool for background email delivery.
//
// Workers pull tasks from an internal buffered channel.  When the channel is
// full, Submit drops the task and returns false instead of spawning an
// unbounded goroutine.  Call Shutdown to drain all pending tasks before
// process exit.
type WorkerPool struct {
	tasks  chan mailTask
	wg     sync.WaitGroup
	logger *slog.Logger
}

// NewWorkerPool starts workers goroutines backed by a buffered channel of
// size queueCapacity and returns a ready pool.
func NewWorkerPool(workers, queueCapacity int, logger *slog.Logger) *WorkerPool {
	p := &WorkerPool{
		tasks:  make(chan mailTask, queueCapacity),
		logger: logger,
	}
	for range workers {
		p.wg.Add(1)
		go p.run()
	}
	return p
}

func (p *WorkerPool) run() {
	defer p.wg.Done()
	for task := range p.tasks {
		ctx, cancel := context.WithTimeout(context.Background(), task.timeout)
		if err := task.fn(ctx); err != nil {
			p.logger.Error("background mail task failed", "error", err)
		}
		cancel()
	}
}

// Submit enqueues a mail task.  Returns false without blocking when the
// channel is at capacity; the caller is responsible for logging the drop.
func (p *WorkerPool) Submit(timeout time.Duration, fn func(ctx context.Context) error) bool {
	select {
	case p.tasks <- mailTask{timeout: timeout, fn: fn}:
		return true
	default:
		return false
	}
}

// Shutdown closes the task channel and blocks until all in-flight tasks finish.
// No new tasks may be submitted after Shutdown is called.
func (p *WorkerPool) Shutdown() {
	close(p.tasks)
	p.wg.Wait()
}
