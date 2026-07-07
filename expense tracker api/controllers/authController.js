const bcrypt = require('bcrypt');

const {User} = require('../models/userModel'); 
const {setUser} = require('../services/jwtService');

async function signUp(req, res) {
    try {
        const body = req.body;

        const existingUser = await User.findOne({ email: body.email });

        if (existingUser) {
            return res.status(409).json({
                message: "An account already exists with this email id",
                success: false,
            });
        }

        const salt = await bcrypt.genSalt(10);
        const encryptedPassword = await bcrypt.hash(body.password, salt);

        await User.create({
            email: body.email,
            password: encryptedPassword,
            categories: body.categories,
        });

        return res.status(201).json({
            message: "Successful",
            success: true,
        });

    } catch (err) {
        console.error(err);

        if (err.code === 11000) {
            return res.status(409).json({
                success: false,
                message: "Email already exists",
            });
        }

        return res.status(500).json({
            success: false,
            message: "Server error",
        });
    }
}


async function userLogin(req, res){
    try{
        const {email} = req.body;
        

        const user = await User.findOne({email});
        if(!user) return res.status(404).json({
            "message": "Invalid email or password",
            "success": false
        });

        const comparison = await bcrypt.compare(
            req.body.password,
            user.password
        );
        
        if(!comparison)return res.status(401).json({
            "message": "Invalid email or password",
            "success": false,
        });

        const token = setUser(user);

        return res.status(200).json({
            "message": "User found",
            "success": true,
            token,
        });
    }
    catch(err){
        return res.status(400).json({
            "message": "User doesn't exist",
            "success": false
        })
    }
}

async function getMe(req, res) {
    try {
        const user = await User.findById(req.user._id).select('-password');
        if (!user) {
            return res.status(404).json({ message: "User not found", success: false });
        }
        return res.status(200).json({ message: "User fetched", success: true, data: user });
    } catch (err) {
        return res.status(500).json({ message: "Error fetching user", success: false });
    }
}

async function updateCategories(req, res) {
    try {
        const { categories } = req.body;
        if (!Array.isArray(categories)) {
            return res.status(400).json({ message: "categories must be an array", success: false });
        }

        const updatedUser = await User.findByIdAndUpdate(
            req.user._id,
            { categories },
            { new: true, runValidators: true }
        ).select('-password');

        return res.status(200).json({ message: "Categories updated", success: true, data: updatedUser });
    } catch (err) {
        return res.status(500).json({ message: "Error updating categories", success: false });
    }
}

module.exports = {
    signUp,
    userLogin,
    getMe,
    updateCategories,
};