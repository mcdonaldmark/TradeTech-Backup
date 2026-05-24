const express = require("express");
const router = express.Router();
const pool = require("../config/db");
const bcrypt = require("bcrypt");
const authMiddleware = require("../middleware/authMiddleware");

router.use(authMiddleware);

/*
  MANAGER + DIRECTOR ONLY
*/
router.get("/", async (req,res)=>{
  if(!["manager","director"].includes(req.user.role)){
    return res.status(403).json({error:"Not allowed"});
  }

  const result = await pool.query("SELECT * FROM users");
  res.json(result.rows);
});

router.post("/", async (req,res)=>{
  if(!["manager","director"].includes(req.user.role)){
    return res.status(403).json({error:"Not allowed"});
  }

  const {name,email,password,role} = req.body;

  const hash = await bcrypt.hash(password,10);

  const result = await pool.query(
    "INSERT INTO users(name,email,password,role) VALUES ($1,$2,$3,$4) RETURNING *",
    [name,email,hash,role]
  );

  res.json(result.rows[0]);
});

module.exports = router;