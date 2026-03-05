# Go Code Style Guide

This isn’t about being right. It’s about writing Go code that your teammates don’t hate reviewing. Real engineers ship code that works and is easy to change.

Go already gives you constraints. Use them. Don’t fight the language.

---

## File Size

Keep files under 200 lines. If you cross that, you’re probably mixing concerns.

Split by what changes together. If two functions always change in the same PR, keep them together. If not, move them out.

Avoid `utils.go` dumping grounds. That’s not structure. That’s procrastination.

---

## Functions

Prefer pure functions. Same input, same output. No hidden state.

Bad:

```go
var counter int

func Increment() int {
	counter++ // hidden state
	return counter
}
```

Good:

```go
func Increment(counter int) int {
	return counter + 1
}
```

If a function needs state, pass it in. Return updated state. Don’t hide it in package-level variables.

Avoid mutating global state. Package-level vars are shared across goroutines. That’s how race conditions start.

### Idempotency

Call it once or ten times, result should be the same when possible.

Database writes can’t always be idempotent. Reads should be. HTTP handlers that create resources should support idempotency keys if the client retries.

File writes should check before overwriting if duplication matters.

---

## Comments

Most comments rot. Code changes. Comments don’t.

Write code that explains itself. Rename things. Extract functions. Reduce nesting.

When you comment, explain why.

Bad:

```go
// Loop through users and increment count
for _, user := range users {
	user.Count++
}
```

Good:

```go
// Totals were corrupted during migration, we recalculate from source of truth
for _, user := range users {
	user.Count = recalculateUserCount(user.ID)
}
```

Better:

```go
for _, user := range users {
	user.Count = recalculateUserCount(user.ID)
}
```

If it’s obvious, don’t comment.

### Comment Style

Talk to another Go developer. Keep it short.

Bad:

```go
// This function comprehensively processes user data and ensures
// robust validation across all input parameters.
```

Good:

```go
// Stripe webhook signature must be verified before trusting payload
```

Use active voice. Keep sentences tight. No fluff.

Never use:

- ensures
- robust
- comprehensive
- seamlessly
- leverages
- facilitates
- optimized
- critical (unless something can actually break production)

No em dashes. If the sentence feels long, split it.

No bullet lists inside code comments unless documenting a public API contract.

---

## Naming

Names should make comments unnecessary.

Bad:

```go
d := time.Now()
tmp := user.Email
flag := true
```

Good:

```go
now := time.Now()
userEmail := user.Email
isProcessing := true
```

Booleans start with:

- is
- has
- can
- should

```go
if isValid && hasPermission && !isProcessing {
	// do work
}
```

Don’t abbreviate unless it’s standard: ID, URL, HTTP, DB.

Go favors short names for short scopes:

```go
for i := 0; i < len(users); i++ {
	u := users[i]
}
```

Short scope, short name. Wide scope, clear name.

---

## Function Size

Functions should do one thing.

If you describe it with “and”, it does two things.

Aim for 5–20 lines. Over 50 lines is a smell. Over 100 lines is a problem.

Bad:

```go
func ProcessUser(ctx context.Context, user User) error {
	if user.Email == "" {
		return errors.New("missing email")
	}
	if user.Name == "" {
		return errors.New("missing name")
	}

	roles, err := getRoles(ctx, user.ID)
	if err != nil {
		return err
	}
	if !contains(roles, "admin") {
		return errors.New("unauthorized")
	}

	if err := updateLastLogin(ctx, user.ID); err != nil {
		return err
	}

	if err := sendEmail(user.Email); err != nil {
		return err
	}

	return logEvent(ctx, "user_login", user.ID)
}
```

Better:

```go
func ProcessUser(ctx context.Context, user User) error {
	if err := validateUser(user); err != nil {
		return err
	}

	if err := checkPermissions(ctx, user.ID); err != nil {
		return err
	}

	if err := recordLogin(ctx, user.ID); err != nil {
		return err
	}

	return notifyUser(user.Email)
}
```

Each helper is small and testable.

---

## Error Handling

Fail fast. Don’t catch errors you can’t handle.

Bad:

```go
result, err := fetchData()
if err != nil {
	log.Println("error fetching data")
	return nil
}
return result
```

Good:

```go
return fetchData()
```

If you add context, wrap it.

```go
result, err := fetchData()
if err != nil {
	return fmt.Errorf("fetch user %s: %w", userID, err)
}
return result, nil
```

Never ignore errors.

Bad:

```go
data, _ := fetchData()
```

If you see `_` swallowing an error, fix it.

---

## Types and Structs

Define structs that reflect your domain, not your database schema.

Validate at the boundary. Trust internally.

Example HTTP handler:

```go
func CreateUser(w http.ResponseWriter, r *http.Request) {
	var input CreateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	if err := input.Validate(); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	user, err := createUser(r.Context(), input)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	writeJSON(w, user)
}
```

Boundary validates. Internal logic assumes valid types.

---

## Concurrency

Don’t spawn goroutines casually. Every goroutine must have:

- A clear lifetime
- A way to stop
- Ownership of what it touches

Always pass `context.Context`. Honor cancellation.

Bad:

```go
go processUser(user)
```

Good:

```go
go func(u User) {
	if err := processUser(ctx, u); err != nil {
		logger.Println(err)
	}
}(user)
```

Better: use worker pools or structured concurrency patterns instead of fire-and-forget.

Never share mutable state across goroutines without synchronization. Use channels or `sync.Mutex`. Run `go test -race`.

---

## Interfaces

Define interfaces where you use them, not where you implement them.

Bad:

```go
type UserService interface {
	Create(User) error
	Get(string) (User, error)
}
```

Defined in the same package that implements it for no reason.

Good:

```go
type userStore interface {
	Save(User) error
	FindByID(string) (User, error)
}
```

Small interface. Defined by the consumer.

If your interface has more than 3–4 methods, it’s probably too big.

---

## Testing

Tests document behavior.

Test outcomes, not internal calls.

Bad:

```go
mockStore.AssertCalled(t, "Save")
```

Good:

```go
err := service.Create(user)
if err != nil {
	t.Fatal(err)
}
```

Use table-driven tests.

```go
func TestIncrement(t *testing.T) {
	tests := []struct {
		input int
		want  int
	}{
		{1, 2},
		{0, 1},
		{-1, 0},
	}

	for _, tt := range tests {
		got := Increment(tt.input)
		if got != tt.want {
			t.Fatalf("got %d, want %d", got, tt.want)
		}
	}
}
```

Pure functions are easy to test. This is not a coincidence.

---

## Imports

Group imports:

1. Standard library
2. Third-party
3. Internal packages

Separate groups with blank lines.

```go
import (
	"context"
	"fmt"
	"net/http"

	"github.com/go-chi/chi/v5"

	"yourapp/internal/user"
)
```

Run `go fmt`. Always.

---

## Package Structure

One package, one responsibility.

Bad:

```
internal/
  utils/
    utils.go
```

Good:

```
internal/
  user/
  auth/
  email/
```

Name packages after what they do, not what they are.

Avoid circular dependencies. If two packages depend on each other, your boundaries are wrong.

---

## Constants

Constants at the top of the file.

Use ALL_CAPS only for true global constants. Otherwise, CamelCase.

```go
const MaxUsersPerPage = 100
```

No magic numbers.

Bad:

```go
if len(users) > 100 {
	return users[:100]
}
```

Good:

```go
const MaxUsersPerPage = 100

if len(users) > MaxUsersPerPage {
	return users[:MaxUsersPerPage]
}
```

---

## Logging

Log at the edge. Not everywhere.

Don’t log and return the same error. That creates duplicate logs.

Bad:

```go
if err != nil {
	log.Println(err)
	return err
}
```

Let the caller decide whether to log.

---

## Code Review Checklist

Before pushing:

- File under 200 lines?
- Functions under 50 lines?
- No hidden global state?
- Clear ownership of goroutines?
- Errors wrapped with context?
- No ignored errors?
- Names obvious without comments?
- Comments explain why?
- Small interfaces?
- No magic numbers?
- `go fmt` run?
- `go test -race` clean?

If you can’t check most of these, you’re not done.
