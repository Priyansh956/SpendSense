const jwt = require('jsonwebtoken');

const {getUser, setUser} = require('../services/jwtService');

const restrictToLoggedInUsersOnly = async (req, res, next) => {
    const authHeader = req.headers.authorization;

    if(!authHeader || !authHeader.startsWith("Bearer ")) return res.status(401).json({"message": "Error", "success": false});
    
    const token = authHeader.split(" ")[1];
    try{
        const decodedUser = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decodedUser;
        next();
    }
    catch(err){
        return res.status(401).json("Error");
    }
}

module.exports = {
    restrictToLoggedInUsersOnly,
};
