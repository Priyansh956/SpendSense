class AppError extends Error{
    constructor (message, statusCode){
        super(message);
        this.name = "AppError";
        this.statusCode = statusCode;
        this.isOperational = true;
        Error.captureStackTrace(this, this.constructor);
    }
}

class NotFoundError extends AppError{
    constructor(resource) {
        super(`${resource} not found`, 404);
        this.name = "NotFoundError";
    }
}

class ValidationError extends AppError{
    constructor(message) {
        super(message, 400);
        this.name = "ValidationError";
    }
}

class UnauthorizedError extends AppError{
    constructor(){
        super("Authentication Required", 401);
        this.name = "UnauthorizedError";
    }
}

class ForbiddenError extends AppError{
    constructor(){
        super("You don't have permission to do this", 403);
        this.name = "ForbiddenError";
    }
}



module.exports = {
    AppError,
    NotFoundError,
    UnauthorizedError,
    ForbiddenError,
}