
CREATE OR REPLACE TABLE cards (
  Cid tinyint NOT NULL,
  Figure enum('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', 'J', 'W') NOT NULL,
  Class enum('Human', 'Elves', 'Dwarves', 'Giants') NOT NULL,
  Pid INTEGER DEFAULT 0,
  PRIMARY KEY (Cid, Figure, Class)
);

INSERT INTO cards(Cid, Figure, Class) VALUES
(1, '1', 'Human'),
(2, '2', 'Human'),
(3, '3', 'Human'),
(4, '4', 'Human'),
(5, '5', 'Human'),
(6, '6', 'Human'),
(7, '7', 'Human'),
(8, '8', 'Human'),
(9, '9', 'Human'),
(10, '10', 'Human'),
(11, '11', 'Human'),
(12, '12', 'Human'),
(13, '13', 'Human'),
(14, '1', 'Giants'),
(15, '2', 'Giants'),
(16, '3', 'Giants'),
(17, '4', 'Giants'),
(18, '5', 'Giants'),
(19, '6', 'Giants'),
(20, '7', 'Giants'),
(21, '8', 'Giants'),
(22, '9', 'Giants'),
(23, '10', 'Giants'),
(24, '11', 'Giants'),
(25, '12', 'Giants'),
(26, '13', 'Giants'),
(27, '1', 'Dwarves'),
(28, '2', 'Dwarves'),
(29, '3', 'Dwarves'),
(30, '4', 'Dwarves'),
(31, '5', 'Dwarves'),
(32, '6', 'Dwarves'),
(33, '7', 'Dwarves'),
(34, '8', 'Dwarves'),
(35, '9', 'Dwarves'),
(36, '10', 'Dwarves'),
(37, '11', 'Dwarves'),
(38, '12', 'Dwarves'),
(39, '13', 'Dwarves'),
(40, '1', 'Elves'),
(41, '2', 'Elves'),
(42, '3', 'Elves'),
(43, '4', 'Elves'),
(44, '5', 'Elves'),
(45, '6', 'Elves'),
(46, '7', 'Elves'),
(47, '8', 'Elves'),
(48, '9', 'Elves'),
(49, '10', 'Elves'),
(50, '11', 'Elves'),
(51, '12', 'Elves'),
(52, '13', 'Elves'),
(53, 'J', 'Elves'),
(54, 'J', 'Human'),
(55, 'J', 'Dwarves'),
(56, 'J', 'Giants'),
(57, 'W', 'Elves'),
(58, 'W', 'Human'),
(59, 'W', 'Dwarves'),
(60, 'W', 'Giants');

CREATE OR REPLACE TABLE `players` (
	`Pid` INTEGER NOT NULL AUTO_INCREMENT,	
	`Username` VARCHAR(50) DEFAULT NULL,
	`Token` VARCHAR(50) DEFAULT NULL,
    `Total_points` INTEGER DEFAULT 0,
	PRIMARY KEY (Pid)
);

CREATE OR REPLACE TABLE `gamedetails` (
	`Status` ENUM('Not active', 'Waiting', 'Playing', 'Finished') NOT NULL DEFAULT 'Not active',
	`Result` ENUM('P1','P2', 'P3', 'P4') NULL DEFAULT NULL
);
INSERT INTO gamedetails VALUES ('Not active', NULL);

CREATE OR REPLACE TABLE `gamestate` (
    `PlayOrder` INTEGER,
    `Pid` INTEGER NOT NULL,
    `Rounds` INTEGER DEFAULT 1,         
    `Bet` INTEGER NULL DEFAULT NULL,             
    `Rounds_won` INTEGER DEFAULT 0,
    `Card_played` TINYINT NULL DEFAULT NULL,
    `Master_Class` ENUM('Human', 'Elves', 'Dwarves', 'Giants', 'J', 'W') NOT NULL DEFAULT 'J',         
    `Trump_Class` ENUM('Human', 'Elves', 'Dwarves', 'Giants', 'J', 'W', 'None') NOT NULL DEFAULT 'None', 
    PRIMARY KEY (`Pid`)
);

-- ==================== FOR TESTING ==========================
-- SELECT * FROM cards WHERE Pid<>0 and Pid<>6 ORDER BY Pid;
-- SELECT * FROM gamestate;
-- SELECT * FROM players;
-- CALL PrepareGame();
-- INSERT INTO players (Pid, Username, Token) VALUES(1, 'KGL', 'kasdf');
-- INSERT INTO players (Pid, Username, Token) VALUES(2, 'AGL', 'aasdf');
-- INSERT INTO players (Pid, Username, Token) VALUES(3, 'WGL', 'wasdf');
-- INSERT INTO players (Pid, Username, Token) VALUES(4, 'FGL', 'fasdf');
-- CALL Deal_cards();
-- CALL Trump_card();
-- SET @exitcode_value = NULL;
-- CALL Place_bet(1, 0, @exitcode_value);
-- CALL Place_bet(2, 1, @exitcode_value);
-- CALL Place_bet(3, 0, @exitcode_value);
-- CALL Place_bet(4, 1, @exitcode_value);

-- CALL Play_trick(1, 29, @exitcode_value);	-- Pid, cid
-- CALL Play_trick(2, 18, @exitcode_value);	-- Pid, cid
-- CALL Play_trick(3, 56, @exitcode_value);	-- Pid, cid
-- CALL Play_trick(4, 14, @exitcode_value);	-- Pid, cid
-- CALL FindWinner(@exitcode_value);
-- CALL Sum_points();

-- 0. Start game.
DELIMITER $$
CREATE OR REPLACE PROCEDURE PrepareGame()
BEGIN
	SET SQL_SAFE_UPDATES = 0;
	TRUNCATE TABLE players;

	TRUNCATE TABLE gamestate;
	INSERT INTO gamestate(PlayOrder, Pid) VALUES (1, 1), (2, 2), (3, 3), (4, 4);
   
	TRUNCATE TABLE gamedetails;
	INSERT INTO gamedetails VALUES ('Not active', NULL);
END $$

-- 1. Deal K cards, for K round.
DELIMITER $$
CREATE OR REPLACE PROCEDURE Deal_cards()
BEGIN

    SET @num := 0;
    UPDATE cards SET Pid = 0;
	SELECT Rounds INTO @rounds FROM gamestate LIMIT 1;
    
    SET @sql = CONCAT('UPDATE cards
    SET Pid = MOD(@num := @num + 1, 4) + 1
    ORDER BY RAND()
    LIMIT ', @rounds * 4);

	PREPARE stmt FROM @sql;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;

END $$

-- 2. Reveal the Trump card (H/E/D/G, J no trumps, W remain).	
DELIMITER $$
CREATE OR REPLACE PROCEDURE Trump_card()
BEGIN 
   
	SELECT Rounds INTO @current_rounds FROM gamestate WHERE Pid = 1;
    
	IF(@current_rounds=15) THEN
		-- NO TRUMPS THIS TIME!
        UPDATE gamestate SET Trump_Class = 'None';
	ELSE
		SET @Trump_Cid = (SELECT Cid
		FROM cards
		WHERE Pid = 0
		ORDER BY RAND()
		LIMIT 1);
		SET @Trump_Class = (SELECT Class
		FROM cards
		WHERE Cid = @Trump_Cid);
		
		IF(@Trump_Class = 'J') THEN
			-- NO TRUMPS THIS TIME!
            UPDATE gamestate SET Trump_Class = 'None';
		-- ELSEIF(@Trump_Class = 'W') THEN							-- REMAIN.
-- 			UPDATE gamestate SET Trump_Class = @Trump_Class;	-- DELETE ME LATER!

        ELSE
			UPDATE cards SET Pid = 6 WHERE Cid = @Trump_Cid;
            UPDATE gamestate SET Trump_Class = @Trump_Class;
		END IF;
	END IF;
    
END $$

-- 3. Place bets. [x4]
DELIMITER $$
CREATE OR REPLACE PROCEDURE Place_bet(IN p INTEGER, IN b INTEGER, OUT exitcode TINYINT)
BEGIN
    
    
    IF ((SELECT Bet FROM gamestate WHERE Pid = p) IS NULL) THEN
		
        IF(b <= (SELECT Rounds FROM gamestate WHERE Pid = p)) THEN
            UPDATE gamestate SET Bet = b WHERE Pid = p;
            SET exitcode = 0;	-- All good.
        ELSE
            SET exitcode = 1; 	-- Advice: You will lose whatever happens.
        END IF;
	ELSE
		SET exitcode = 2; 		-- Error: You already have placed your bet.
    END IF;
    SELECT exitcode;
    
END $$

-- 4. Play the tricks (Round No K, has K tricks therefore each player has K cards). [x4]
DELIMITER $$
CREATE OR REPLACE PROCEDURE Play_trick(IN p INTEGER, IN Card_played TINYINT, OUT exitcode TINYINT)
BEGIN
	
    IF((SELECT Pid FROM cards WHERE cid = Card_played) = p) THEN
		SET exitcode = 3;	-- Error: Not the appropriate card!
        
        -- Follows Master_Class OR throws Joker/Wizard OR does NOT follow Master_Class (iff he doesn't have Master_Class card on his hand)?
		IF((SELECT Master_Class FROM gamestate LIMIT 1) = (SELECT Class FROM cards WHERE cid = Card_played)
        OR (SELECT Figure FROM cards WHERE Cid = Card_played LIMIT 1) = 'J' 
        OR (SELECT Figure FROM cards WHERE Cid = Card_played LIMIT 1) = 'W' 
        OR ((SELECT Master_Class FROM gamestate LIMIT 1) = 'J')
        OR (((SELECT Master_Class FROM gamestate WHERE Master_Class LIMIT 1) NOT IN (SELECT Class FROM cards WHERE Pid = p)))) THEN
			
        
            SET exitcode = 0;			-- ΟΚ.
			UPDATE cards
			SET Pid = 5	
			WHERE Cid = Card_played;
			UPDATE gamestate SET Card_played = Card_played WHERE Pid = p;
            CALL CalcPlayOrder(p);
            
			IF((SELECT Master_Class FROM gamestate LIMIT 1) = 'J') THEN
            
				IF((SELECT Figure FROM cards WHERE Cid = Card_played LIMIT 1) <> 'J')THEN
					UPDATE gamestate SET Master_Class = (SELECT Class FROM cards WHERE Cid = Card_played);
				END IF;
                
                SET exitcode = 1;		-- OK, ALSO defined Master_Class.
			END IF;
		 END IF;
     ELSE
		SET exitcode = 2;				-- Error: Does not have the card on his hand!
	END IF;
	SELECT exitcode;
    
END $$

-- 5a. Find who won the trick. If he won, he will play first on the next trick.
DELIMITER $$
CREATE OR REPLACE PROCEDURE FindWinner(OUT exitcode TINYINT)	-- Did he win the trick? If so, Rounds_won + 1 and PlayOrder changes accordingly.
BEGIN
	
    /* 
		Did someone play a wizard? If so the first one who played it, wins.
		Did someone play a trump card? If so the highest of them, wins.
        Did someone play a master card? If so the highest of them, wins.
    */
	SELECT Pid INTO @wizardwinner FROM gamestate WHERE Card_played = 57 OR Card_played = 58 OR Card_played = 59 OR Card_played = 60 ORDER BY Pid LIMIT 1;
    SELECT g.Pid INTO @atouwinner FROM cards c join gamestate g on (c.Cid=g.Card_played) WHERE c.Class = g.Trump_class AND c.Figure <> 'J' ORDER BY c.Figure DESC LIMIT 1;
	SELECT g.Pid INTO @masterwinner FROM cards c join gamestate g on (c.Cid=g.Card_played) WHERE c.Class = g.Master_class AND c.Figure <> 'J' ORDER BY c.Figure DESC LIMIT 1;
	
    IF(@wizardwinner IS NOT NULL) THEN
		UPDATE gamestate SET Rounds_won = Rounds_won + 1 WHERE Pid = @wizardwinner;
        SET @winner = @wizardwinner;
    ELSE
		IF(@atouwinner IS NOT NULL) THEN 
			UPDATE gamestate SET Rounds_won = Rounds_won + 1 WHERE Pid = @atouwinner;
            SET @winner = @atouwinner;
        ELSE
			UPDATE gamestate SET Rounds_won = Rounds_won + 1 WHERE Pid = @masterwinner;
            SET @winner = @masterwinner;
        END IF;
    END IF;
    UPDATE gamestate SET Card_played = NULL;
    SET exitcode = @winner;
    SELECT(exitcode);
    
    CALL CalcPlayOrder(@winner);

END $$

-- 5b. Calculate the PlayOrder.
DELIMITER $$
CREATE OR REPLACE PROCEDURE CalcPlayOrder(IN p INTEGER)
BEGIN
	IF (p = 1) OR (p = 5) THEN
		UPDATE gamestate SET PlayOrder = 1 WHERE pid = 1;
		UPDATE gamestate SET PlayOrder = 2 WHERE pid = 2;
		UPDATE gamestate SET PlayOrder = 3 WHERE pid = 3;
		UPDATE gamestate SET PlayOrder = 4 WHERE pid = 4;
		
	ELSEIF (p = 2) THEN
		UPDATE gamestate SET PlayOrder = 1 WHERE pid = 2;
		UPDATE gamestate SET PlayOrder = 2 WHERE pid = 3;
		UPDATE gamestate SET PlayOrder = 3 WHERE pid = 4;
		UPDATE gamestate SET PlayOrder = 4 WHERE pid = 1;
		
	ELSEIF (p = 3) THEN
		UPDATE gamestate SET PlayOrder = 1 WHERE pid = 3;
		UPDATE gamestate SET PlayOrder = 2 WHERE pid = 4;
		UPDATE gamestate SET PlayOrder = 3 WHERE pid = 1;
		UPDATE gamestate SET PlayOrder = 4 WHERE pid = 2;
		
	ELSEIF (p = 4) THEN
		UPDATE gamestate SET PlayOrder = 1 WHERE pid = 4;
		UPDATE gamestate SET PlayOrder = 2 WHERE pid = 1;
		UPDATE gamestate SET PlayOrder = 3 WHERE pid = 2;
		UPDATE gamestate SET PlayOrder = 4 WHERE pid = 3;
	END IF;
END $$

-- 6. Add/Subtract points for this round + reset the board.
DELIMITER $$
CREATE OR REPLACE PROCEDURE Sum_points()
BEGIN
	SET @B1 := (SELECT Bet FROM gamestate WHERE Pid=1);
    SET @B2 := (SELECT Bet FROM gamestate WHERE Pid=2);
    SET @B3 := (SELECT Bet FROM gamestate WHERE Pid=3);
    SET @B4 := (SELECT Bet FROM gamestate WHERE Pid=4);
    
    SET @Rw1 := (SELECT Rounds_won FROM gamestate WHERE Pid=1);
    SET @Rw2 := (SELECT Rounds_won FROM gamestate WHERE Pid=2);
    SET @Rw3 := (SELECT Rounds_won FROM gamestate WHERE Pid=3);
    SET @Rw4 := (SELECT Rounds_won FROM gamestate WHERE Pid=4);
    
    
    IF(SELECT ABS(@B1-@Rw1) = 0) THEN
		UPDATE players SET Total_points = Total_points + 20 + (@Rw1 * 10) WHERE Pid = 1;
	ELSE
		UPDATE players SET Total_points = Total_points - (ABS(@B1-@Rw1) * 10) WHERE Pid = 1;
    END IF;
    
    IF(SELECT ABS(@B2-@Rw2) = 0) THEN
		UPDATE players SET Total_points = Total_points + 20 + (@Rw2 * 10) WHERE Pid = 2;
	ELSE
		UPDATE players SET Total_points = Total_points - (ABS(@B2-@Rw2) * 10) WHERE Pid = 2;
    END IF;
    
    IF(SELECT ABS(@B3-@Rw3) = 0) THEN
		UPDATE players SET Total_points = Total_points + 20 + (@Rw3 * 10) WHERE Pid = 3;
	ELSE
		UPDATE players SET Total_points = Total_points - (ABS(@B3-@Rw3) * 10) WHERE Pid = 3;
    END IF;
    
    IF(SELECT ABS(@B4-@Rw4) = 0) THEN
		UPDATE players SET Total_points = Total_points + 20 + (@Rw4 * 10) WHERE Pid = 4;
	ELSE
		UPDATE players SET Total_points = Total_points - (ABS(@B4-@Rw4) * 10) WHERE Pid = 4;
    END IF;
    
    UPDATE gamestate SET Bet = NULL, Rounds_won = 0, Master_Class = 'J', Rounds = Rounds + 1;
    UPDATE cards SET Pid = 0 WHERE Pid = 5;
    
END $$

/* =========== */
/* |UTILITIES| */
/* =========== */
DELIMITER $$
CREATE OR REPLACE PROCEDURE AddPlayer(IN Pname VARCHAR(50), IN t VARCHAR(50), OUT ExitCode INTEGER)
BEGIN
    SET @NumOfP := (SELECT COUNT(*) FROM players);

    IF EXISTS (SELECT * FROM players WHERE Token = t) THEN
        SET ExitCode = 2;										-- Error: Player already exists!
    ELSEIF @NumOfP < 4 THEN
        INSERT INTO players(Username, Token) VALUES (Pname, t);
        UPDATE gamedetails SET status = `Waiting`, Result = NULL;
        SET ExitCode = 0;                                       -- All good.
    ELSE
        SET ExitCode = 1;                                       -- Error: Only 4 players can play the game!
    END IF;

    SELECT ExitCode;	
END $$

DELIMITER $$
CREATE OR REPLACE PROCEDURE ShowHand (IN p INTEGER)
BEGIN
	SELECT Cid, Figure, Class FROM cards WHERE pid=p;
END $$

DELIMITER $$
CREATE OR REPLACE PROCEDURE TokenToPid (IN t VARCHAR(50))
BEGIN	
	SELECT Pid FROM players WHERE Token=t;
END $$

DELIMITER $$
CREATE OR REPLACE PROCEDURE AllowedToPlay(IN p INTEGER)
BEGIN
    SET @PlayerToPlay = (SELECT pid FROM gamestate WHERE PlayOrder = 1);

    IF p = @PlayerToPlay THEN
        SET @Allowed = 0;
    ELSE
        SET @Allowed = 1;	
    END IF;
    
    SELECT @Allowed;
END $$
