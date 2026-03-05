# Go Engineering Style Guide (Compact)

## 1. Principles

Write Go that is:

```
Simple
Readable
Explicit
Composable
```

Prefer:

```
clarity > cleverness
composition > inheritance
small interfaces > large interfaces
```

---

# 2. Project Layout

Use a simple, predictable structure.

```
cmd/        application entrypoints
internal/   private application code
pkg/        reusable libraries
api/        contracts / proto / schemas
configs/    configuration
```

Example:

```
cmd/server/main.go

internal/user/
    handler.go
    service.go
    repository.go
    model.go
```

Rules:

* `internal/` = private packages
* avoid deep nesting
* organize by **domain**, not by layer

Bad:

```
controllers/
services/
repositories/
```

Good:

```
user/
payment/
auth/
```

---

# 3. Package Rules

Packages should:

```
be small
have one responsibility
avoid cycles
```

Bad:

```
utils
helpers
common
misc
```

Prefer domain packages:

```
auth
user
payment
email
```

---

# 4. Naming

## Packages

```
lowercase
no underscores
short
```

Good

```
auth
server
store
config
```

---

## Variables

Prefer short meaningful names.

```
user
req
ctx
cfg
err
```

Loop variables:

```
i j k
```

---

## Interfaces

Use `-er` pattern when possible.

```
Reader
Writer
Logger
Notifier
```

Example:

```go
type UserRepository interface {
	GetUser(ctx context.Context, id string) (*User, error)
}
```

Keep interfaces **small**.

---

# 5. Formatting

Always format code with:

```
gofmt
go fmt ./...
```

Imports grouped:

```go
import (
	"context"
	"fmt"

	"github.com/google/uuid"
)
```

Never manually format Go.

---

# 6. Variables

Prefer short declaration.

```go
name := "sameer"
count := 10
```

Use `var` only when needed.

```go
var err error
```

Avoid unused variables.

---

# 7. Functions

Functions should:

```
do one thing
be small
be readable
```

Avoid large functions.

Bad

```
200 line handler
```

Better

```
parseRequest
validateRequest
processUser
```

---

# 8.5 Pointers

Use pointers **only when needed**.

Use a pointer when:

```
the value must be mutated
the struct is large
nil is a meaningful state
shared ownership is required
```

Example:

```go
type User struct {
	ID   string
	Name string
}

func UpdateName(u *User, name string) {
	u.Name = name
}
```

Prefer **values for small structs**.

Good

```go
func PrintUser(u User)
```

Avoid pointer overuse.

Bad

```go
type Config struct {
	Port *int
}
```

Good

```go
type Config struct {
	Port int
}
```

### Method Receivers

Use pointer receivers when the method **modifies state**.

```go
func (u *User) SetName(name string) {
	u.Name = name
}
```

Use value receivers for **read-only methods**.

```go
func (u User) IsAdmin() bool
```

---

# 8.6 When NOT to Use Interfaces

Do **not** introduce interfaces prematurely.

Avoid interfaces when:

```
there is only one implementation
the interface is used in only one package
it exists only for testing
```

Bad:

```go
type UserService interface {
	CreateUser(ctx context.Context, u User) error
}
```

Better:

```go
type Service struct {
	repo Repository
}
```

Create interfaces **at the consumer boundary**, not the provider.

Example:

```go
type UserStore interface {
	GetUser(ctx context.Context, id string) (*User, error)
}
```

Rule:

```
interfaces belong to the package that uses them
```

---

# 8. Struct Design

Structs represent data models.

```go
type User struct {
	ID    string
	Name  string
	Email string
}
```

Prefer composition.

```go
type Service struct {
	repo UserRepository
}
```

Avoid deep embedding.

---

# 9. Error Handling

Errors are **values**.

Always handle them.

```go
user, err := repo.GetUser(ctx, id)
if err != nil {
	return nil, err
}
```

Never ignore errors.

Bad

```go
user, _ := repo.GetUser(...)
```

---

## Error Wrapping

Use wrapping.

```go
return fmt.Errorf("fetch user: %w", err)
```

---

## Sentinel Errors

```go
var ErrUserNotFound = errors.New("user not found")
```

Check using:

```go
errors.Is(err, ErrUserNotFound)
```

---

# 10. Context Usage

Rules:

```
ctx is first parameter
ctx must propagate
never store ctx in struct
never use context.Background in handlers
```

Example:

```go
func GetUser(ctx context.Context, id string)
```

---

# 11. Dependency Injection

Prefer constructor injection.

```go
type Service struct {
	repo Repository
}
```

Constructor:

```go
func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}
```

Avoid globals.

---

# 12. Concurrency

Use goroutines carefully.

Example:

```go
go processJob(job)
```

Use synchronization:

```
WaitGroup
channels
context cancellation
```

Avoid shared mutable state.

---

# 13. Logging

Do not use `fmt.Println` in production.

Prefer structured logging.

Examples:

```
slog
zap
zerolog
```

Example:

```go
logger.Info("user created", "id", user.ID)
```

---

# 14. Testing

Tests live in:

```
*_test.go
```

Example:

```
user_test.go
```

Test naming:

```
TestCreateUser
TestLogin
```

---

## Table Tests

Preferred pattern.

```go
tests := []struct{
	name string
	in int
	want int
}{
	{"double 2",2,4},
}

for _,tt := range tests {
	t.Run(tt.name, func(t *testing.T){
		if Double(tt.in) != tt.want {
			t.Fatal()
		}
	})
}
```

---

# 15. Documentation

Public functions require GoDoc comments.

```go
// CreateUser creates a new user.
func CreateUser(name string) *User
```

---

# 16. Modules

Always use Go modules.

```
go mod init
go mod tidy
```

Pin dependencies.

Avoid unnecessary packages.

---

# 17. Linting

Use:

```
golangci-lint
```

Recommended rules:

```
govet
staticcheck
errcheck
ineffassign
```

---

# 18. Security Basics

Always validate:

```
input
headers
JSON payloads
```

Never store plain passwords.

Use:

```
bcrypt
argon2
```

---

# 19. Performance

Prefer:

```
[]T over []*T
values over pointers (unless mutation needed)
avoid unnecessary allocations
```

Measure before optimizing.

---

# 20. Go Proverbs

Follow Go philosophy:

```
Clear is better than clever
Don't communicate by sharing memory
Share memory by communicating
```

---

# Final Rule

If your Go code requires **many comments to explain**, rewrite it.

Good Go code should be **obvious**.


