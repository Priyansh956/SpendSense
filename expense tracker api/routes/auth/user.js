const express = require('express');

const {restrictToLoggedInUsersOnly} = require('../../middleware/auth');
const {signUp, userLogin, getMe, updateCategories} = require('../../controllers/authController');

const router = express.Router();

router.post('/signup', signUp);
router.post('/login', userLogin);

router.get('/me', restrictToLoggedInUsersOnly, getMe);
router.patch('/categories', restrictToLoggedInUsersOnly, updateCategories);

module.exports = router;