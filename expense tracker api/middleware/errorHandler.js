const errorHandler = (error, req, res, next) => {
    if(error.isOperational){
        return res.status(error.statusCode).json({
            "success": false,
            "message": error.message,
        });
    }

    console.error("BUG: ", error.stack);

    res.status(500).json({
        "success": false,
        "message": "Something went wrong",
    });
}

module.exports = {errorHandler};