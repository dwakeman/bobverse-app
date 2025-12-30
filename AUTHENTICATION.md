# Bobverse API Authentication Implementation

The Bobverse API implements a **JWT (JSON Web Token) based authentication system** with secure password hashing and flexible authentication patterns.

## 🔐 Authentication Flow

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant AuthService
    participant TokenService
    participant PasswordService
    participant Database

    Note over Client,Database: Registration Flow
    Client->>API: POST /users (email, password, username)
    API->>AuthService: sign_up_user()
    AuthService->>PasswordService: get_password_hash(password)
    PasswordService-->>AuthService: bcrypt hashed password
    AuthService->>Database: Create user with hashed password
    Database-->>AuthService: User created
    AuthService->>TokenService: generate_jwt_token(user)
    TokenService-->>AuthService: JWT token (7 day expiry)
    AuthService-->>API: CreatedUserDTO + token
    API-->>Client: User data + JWT token

    Note over Client,Database: Login Flow
    Client->>API: POST /users/login (email, password)
    API->>AuthService: sign_in_user()
    AuthService->>Database: Get user by email
    Database-->>AuthService: User record
    AuthService->>PasswordService: verify_password(plain, hashed)
    PasswordService-->>AuthService: Password valid ✓
    AuthService->>TokenService: generate_jwt_token(user)
    TokenService-->>AuthService: JWT token
    AuthService-->>API: LoggedInUserDTO + token
    API-->>Client: User data + JWT token

    Note over Client,Database: Protected Request Flow
    Client->>API: GET /user<br/>Authorization: Token xxx
    API->>TokenService: parse_jwt_token(token)
    TokenService->>TokenService: Validate signature & expiration
    TokenService-->>API: TokenPayloadDTO (user_id, username)
    API->>Database: Get user by user_id
    Database-->>API: User record
    API-->>Client: Protected resource
```

### Registration Flow
1. Client sends POST request to `/users` with email, password, and username
2. `AuthService.sign_up_user()` creates user with bcrypt-hashed password
3. `AuthTokenService.generate_jwt_token()` creates JWT token
4. API returns user data with JWT token

### Login Flow
1. Client sends POST request to `/users/login` with email and password
2. `AuthService.sign_in_user()` retrieves user by email
3. Password verified using bcrypt via `verify_password()`
4. JWT token generated for authenticated user
5. API returns user data with JWT token

### Protected Request Flow
1. Client includes JWT in Authorization header: `Token xxx` or `Bearer xxx`
2. `HTTPTokenHeader` extracts and validates token format
3. `AuthTokenService.parse_jwt_token()` validates and decodes JWT
4. User fetched from database using `user_id` from token payload
5. Protected resource returned to authenticated user

## 🔑 Key Components

### 1. Password Hashing (`bobverse/services/password.py`)

Uses **bcrypt** via `passlib.context.CryptContext` for secure password hashing:

```python
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    """Convert user password to hash string."""
    return pwd_context.hash(secret=password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Check if the user password from request is valid."""
    return pwd_context.verify(secret=plain_password, hash=hashed_password)
```

**Security Features:**
- Industry-standard bcrypt algorithm
- Automatic salt generation
- Configurable work factor for future-proofing

### 2. JWT Token Service (`bobverse/services/auth_token.py`)

Handles JWT token generation and validation:

```python
class AuthTokenService(IAuthTokenService):
    def __init__(self, secret_key: str, token_expiration_minutes: int, algorithm: str):
        self._secret_key = secret_key
        self._algorithm = algorithm  # HS256
        self._token_expiration_minutes = token_expiration_minutes  # 7 days default

    def generate_jwt_token(self, user: UserDTO) -> str:
        expire = datetime.now() + timedelta(minutes=self._token_expiration_minutes)
        payload = {"user_id": user.id, "username": user.username, "exp": expire}
        return jwt.encode(payload, self._secret_key, algorithm=self._algorithm)

    def parse_jwt_token(self, token: str) -> TokenPayloadDTO:
        try:
            payload = jwt.decode(token, self._secret_key, algorithms=[self._algorithm])
        except jwt.InvalidTokenError as err:
            raise IncorrectJWTTokenException()
        return TokenPayloadDTO(user_id=payload["user_id"], username=payload["username"])
```

**Configuration:**
- **Algorithm**: HS256 (HMAC with SHA-256)
- **Token Expiration**: 7 days (configurable via `jwt_token_expiration_minutes`)
- **Token Payload**: Contains `user_id`, `username`, and `exp` (expiration timestamp)

### 3. Authentication Service (`bobverse/services/auth.py`)

Orchestrates user authentication operations:

**Registration** (`sign_up_user()`):
```python
async def sign_up_user(self, session: AsyncSession, user_to_create: CreateUserDTO) -> CreatedUserDTO:
    user = await self._user_service.create_user(session=session, user_to_create=user_to_create)
    jwt_token = self._auth_token_service.generate_jwt_token(user=user)
    return CreatedUserDTO(
        id=user.id,
        email=user.email,
        username=user.username,
        bio=user.bio,
        image=user.image_url,
        token=jwt_token,
    )
```

**Login** (`sign_in_user()`):
```python
async def sign_in_user(self, session: AsyncSession, user_to_login: LoginUserDTO) -> LoggedInUserDTO:
    try:
        user = await self._user_service.get_user_by_email(session=session, email=user_to_login.email)
    except UserNotFoundException:
        raise IncorrectLoginInputException()

    if not verify_password(plain_password=user_to_login.password, hashed_password=user.password_hash):
        raise IncorrectLoginInputException()

    jwt_token = self._auth_token_service.generate_jwt_token(user=user)
    return LoggedInUserDTO(
        email=user.email,
        username=user.username,
        bio=user.bio,
        image=user.image_url,
        token=jwt_token,
    )
```

### 4. Token Extraction (`bobverse/core/security.py`)

Custom `HTTPTokenHeader` class for extracting JWT tokens from Authorization header:

```python
class HTTPTokenHeader(APIKeyHeader):
    def __init__(self, raise_error: bool, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.raise_error = raise_error

    async def __call__(self, request: Request) -> str | None:
        api_key = request.headers.get(self.model.name)
        if not api_key:
            if not self.raise_error:
                return ""
            raise HTTPException(status_code=HTTP_403_FORBIDDEN, detail="Missing authorization credentials")

        try:
            token_prefix, token = api_key.split(" ")
        except ValueError:
            raise HTTPException(status_code=HTTP_403_FORBIDDEN, detail="Invalid token schema")

        if token_prefix.lower() not in ["token", "bearer"]:
            raise HTTPException(status_code=HTTP_403_FORBIDDEN, detail="Invalid token schema")

        return token
```

**Supported Token Formats:**
- `Authorization: Token eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
- `Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 5. Dependency Injection (`bobverse/core/dependencies.py`)

Provides authentication dependencies for FastAPI endpoints:

**Required Authentication:**
```python
async def get_current_user(
    token: JWTToken,
    session: DBSession,
    auth_token_service: IAuthTokenService,
    user_service: IUserService,
) -> UserDTO:
    jwt_user = auth_token_service.parse_jwt_token(token=token)
    current_user_dto = await user_service.get_user_by_id(session=session, user_id=jwt_user.user_id)
    return current_user_dto

CurrentUser = Annotated[UserDTO, Depends(get_current_user)]
```

**Optional Authentication:**
```python
async def get_current_user_or_none(
    token: JWTTokenOptional,
    session: DBSession,
    auth_token_service: IAuthTokenService,
    user_service: IUserService,
) -> UserDTO | None:
    if token:
        jwt_user = auth_token_service.parse_jwt_token(token=token)
        current_user_dto = await user_service.get_user_by_id(session=session, user_id=jwt_user.user_id)
        return current_user_dto

CurrentOptionalUser = Annotated[UserDTO | None, Depends(get_current_user_or_none)]
```

## 📋 API Usage Examples

### Registration Request
```http
POST /api/users
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "username": "johndoe",
    "password": "securepassword123"
  }
}
```

### Registration Response
```json
{
  "user": {
    "email": "user@example.com",
    "username": "johndoe",
    "bio": "",
    "image": "https://api.bobnews.io/images/smiley-cyrus.jpeg",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJ1c2VybmFtZSI6ImpvaG5kb2UiLCJleHAiOjE3MDQ5ODc2MDB9.xxx"
  }
}
```

### Login Request
```http
POST /api/users/login
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "password": "securepassword123"
  }
}
```

### Protected Request
```http
GET /api/user
Authorization: Token eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

or

```http
GET /api/user
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 🔒 Security Features

1. **Bcrypt Password Hashing**
   - Industry-standard password security
   - Automatic salt generation
   - Configurable work factor

2. **JWT Tokens**
   - Stateless authentication
   - Configurable expiration (default: 7 days)
   - Signed with secret key to prevent tampering

3. **Token Validation**
   - Verifies signature on each request
   - Checks expiration timestamp
   - Raises exceptions for invalid/expired tokens

4. **Flexible Token Formats**
   - Supports both `Token` and `Bearer` prefixes
   - Standard HTTP Authorization header

5. **Optional Authentication**
   - Allows public endpoints to optionally use authentication
   - Enables personalized responses for authenticated users

## 🔧 Configuration

Authentication settings are configured in `bobverse/core/settings/base.py`:

```python
jwt_secret_key: str  # Secret key for signing JWT tokens
jwt_token_expiration_minutes: int = 60 * 24 * 7  # 7 days
jwt_algorithm: str = "HS256"  # HMAC with SHA-256
```

## ⚠️ Security Notes

### Production Considerations
- Store `jwt_secret_key` securely (environment variables, secrets manager)
- Use HTTPS for all API communications
- Implement rate limiting on authentication endpoints
- Consider token refresh mechanism for long-lived sessions
- Monitor for suspicious authentication patterns

### Vulnerable Code (Demo Only)
The codebase includes intentionally vulnerable functions using MD5 hashing:
- `get_weak_password_hash()` - Uses MD5 (CWE-327: Weak Cryptography)
- `verify_weak_password()` - Uses MD5 for verification

**These functions are for demonstration/testing purposes only and should NEVER be used in production.**

## 📚 Related Files

- `bobverse/services/auth_token.py` - JWT token generation and validation
- `bobverse/services/auth.py` - User authentication logic
- `bobverse/services/password.py` - Password hashing utilities
- `bobverse/core/security.py` - Token extraction from headers
- `bobverse/core/dependencies.py` - FastAPI authentication dependencies
- `bobverse/api/routes/authentication.py` - Authentication API endpoints
- `bobverse/core/settings/base.py` - Authentication configuration