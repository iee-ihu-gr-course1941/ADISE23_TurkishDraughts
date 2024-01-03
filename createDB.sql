/*	
    1. Shuffle and deal cards: Start of each round. 			Deal_cards	Done!
    2. Reveal the Trump card (H/E/D/G, J no trumps, W choose).		Trump_card	Done* (TODO: Player choice when Wizard is revealed).
    3. Place bets.							Place_bet 	Done!	
    4. Play the trick.							Play_trick	Done!
    5. Find Winner.							FindWinner	NOT Done!
    6. Shuffle back everything into the deck.				Reset_Board	Done!
    7. Sum points.							Sum_points	Done!
*/
CREATE OR REPLACE TABLE cards (
  Cid tinyint NOT NULL,
  Figure enum('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', 'J', 'W') NOT NULL,
  Class enum('Human', 'Elves', 'Dwarves', 'Giants') NOT NULL,
  Pid integer NULL DEFAULT NULL,
  PRIMARY KEY (Cid, Figure, Class)
);

INSERT INTO cards(Cid, Figure, Class) VALUES
(1,  '1',  'Human'),
(2,  '2',  'Human'),
(3,  '3',  'Human'),
(4,  '4',  'Human'),
(5,  '5',  'Human'),
(6,  '6',  'Human'),
(7,  '7',  'Human'),
(8,  '8',  'Human'),
(9,  '9',  'Human'),
(10, '10', 'Human'),
(11, '11', 'Human'),
(12, '12', 'Human'),
(13, '13', 'Human'),
(14, '1',  'Giants'),
(15, '2',  'Giants'),
(16, '3',  'Giants'),
(17, '4',  'Giants'),
(18, '5',  'Giants'),
(19, '6',  'Giants'),
(20, '7',  'Giants'),
(21, '8',  'Giants'),
(22, '9',  'Giants'),
(23, '10', 'Giants'),
(24, '11', 'Giants'),
(25, '12', 'Giants'),
(26, '13', 'Giants'),
(27, '1',  'Dwarves'),
(28, '2',  'Dwarves'),
(29, '3',  'Dwarves'),
(30, '4',  'Dwarves'),
(31, '5',  'Dwarves'),
(32, '6',  'Dwarves'),
(33, '7',  'Dwarves'),
(34, '8',  'Dwarves'),
(35, '9',  'Dwarves'),
(36, '10', 'Dwarves'),
(37, '11', 'Dwarves'),
(38, '12', 'Dwarves'),
(39, '13', 'Dwarves'),
(40, '1',  'Elves'),
(41, '2',  'Elves'),
(42, '3',  'Elves'),
(43, '4',  'Elves'),
(44, '5',  'Elves'),
(45, '6',  'Elves'),
(46, '7',  'Elves'),
(47, '8',  'Elves'),
(48, '9',  'Elves'),
(49, '10', 'Elves'),
(50, '11', 'Elves'),
(51, '12', 'Elves'),
(52, '13', 'Elves'),
(53, 'J',  'Elves'),
(54, 'J',  'Human'),
(55, 'J',  'Dwarves'),
(56, 'J',  'Giants'),
(57, 'W',  'Elves'),
(58, 'W',  'Human'),
(59, 'W',  'Dwarves'),
(60, 'W',  'Giants');

CREATE OR REPLACE TABLE `players` (
	`Pid` INTEGER NOT NULL AUTO_INCREMENT,	
	`Username` VARCHAR(50) DEFAULT NULL,
	`Token` VARCHAR(50) DEFAULT NULL,
    	`Total_points` INTEGER DEFAULT 0,
	PRIMARY KEY (Pid)
);

CREATE OR REPLACE TABLE `gamedetails` (
	`Status` ENUM('Not active', 'Waiting', 'Playing', 'Finished', 'Aborted') NOT NULL DEFAULT 'not active',
	`Result` ENUM('P1','P2', 'P3', 'P4') NULL DEFAULT NULL,
	`MasterLock` BIT NULL DEFAULT NULL
);

CREATE OR REPLACE TABLE `gamestate` (
    `PlayOrder` INTEGER,
    `Pid` INTEGER NOT NULL,
    `Rounds` INTEGER,         
    `Bet` INTEGER DEFAULT 0,             
    `Rounds_won` INTEGER DEFAULT 0,
    `Card_played` TINYINT NULL DEFAULT NULL,	
    `Master_Class` ENUM('Human', 'Elves', 'Dwarves', 'Giants', 'J', 'W', 'None') NOT NULL,         
    `Trump_Class` ENUM('Human', 'Elves', 'Dwarves', 'Giants', 'J', 'W', 'None') NOT NULL, 
    `LastChange` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`Pid`)
);

-- 1. Shuffle and deal cards: Start of each round.

DELIMITER $$
CREATE OR REPLACE PROCEDURE Deal_cards()		-- Every round.
BEGIN
	-- SET @round = (SELECT Rounds FROM gamestate);
	-- SELECT @round;
    
    	-- SET @rounds = 13;
    
    SET @num := 0;
    UPDATE cards
    SET Pid = 0;					-- CARE! WHICH Pid denotes the deck? 
	
    SET @sql = CONCAT(`UPDATE cards
    SET Pid = MOD(@num := @num + 1, 4) + 1
    ORDER BY RAND()
    LIMIT `, @rounds * 4);

	PREPARE stmt FROM @sql;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;
	

END $$

-- 2. Reveal the Trump card (H/E/D/G, J no trumps, W choose).

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
		WHERE Pid IS NULL						-- CARE! WHICH Pid denotes the deck?
		ORDER BY RAND()
		LIMIT 1);
		SET @Trump_Class = (SELECT Class
		FROM cards
		WHERE Cid = @Trump_Cid);
		
		IF(@Trump_Class = 'J') THEN
			-- NO TRUMPS THIS TIME!
            		UPDATE gamestate SET Trump_Class = 'None';
		ELSEIF(@Trump_Class = 'W') THEN
			-- PLAYER WILL CHOOSE THE CLASS!
            		-- CALL choose_class_for_trump();			-- FIX ME LATER!
			UPDATE gamestate SET Trump_Class = @Trump_Class;	-- DELETE ME LATER!
        	ELSE
			UPDATE cards SET Pid = 6 WHERE Cid = @Trump_Cid;
            		UPDATE gamestate SET Trump_Class = @Trump_Class;
		END IF;
	END IF;
    
END $$

-- 3. Place bets.

DELIMITER $$
CREATE OR REPLACE PROCEDURE Place_bet(IN p INTEGER, IN b INTEGER, OUT exitcode TINYINT)
BEGIN
    
    	IF ((SELECT Bet FROM gamestate WHERE Pid = p) IS NULL) THEN
		
        	IF(b > (SELECT Rounds FROM gamestate WHERE Pid = p)) THEN
            		UPDATE gamestate SET Bet = b WHERE Pid = p;
            		SET exitcode = 0;						-- ΟΚ.
        	ELSE
            		SET exitcode = 1; 						-- Advice: Lost no matter what...
        	END IF;
	ELSE
		SET exitcode = 2; 					-- Notice: You 've already placed your bet..
    	END IF;
END $$

-- 4. Play the trick.

DELIMITER $$
CREATE OR REPLACE PROCEDURE Play_trick(IN p INTEGER, IN Card_played TINYINT, OUT exitcode TINYINT)
BEGIN
	
	IF((SELECT Pid FROM cards WHERE cid = Card_played) = p) THEN
		SET exitcode = 3;					-- Notice: Illegal move!
        
									-- Λγκ joker στις αρχικές συνθήκες;
		IF((SELECT Master_Class FROM gamestate) = (SELECT Class FROM cards WHERE cid = Card_played)
        	OR (SELECT Master_Class FROM gamestate) = `J` 
        	OR (SELECT Master_Class FROM gamestate) = `W` 
        	OR NOT((SELECT Master_Class FROM gamestate WHERE Master_Class NOT IN (SELECT Class FROM cards WHERE Pid = p)))) THEN
			
        
            		SET exitcode = 0;				-- ΟΚ.
			UPDATE cards
			SET Pid = 5					
			WHERE Cid = Card_played;			-- CARE! WHICH Pid denotes played cards stack?
			
			IF((SELECT Master_Class FROM gamestate) = `J`) THEN
				UPDATE gamestate SET Master_Class = (SELECT Class FROM cards WHERE Cid = Card_played);
				
                		SET exitcode = 1;			-- Legal move + define Master_Class.
			END IF;
		 END IF;
     	ELSE
		SET exitcode = 2;					-- Notice: Illegal move, specified card does not exist in Pid=p hand.
	END IF;
	SELECT exitcode;
    
END $$

-- 5. Find Winner.

-- 6. Shuffle back everything into the deck.

DELIMITER $$
CREATE OR REPLACE PROCEDURE Reset_Board()
BEGIN	
	UPDATE cards SET Pid = NULL WHERE Pid = 5;
END $$

-- 7. Sum points.

DELIMITER $$
CREATE OR REPLACE PROCEDURE Sum_points()
BEGIN

    SET @B1 := (SELECT Bet FROM gamestate WHERE Pid=1);
    SELECT @B1 AS 'B1_Value';

    SET @B2 := (SELECT Bet FROM gamestate WHERE Pid=2);
    SELECT @B2 AS 'B2_Value';

    SET @B3 := (SELECT Bet FROM gamestate WHERE Pid=3);
    SELECT @B3 AS 'B3_Value';

    SET @B4 := (SELECT Bet FROM gamestate WHERE Pid=4);
    SELECT @B4 AS 'B4_Value';
    
    SET @Rw1 := (SELECT Rounds_won FROM gamestate WHERE Pid=1);
    SET @Rw2 := (SELECT Rounds_won FROM gamestate WHERE Pid=2);
    SET @Rw3 := (SELECT Rounds_won FROM gamestate WHERE Pid=3);
    SET @Rw4 := (SELECT Rounds_won FROM gamestate WHERE Pid=4);
    
    
    IF(SELECT ABS(@B1-@Rw1) = 0) THEN
	UPDATE players SET Total_points = Total_points + 20 + (@Rw1 * 10) WHERE Pid = 1;
    ELSE
	UPDATE players SET Total_points = Total_points - (@Rw1 * 10) WHERE Pid = 1;
    END IF;

    UPDATE gamestate SET Bet = 0, Rounds_won = 0 WHERE Pid = 1;
    
    IF(SELECT ABS(@B2-@Rw2) = 0) THEN
	UPDATE players SET Total_points = Total_points + 20 + (@Rw2 * 10) WHERE Pid = 2;
    ELSE
	UPDATE players SET Total_points = Total_points - (@Rw2 * 10) WHERE Pid = 2;
    END IF;

    UPDATE gamestate SET Bet = 0, Rounds_won = 0 WHERE Pid = 2;
    
    IF(SELECT ABS(@B3-@Rw3) = 0) THEN
	UPDATE players SET Total_points = Total_points + 20 + (@Rw3 * 10) WHERE Pid = 3;
    ELSE
	UPDATE players SET Total_points = Total_points - (@Rw3 * 10) WHERE Pid = 3;
    END IF;

    UPDATE gamestate SET Bet = 0, Rounds_won = 0 WHERE Pid = 3;
    
    IF(SELECT ABS(@B4-@Rw4) = 0) THEN
	UPDATE players SET Total_points = Total_points + 20 + (@Rw4 * 10) WHERE Pid = 4;
    ELSE
	UPDATE players SET Total_points = Total_points - (@Rw4 * 10) WHERE Pid = 4;
    END IF;

    UPDATE gamestate SET Bet = 0, Rounds_won = 0 WHERE Pid = 4;
    
END $$

